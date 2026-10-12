import Foundation
import Photos

enum ExportService {
    static func safeName(_ value:String) -> String {
        let cleaned=value.components(separatedBy:CharacterSet(charactersIn:"/\\:").union(.controlCharacters)).joined(separator:"_")
        return cleaned.isEmpty || cleaned == "." || cleaned == ".." ? "사진.jpg" : cleaned
    }
    static func write(_ files:[ExportFile]) throws -> [URL] {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent("TCONExports",isDirectory:true).appendingPathComponent(UUID().uuidString,isDirectory:true)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        var used=Set<String>()
        do {
            return try files.map { file in
                guard let data=Data(base64Encoded:file.base64),data.count==file.size else { throw AppFailure("저장할 파일이 손상됐어요. 다시 시도해 주세요.") }
                let name=safeName(file.name);let ext=(name as NSString).pathExtension;let stem=(name as NSString).deletingPathExtension
                var unique=name;var index=2
                while used.contains(unique.lowercased()) { unique="\(stem)_\(index)"+(ext.isEmpty ? "" : ".\(ext)");index+=1 }
                used.insert(unique.lowercased())
                let url=directory.appendingPathComponent(unique);try data.write(to:url,options:.atomic);return url
            }
        } catch { try? FileManager.default.removeItem(at:directory);throw error }
    }
    static func saveToPhotos(_ urls:[URL]) async throws {
        let status=await PHPhotoLibrary.requestAuthorization(for:.addOnly)
        guard status == .authorized || status == .limited else { throw AppFailure("사진 저장 권한이 꺼져 있어요. 설정에서 사진 추가 권한을 켜거나 파일 앱에 저장해 주세요.") }
        try await PHPhotoLibrary.shared().performChanges {
            for url in urls { PHAssetCreationRequest.forAsset().addResource(with:.photo,fileURL:url,options:nil) }
        }
    }
    static func cleanOldExports() {
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent("TCONExports")
        // Export URLs must remain alive while Files or a share extension consumes them.
        // Clear the previous process's temporary exports only at cold launch.
        try? FileManager.default.removeItem(at:dir)
    }
}
