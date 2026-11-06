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
