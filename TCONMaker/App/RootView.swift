import AVFoundation
import PhotosUI
import SwiftUI

struct RootView: View {
  @StateObject private var store = PhotoStore()
  var body: some View {
    TabView(selection: $store.selectedTab) {
      NavigationStack { StartView() }
        .tabItem { Label("홈", systemImage: "house") }.tag(AppTab.home)
      NavigationStack(path: $store.path) {
        FolderLibraryView()
          .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .folder(let id): BatchView(folderID: id)
            case .editor(let id): EditorView(initialID: id, folderID: store.folderID(for: id))
            case .export(let ids): ExportView(ids: ids)
            }
          }
      }.tabItem { Label("파일", systemImage: "folder") }.tag(AppTab.files)
    }
    .background(
      EngineHost(engine: store.engine).frame(width: 2, height: 2).opacity(0.01).accessibilityHidden(
        true)
    )
    .environmentObject(store).tint(.seolin)
    .overlay {
      if store.busy {
        ZStack {
          Color.black.opacity(0.18).ignoresSafeArea()
          VStack(spacing: 16) {
            ProgressView()
            Text(store.progress.isEmpty ? "처리 중…" : store.progress).font(
              .subheadline.weight(.medium))
          }.padding(28).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }.accessibilityIdentifier("processingOverlay")
      }
    }
    .alert(
      store.error == nil ? "안내" : "작업을 확인해 주세요",
      isPresented: Binding(
        get: { store.error != nil || store.notice != nil },
        set: { if !$0 { clearMessage() } })
    ) {
      if store.error != nil && store.permissionHelp {
        Button("설정 열기") {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
          clearMessage()
        }
      }
      Button("확인", role: .cancel) { clearMessage() }
    } message: {
      Text(store.error ?? store.notice ?? "")
    }
    .task { await store.prepare() }
  }
  private func clearMessage() {
    store.error = nil
    store.notice = nil
  }
}
