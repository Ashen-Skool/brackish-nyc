import XCTest
final class PhotoJourneyTests:XCTestCase {
    func testPhotoImportComparisonAndRecord() throws {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--reset-test-data"];app.launch()
        for _ in 0..<3 {let b=app.buttons["onboarding-next"];XCTAssertTrue(b.waitForExistence(timeout:8));b.tap()}
        app.buttons["tab-identify"].tap()
        let photos=app.buttons["photos-button"];XCTAssertTrue(photos.waitForExistence(timeout:5));photos.tap()
        // Simulator fixture is imported by Scripts/verify.sh before this test.
        let grid=app.scrollViews["photosView_content_scroll_view"]
        XCTAssertTrue(grid.waitForExistence(timeout:12))
        XCTAssertTrue(app.buttons["Collections"].waitForExistence(timeout:8))
        let picker=XCTAttachment(screenshot:XCUIScreen.main.screenshot());picker.name="native-photo-picker";picker.lifetime = .keepAlways;add(picker)
        // iOS 26.5's picker does not expose these thumbnail cells to XCTest.
        // This point is the visually verified first cell on the declared iPhone 16.
        app.coordinate(withNormalizedOffset:CGVector(dx:0.17,dy:0.44)).tap()
        let compare=app.buttons["compare-photo"]
        for _ in 0..<5 {if compare.isHittable {break};app.swipeUp()}
        XCTAssertTrue(compare.waitForExistence(timeout:8));compare.tap()
        let candidate=app.buttons["candidate-yellow-perch"]
        for _ in 0..<5 {if candidate.isHittable {break};app.swipeUp()}
        XCTAssertTrue(candidate.waitForExistence(timeout:20));candidate.tap()
        let a=XCTAttachment(screenshot:XCUIScreen.main.screenshot());a.name="real-photo-candidates";a.lifetime = .keepAlways;add(a)
        let record=app.buttons["record-candidate"]
        for _ in 0..<5 {if record.isHittable {break};app.swipeUp()};record.tap()
        let notes=app.descendants(matching:.any)["entry-notes"].firstMatch
        for _ in 0..<3 {if notes.isHittable {break};app.swipeUp()}
        notes.tap();notes.typeText("Showcase example. Attributed iNaturalist evaluation photograph; not a personal catch.")
        if app.buttons["Done"].exists {app.buttons["Done"].firstMatch.tap()}
        let save=app.buttons["save-entry"]
        for _ in 0..<4 {if save.isHittable {break};app.swipeUp()};save.tap()
        XCTAssertTrue(app.buttons["tab-journal"].waitForExistence(timeout:8));app.buttons["tab-journal"].tap()
        XCTAssertTrue(app.staticTexts["Yellow perch"].waitForExistence(timeout:8))
        let final=XCTAttachment(screenshot:XCUIScreen.main.screenshot());final.name="photo-journal-entry";final.lifetime = .keepAlways;add(final)
        app.buttons["Settings and privacy"].tap();app.buttons["export-journal"].tap()
        let filename=app.textFields["DOCPicker.filenameTextField"]
        XCTAssertTrue(filename.waitForExistence(timeout:25));filename.tap()
        filename.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:(filename.value as? String ?? "").count))
        filename.typeText("Brackish-Photo-export-\(UUID().uuidString.prefix(8))")
        let exportSave=app.buttons["Save"].firstMatch;XCTAssertTrue(exportSave.waitForExistence(timeout:25));exportSave.tap()
        XCTAssertTrue(app.staticTexts["export-result"].waitForExistence(timeout:12))
    }
}
