import SwiftUI

struct TutorialCropPreview: View {
  @Binding var preset: String
  @Binding var zoom: Double
  @Environment(\.dynamicTypeSize) private var typeSize
  private let presets = [
    ("tcon", "TCON", "20 × 25 mm"), ("id", "증명사진", "30 × 40 mm"),
    ("passport", "여권사진", "35 × 45 mm"),
  ]
  private var ratio: CGFloat { preset == "tcon" ? 0.8 : preset == "id" ? 0.75 : 35.0 / 45.0 }

  var body: some View {
    VStack(spacing: 18) {
      if typeSize.isAccessibilitySize {
        VStack(spacing: 8) { presetButtons }
      } else {
        HStack(spacing: 8) { presetButtons }
      }
      ZStack {
        Image("DemoPortrait").resizable().scaledToFill()
          .frame(width: 200 * ratio, height: 200).scaleEffect(zoom)
        Canvas { context, size in
          var lines = Path()
          lines.move(to: CGPoint(x: size.width / 2, y: 0))
          lines.addLine(to: CGPoint(x: size.width / 2, y: size.height))
          lines.move(to: CGPoint(x: 0, y: size.height / 3))
          lines.addLine(to: CGPoint(x: size.width, y: size.height / 3))
          context.stroke(
            lines, with: .color(.white.opacity(0.8)),
            style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
      }.frame(width: 200 * ratio, height: 200).clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.seolin, lineWidth: 2))
        .accessibilityElement(children: .ignore).accessibilityLabel("구도 조정 예시 사진")
      Text(presets.first { $0.0 == preset }?.2 ?? "")
        .font(.subheadline.weight(.medium)).foregroundStyle(Color.seolin)
        .accessibilityIdentifier("tutorialDimensions")
      HStack {
        Text("확대").font(.subheadline)
        Slider(value: $zoom, in: 1...1.5).accessibilityLabel("예시 사진 확대")
          .accessibilityIdentifier("tutorialZoom")
        Text("\(Int(zoom * 100))%").font(.caption.monospacedDigit()).frame(minWidth: 40)
      }
    }
  }

  private var presetButtons: some View {
    ForEach(presets, id: \.0) { key, title, _ in
      Button {
        preset = key
      } label: {
        Text(title).font(.subheadline.weight(.semibold))
          .frame(maxWidth: .infinity).padding(.vertical, 12)
          .foregroundStyle(preset == key ? Color.white : Color.primary)
          .background(
            preset == key ? Color.brandNavy : Color.appBackground,
            in: RoundedRectangle(cornerRadius: 10))
      }.buttonStyle(.plain).accessibilityIdentifier("tutorialPreset-\(key)")
        .accessibilityValue(preset == key ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(preset == key ? [.isSelected] : [])
    }
  }
}
