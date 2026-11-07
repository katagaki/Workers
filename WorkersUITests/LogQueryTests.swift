import XCTest

@MainActor
final class LogQueryTests: XCTestCase {
    private var app: XCUIApplication!
    private var editor: XCUIElement { app.descendants(matching: .any)["LogQueryEditor"].firstMatch }

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-DemoMode", "YES", "-ScreenshotMode", "YES"]
        app.launch()
        let worker = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "wildhunt-visitor-management")).firstMatch
        XCTAssertTrue(worker.waitForExistence(timeout: 40))
        worker.tap()
        let logs = app.buttons.matching(NSPredicate(format: "label == %@", "Logs")).firstMatch
        // Rows below the fold are not in the hierarchy until scrolled to.
        for _ in 0..<4 where !(logs.exists && logs.isHittable) {
            app.swipeUp()
            _ = logs.waitForExistence(timeout: 2)
        }
        logs.tap()
        let queryMode = app.segmentedControls.buttons["Query"]
        XCTAssertTrue(queryMode.waitForExistence(timeout: 10))
        queryMode.tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.tap()
    }

    private func suggestion(_ text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", text)).firstMatch
    }

    func testCompletingAFilterKeepsTheKeyboardAndRunsTheQuery() {
        XCTAssertTrue(suggestion("$metadata.message").waitForExistence(timeout: 5))

        editor.typeText("lev")
        XCTAssertTrue(suggestion("$metadata.level").waitForExistence(timeout: 5))
        suggestion("$metadata.level").tap()
        XCTAssertEqual(editor.value as? String, "$metadata.level ")
        XCTAssertTrue(app.keyboards.firstMatch.exists)

        XCTAssertTrue(suggestion("contains").waitForExistence(timeout: 5))
        suggestion("=").tap()
        XCTAssertEqual(editor.value as? String, "$metadata.level = ")

        XCTAssertTrue(suggestion("error").waitForExistence(timeout: 10))
        suggestion("error").tap()
        XCTAssertEqual(editor.value as? String, "$metadata.level = error ")

        editor.typeText("\n")
        XCTAssertEqual(editor.value as? String, "$metadata.level = error ")
        let result = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Error")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
    }

    func testOrSuggestionBuildsAQueryMatchingEitherSide() {
        editor.typeText("$metadata.level = error ")
        XCTAssertTrue(suggestion("OR").waitForExistence(timeout: 5))
        suggestion("OR").tap()
        XCTAssertEqual(editor.value as? String, "$metadata.level = error OR ")

        editor.typeText("$metadata.level = log\n")
        let errorResult = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Error")).firstMatch
        let otherResult = app.buttons.matching(NSPredicate(format: "NOT (label CONTAINS %@) AND label CONTAINS %@", "Error", "Scheduled")).firstMatch
        XCTAssertTrue(errorResult.waitForExistence(timeout: 10))
        XCTAssertTrue(otherResult.waitForExistence(timeout: 10))
    }

    func testParenthesesGroupConditions() {
        editor.typeText("(")
        XCTAssertTrue(suggestion("$metadata.message").waitForExistence(timeout: 5))
        editor.typeText("$metadata.level = error OR $metadata.level = log) ")
        XCTAssertTrue(suggestion("OR").waitForExistence(timeout: 5))
        editor.typeText("$metadata.message contains a\n")
        XCTAssertEqual(editor.value as? String, "($metadata.level = error OR $metadata.level = log) $metadata.message contains a")
        let result = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Scheduled")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 10))
    }

    func testUnclosedParenthesisShowsAnError() {
        editor.typeText("($metadata.level = error\n")
        XCTAssertTrue(app.staticTexts["Close each opening parenthesis in your query."].waitForExistence(timeout: 5))
    }

    func testDanglingOrShowsAnError() {
        editor.typeText("$metadata.level = error OR\n")
        XCTAssertTrue(app.staticTexts["Add a condition on both sides of OR and AND."].waitForExistence(timeout: 5))
    }

    func testSuggestionsFollowTheCursor() {
        editor.typeText("$workers.cpuTimeMs ")
        XCTAssertTrue(suggestion(">=").waitForExistence(timeout: 5))
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.005, dy: 0.5)).tap()
        XCTAssertTrue(suggestion("$metadata.message").waitForExistence(timeout: 5))
        XCTAssertFalse(suggestion(">=").exists)
    }

    func testInvalidQueryShowsAnError() {
        editor.typeText("$metadata.level =\n")
        XCTAssertTrue(app.staticTexts["Enter a value after each operator."].waitForExistence(timeout: 5))
    }
}
