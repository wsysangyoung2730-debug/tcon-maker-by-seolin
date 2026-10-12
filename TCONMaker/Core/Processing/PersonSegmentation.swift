import CoreImage
import ImageIO
import UIKit
import Vision
import WebKit

/// Apple Vision performs person segmentation entirely on this device.
/// The web renderer receives only a grayscale mask, never a remote model URL.
enum PersonSegmentation {
  static func maskPNG(_ base64: String) throws -> String {
    guard base64.utf8.count <= 12 * 1024 * 1024,
      let data = Data(base64Encoded: base64),
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
      image.width > 0, image.height > 0,
      image.width <= 1600, image.height <= 1600
    else { throw AppFailure("배경을 분석할 사진을 읽지 못했어요.") }
    let request = VNGeneratePersonSegmentationRequest()
    request.qualityLevel = .accurate
    request.outputPixelFormat = kCVPixelFormatType_OneComponent8
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try handler.perform([request])
    guard let buffer = request.results?.first?.pixelBuffer else {
      throw AppFailure("인물을 찾지 못했어요. 원본 배경을 선택하거나 다른 사진으로 시도해 주세요.")
    }
    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    let hasPerson: Bool
    if let pixels = CVPixelBufferGetBaseAddress(buffer)?.assumingMemoryBound(to: UInt8.self) {
      let width = CVPixelBufferGetWidth(buffer), height = CVPixelBufferGetHeight(buffer)
      let stride = CVPixelBufferGetBytesPerRow(buffer)
      hasPerson = (0..<height).contains { y in (0..<width).contains { pixels[y * stride + $0] > 32 } }
    } else { hasPerson = false }
    CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
    guard hasPerson else {
      throw AppFailure("인물을 찾지 못했어요. 원본 배경을 선택하거나 다른 사진으로 시도해 주세요.")
    }
    let mask = CIImage(cvPixelBuffer: buffer)
    let context = CIContext(options: [.useSoftwareRenderer: false])
    guard let cg = context.createCGImage(mask, from: mask.extent),
      let png = UIImage(cgImage: cg).pngData()
    else { throw AppFailure("배경 분석 결과를 읽지 못했어요.") }
    return png.base64EncodedString()
  }
}

@MainActor
final class PersonSegmentationHandler: NSObject, WKScriptMessageHandlerWithReply {
  func userContentController(
    _ userContentController: WKUserContentController, didReceive message: WKScriptMessage,
    replyHandler: @escaping (Any?, String?) -> Void
  ) {
    guard message.frameInfo.isMainFrame, let base64 = message.body as? String else {
      replyHandler(nil, "사진 분석 요청이 올바르지 않아요.")
      return
    }
    Task {
      do {
        let result = try await Task.detached(priority: .userInitiated) {
          try autoreleasepool { try PersonSegmentation.maskPNG(base64) }
        }.value
        replyHandler(result, nil)
      } catch {
        let message = (error as? AppFailure)?.localizedDescription
          ?? "이 환경에서 인물 분리를 완료하지 못했어요. 원본 배경을 선택하거나 실제 iPhone에서 다시 시도해 주세요."
        replyHandler(nil, message)
      }
    }
  }
}
