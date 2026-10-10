import XCTest

@MainActor
final class WorkersAITests: XCTestCase {
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
        let model = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "@cf/baai/bge-base-en-v1.5")).firstMatch
        XCTAssertTrue(model.waitForExistence(timeout: 15))
        model.tap()
        XCTAssertTrue(app.staticTexts["Input Tokens"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Output Tokens"].exists)
        XCTAssertTrue(app.staticTexts["Average Inference Time"].exists)
        app.segmentedControls.buttons["30 Days"].tap()
        XCTAssertTrue(app.staticTexts["Input Tokens"].waitForExistence(timeout: 10))
    }
}
