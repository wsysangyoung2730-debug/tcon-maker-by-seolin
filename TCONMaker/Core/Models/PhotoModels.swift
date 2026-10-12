import Foundation
import UIKit

struct PhotoSettings: Codable, Equatable {
  var wmm = 20.0, hmm = 25.0, maxkb = 300.0
  var orig = false, whitebg = true, clear = false, grid = true
  var bright = 0.0, head = 72.0, top = 8.0, below = 1.2
  var mode = "chest", center = "mix"
  var background: String {
    get { !whitebg ? "orig" : clear ? "clear" : "white" }
    set {
      whitebg = newValue != "orig"
      clear = newValue == "clear"
    }
  }
  var presetName: String {
    if wmm == 20 && hmm == 25 { return "TCON" }
    if wmm == 30 && hmm == 40 { return "증명사진" }
    if wmm == 35 && hmm == 45 { return "여권사진" }
    return "직접 설정"
  }
  var dimensions: String { "\(wmm.formatted()) × \(hmm.formatted()) mm" }
  mutating func preset(_ key: String) {
    switch key {
    case "id":
      wmm = 30
      hmm = 40
      mode = "chest"
      below = 0.9
    case "passport":
      wmm = 35
      hmm = 45
      mode = "face"
      head = 75
    default:
      wmm = 20
      hmm = 25
      mode = "chest"
      below = 1.2
    }
  }
  mutating func validate() {
    wmm = wmm.finiteClamped(10...200, fallback: 20)
    hmm = hmm.finiteClamped(10...200, fallback: 25)
    maxkb = maxkb.finiteClamped(20...20000, fallback: 300)
    bright = bright.finiteClamped(-50...50, fallback: 0)
    head = head.finiteClamped(55...85, fallback: 72)
    top = top.finiteClamped(3...16, fallback: 8)
    below = below.finiteClamped(0.6...1.8, fallback: 1.2)
    if !["chest", "face"].contains(mode) { mode = "chest" }
    if !["face", "mix", "body"].contains(center) { center = "mix" }
  }
}
extension Double {
  func finiteClamped(_ range: ClosedRange<Double>, fallback: Double) -> Double {
    isFinite ? min(range.upperBound, max(range.lowerBound, self)) : fallback
  }
}
extension Encodable {
  func dictionary() throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: JSONEncoder().encode(self)) as? [String: Any] ?? [:]
  }
}
struct Adjustment: Codable, Equatable {
  var bright = 0.0, zoom = 1.0, tilt = 0.0, dx = 0.0, dy = 0.0
}
struct Composition: Codable, Equatable {
  var mode = "chest", center = "mix", head = 72.0, top = 8.0, below = 1.2
}
struct PhotoItem: Decodable, Identifiable {
  let id: Int
  var name: String, status: String, error: String?, preview: String?
  var width: Int, height: Int, face: Bool, warnings: [String]
  var adjustment: Adjustment, background: String, snap: Bool, rotation: Int, custom: Bool
  var composition: Composition, eye: Double?
  var image: UIImage? {
    guard let raw = preview?.split(separator: ",", maxSplits: 1).last,
      let data = Data(base64Encoded: String(raw))
    else { return nil }
    return UIImage(data: data)
  }
  var needsReview: Bool { status != "done" || !warnings.isEmpty }
}
struct EngineSnapshot: Decodable {
  var photos: [PhotoItem]
  var faceAvailable: Bool
  var backgroundAvailable: Bool
}
struct EngineAvailability: Decodable {
  var faceAvailable: Bool
  var backgroundAvailable: Bool
}
struct ExportFile: Decodable { let name: String, mime: String, size: Int, base64: String }
struct AppFailure: LocalizedError {
  let message: String
  let canOpenSettings: Bool
  var errorDescription: String? { message }
  init(_ message: String, canOpenSettings: Bool = false) {
    self.message = message
    self.canOpenSettings = canOpenSettings
  }
}
