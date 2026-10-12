import XCTest

final class FolderManagementUITests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testFoldersLongPressMoveRelaunchAndDelete() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-reset", "--ui-sample"]
    app.launch()
    XCTAssertTrue(app.buttons["photo-1"].waitForExistence(timeout: 180))
    back(app)
    XCTAssertTrue(app.buttons["newFolder"].waitForExistence(timeout: 10))
    app.buttons["newFolder"].tap()
    let name = app.textFields["folderName"]
    XCTAssertTrue(name.waitForExistence(timeout: 10))
    name.tap()
    name.typeText("10월 심사")
    app.buttons["saveFolder"].tap()
    XCTAssertTrue(app.buttons["folder-10월 심사"].waitForExistence(timeout: 10))
    capture("07-folders")
    app.buttons["folder-unfiled"].tap()
    let first = app.buttons["photo-1"]
    let second = app.buttons["photo-2"]
    XCTAssertTrue(first.waitForExistence(timeout: 10))
    XCTAssertFalse(app.buttons["사진 관리"].exists)
    first.press(forDuration: 0.8)
    XCTAssertTrue(app.buttons["deleteSelectedPhotos"].waitForExistence(timeout: 10))
    XCTAssertEqual(first.value as? String, "선택됨")
    second.tap()
    XCTAssertEqual(app.staticTexts["selectedPhotoCount"].label, "2장 선택")
    XCTAssertGreaterThan(
      app.staticTexts["originalNotice"].frame.minY, app.buttons["batchExport"].frame.maxY)
    capture("08-photo-selection")
    app.buttons["batchExport"].tap()
    XCTAssertTrue(app.staticTexts["선택한 사진 2장"].waitForExistence(timeout: 10))
    back(app)
    second.tap()
    app.buttons["moveSelectedPhotos"].tap()
    XCTAssertTrue(app.buttons["moveTo-10월 심사"].waitForExistence(timeout: 10))
    app.buttons["moveTo-10월 심사"].tap()
    let gone = NSPredicate(format: "exists == false")
    expectation(for: gone, evaluatedWith: app.buttons["photo-1"])
    waitForExpectations(timeout: 10)
    XCTAssertTrue(second.exists)
    back(app)
    XCTAssertEqual(app.buttons["folder-10월 심사"].value as? String, "사진 1장")
    app.buttons["selectFolders"].tap()
    app.buttons["folder-10월 심사"].tap()
    app.buttons["renameFolder"].tap()
    XCTAssertTrue(name.waitForExistence(timeout: 10))
    name.tap()
    name.typeText(
      String(repeating: XCUIKeyboardKey.delete.rawValue, count: "10월 심사".count) + "승급 심사")
    app.buttons["saveFolder"].tap()
    XCTAssertTrue(app.buttons["folder-승급 심사"].waitForExistence(timeout: 10))
    app.buttons["selectFolders"].tap()
    app.buttons["folder-승급 심사"].tap()
    XCTAssertTrue(first.waitForExistence(timeout: 10))
    XCTAssertFalse(second.exists)
    capture("09-folder-photos")

    app.terminate()
    app.launchArguments = ["--ui-testing"]
    app.launch()
    waitEnabled(app.buttons["importPhotos"])
    app.tabBars.buttons["파일"].tap()
    let restored = app.buttons["folder-승급 심사"]
    XCTAssertTrue(restored.waitForExistence(timeout: 180))
    waitEnabled(app.buttons["newFolder"])
    XCTAssertEqual(restored.value as? String, "사진 1장")
    restored.tap()
    XCTAssertTrue(app.buttons["photo-1"].waitForExistence(timeout: 20))
    XCTAssertFalse(app.buttons["photo-2"].exists)
    back(app)
    app.buttons["selectFolders"].tap()
    restored.tap()
    app.buttons["deleteFolders"].tap()
    app.buttons["폴더만 삭제"].tap()
    expectation(for: gone, evaluatedWith: restored)
    waitForExpectations(timeout: 10)
    XCTAssertEqual(app.buttons["folder-unfiled"].value as? String, "사진 2장")
    app.buttons["folder-unfiled"].tap()
    XCTAssertTrue(app.buttons["photo-1"].waitForExistence(timeout: 10))
    app.buttons["photo-1"].press(forDuration: 0.8)
    app.buttons["deleteSelectedPhotos"].tap()
    app.buttons["사진함에서 삭제"].tap()
    expectation(for: gone, evaluatedWith: app.buttons["photo-1"])
    waitForExpectations(timeout: 10)
    XCTAssertTrue(app.buttons["photo-2"].exists)
    app.terminate()
    app.launch()
    waitEnabled(app.buttons["importPhotos"])
    app.tabBars.buttons["파일"].tap()
    waitEnabled(app.buttons["newFolder"])
    XCTAssertEqual(app.buttons["folder-unfiled"].value as? String, "사진 1장")
    XCTAssertFalse(app.buttons["folder-승급 심사"].exists)
  }

  private func back(_ app: XCUIApplication) { app.navigationBars.buttons.element(boundBy: 0).tap() }
  private func waitEnabled(_ element: XCUIElement) {
    let ready = NSPredicate(format: "exists == true AND enabled == true")
    expectation(for: ready, evaluatedWith: element)
    waitForExpectations(timeout: 180)
  }
  private func capture(_ name: String) {
    let shot = XCTAttachment(screenshot: XCUIApplication().screenshot())
    shot.name = name
    shot.lifetime = .keepAlways
    add(shot)
  }
}
