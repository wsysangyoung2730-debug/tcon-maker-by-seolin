import UIKit
import UniformTypeIdentifiers
import ImageIO

enum PhotoImport {
    /// Normalizes HEIC/EXIF orientation once, at source pixel size. PNG preserves alpha.
    static func normalize(_ data:Data,name:String) throws -> (Data,String,String) {
        guard let source=CGImageSourceCreateWithData(data as CFData,nil),let properties=CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any],
              let width=properties[kCGImagePropertyPixelWidth] as? Int,let height=properties[kCGImagePropertyPixelHeight] as? Int,
              width>0,height>0,width<=60000,height<=60000,width*height<=100_000_000 else { throw AppFailure("열 수 없거나 너무 큰 사진이에요. 1억 화소 이하의 사진을 선택해 주세요.") }
        guard let image=UIImage(data:data) else { throw AppFailure("이 사진을 열 수 없어요.") }
        let sourceType=CGImageSourceGetType(source) as String?
        if image.imageOrientation == .up && [UTType.jpeg.identifier,UTType.png.identifier].contains(sourceType ?? "") {
            return (data,name,sourceType == UTType.png.identifier ? "image/png" : "image/jpeg")
        }
        let format=UIGraphicsImageRendererFormat();format.scale=1;format.opaque=false
        let size=CGSize(width:image.size.width*image.scale,height:image.size.height*image.scale)
        let normalized=UIGraphicsImageRenderer(size:size,format:format).image { _ in image.draw(in:CGRect(origin:.zero,size:size)) }
        guard let result=normalized.pngData() else { throw AppFailure("사진 방향을 변환하지 못했어요.") }
        return (result,(name as NSString).deletingPathExtension+".png","image/png")
    }
}
