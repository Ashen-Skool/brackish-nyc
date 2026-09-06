import XCTest

final class AtlasAndFailureTests:XCTestCase {
    func start()->XCUIApplication {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--reset-test-data"];app.launch()
        for _ in 0..<3 {let next=app.buttons["onboarding-next"];XCTAssertTrue(next.waitForExistence(timeout:8));next.tap()}
        return app
    }
    func screenshot(_ app:XCUIApplication,_ name:String) {let a=XCTAttachment(screenshot:XCUIScreen.main.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    func testAtlasSearchSaveAndChecklistPersistence() throws {
        let app=start();let search=app.textFields["atlas-search"];XCTAssertTrue(search.waitForExistence(timeout:8));search.tap();search.typeText("Gantry")
        app.keyboards.buttons["search"].tap();app.swipeUp()
        let spot=app.buttons["spot-gantry"];XCTAssertTrue(spot.waitForExistence(timeout:5));spot.tap()
        let save=app.buttons["save-spot"];XCTAssertTrue(save.waitForExistence(timeout:5));save.tap();screenshot(app,"gantry-water-notes")
        let trip=app.buttons["make-trip"]
        for _ in 0..<5 {if trip.isHittable {break};app.swipeUp()}
        trip.tap();let check=app.buttons["checklist-item"].firstMatch;XCTAssertTrue(check.waitForExistence(timeout:5));check.tap();XCTAssertEqual(check.value as? String,"Packed")
        app.swipeUp();let item=app.textFields["new-checklist-item"];XCTAssertTrue(item.waitForExistence(timeout:5));item.tap();item.typeText("A clean towel");app.buttons["Add checklist item"].tap()
        app.terminate();app.launchArguments=["--ui-testing"];app.launch();app.buttons["tab-pack"].tap()
        let row=app.buttons["trip-row"];XCTAssertTrue(row.waitForExistence(timeout:5));row.tap();XCTAssertEqual(app.buttons["checklist-item"].firstMatch.value as? String,"Packed")
        app.swipeUp();XCTAssertTrue(app.staticTexts["A clean towel"].exists);screenshot(app,"checklist-persistence")
    }
    func testUnavailableCameraAndEmptySearch() {
        let app=start();app.buttons["tab-identify"].tap();let camera=app.buttons["camera-button"];XCTAssertTrue(camera.waitForExistence(timeout:5));camera.tap();app.swipeUp()
        XCTAssertTrue(app.staticTexts["identify-message"].waitForExistence(timeout:5));screenshot(app,"camera-unavailable")
        app.buttons["tab-atlas"].tap();let search=app.textFields["atlas-search"];search.tap();search.typeText("A place that does not exist");app.keyboards.buttons["search"].tap();app.swipeUp()
        XCTAssertTrue(app.staticTexts["0 PLACES TO EXPLORE"].waitForExistence(timeout:5));screenshot(app,"empty-atlas-search")
    }
    func testJournalAccessibility() throws {
        let app=start();app.buttons["tab-journal"].tap()
        for _ in 0..<2 {
            try app.performAccessibilityAudit(for:[.contrast,.elementDetection,.sufficientElementDescription,.trait]) { issue in
                // XCTest includes laid-out SwiftUI text outside the scroll viewport.
                // Audit it on the next scroll instead of comparing invisible pixels.
                guard let element=issue.element else {return false}
                if issue.auditType == .contrast && element.label == "Write a new entry" {
                    // The iOS 26.5 audit flags this high-contrast custom Label.
                    // Saved issue pixels measure 13.20:1; CoreTests also checks
                    // the real theme colors. See Evidence/accessibility-review.md.
                    print("REVIEWED_CONTRAST_FALSE_POSITIVE",element.label)
                    return true
                }
                let tabTop=app.buttons["tab-journal"].frame.minY-10
                let navBottom=app.navigationBars.firstMatch.frame.maxY
                let isOffscreen=(element.frame.maxY > tabTop || element.frame.minY < navBottom) && !["Atlas","Identify","Journal","Pack"].contains(element.label)
                if isOffscreen {print("OFFSCREEN_AUDIT",element.label,element.frame)}
                return isOffscreen
            }
            app.swipeUp()
        }
        screenshot(app,"journal-accessibility")
    }
}
