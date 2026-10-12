import SwiftUI

struct TCONLogo: View {
  var size: CGFloat = 46
  var body: some View {
    Image("TCONLogo").resizable().scaledToFit().frame(width: size, height: size)
      .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
      .accessibilityLabel("TCON 앱 로고")
  }
}

/// Publisher signature, placed above the home indicator or tab bar safe area.
struct SeolinSignature: View {
  var body: some View {
    Image("SeolinLogo").resizable().scaledToFit().frame(width: 62, height: 56)
      .padding(4).background(.white, in: RoundedRectangle(cornerRadius: 8))
      .frame(maxWidth: .infinity, alignment: .trailing)
      .accessibilityLabel("서린태권도")
      .accessibilityIdentifier("seolinSignature")
  }
}
