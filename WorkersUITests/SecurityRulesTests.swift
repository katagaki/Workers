import XCTest

@MainActor
final class SecurityRulesTests: XCTestCase {
    func testReorderingPersistsAfterRefresh() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-DemoMode", "YES", "-ScreenshotMode", "YES",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US"
        ]
        app.launch()
        let domains = app.tabBars.buttons["Domains"]
        XCTAssertTrue(domains.waitForExistence(timeout: 15))
        domains.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "schale.gov.kv,")).firstMatch.tap()
        let security = app.staticTexts["Security Rules"]
        for _ in 0..<6 where !security.exists || !security.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(security.exists && security.isHittable)
        security.tap()
        let first = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Challenge the admin area, 1.")).firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        app.navigationBars.buttons["Edit"].tap()
        XCTAssertTrue(app.navigationBars.buttons["Done"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.switches.count, 0)

        let source = app.cells.containing(.staticText, identifier: "Challenge the login page").firstMatch
        let destination = app.cells.containing(.staticText, identifier: "Challenge the admin area").firstMatch
        XCTAssertTrue(source.exists && destination.exists)
        source.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5))
            .press(forDuration: 1, thenDragTo: destination.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.1)))
        let moved = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Challenge the login page, 1.")).firstMatch
        XCTAssertTrue(moved.waitForExistence(timeout: 10))
        app.navigationBars.buttons["Done"].tap()
        XCTAssertGreaterThan(app.switches.count, 0)

        app.navigationBars.buttons["schale.gov.kv"].tap()
        XCTAssertTrue(security.waitForExistence(timeout: 5))
        security.tap()
        XCTAssertTrue(moved.waitForExistence(timeout: 10))
    }
}
