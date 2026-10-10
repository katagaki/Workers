import XCTest

/// Stages and captures the App Store screenshots in demo mode, in dark mode.
///
/// Driven by `Assets/App Store/capture.sh`, which says where to write through
/// `SCREENSHOT_DIR` and which language to use through `SCREENSHOT_LANGUAGE`.
/// Without them the test skips, so it stays out of the way of an ordinary test run.
@MainActor
final class AppStoreScreenshots: XCTestCase {
    private enum Step {
        case tab([String: String])
        case tap(String)
        case tapLocalized([String: String])
        /// Opens the iPad sidebar and picks an item in it.
        case sidebar(String)
    }

    private struct Shot {
        let name: String
        let steps: [Step]
    }

    private static let workersTab = Step.tab(["en": "Workers", "ja": "Workers"])
    private static let storageTab = Step.tab(["en": "Storage", "ja": "ストレージ"])
    private static let domainsTab = Step.tab(["en": "Domains", "ja": "ドメイン"])
    private static let analyticsTab = Step.tab(["en": "Analytics", "ja": "分析"])
    private static let logs = Step.tapLocalized(["en": "Logs", "ja": "ログ"])

    private static let iPhoneShots = [
        Shot(name: "01-workers", steps: [workersTab]),
        Shot(name: "02-worker", steps: [workersTab, .tap("schale-gateway")]),
        Shot(name: "03-logs", steps: [workersTab, .tap("schale-gateway"), logs]),
        Shot(name: "04-storage", steps: [storageTab, .tap("D1"), .tap("momotalk-auth-db"), .tap("accounts")]),
        Shot(name: "05-domain", steps: [domainsTab, .tap("schale.gov.kv")]),
        Shot(name: "06-analytics", steps: [analyticsTab]),
    ]

    /// On iPad the workers, storage, and domains live in the sidebar.
    private static let iPadShots = [
        Shot(name: "01-workers", steps: [.sidebar("schale-gateway"), .tap("ToggleSideBar")]),
        Shot(name: "02-worker", steps: [.sidebar("schale-gateway")]),
        Shot(name: "03-logs", steps: [.sidebar("schale-gateway"), logs]),
        Shot(name: "04-storage", steps: [.sidebar("D1"), .tap("momotalk-auth-db"), .tap("accounts")]),
        Shot(name: "05-domain", steps: [.sidebar("schale.gov.kv")]),
        Shot(name: "06-analytics", steps: [analyticsTab]),
    ]

    private var shots: [Shot] {
        UIDevice.current.userInterfaceIdiom == .pad ? Self.iPadShots : Self.iPhoneShots
    }

    private var directory: URL!
    private var language = "en"
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        let environment = ProcessInfo.processInfo.environment
        guard let path = environment["SCREENSHOT_DIR"], !path.isEmpty else {
            throw XCTSkip("run through Assets/App Store/capture.sh")
        }
        directory = URL(fileURLWithPath: path)
        language = environment["SCREENSHOT_LANGUAGE"] ?? "en"
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func testScreens() throws {
        defer { XCUIDevice.shared.appearance = .light }
        XCUIDevice.shared.appearance = .dark
        // The appearance change is not picked up by an app launched right after it.
        Thread.sleep(forTimeInterval: 2)
        for shot in shots {
            launch()
            for step in shot.steps {
                perform(step)
            }
            // Let the charts and any pushed view finish animating in.
            Thread.sleep(forTimeInterval: 3)
            let file = directory.appendingPathComponent("\(shot.name).png")
            try XCUIScreen.main.screenshot().pngRepresentation.write(to: file)
        }
    }

    // MARK: - Steps

    private func launch() {
        app = XCUIApplication()
        let locale = language == "ja" ? "ja_JP" : "en_US"
        app.launchArguments += [
            "-AppleLanguages", "(\(language))", "-AppleLocale", locale,
            "-DemoMode", "YES", "-ScreenshotMode", "YES",
        ]
        app.launch()
    }

    private func perform(_ step: Step) {
        switch step {
        case .tab(let labels):
            let label = labels[language] ?? labels["en"]!
            let button = app.tabBars.buttons[label].exists
                ? app.tabBars.buttons[label]
                : app.buttons.matching(identifier: label).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 15), "missing \(label) tab")
            button.tap()
        case .tap(let label):
            tap(label)
        case .tapLocalized(let labels):
            tap(labels[language] ?? labels["en"]!)
        case .sidebar(let label):
            // Each shot relaunches the app, so the sidebar always starts closed.
            tap("ToggleSideBar")
            // A tap while the sidebar is still sliding in lands on the wrong row.
            Thread.sleep(forTimeInterval: 1.5)
            let matches = app.descendants(matching: .any).matching(identifier: label)
            XCTAssertTrue(matches.firstMatch.waitForExistence(timeout: 10), "missing \(label) in the sidebar")
            // Tabs hidden from the tab bar keep elements with the same label off screen.
            let item = matches.allElementsBoundByIndex.first { $0.isHittable }
            XCTAssertNotNil(item, "\(label) is not on screen in the sidebar")
            item?.tap()
        }
    }

    private func tap(_ label: String) {
        let element = app.descendants(matching: .any).matching(identifier: label)
            .matching(NSPredicate(format: "elementType == %d OR elementType == %d",
                                  XCUIElement.ElementType.button.rawValue,
                                  XCUIElement.ElementType.staticText.rawValue))
            .firstMatch
        _ = element.waitForExistence(timeout: 10)
        // Rows below the fold are not in the hierarchy until scrolled to.
        for _ in 0..<4 where !(element.exists && element.isHittable) {
            app.swipeUp()
            _ = element.waitForExistence(timeout: 2)
        }
        XCTAssertTrue(element.exists, "missing \(label)")
        element.tap()
    }
}
