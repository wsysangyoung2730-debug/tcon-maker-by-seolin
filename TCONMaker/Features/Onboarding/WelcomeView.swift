import SwiftUI

struct WelcomeView: View {
  let onStart: () -> Void
  let onTutorial: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        HStack(spacing: 12) {
          TCONLogo(size: 44)
            .accessibilityHidden(true)
          VStack(alignment: .leading, spacing: 3) {
            Text("TCON Maker").font(.headline)
            Text("by SEOLIN").font(.caption).foregroundStyle(.secondary)
          }
        }
        VStack(alignment: .leading, spacing: 12) {
          Text("심사 사진 준비,\n처음부터 간편하게")
            .font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("welcomeTitle")
          Text("사진을 고르고, 맞추고, 저장하세요.\n서린태권도가 함께 준비해 드릴게요.")
            .font(.body).foregroundStyle(.secondary)
        }
        ZStack {
          RoundedRectangle(cornerRadius: 28).fill(Color.seolin.opacity(0.07))
          VStack(spacing: 16) {
            Image("DemoPortrait").resizable().scaledToFill()
              .frame(width: 132, height: 165).clipped()
              .clipShape(RoundedRectangle(cornerRadius: 12))
              .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.seolin, lineWidth: 2))
              .accessibilityHidden(true)
            Label("한 장부터 여러 장까지", systemImage: "photo.stack")
              .font(.subheadline.weight(.semibold)).foregroundStyle(Color.seolin)
          }.padding(24)
        }.accessibilityElement(children: .ignore).accessibilityLabel("심사 사진 예시")
        VStack(alignment: .leading, spacing: 22) {
          benefit("crop", "원하는 규격으로", "얼굴 정렬과 배경·구도를 한곳에서 맞춰요.")
          benefit("folder", "폴더로 차곡차곡", "심사일이나 수련반별로 작업 사진을 관리해요.")
          benefit("square.and.arrow.down", "필요한 사진만 저장", "여러 장을 선택해 사진 앱·파일·ZIP으로 저장해요.")
        }
        Label("사진은 기기 안에서 처리하고 원본은 그대로 보관해요.", systemImage: "lock.shield")
          .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      }.padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity)
    }
    .background(Color.panel)
    .safeAreaInset(edge: .bottom) {
      VStack(spacing: 10) {
        PrimaryButton(title: "사용법 살펴보기", icon: "hand.tap", action: onTutorial)
          .accessibilityIdentifier("startTutorial")
        Button("바로 시작하기", action: onStart)
          .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
          .accessibilityIdentifier("finishOnboarding")
        SeolinSignature()
      }.padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 6)
        .frame(maxWidth: 560).frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }
  }

  private func benefit(_ icon: String, _ title: String, _ detail: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
      Image(systemName: icon).font(.title3).foregroundStyle(Color.seolin)
        .frame(width: 42, height: 42)
        .background(Color.seolin.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.headline)
        Text(detail).font(.subheadline).foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }.accessibilityElement(children: .combine)
  }
}
