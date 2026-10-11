import XCTest

@MainActor
final class WidgetPrototypeTests: XCTestCase {
    func testFiveWidgetDesignsRender() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-DemoMode", "YES", "-ScreenshotMode", "YES"]
        app.launch()
        let account = app.navigationBars.buttons["Account"]
        XCTAssertTrue(account.waitForExistence(timeout: 15))
        account.tap()
        app.buttons["WidgetDesignGallery"].tap()
        for design in ["traffic", "reliability", "trend", "overview", "compact"] {
            let button = app.buttons["WidgetDetail.\(design)"]
            for _ in 0..<8 {
                if button.exists && button.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(button.isHittable)
            button.tap()
            XCTAssertTrue(app.staticTexts["Home Screen and StandBy"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["Lock Screen"].exists)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Widget design \(design)"
            attachment.lifetime = .keepAlways
            add(attachment)
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
}
