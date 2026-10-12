import SwiftUI
import WebKit

/// SwiftUI owns the interface. The original offline algorithms run in an isolated WKWebView.
@MainActor
final class PhotoEngine: NSObject, ObservableObject, WKNavigationDelegate {
  let webView: WKWebView
  @Published private(set) var loaded = false
  private var navigationError: Error?
  private(set) var needsReload = false
  var onFailure: (() -> Void)?
  var operationTimeout: TimeInterval = 120

  func restart() {
    webView.stopLoading()
    loaded = false
    loadStarted = false
    navigationError = nil
    needsReload = false
    load()
  }

  private func fail(_ error: Error) {
    navigationError = error
    loaded = false
    needsReload = true
    onFailure?()
  }
  private var loadStarted = false
  override init() {
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()
    #if targetEnvironment(simulator)
      // The iOS 27 simulator can stall when initializing the WebGL backend.
      // The physical app continues to use the faster GPU backend.
      configuration.userContentController.addUserScript(WKUserScript(
        source: "window.TCONPreferCPU = true;", injectionTime: .atDocumentStart,
        forMainFrameOnly: true))
    #endif
    configuration.userContentController.addScriptMessageHandler(
      PersonSegmentationHandler(), contentWorld: .page, name: "segmentPerson")
    webView = WKWebView(
      frame: CGRect(x: 0, y: 0, width: 390, height: 844), configuration: configuration)
    super.init()
    webView.navigationDelegate = self
    webView.isOpaque = false
    webView.isUserInteractionEnabled = false
    webView.accessibilityElementsHidden = true
    webView.scrollView.isScrollEnabled = false
  }
  func load() {
    guard !loadStarted else { return }
    loadStarted = true
    guard
      let url = Bundle.main.url(
        forResource: "engine", withExtension: "html", subdirectory: "Engine")
    else {
      fail(AppFailure("사진 처리 파일을 찾을 수 없어요."))
      return
    }
    do {
      // The engine is self-contained. Loading its text avoids file-access grants
      // to WebKit helper processes and needs no filesystem or network navigation.
      let html = try String(contentsOf: url, encoding: .utf8)
      webView.loadHTMLString(html, baseURL: nil)
    } catch { fail(error) }
  }
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    if !needsReload { loaded = true }
  }
  func webView(
    _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) { fail(error) }
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    fail(error)
  }
  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    fail(AppFailure("사진 처리가 중단됐어요. 홈에서 다시 시도하면 보관된 사진을 불러옵니다."))
  }
  func webView(
    _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    decisionHandler(navigationAction.request.url?.absoluteString == "about:blank" ? .allow : .cancel)
  }
  func call<T: Decodable>(_ command: String, _ payload: [String: Any] = [:], as: T.Type = T.self)
    async throws -> T
  {
    load()
    let start = Date()
    while !loaded {
      if let error = navigationError { throw error }
      if Date().timeIntervalSince(start) > 30 {
        let error = AppFailure("사진 도구를 준비하지 못했어요. 홈에서 다시 시도해 주세요.")
        fail(error)
        throw error
      }
      try await Task.sleep(nanoseconds: 50_000_000)
    }
    if let error = navigationError { throw error }
    let value: Any?
    do {
      value = try await withCheckedThrowingContinuation { continuation in
        // A stuck JavaScript promise must not leave the whole app blocked forever.
        var finished = false
        let timeout = Task { @MainActor [weak self] in
          do { try await Task.sleep(for: .seconds(self?.operationTimeout ?? 120)) }
          catch { return }
          guard !finished else { return }
          finished = true
          let error = AppFailure("사진 처리 시간이 초과됐어요. 홈에서 다시 시도해 주세요.")
          self?.fail(error)
          continuation.resume(throwing: error)
        }
        webView.callAsyncJavaScript(
          "return await window.TCONNative.execute(command, payload);",
          arguments: ["command": command, "payload": payload], in: nil, in: .page
        ) { result in
          guard !finished else { return }
          finished = true
          timeout.cancel()
          continuation.resume(with: result.map { $0 as Any? })
        }
      }
    } catch {
      let failure = error as NSError
      if failure.domain == WKError.errorDomain,
        [WKError.Code.unknown.rawValue, WKError.Code.webContentProcessTerminated.rawValue,
         WKError.Code.webViewInvalidated.rawValue].contains(failure.code)
      {
        let recovery = AppFailure("사진 처리가 중단됐어요. 홈에서 다시 시도하면 보관된 사진을 불러옵니다.")
        fail(recovery)
        throw recovery
      }
      let details = (error as NSError).userInfo["WKJavaScriptExceptionMessage"] as? String
      throw AppFailure(
        details?.replacingOccurrences(of: "Error: ", with: "") ?? error.localizedDescription)
    }
    guard let value else { throw AppFailure("사진 처리 결과를 받지 못했어요.") }
    return try JSONDecoder().decode(
      T.self, from: JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed]))
  }
}
struct EngineHost: UIViewRepresentable {
  @ObservedObject var engine: PhotoEngine
  func makeUIView(context: Context) -> WKWebView {
    engine.load()
    return engine.webView
  }
  func updateUIView(_ uiView: WKWebView, context: Context) {}
}
