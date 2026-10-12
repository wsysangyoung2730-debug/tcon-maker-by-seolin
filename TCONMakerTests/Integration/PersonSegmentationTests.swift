import ImageIO
import UIKit
import XCTest
@testable import TCONMaker

func requirePersonSegmentationRuntime() throws {
  #if targetEnvironment(simulator)
    throw XCTSkip("Apple 인물 분리 통합 검증은 실제 iPhone에서 실행합니다. 시뮬레이터 Vision 런타임은 지원하지 않습니다.")
  #endif
}

final class PersonSegmentationTests: XCTestCase {
  func testRejectsInvalidOrOversizedInput() {
    XCTAssertThrowsError(try PersonSegmentation.maskPNG("invalid image"))
    XCTAssertThrowsError(try PersonSegmentation.maskPNG(String(repeating: "A", count: 12 * 1024 * 1024 + 1)))
  }

  func testPersonMaskAndEmptyScene() throws {
    try requirePersonSegmentationRuntime()
    let image = try XCTUnwrap(UIImage(named: "DemoPortrait")?.pngData())
    let result = try PersonSegmentation.maskPNG(image.base64EncodedString())
    let data = try XCTUnwrap(Data(base64Encoded: result))
    let mask = try XCTUnwrap(UIImage(data: data)?.cgImage)
    XCTAssertGreaterThan(mask.width, 0)
    XCTAssertGreaterThan(mask.height, 0)
    let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
    attachment.name = "apple-person-mask"
    attachment.lifetime = .keepAlways
    add(attachment)
    let blank = UIGraphicsImageRenderer(size: CGSize(width: 640, height: 640)).image { context in
      UIColor.white.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 640, height: 640))
    }
    XCTAssertThrowsError(try PersonSegmentation.maskPNG(try XCTUnwrap(blank.pngData()).base64EncodedString()))
  }
}
