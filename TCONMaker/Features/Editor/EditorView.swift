import SwiftUI

struct EditorView: View {
  @EnvironmentObject private var store: PhotoStore
  @Environment(\.dismiss) private var dismiss
  let initialID: Int
  let folderID: UUID?
  private var folderPhotos: [PhotoItem] { store.photos(in: folderID) }
  @State private var selectedID = 0
  @State private var adjustment = Adjustment()
  @State private var composition = Composition()
  @State private var background = "white"
  @State private var snap = true
  @State private var tool = "구도"
  @State private var grid = true
  @State private var deletePrompt = false
  @State private var pending: Task<Void, Never>?
  @GestureState private var translation = CGSize.zero
  @GestureState private var magnification: CGFloat = 1
  @GestureState private var rotation = Angle.zero
  private var photo: PhotoItem? { store.photo(selectedID) }
  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 0) {
          if let photo, photo.status == "done" {
            canvas(photo, height: min(480, max(260, geometry.size.height * 0.47)))
            thumbnails.padding(.vertical, 12)
            HStack(spacing: 0) {
              ForEach(
                [
                  ("맞춤", "crop"), ("구도", "viewfinder"), ("배경", "square.dashed"), ("밝기", "sun.max"),
                  ("회전", "rotate.right"),
                ], id: \.0
              ) { name, icon in
                Button {
                  tool = name
                } label: {
                  VStack(spacing: 7) {
                    Image(systemName: icon).font(.title2)
                    Text(name).font(.caption)
                  }.frame(maxWidth: .infinity).padding(.vertical, 12).background(
                    tool == name ? Color.seolin.opacity(0.08) : .clear,
                    in: RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain).foregroundStyle(tool == name ? Color.seolin : Color.primary)
                  .accessibilityIdentifier("tool-\(name)")
              }
            }.padding(.horizontal, 16)
            Divider().padding(.vertical, 14)
            controls.padding(.horizontal, 22)
            if !photo.warnings.isEmpty {
              Label(photo.warnings.joined(separator: " · "), systemImage: "exclamationmark.circle")
                .font(.caption).foregroundStyle(.orange).padding(.horizontal, 22).padding(.top, 14)
            }
            HStack {
              Button("초기화", systemImage: "arrow.counterclockwise") {
                Task {
                  await pending?.value
                  await store.edit("reset", payload: ["id": selectedID])
                  load(selectedID)
                }
              }.accessibilityIdentifier("resetPhoto")
              Spacer()
              Button("삭제", systemImage: "trash", role: .destructive) { deletePrompt = true }
            }.font(.subheadline).padding(24)
          } else if let photo {
            ContentUnavailableView(
              "사진을 처리하지 못했어요", systemImage: "photo.badge.exclamationmark",
              description: Text(photo.error ?? "다른 사진을 선택해 주세요."))
            Button("목록에서 삭제", role: .destructive) { deletePrompt = true }
          }
        }.frame(maxWidth: 650).frame(maxWidth: .infinity)
      }.background(Color.panel)
    }
    .navigationTitle("사진 편집").navigationBarTitleDisplayMode(.inline).toolbar(
      .visible, for: .navigationBar
    )
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          Task {
            await pending?.value
            store.path.append(.export([selectedID]))
          }
        } label: {
          Image(systemName: "square.and.arrow.up")
        }.accessibilityLabel("이 사진 저장").accessibilityIdentifier("editorExport").disabled(
          photo?.status != "done")
        Button("완료") {
          Task {
            await pending?.value
            dismiss()
          }
        }.fontWeight(.semibold)
      }
    }
    .onAppear {
      if selectedID == 0 {
        load(initialID)
        grid = store.settings.grid
      }
    }
    .confirmationDialog(
      "이 사진을 작업 목록에서 삭제할까요?", isPresented: $deletePrompt, titleVisibility: .visible
    ) {
      Button("삭제", role: .destructive) {
        let id = selectedID
        dismiss()
        Task { await store.remove([id]) }
      }
    } message: {
      Text("원본 사진은 유지됩니다.")
    }
  }
  private var thumbnails: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(folderPhotos) { item in
          Button {
            Task {
              await pending?.value
              load(item.id)
            }
          } label: {
            PhotoThumbnail(photo: item).frame(width: 54, height: 67).clipShape(
              RoundedRectangle(cornerRadius: 8)
            ).overlay(
              RoundedRectangle(cornerRadius: 8).stroke(
                item.id == selectedID ? Color.seolin : Color.clear, lineWidth: 2))
          }.buttonStyle(.plain)
        }
      }.padding(.horizontal, 20)
    }
  }
  private func canvas(_ item: PhotoItem, height: CGFloat) -> some View {
    GeometryReader { geo in
      let ratio = store.settings.wmm / store.settings.hmm
      let h = min(geo.size.height - 36, (geo.size.width - 70) / ratio)
      let w = h * ratio
      ZStack {
        Color(red: 0.13, green: 0.14, blue: 0.16)
        ZStack {
          Checkerboard()
          if let image = item.image {
            Image(uiImage: image).resizable().scaledToFit().scaleEffect(magnification)
              .rotationEffect(rotation).offset(translation)
          }
        }.frame(width: w, height: h).clipped()
          .overlay {
            if grid {
              CropGuides(top: composition.top / 100, eye: item.eye).frame(width: w, height: h)
                .allowsHitTesting(false)
            }
          }
          .overlay(Rectangle().stroke(.white.opacity(0.9), lineWidth: 1))
          .contentShape(Rectangle())
          .gesture(
            DragGesture().updating($translation) { value, state, _ in state = value.translation }
              .onEnded { value in
                adjustment.dx = (adjustment.dx + value.translation.width / w).finiteClamped(
                  -0.5...0.5, fallback: 0)
                adjustment.dy = (adjustment.dy + value.translation.height / h).finiteClamped(
                  -0.5...0.5, fallback: 0)
                commit(debounce: true, realign: true)
              }
          )
          .simultaneousGesture(
            MagnificationGesture().updating($magnification) { value, state, _ in state = value }
              .onEnded { value in
                adjustment.zoom = (adjustment.zoom * value).finiteClamped(0.4...3, fallback: 1)
                commit(debounce: true, realign: true)
              }
          )
          .simultaneousGesture(
            RotationGesture().updating($rotation) { value, state, _ in state = value }.onEnded {
              value in
              adjustment.tilt = (adjustment.tilt - value.degrees).finiteClamped(
                -45...45, fallback: 0)
              if abs(adjustment.tilt) < 0.8 {
                adjustment.tilt = 0
                UISelectionFeedbackGenerator().selectionChanged()
              }
              commit(debounce: true, realign: true)
            }
          )
          .accessibilityIdentifier("editorCanvas").accessibilityLabel(
            "사진 미리보기. 아래 맞춤 도구에서 크기와 위치를 숫자로 조절할 수 있습니다.")
        VStack {
          HStack {
            Text("\((folderPhotos.firstIndex{$0.id==selectedID} ?? 0)+1) / \(folderPhotos.count)")
              .font(.caption.monospacedDigit()).foregroundStyle(.white)
            Spacer()
            Button {
              grid.toggle()
            } label: {
              Image(systemName: grid ? "grid" : "grid.circle").font(.title3).padding(10).background(
                .black.opacity(0.4), in: Circle()
              ).foregroundStyle(.white)
            }.accessibilityLabel("안내선 표시 전환")
          }
          Spacer()
        }.padding(10)
      }
    }.frame(height: height)
  }
  @ViewBuilder private var controls: some View {
    VStack(spacing: 16) {
      switch tool {
      case "맞춤":
        Toggle("인물 기준 자동 정렬", isOn: $snap).onChange(of: snap) { _, _ in commit() }
        ValueSlider(
          title: "크기",
          value: Binding(get: { adjustment.zoom * 100 }, set: { adjustment.zoom = $0 / 100 }),
          range: 40...300, suffix: "%", onCommit: { commit() })
        ValueSlider(
          title: "좌우",
          value: Binding(get: { adjustment.dx * 100 }, set: { adjustment.dx = $0 / 100 }),
          range: -50...50, onCommit: { commit() })
        ValueSlider(
          title: "상하",
          value: Binding(get: { adjustment.dy * 100 }, set: { adjustment.dy = $0 / 100 }),
          range: -50...50, onCommit: { commit() })
      case "구도":
        ChoiceRow(
          title: "이 사진의 구도", selection: $composition.mode,
          choices: [("chest", "상반신"), ("face", "얼굴 크게")], onChange: { commit() })
        ValueSlider(
          title: "머리 위 여백", value: $composition.top, range: 3...16, suffix: "%",
          onCommit: { commit() })
        ChoiceRow(
          title: "가운데 기준", selection: $composition.center,
          choices: [("face", "얼굴"), ("mix", "균형"), ("body", "상체")], onChange: { commit() })
        if composition.mode == "chest" {
          ValueSlider(
            title: "아래로 보일 범위", value: $composition.below, range: 0.6...1.8, step: 0.05,
            onCommit: { commit() })
          Text("왼쪽은 어깨까지, 오른쪽은 가슴 아래까지").font(.caption).foregroundStyle(.secondary)
        } else {
          ValueSlider(
            title: "얼굴 크기", value: $composition.head, range: 55...85, suffix: "%",
            onCommit: { commit() })
        }
      case "배경":
        ChoiceRow(
          title: "이 사진의 배경", selection: $background,
          choices: [("white", "흰색"), ("clear", "투명"), ("orig", "원본")], onChange: { commit() })
        Text(
          background == "clear"
            ? "투명 배경은 PNG로 저장됩니다. 최대 용량 설정은 적용되지 않아요." : "머리카락과 도복 경계가 자연스러운지 확인해 주세요."
        ).font(.caption).foregroundStyle(.secondary)
      case "밝기":
        ValueSlider(
          title: "이 사진의 밝기", value: $adjustment.bright, range: -50...50, onCommit: { commit() })
        Text("전체 밝기 \(Int(store.settings.bright))에 더해집니다. 흰 배경은 유지됩니다.").font(.caption)
          .foregroundStyle(.secondary)
      default:
        HStack {
          Button("왼쪽 90°", systemImage: "rotate.left") { rotate(-1) }
          Spacer()
          Button("오른쪽 90°", systemImage: "rotate.right") { rotate(1) }
        }.buttonStyle(.bordered)
        ValueSlider(
          title: "기울기", value: $adjustment.tilt, range: -45...45, step: 0.1, suffix: "°",
          onCommit: { commit() })
      }
    }
  }
  private func load(_ id: Int) {
    guard let item = store.photo(id) else { return }
    selectedID = id
    adjustment = item.adjustment
    composition = item.composition
    background = item.background
    snap = item.snap
  }
  private func rotate(_ direction: Int) {
    Task {
      await pending?.value
      await store.edit("rotate", payload: ["id": selectedID, "direction": direction])
      load(selectedID)
    }
  }
  private func commit(debounce: Bool = false, realign: Bool = false) {
    let previous = pending
    previous?.cancel()
    let id = selectedID
    let a = adjustment
    let c = composition
    let b = background
    let s = snap
    pending = Task {
      if debounce { do { try await Task.sleep(nanoseconds: 150_000_000) } catch { return } }
      await previous?.value
      guard !Task.isCancelled else { return }
      await store.update(
        id: id, adjustment: a, background: b, composition: c, snap: s, realign: realign)
    }
  }
}
struct CropGuides: View {
  var top: Double
  var eye: Double?
  var body: some View {
    Canvas { context, size in
      var thirds = Path()
      for fraction in [1.0 / 3, 2.0 / 3] {
        thirds.move(to: CGPoint(x: size.width * fraction, y: 0))
        thirds.addLine(to: CGPoint(x: size.width * fraction, y: size.height))
        thirds.move(to: CGPoint(x: 0, y: size.height * fraction))
        thirds.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
      }
      context.stroke(thirds, with: .color(.white.opacity(0.7)), lineWidth: 0.8)
      var center = Path()
      center.move(to: CGPoint(x: size.width / 2, y: 0))
      center.addLine(to: CGPoint(x: size.width / 2, y: size.height))
      context.stroke(center, with: .color(.cyan), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
      for (fraction, color) in [(top, Color.yellow), (eye ?? -1, Color.cyan)]
      where fraction >= 0 && fraction <= 1 {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height * fraction))
        path.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
      }
    }
  }
}
