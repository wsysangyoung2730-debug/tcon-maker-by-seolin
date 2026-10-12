import XCTest
import UIKit
@testable import TCONMaker

final class PhotoModelTests:XCTestCase {
    func testPresetsAndInvalidSavedSettings() {
        var s=PhotoSettings();s.preset("passport");XCTAssertEqual(s.wmm,35);XCTAssertEqual(s.hmm,45);XCTAssertEqual(s.mode,"face");XCTAssertEqual(s.head,75)
        s.wmm = .infinity;s.hmm = -2;s.maxkb = 1;s.center="invalid";s.validate()
        XCTAssertEqual(s.wmm,20);XCTAssertEqual(s.hmm,10);XCTAssertEqual(s.maxkb,20);XCTAssertEqual(s.center,"mix")
    }
    func testSafeDuplicateFilenamesAndDataValidation() throws {
        XCTAssertEqual(ExportService.safeName("../학생:사진.png"),".._학생_사진.png")
        let data=Data([1,2,3]);let files=[ExportFile(name:"same.png",mime:"image/png",size:3,base64:data.base64EncodedString()),ExportFile(name:"same.png",mime:"image/png",size:3,base64:data.base64EncodedString())]
        let urls=try ExportService.write(files);defer{try? FileManager.default.removeItem(at:urls[0].deletingLastPathComponent())}
        XCTAssertEqual(urls[0].lastPathComponent,"same.png");XCTAssertEqual(urls[1].lastPathComponent,"same_2.png");XCTAssertEqual(try Data(contentsOf:urls[0]),data)
        XCTAssertThrowsError(try ExportService.write([ExportFile(name:"broken.jpg",mime:"image/jpeg",size:30,base64:"invalid")]))
    }
    func testImageImportRejectsCorruptionAndPreservesPNG() throws {
        XCTAssertThrowsError(try PhotoImport.normalize(Data([0,1,2]),name:"bad.heic"))
        let format=UIGraphicsImageRendererFormat();format.scale=1
        let image=UIGraphicsImageRenderer(size:CGSize(width:80,height:100),format:format).image{ctx in UIColor.red.setFill();ctx.fill(CGRect(x:0,y:0,width:80,height:100))}
        let data=try XCTUnwrap(image.pngData());let result=try PhotoImport.normalize(data,name:"small.png")
        XCTAssertEqual(result.0,data);XCTAssertEqual(result.2,"image/png")
    }
}
