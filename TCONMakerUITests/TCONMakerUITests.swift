import XCTest

final class TCONMakerUITests:XCTestCase {
    override func setUpWithError() throws{continueAfterFailure=false}
    func testHomeAndSettings() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing"];app.launch()
        XCTAssertTrue(app.buttons["openSettings"].waitForExistence(timeout:30));capture("01-start")
        app.buttons["openSettings"].tap()
        XCTAssertTrue(app.buttons["applySettings"].waitForExistence(timeout:10))
        app.buttons["여권사진"].tap()
        XCTAssertEqual(app.textFields["setting-가로"].value as? String,"35")
        XCTAssertEqual(app.textFields["setting-세로"].value as? String,"45")
        capture("05-settings")
        app.buttons["취소"].tap()
    }
    func testPhotoEditBatchAndExport() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--ui-sample"];app.launch()
        XCTAssertTrue(app.buttons["photo-1"].waitForExistence(timeout:240),app.debugDescription)
        capture("02-batch");app.buttons["photo-1"].tap()
        XCTAssertTrue(app.images["editorCanvas"].waitForExistence(timeout:20))
        capture("03-editor")
        app.buttons["tool-밝기"].tap()
        let input=app.buttons["이 사진의 밝기 숫자 입력"];XCTAssertTrue(input.waitForExistence(timeout:10));input.tap()
        let field=app.alerts.textFields.firstMatch;XCTAssertTrue(field.waitForExistence(timeout:5));field.tap();field.typeText(XCUIKeyboardKey.delete.rawValue+"12")
        app.alerts.buttons["적용"].tap()
        let export=app.buttons["editorExport"];XCTAssertTrue(export.waitForExistence(timeout:20))
        let gone=NSPredicate(format:"exists == false");expectation(for:gone,evaluatedWith:app.otherElements["processingOverlay"]);waitForExpectations(timeout:120)
        export.tap();XCTAssertTrue(app.buttons["savePhotos"].waitForExistence(timeout:15));capture("04-export")
        app.scrollViews.firstMatch.swipeUp()
        app.buttons["destination-zip"].tap()
        XCTAssertEqual(app.buttons["destination-zip"].value as? String,"선택됨")
        app.buttons["savePhotos"].tap()
        let filesShown=NSPredicate{_,_ in app.buttons["취소"].exists || app.buttons["Cancel"].exists || app.navigationBars["Browse"].exists || app.buttons["저장"].exists || app.buttons["Save"].exists}
        expectation(for:filesShown,evaluatedWith:app);waitForExpectations(timeout:30)
        capture("06-files-export")
    }
    private func capture(_ name:String){_ = XCTWaiter.wait(for:[],timeout:0.8);let a=XCTAttachment(screenshot:XCUIApplication().screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
}
