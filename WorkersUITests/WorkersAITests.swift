import XCTest

@MainActor
final class WorkersAITests: XCTestCase {
    func testPlaygroundGeneratesDemoResponse() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-DemoMode", "YES", "-ScreenshotMode", "YES"]
        app.launch()
        let aiTab = app.tabBars.buttons["Workers AI"]
        XCTAssertTrue(aiTab.waitForExistence(timeout: 15))
        aiTab.tap()
        let playground = app.buttons["OpenPlayground"]
        if !playground.isHittable { app.swipeUp() }
        XCTAssertTrue(playground.waitForExistence(timeout: 10))
        playground.tap()
        let prompt = app.textFields["PlaygroundPrompt"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 10))
        prompt.tap()
        prompt.typeText("Explain Workers")
        app.buttons["PlaygroundRun"].tap()
        let response = app.staticTexts["PlaygroundResponse"]
        XCTAssertTrue(response.waitForExistence(timeout: 15))
        XCTAssertTrue(response.label.contains("sample response"))
    }

    func testUsageAndModelDetails() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-DemoMode", "YES", "-ScreenshotMode", "YES"]
        app.launch()
        let aiTab = app.tabBars.buttons["Workers AI"]
        XCTAssertTrue(aiTab.waitForExistence(timeout: 15))
        XCTAssertGreaterThan(aiTab.frame.minX, app.tabBars.buttons["Storage"].frame.minX)
        XCTAssertLessThan(aiTab.frame.minX, app.tabBars.buttons["Domains"].frame.minX)
        aiTab.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", "Neurons Usage")).firstMatch.waitForExistence(timeout: 15))
        let model = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "@cf/seminar-research/koyuki-chat-2-2b")).firstMatch
        XCTAssertTrue(model.waitForExistence(timeout: 15))
        model.tap()
        XCTAssertTrue(app.staticTexts["Input Tokens"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Output Tokens"].exists)
        XCTAssertTrue(app.staticTexts["Avg. Inference"].exists)
        app.segmentedControls.buttons["30 Days"].tap()
        XCTAssertTrue(app.staticTexts["Input Tokens"].waitForExistence(timeout: 10))
    }
}
