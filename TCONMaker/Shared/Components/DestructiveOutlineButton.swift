import SwiftUI

struct DestructiveOutlineButton: View {
  let title: String
  var disabled = false
  let action: () -> Void
  var body: some View {
    Button(role: .destructive, action: action) {
      Label(title, systemImage: "trash")
        .font(.subheadline.weight(.semibold))
        .frame(maxWidth: .infinity, minHeight: 48)
        .foregroundStyle(.red)
        .background(Color.red.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red, lineWidth: 1.5))
        .contentShape(RoundedRectangle(cornerRadius: 14))
    }.buttonStyle(.plain).disabled(disabled).opacity(disabled ? 0.4 : 1)
  }
}
