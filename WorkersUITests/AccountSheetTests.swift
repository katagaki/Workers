import XCTest

@MainActor
final class AccountSheetTests: XCTestCase {
    func testAccountSheetOpensFromEachTabAndDismisses() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("This test covers the iPhone tab bar.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-DemoMode", "YES", "-ScreenshotMode", "YES"
        ]
        app.launch()

        XCTAssertFalse(app.tabBars.buttons["More"].exists)
        for tab in ["Workers", "Storage", "Domains", "Analytics"] {
            let tabButton = app.tabBars.buttons[tab]
            XCTAssertTrue(tabButton.waitForExistence(timeout: 15))
            tabButton.tap()
            let accountButton = app.navigationBars.buttons["Account"]
            XCTAssertTrue(accountButton.waitForExistence(timeout: 15))
            accountButton.tap()

            let accountNavigationBar = app.navigationBars["Account"]
            XCTAssertTrue(accountNavigationBar.waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["Kivotos Cloud"].exists)
            XCTAssertTrue(app.buttons["Manage Accounts..."].exists)
            let doneButton = accountNavigationBar.buttons["Done"]
            XCTAssertTrue(doneButton.exists)
            doneButton.tap()
            XCTAssertTrue(accountNavigationBar.waitForNonExistence(timeout: 5))

            accountButton.tap()
            XCTAssertTrue(accountNavigationBar.waitForExistence(timeout: 5))
            accountNavigationBar.swipeDown()
            XCTAssertTrue(accountNavigationBar.waitForNonExistence(timeout: 5))
        }
    }
}
