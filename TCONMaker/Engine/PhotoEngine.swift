import SwiftUI
import WebKit

/// SwiftUI owns the interface. The original offline algorithms run in an isolated WKWebView.
@MainActor
final class PhotoEngine: NSObject, ObservableObject, WKNavigationDelegate {
    let webView: WKWebView
    @Published private(set) var loaded = false
    private var navigationError: Error?
    private var loadStarted = false
    override init() {
        let configuration=WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        webView=WKWebView(frame:CGRect(x:0,y:0,width:390,height:844),configuration:configuration)
        super.init()
        webView.navigationDelegate=self
        webView.isOpaque=false
        webView.isUserInteractionEnabled=false
        webView.accessibilityElementsHidden=true
        webView.scrollView.isScrollEnabled=false
    }
    func load() {
        guard !loadStarted else { return }; loadStarted=true
        guard let url=Bundle.main.url(forResource:"engine",withExtension:"html",subdirectory:"Engine") else { navigationError=AppFailure("사진 처리 파일을 찾을 수 없어요.");return }
        webView.loadFileURL(url,allowingReadAccessTo:url.deletingLastPathComponent())
    }
    func webView(_ webView:WKWebView,didFinish navigation:WKNavigation!) { loaded=true }
    func webView(_ webView:WKWebView,didFailProvisionalNavigation navigation:WKNavigation!,withError error:Error) { navigationError=error }
    func webView(_ webView:WKWebView,didFail navigation:WKNavigation!,withError error:Error) { navigationError=error }
    func webViewWebContentProcessDidTerminate(_ webView:WKWebView) {
        loaded=false;navigationError=AppFailure("사진 처리 작업이 메모리 부족으로 중단됐어요. 앱을 다시 열어 사진을 적게 선택해 주세요.")
    }
    func webView(_ webView:WKWebView,decidePolicyFor navigationAction:WKNavigationAction,decisionHandler:@escaping (WKNavigationActionPolicy)->Void) {
        decisionHandler(navigationAction.request.url?.isFileURL == true ? .allow : .cancel)
    }
    func call<T:Decodable>(_ command:String,_ payload:[String:Any]=[:],as:T.Type=T.self) async throws -> T {
        load()
        let start=Date()
        while !loaded {
            if let error=navigationError { throw error }
            if Date().timeIntervalSince(start)>30 { throw AppFailure("사진 처리 화면을 준비하지 못했어요. 앱을 다시 열어 주세요.") }
            try await Task.sleep(nanoseconds:50_000_000)
        }
        if let error=navigationError { throw error }
        let value:Any?
        do {
            value=try await webView.callAsyncJavaScript("return await window.TCONNative.execute(command, payload);",arguments:["command":command,"payload":payload],in:nil,contentWorld:.page)
        } catch {
            let details=(error as NSError).userInfo["WKJavaScriptExceptionMessage"] as? String
            throw AppFailure(details?.replacingOccurrences(of:"Error: ",with:"") ?? error.localizedDescription)
        }
        guard let value else { throw AppFailure("사진 처리 결과를 받지 못했어요.") }
        return try JSONDecoder().decode(T.self,from:JSONSerialization.data(withJSONObject:value,options:[.fragmentsAllowed]))
    }
}
struct EngineHost: UIViewRepresentable {
    @ObservedObject var engine:PhotoEngine
    func makeUIView(context:Context)->WKWebView { engine.load();return engine.webView }
    func updateUIView(_ uiView:WKWebView,context:Context) {}
}
