import XCTest
final class JournalEditingTests:XCTestCase {
    func testEditValidationAndDeleteEntry() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing","--reset-test-data"];app.launch()
        for _ in 0..<3 {let b=app.buttons["onboarding-next"];XCTAssertTrue(b.waitForExistence(timeout:8));b.tap()}
        app.buttons["tab-journal"].tap();app.buttons["new-journal-entry"].tap()
        let notes=app.descendants(matching:.any)["entry-notes"].firstMatch;XCTAssertTrue(notes.waitForExistence(timeout:5));notes.tap();notes.typeText("Before editing.")
        if app.buttons["Done"].exists {app.buttons["Done"].firstMatch.tap()};app.swipeUp()
        let length=app.textFields["entry-length"];length.tap();length.typeText("999")
        if app.buttons["Done"].exists {app.buttons["Done"].firstMatch.tap()}
        app.buttons["save-entry"].tap();XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label BEGINSWITH 'Use a positive number'")).firstMatch.waitForExistence(timeout:5))
        length.tap();length.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:3));length.typeText("12.5");if app.buttons["Done"].exists {app.buttons["Done"].firstMatch.tap()};app.buttons["save-entry"].tap()
        let row=app.buttons["journal-entry"];XCTAssertTrue(row.waitForExistence(timeout:5));row.tap()
        let edit=app.buttons["edit-entry"];for _ in 0..<3 {if edit.isHittable {break};app.swipeUp()};edit.tap()
        let editNotes=app.descendants(matching:.any)["entry-notes"].firstMatch;XCTAssertTrue(editNotes.waitForExistence(timeout:5));editNotes.tap();editNotes.typeText(" Edited after the trip.")
        if app.buttons["Done"].exists {app.buttons["Done"].firstMatch.tap()};app.swipeUp();app.buttons["save-entry"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label CONTAINS 'Edited after the trip.'")).firstMatch.waitForExistence(timeout:5))
        let delete=app.buttons["delete-entry"];for _ in 0..<3 {if delete.isHittable {break};app.swipeUp()};delete.tap()
        let confirm=app.buttons.matching(NSPredicate(format:"label == 'Delete entry'")).allElementsBoundByIndex.first(where:{$0.isHittable})
        XCTAssertNotNil(confirm);confirm?.tap()
        XCTAssertTrue(app.buttons["new-journal-entry"].waitForExistence(timeout:8));XCTAssertFalse(app.buttons["journal-entry"].exists)
    }
}
