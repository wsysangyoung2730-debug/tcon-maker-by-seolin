import SwiftUI

struct TutorialView: View {
  var isOnboarding = false
  let onClose: () -> Void
  let onComplete: () -> Void
  @State private var step = 0
  @State private var pickedPhoto = false
  @State private var preset = "tcon"
  @State private var zoom = 1.0
  @State private var createdFolder = false
  @State private var selecting = false
  @State private var selection = Set<Int>()
  @State private var destination = "photos"
  @State private var practicedSave = false

  private let titles = [
    "사진부터 골라볼까요?", "규격과 구도를 맞춰요", "폴더로 정리해요", "꾹 눌러 여러 장을 선택해요", "원하는 곳에 저장해요",
  ]
  private let descriptions = [
    "홈에서 사진을 선택하거나 촬영할 수 있어요. 여러 장도 한 번에 가져올 수 있습니다.",
    "전체 설정에서 규격을 고르고, 사진을 눌러 구도와 밝기를 조정하세요. 저장 전 얼굴과 여백을 확인해 주세요.",
    "파일 탭의 +로 심사일이나 수련반 폴더를 만드세요. 홈에서 추가한 사진은 미분류에 보관됩니다.",
    "사진을 길게 누르면 선택이 시작돼요. 다른 사진도 눌러 함께 저장하거나 폴더를 옮기고 삭제할 수 있어요.",
    "사진 앱, 파일 앱, ZIP 중 저장할 곳을 골라요. 원본 사진은 그대로 유지됩니다.",
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Label("예시 사진으로 연습", systemImage: "hand.tap")
              Spacer()
              Text("\(step + 1) / \(titles.count)").monospacedDigit()
                .accessibilityIdentifier("tutorialProgress")
            }.font(.subheadline.weight(.medium)).foregroundStyle(Color.seolin)
            ProgressView(value: Double(step + 1), total: Double(titles.count))
              .accessibilityLabel("튜토리얼 진행").accessibilityValue("5단계 중 \(step + 1)단계")
          }
          VStack(alignment: .leading, spacing: 12) {
            Text(titles[step]).font(.title.bold()).accessibilityAddTraits(.isHeader)
              .accessibilityIdentifier("tutorialTitle")
            Text(descriptions[step]).foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          preview
            .padding(20).frame(maxWidth: .infinity)
            .background(Color.panel, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.seolin.opacity(0.12)))
          Label(tip, systemImage: "lightbulb")
            .font(.subheadline).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
          Text("연습 화면입니다. 실제 사진이나 설정은 변경되지 않아요.")
            .font(.caption).foregroundStyle(.secondary)
        }.padding(22).frame(maxWidth: 600).frame(maxWidth: .infinity)
      }.background(Color.appBackground).id(step)
        .navigationTitle("사용법 알아보기").navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("닫기", action: onClose).accessibilityIdentifier("closeTutorial")
          }
        }
        .safeAreaInset(edge: .bottom) {
          VStack(spacing: 12) {
            PrimaryButton(
              title: step == titles.count - 1 ? "튜토리얼 마치기" : "다음",
              icon: step == titles.count - 1 ? "checkmark" : "arrow.right"
            ) {
              if step == titles.count - 1 { onComplete() } else { step += 1 }
            }.accessibilityIdentifier("tutorialNext")
            HStack {
              Button("이전") { step -= 1 }
                .disabled(step == 0).accessibilityIdentifier("tutorialPrevious")
              Spacer()
              Button(isOnboarding ? "건너뛰고 시작하기" : "그만 보기", action: onComplete)
                .accessibilityIdentifier("skipTutorial")
            }.font(.subheadline).frame(minHeight: 32)
          }.padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity)
            .background(.regularMaterial)
        }
    }.tint(.seolin)
  }

  @ViewBuilder private var preview: some View {
    switch step {
    case 0: photoPreview
    case 1: TutorialCropPreview(preset: $preset, zoom: $zoom)
    case 2: folderPreview
    case 3: selectionPreview
    default: savePreview
    }
  }

  private var tip: String {
    switch step {
    case 0: "폴더 안의 + 버튼에서는 사진 보관함·파일·카메라로 사진을 추가할 수 있어요."
    case 1: "배경·밝기·이동·확대·회전은 사진별로 조정할 수 있어요."
    case 2: "폴더 화면의 선택 버튼으로 이름 변경과 삭제를 할 수 있어요. 폴더를 지워도 안의 사진은 미분류에 남아요."
    case 3: "사진을 짧게 누르면 개별 편집, 길게 누르면 여러 장 선택입니다. 선택 삭제도 사진 보관함의 원본에는 영향을 주지 않아요."
    default: "ZIP은 여러 장을 하나의 파일로 묶어요. 투명 배경은 PNG로 저장됩니다. 사용법은 전체 설정에서 다시 볼 수 있어요."
    }
  }

  private var photoPreview: some View {
    VStack(spacing: 18) {
      if pickedPhoto {
        TutorialPortrait().frame(width: 128, height: 160)
        Label("예시 사진을 골랐어요", systemImage: "checkmark.circle.fill")
          .foregroundStyle(Color.seolin).accessibilityIdentifier("tutorialPhotoPicked")
      } else {
        Image(systemName: "photo.badge.plus").font(.system(size: 56, weight: .light))
          .foregroundStyle(Color.seolin).padding(32).accessibilityHidden(true)
      }
      PrimaryButton(title: pickedPhoto ? "예시 사진 다시 고르기" : "예시 사진 고르기", icon: "photo") {
        pickedPhoto = true
      }.accessibilityIdentifier("tutorialPickPhoto")
      Text("내 사진을 가져오거나 접근 권한을 요청하지 않아요.")
        .font(.caption).foregroundStyle(.secondary)
    }
  }

  private var folderPreview: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        Text("파일").font(.title2.bold())
        Spacer()
        Button {
          createdFolder = true
        } label: {
          Image(systemName: "plus").font(.title2).frame(width: 44, height: 44)
        }.accessibilityLabel("예시 폴더 만들기").accessibilityIdentifier("tutorialNewFolder")
      }
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 12) { folderCards }
        VStack(spacing: 12) { folderCards }
      }
      Text(createdFolder ? "승급 심사 폴더를 만들었어요" : "+ 버튼을 눌러 예시 폴더를 만들어 보세요")
        .font(.subheadline).foregroundStyle(Color.seolin)
        .accessibilityIdentifier("tutorialFolderFeedback")
    }
  }

  @ViewBuilder private var folderCards: some View {
    folderCard("미분류", icon: "tray.full.fill")
    if createdFolder { folderCard("승급 심사", icon: "folder.fill") }
  }

  private func folderCard(_ name: String, icon: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Image(systemName: icon).font(.system(size: 32)).foregroundStyle(Color.seolin)
        .accessibilityHidden(true)
      Text(name).font(.headline)
      Text("예시 폴더").font(.caption).foregroundStyle(.secondary)
    }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 16))
      .accessibilityElement(children: .combine)
  }

  private var selectionPreview: some View {
    VStack(spacing: 18) {
      HStack {
        Text(selecting ? "\(selection.count)장 선택" : "승급 심사").font(.headline)
          .accessibilityIdentifier("tutorialSelectionCount")
        Spacer()
        if selecting {
          Button("취소") {
            selecting = false
            selection = []
          }
          .accessibilityIdentifier("tutorialCancelSelection")
        }
      }
      HStack(spacing: 14) {
        ForEach(1...2, id: \.self) { id in
          Button {
            if selecting { toggleSelection(id) }
          } label: {
            TutorialPortrait().aspectRatio(0.8, contentMode: .fit)
              .overlay(alignment: .topTrailing) {
                if selecting {
                  Image(systemName: selection.contains(id) ? "checkmark.circle.fill" : "circle")
                    .font(.title2).foregroundStyle(Color.seolin)
                    .padding(6).background(Color.panel, in: Circle()).padding(6)
                }
              }
              .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(
                  selection.contains(id) ? Color.seolin : Color.clear, lineWidth: 3))
          }.buttonStyle(.plain).accessibilityLabel("예시 사진 \(id)")
            .accessibilityValue(selection.contains(id) ? "선택됨" : "선택 안 됨")
            .accessibilityIdentifier("tutorialPhoto-\(id)")
            .highPriorityGesture(
              LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                selecting = true
                selection.insert(id)
              }
            )
            .accessibilityAction(named: Text("사진 선택")) {
              selecting = true
              selection.insert(id)
            }
        }
      }.frame(maxWidth: 340).frame(maxWidth: .infinity)
      if selecting {
        Label("선택한 사진은 폴더 이동·삭제도 가능해요", systemImage: "folder")
          .font(.caption).foregroundStyle(.secondary)
        PrimaryButton(title: "선택한 \(selection.count)장 저장하기", icon: "square.and.arrow.down") {
          step = 4
        }.disabled(selection.isEmpty).opacity(selection.isEmpty ? 0.45 : 1)
          .accessibilityIdentifier("tutorialSaveSelected")
        Text("원본 사진은 변경되지 않아요").font(.caption).foregroundStyle(.secondary)
      } else {
        Text("사진 한 장을 꾹 누른 다음, 다른 사진도 눌러보세요.")
          .font(.subheadline).foregroundStyle(Color.seolin)
      }
    }
  }

  private func toggleSelection(_ id: Int) {
    if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
  }

  private var savePreview: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("저장 위치").font(.headline)
      ForEach(
        [
          ("photos", "사진 앱", "photo.on.rectangle"), ("files", "파일 앱", "folder"),
          ("zip", "ZIP 파일", "doc.zipper"),
        ], id: \.0
      ) { key, title, icon in
        Button {
          destination = key
          practicedSave = false
        } label: {
          HStack(spacing: 14) {
            Image(systemName: icon).frame(width: 28)
            Text(title).foregroundStyle(.primary)
            Spacer()
            Image(systemName: destination == key ? "checkmark.circle.fill" : "circle")
          }.padding(14).background(
            destination == key ? Color.seolin.opacity(0.1) : Color.appBackground,
            in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain).accessibilityIdentifier("tutorialDestination-\(key)")
          .accessibilityValue(destination == key ? "선택됨" : "선택 안 됨")
      }
      PrimaryButton(title: "저장 연습하기", icon: "square.and.arrow.down") {
        practicedSave = true
      }.accessibilityIdentifier("tutorialPracticeSave")
      Text("원본 사진은 변경되지 않아요").font(.caption).foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
      if practicedSave {
        Label("저장 방법을 익혔어요! 실제 사진으로 시작해 보세요.", systemImage: "checkmark.circle.fill")
          .font(.subheadline).foregroundStyle(Color.seolin)
          .accessibilityIdentifier("tutorialSaveComplete")
      }
    }
  }
}

struct TutorialPortrait: View {
  var body: some View {
    GeometryReader { geometry in
      Image("DemoPortrait").resizable().scaledToFill()
        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
    }.clipShape(RoundedRectangle(cornerRadius: 12)).accessibilityHidden(true)
  }
}
