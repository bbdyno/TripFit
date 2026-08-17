import XCTest

final class TripFitScreenshotUITests: XCTestCase {
    private struct Language {
        let code: String
        let locale: String
    }

    private let languages = [
        Language(code: "en", locale: "en_US"),
        Language(code: "ko", locale: "ko_KR"),
        Language(code: "ja", locale: "ja_JP"),
        Language(code: "zh-Hans", locale: "zh_Hans_CN"),
        Language(code: "zh-Hant", locale: "zh_Hant_TW"),
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureStoreScreenshots() throws {
        warmUpApplicationLaunch()

        for language in languages {
            let app = XCUIApplication()
            app.launchEnvironment["TRIPFIT_SCREENSHOT_MODE"] = "1"
            app.launchArguments = [
                "-AppleLanguages", "(\(language.code))",
                "-AppleLocale", language.locale,
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL",
            ]
            app.launch()

            XCTAssertTrue(app.buttons["tripfit.tab.home"].waitForExistence(timeout: 10))
            waitForUIToSettle(duration: 1.5)
            capture(name: "\(language.code)-01-home")

            app.buttons["tripfit.tab.wardrobe"].tap()
            waitForUIToSettle()
            capture(name: "\(language.code)-02-wardrobe")

            app.buttons["tripfit.tab.outfits"].tap()
            waitForUIToSettle()
            capture(name: "\(language.code)-03-outfits")

            app.buttons["tripfit.tab.trips"].tap()
            waitForUIToSettle()
            capture(name: "\(language.code)-04-trips")

            app.buttons["tripfit.tab.home"].tap()
            app.buttons["tripfit.home.settings"].tap()
            let supportRow = app.descendants(matching: .any)["tripfit.more.supportDeveloper"]
            XCTAssertTrue(supportRow.waitForExistence(timeout: 5))
            while !supportRow.isHittable {
                app.swipeUp()
            }
            supportRow.tap()
            waitForUIToSettle()
            capture(name: "\(language.code)-05-support")

            app.terminate()
        }
    }

    private func warmUpApplicationLaunch() {
        let app = XCUIApplication()
        app.launchEnvironment["TRIPFIT_SCREENSHOT_MODE"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["tripfit.tab.home"].waitForExistence(timeout: 10))
        waitForUIToSettle(duration: 1.5)
        app.terminate()
    }

    private func waitForUIToSettle(duration: TimeInterval = 0.7) {
        RunLoop.current.run(until: Date().addingTimeInterval(duration))
    }

    private func capture(name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
