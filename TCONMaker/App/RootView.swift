import AVFoundation
import PhotosUI
import SwiftUI

struct RootView: View {
  @StateObject private var store = PhotoStore()
  var body: some View {
    NavigationStack(path: $store.path) {
      StartView()
        .navigationDestination(for: AppRoute.self) { route in
          switch route {
          case .batch: BatchView()
          case .editor(let id): EditorView(initialID: id)
          case .export(let ids): ExportView(ids: ids)
          }
        }
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
      "작업을 확인해 주세요",
      isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })
    ) {
      Button("확인", role: .cancel) { store.error = nil }
    } message: {
      Text(store.error ?? "")
    }
    .alert(
      "안내",
      isPresented: Binding(get: { store.notice != nil }, set: { if !$0 { store.notice = nil } })
    ) {
      Button("확인", role: .cancel) { store.notice = nil }
    } message: {
      Text(store.notice ?? "")
    }
    .task { await store.prepare() }
  }
}
