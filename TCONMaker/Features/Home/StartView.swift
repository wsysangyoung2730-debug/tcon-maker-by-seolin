import SwiftUI

struct StartView: View {
  @EnvironmentObject private var store: PhotoStore
  @State private var settings = false
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        HStack(spacing: 12) {
          TCONLogo()
            .accessibilityHidden(true)
          VStack(alignment: .leading, spacing: 2) {
            Text("TCON Maker").font(.title2.bold())
            Text("by SEOLIN").font(.caption).foregroundStyle(.secondary)
          }
          Spacer()
          Button {
            settings = true
          } label: {
            Image(systemName: "gearshape").font(.title2).frame(width: 44, height: 44)
          }.accessibilityLabel("전체 설정").accessibilityIdentifier("openSettings")
        }
        VStack(alignment: .leading, spacing: 12) {
          Text("심사 사진 준비를\n간편하게").font(.system(size: 34, weight: .bold))
          Text("사진을 고르면 크기와 구도를 맞춰드려요").font(.subheadline).foregroundStyle(.secondary)
        }
        LibraryPhotoPicker {
          VStack(spacing: 12) {
            Image("DemoPortrait").resizable().scaledToFill().frame(width: 134, height: 168)
              .clipped().overlay(
                RoundedRectangle(cornerRadius: 4).stroke(Color.seolin.opacity(0.4), lineWidth: 2))
            Label("얼굴 정렬 · 배경 정리 · 규격 맞춤", systemImage: "sparkles")
              .font(.caption).foregroundStyle(Color.seolin)
            Text("사진을 눌러 시작하기")
              .font(.caption2).foregroundStyle(.secondary)
          }.padding(20).frame(maxWidth: .infinity)
            .background(Color.seolin.opacity(0.05), in: RoundedRectangle(cornerRadius: 24))
            .contentShape(RoundedRectangle(cornerRadius: 24))
        }.buttonStyle(.plain)
          .accessibilityLabel("예시 사진을 눌러 사진 선택하기")
          .accessibilityHint("사진 보관함에서 최대 30장을 선택합니다")
          .accessibilityIdentifier("homeExamplePhoto")
        VStack(alignment: .leading, spacing: 10) {
          Text("사진 규격").font(.subheadline).foregroundStyle(.secondary)
          Button {
            settings = true
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(store.settings.presetName).font(.headline)
                Text(store.settings.dimensions).foregroundStyle(.secondary)
              }
              Spacer()
              Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }.padding(18).background(Color.panel, in: RoundedRectangle(cornerRadius: 16)).overlay(
              RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.2)))
          }.buttonStyle(.plain)
          Text(
            "\(store.settings.background == "white" ? "흰색" : store.settings.background == "clear" ? "투명" : "원본") 배경 · \(store.settings.orig || store.settings.clear ? "용량 제한 없음" : "최대 \(Int(store.settings.maxkb)) KB")"
          ).font(.caption).foregroundStyle(.secondary)
        }
        if !store.ready {
          HStack {
            if store.busy { ProgressView() }
            Text(store.busy ? store.progress : "사진 도구를 다시 준비해 주세요").font(.caption)
            if !store.busy {
              Button("다시 시도") { Task { await store.prepare() } }
                .accessibilityIdentifier("retryEngine")
            }
          }.frame(maxWidth: .infinity)
        }
        VStack(spacing: 10) {
          ImportActions()
          HStack(alignment: .center) {
            Text("여러 장을 한 번에 선택할 수 있어요")
              .font(.caption).foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
            SeolinSignature().frame(width: 70)
          }
        }
      }.padding(22).frame(maxWidth: 560).frame(maxWidth: .infinity)
    }.accessibilityIdentifier("homeContent")
      .background(Color.panel).toolbar(.hidden, for: .navigationBar)
      .sheet(isPresented: $settings) { SettingsView(draft: store.settings) }
  }
}
