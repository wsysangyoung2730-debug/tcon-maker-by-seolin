import AVFoundation
import PhotosUI
import SwiftUI

struct ImportActions: View {
  @EnvironmentObject private var store: PhotoStore
  @State private var picks: [PhotosPickerItem] = []
  @State private var camera = false
  @State private var files = false
  var compact = false
  var folderID: UUID? = nil
  var body: some View {
    Group {
      if compact {
        Menu {
          PhotosPicker(
            selection: $picks, maxSelectionCount: 30, matching: .images,
            preferredItemEncoding: .current
          ) { Label("사진 보관함", systemImage: "photo.on.rectangle") }
          Button("파일에서 가져오기", systemImage: "folder") { files = true }
          Button("촬영하기", systemImage: "camera") { openCamera() }
        } label: {
          Image(systemName: "plus").font(.title3).frame(width: 44, height: 44)
        }.accessibilityLabel("사진 추가").accessibilityIdentifier("addFolderPhoto")
      } else {
        VStack(spacing: 12) {
          PhotosPicker(
            selection: $picks, maxSelectionCount: 30, matching: .images,
            preferredItemEncoding: .current
          ) {
            Label("사진 선택하기", systemImage: "photo").font(.headline).frame(maxWidth: .infinity)
              .padding(.vertical, 18).foregroundStyle(.white).background(
                Color.brandNavy, in: RoundedRectangle(cornerRadius: 16))
          }.accessibilityIdentifier("importPhotos")
          Button(action: openCamera) {
            Label("촬영하기", systemImage: "camera").font(.headline).frame(maxWidth: .infinity).padding(
              .vertical, 16
            ).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.seolin, lineWidth: 1))
          }

        }
      }
    }.disabled(!store.ready || store.busy)
      .onChange(of: picks) { _, items in
        guard !items.isEmpty else { return }
        picks = []
        Task { await store.importSelections(items, folderID: folderID) }
      }
      .fileImporter(
        isPresented: $files, allowedContentTypes: [.image], allowsMultipleSelection: true
      ) { result in
        switch result {
        case .success(let urls): Task { await store.importFiles(urls, folderID: folderID) }
        case .failure(let error): store.error = error.localizedDescription
        }
      }
      .fullScreenCover(isPresented: $camera) {
        CameraPicker { image in Task { await store.importCamera(image, folderID: folderID) } }
          .ignoresSafeArea()
      }
  }
  private func openCamera() {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      store.error = "이 기기에서는 카메라를 사용할 수 없어요. 사진 보관함이나 파일에서 가져와 주세요."
      return
    }
    Task {
      let permission = AVCaptureDevice.authorizationStatus(for: .video)
      let allowed =
        permission == .authorized
        ? true
        : permission == .notDetermined ? await AVCaptureDevice.requestAccess(for: .video) : false
      if allowed { camera = true } else { store.error = "카메라 권한이 꺼져 있어요. 아이폰 설정에서 카메라 권한을 켜 주세요." }
    }
  }
}
