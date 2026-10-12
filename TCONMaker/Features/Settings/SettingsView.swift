import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var store: PhotoStore
  @Environment(\.dismiss) private var dismiss
  @State var draft: PhotoSettings
  @State private var preserve = true
  @State private var showAbout = false
  var body: some View {
    NavigationStack {
      Form {
        Section("사진 규격") {
          HStack {
            ForEach([("tcon", "TCON"), ("id", "증명사진"), ("passport", "여권사진")], id: \.0) {
              key, label in
              Button {
                draft.preset(key)
              } label: {
                Text(label).font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(
                  .vertical, 12
                ).background(
                  draft.presetName == label ? Color.brandNavy : Color.appBackground,
                  in: RoundedRectangle(cornerRadius: 10)
                )
                .foregroundStyle(draft.presetName == label ? Color.white : Color.primary)
                .contentShape(RoundedRectangle(cornerRadius: 10))
              }.buttonStyle(.plain)
                .accessibilityValue(draft.presetName == label ? "선택됨" : "선택 안 됨")
                .accessibilityAddTraits(draft.presetName == label ? [.isSelected] : [])
            }
          }
          numberRow("가로", value: $draft.wmm, unit: "mm")
          numberRow("세로", value: $draft.hmm, unit: "mm")
          Text("TCON 기본값은 기존 앱의 설정입니다. 제출 기관의 최신 안내를 확인해 주세요.").font(.caption).foregroundStyle(
            .secondary)
        }
        Section("저장 품질") {
          Toggle("고화질 저장 · 용량 제한 없음", isOn: $draft.orig)
          numberRow("최대 용량", value: $draft.maxkb, unit: "KB").disabled(
            draft.orig || draft.background == "clear")
          Text(
            draft.background == "clear"
              ? "투명 배경은 PNG로 저장되며 용량 제한이 적용되지 않아요."
              : "원본 픽셀을 기준으로 자르고, JPG 압축률로 용량을 맞춥니다. 큰 사진은 최대 1,600만 화소로 저장합니다."
          ).font(.caption).foregroundStyle(.secondary)
        }
        Section("전체 사진 설정") {
          ChoiceRow(
            title: "배경", selection: $draft.background,
            choices: [("white", "흰색"), ("clear", "투명"), ("orig", "원본")])
          ValueSlider(title: "전체 밝기", value: $draft.bright, range: -50...50)
          ChoiceRow(
            title: "가운데 기준", selection: $draft.center,
            choices: [("face", "얼굴"), ("mix", "균형"), ("body", "상체")])
          ChoiceRow(
            title: "구도", selection: $draft.mode, choices: [("chest", "상반신"), ("face", "얼굴 크게")])
          if draft.mode == "chest" {
            ValueSlider(title: "아래로 보일 범위", value: $draft.below, range: 0.6...1.8, step: 0.05)
          } else {
            ValueSlider(title: "얼굴 크기", value: $draft.head, range: 55...85, suffix: "%")
          }
          ValueSlider(title: "머리 위 여백", value: $draft.top, range: 3...16, suffix: "%")
          Toggle("안내선 표시", isOn: $draft.grid)
        }
        if !store.photos.isEmpty {
          Section {
            Toggle("개별 수정 유지", isOn: $preserve)
          } footer: {
            Text(
              preserve
                ? "개별 배경·구도·이동·회전·밝기 값을 유지합니다. 전체 밝기는 개별 밝기에 더해집니다."
                : "개별 배경·구도·이동·기울기·밝기를 초기화합니다. 수동 90도 회전은 유지됩니다.")
          }
        }
        Section {
          Button("기본 설정으로 되돌리기") { draft = PhotoSettings() }
          Button("앱 정보 및 개인정보") { showAbout = true }
        }
      }
      .navigationTitle("전체 설정").navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("적용") {
            draft.validate()
            let value = draft
            let keep = preserve
            dismiss()
            Task { await store.applySettings(value, preserve: keep) }
          }.fontWeight(.semibold).accessibilityIdentifier("applySettings")
        }
      }
      .sheet(isPresented: $showAbout) { AboutView() }
    }
  }
  private func numberRow(_ title: String, value: Binding<Double>, unit: String) -> some View {
    HStack {
      Text(title)
      Spacer()
      TextField(title, value: value, format: .number).keyboardType(.decimalPad)
        .multilineTextAlignment(.trailing).frame(width: 90).accessibilityIdentifier(
          "setting-\(title)")
      Text(unit).foregroundStyle(.secondary)
    }
  }
}
struct AboutView: View {
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      List {
        Section {
          Image("SeolinLogo").resizable().scaledToFit().frame(height: 100).frame(
            maxWidth: .infinity)
          Text("TCON Maker by SEOLIN").font(.headline)
          Text("서린태권도에서 만든 심사 사진 편집 도구")
        }
        Section("사진과 개인정보") {
          Text("사진은 이 기기 안에서만 처리하며 외부 서버로 전송하지 않습니다. 원본 사진을 덮어쓰지 않습니다.")
          Text(
            "작업 사진·편집 상태·폴더는 이 기기에 보관되며 앱을 다시 열면 복구됩니다. 앱을 삭제하면 함께 삭제됩니다. 완성본은 사진 앱이나 파일 앱에 저장해 주세요."
          )
          Text("설정값은 기기에 저장됩니다. 분석·광고·추적 기능은 없습니다.")
        }
        Section("사용 안내") {
          Text("자동 맞춤은 편집 보조 기능입니다. 얼굴·머리·도복 경계와 제출 규격을 직접 확인해 주세요.")
          Text("TCON 및 여권 사진의 공식 승인 여부를 판정하지 않습니다.")
          Link("서린태권도", destination: URL(string: "https://naver.me/FGhs3b3C")!)
        }
        Section("오픈소스") {
          Text("face-api · TensorFlow.js · JSZip · pako")
          Text("원본 사진 처리 엔진의 라이선스 고지를 앱 번들에 포함합니다.").font(.footnote).foregroundStyle(.secondary)
        }
      }.navigationTitle("앱 정보").navigationBarTitleDisplayMode(.inline).toolbar {
        Button("닫기") { dismiss() }
      }
    }
  }
}
