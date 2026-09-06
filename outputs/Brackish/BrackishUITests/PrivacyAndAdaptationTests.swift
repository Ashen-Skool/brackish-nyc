import XCTest
final class PrivacyAndAdaptationTests:XCTestCase {
    func launch(_ extra:[String]=[])->XCUIApplication {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--reset-test-data"]+extra;app.launch()
        for _ in 0..<3 {let next=app.buttons["onboarding-next"];XCTAssertTrue(next.waitForExistence(timeout:8));next.tap()}
        return app
    }
    func testExportToFilesAndDeleteAll() {
        let app=launch();app.buttons["Settings and privacy"].tap()
        let export=app.buttons["export-journal"];XCTAssertTrue(export.waitForExistence(timeout:5));export.tap()
        let filename=app.textFields["DOCPicker.filenameTextField"]
        XCTAssertTrue(filename.waitForExistence(timeout:25))
        filename.tap();filename.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:(filename.value as? String ?? "").count));filename.typeText("Brackish-UI-export-\(UUID().uuidString.prefix(8))")
        let save=app.buttons["Save"].firstMatch;XCTAssertTrue(save.waitForExistence(timeout:25))
        let attachment=XCTAttachment(screenshot:XCUIScreen.main.screenshot());attachment.name="native-export";attachment.lifetime = .keepAlways;add(attachment)
        save.tap();XCTAssertTrue(app.staticTexts["export-result"].waitForExistence(timeout:12))
        let erase=app.buttons["delete-all"]
        for _ in 0..<15 {if erase.isHittable {break};app.swipeUp()}
        XCTAssertTrue(erase.exists)
        // The runtime can report this visible bottom List row as not hittable
        // after returning from Files. Use its actual layout coordinate.
        erase.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5)).tap()
        let confirmations=app.buttons.matching(NSPredicate(format:"label == 'Delete all local data'")).allElementsBoundByIndex
        let confirm=confirmations.first(where:{$0.isHittable})
        XCTAssertNotNil(confirm);confirm?.tap()
        XCTAssertTrue(app.buttons["onboarding-next"].waitForExistence(timeout:8))
        app.terminate();app.launchArguments=["--ui-testing"];app.launch();XCTAssertTrue(app.buttons["onboarding-next"].waitForExistence(timeout:8))
    }
    func testLargestDynamicTypeCanNavigateAndWrite() {
        let app=launch(["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"])
        app.buttons["tab-journal"].tap()
        let button=app.buttons["new-journal-entry"]
        for _ in 0..<5 {if button.isHittable {break};app.swipeUp()}
        XCTAssertTrue(button.exists)
        let a=XCTAttachment(screenshot:XCUIScreen.main.screenshot());a.name="largest-dynamic-type";a.lifetime = .keepAlways;add(a)
        button.tap();XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout:5))
    }
    func testShowOnboardingAgainFromSettings() {
        let app=launch()
        app.buttons["Settings and privacy"].tap()
        let replay=app.buttons["show-onboarding-again"]
        XCTAssertTrue(replay.waitForExistence(timeout:5))
        replay.tap()

        let next=app.buttons["onboarding-next"]
        XCTAssertTrue(next.waitForExistence(timeout:8))
        XCTAssertTrue(app.staticTexts["A different\nkind of city."].exists)
        for _ in 0..<3 {
            XCTAssertTrue(next.waitForExistence(timeout:8))
            next.tap()
        }
        XCTAssertTrue(app.buttons["tab-atlas"].waitForExistence(timeout:8))
    }
}
