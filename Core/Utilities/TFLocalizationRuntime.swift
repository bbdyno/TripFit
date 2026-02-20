//
//  TFLocalizationRuntime.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Foundation
import ObjectiveC.runtime
import UIKit

public enum TFLocalizationRuntime {
    private static let englishTable: [String: String] = {
        guard
            let path = Bundle.module.path(forResource: "en", ofType: "lproj"),
            let bundle = Bundle(path: path),
            let url = bundle.url(forResource: "Localizable", withExtension: "strings"),
            let dict = NSDictionary(contentsOf: url) as? [String: String]
        else {
            return [:]
        }

        var mapped: [String: String] = [:]
        for (key, value) in dict {
            mapped[value] = key
        }
        return mapped
    }()

    public static func enable() {
        _ = swizzleOnce
    }

    public static func localized(_ text: String?) -> String? {
        guard let text else { return nil }
        guard text.isEmpty == false else { return text }

        let leading = String(text.prefix { $0 == " " })
        let trailing = String(text.reversed().prefix { $0 == " " }.reversed())
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false else { return text }

        if let dynamic = localizeDynamic(trimmed) {
            return "\(leading)\(dynamic)\(trailing)"
        }

        if let key = englishTable[trimmed] {
            let localized = localizedString(forKey: key)
            return "\(leading)\(localized)\(trailing)"
        }

        return text
    }

    private static let swizzleOnce: Void = {
        swizzle(
            UILabel.self,
            original: #selector(setter: UILabel.text),
            swizzled: #selector(UILabel.tf_setText(_:))
        )
        swizzle(
            UIButton.self,
            original: #selector(UIButton.setTitle(_:for:)),
            swizzled: #selector(UIButton.tf_setTitle(_:for:))
        )
        swizzle(
            UITextField.self,
            original: #selector(setter: UITextField.placeholder),
            swizzled: #selector(UITextField.tf_setPlaceholder(_:))
        )
        swizzle(
            UISearchBar.self,
            original: #selector(setter: UISearchBar.placeholder),
            swizzled: #selector(UISearchBar.tf_setPlaceholder(_:))
        )
        swizzle(
            UISearchBar.self,
            original: #selector(setter: UISearchBar.prompt),
            swizzled: #selector(UISearchBar.tf_setPrompt(_:))
        )
        swizzle(
            UIViewController.self,
            original: #selector(setter: UIViewController.title),
            swizzled: #selector(UIViewController.tf_setTitle(_:))
        )
        swizzle(
            UINavigationItem.self,
            original: #selector(setter: UINavigationItem.title),
            swizzled: #selector(UINavigationItem.tf_setTitle(_:))
        )
        swizzle(
            UIBarButtonItem.self,
            original: #selector(setter: UIBarButtonItem.title),
            swizzled: #selector(UIBarButtonItem.tf_setTitle(_:))
        )
        swizzle(
            UITabBarItem.self,
            original: #selector(setter: UITabBarItem.title),
            swizzled: #selector(UITabBarItem.tf_setTitle(_:))
        )
    }()

    private static func swizzle(_ cls: AnyClass, original: Selector, swizzled: Selector) {
        guard
            let originalMethod = class_getInstanceMethod(cls, original),
            let swizzledMethod = class_getInstanceMethod(cls, swizzled)
        else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    private static func localizeDynamic(_ text: String) -> String? {
        if let number = parseInt(text, prefix: "Add selected (", suffix: ")") {
            return CoreStrings.Format.addSelected(number)
        }
        if let number = parseInt(text, suffix: " items") {
            return CoreStrings.Format.itemsCount(number)
        }
        if let number = parseInt(text, suffix: " days") {
            return CoreStrings.Format.daysCount(number)
        }
        if let number = parseInt(text, suffix: " Days") {
            return CoreStrings.Format.daysCount(number)
        }
        if let suffix = parseSuffix(text, prefix: "Updated ") {
            return CoreStrings.Format.updated(suffix)
        }
        if let suffix = parseSuffix(text, prefix: "Packed: ") {
            return CoreStrings.Format.packed(suffix)
        }
        if let suffix = parseSuffix(text, prefix: "Country Filter: ") {
            return CoreStrings.Format.countryFilterPrompt(suffix)
        }
        if let suffix = parseSuffix(text, prefix: "Voltage: ") {
            return CoreStrings.Format.voltage(suffix)
        }
        if let suffix = parseSuffix(text, prefix: "Frequency: ") {
            return CoreStrings.Format.frequency(suffix)
        }
        if let suffix = parseSuffix(text, prefix: "Plug Types: ") {
            return CoreStrings.Format.plugTypes(suffix)
        }
        if let number = parseInt(text, prefix: "Added ", suffix: " items") {
            return CoreStrings.Format.addedItems(number)
        }
        if let suffix = parseInner(text, prefix: "Added to ", suffix: ".") {
            return CoreStrings.Format.addedToTrip(suffix)
        }
        if let suffix = parseInner(text, prefix: "This item is already in ", suffix: ".") {
            return CoreStrings.Format.alreadyInTrip(suffix)
        }
        return nil
    }

    private static func parseInt(_ text: String, prefix: String? = nil, suffix: String? = nil) -> Int? {
        var value = text
        if let prefix {
            guard value.hasPrefix(prefix) else { return nil }
            value.removeFirst(prefix.count)
        }
        if let suffix {
            guard value.hasSuffix(suffix) else { return nil }
            value.removeLast(suffix.count)
        }
        return Int(value)
    }

    private static func parseSuffix(_ text: String, prefix: String) -> String? {
        guard text.hasPrefix(prefix) else { return nil }
        return String(text.dropFirst(prefix.count))
    }

    private static func parseInner(_ text: String, prefix: String, suffix: String) -> String? {
        guard text.hasPrefix(prefix), text.hasSuffix(suffix) else { return nil }
        let start = text.index(text.startIndex, offsetBy: prefix.count)
        let end = text.index(text.endIndex, offsetBy: -suffix.count)
        guard start <= end else { return nil }
        return String(text[start..<end])
    }

    private static func localizedString(forKey key: String) -> String {
        guard let languageBundle = currentLanguageBundle() else { return key }
        let value = languageBundle.localizedString(forKey: key, value: key, table: "Localizable")
        return value
    }

    private static func currentLanguageBundle() -> Bundle? {
        let language = TFAppLanguage.current().rawValue
        guard let path = Bundle.module.path(forResource: language, ofType: "lproj") else {
            return Bundle.module
        }
        return Bundle(path: path)
    }
}

private extension UILabel {
    @objc func tf_setText(_ text: String?) {
        tf_setText(TFLocalizationRuntime.localized(text))
    }
}

private extension UIButton {
    @objc func tf_setTitle(_ title: String?, for state: UIControl.State) {
        tf_setTitle(TFLocalizationRuntime.localized(title), for: state)
    }
}

private extension UITextField {
    @objc func tf_setPlaceholder(_ placeholder: String?) {
        tf_setPlaceholder(TFLocalizationRuntime.localized(placeholder))
    }
}

private extension UISearchBar {
    @objc func tf_setPlaceholder(_ placeholder: String?) {
        tf_setPlaceholder(TFLocalizationRuntime.localized(placeholder))
    }

    @objc func tf_setPrompt(_ prompt: String?) {
        tf_setPrompt(TFLocalizationRuntime.localized(prompt))
    }
}

private extension UIViewController {
    @objc func tf_setTitle(_ title: String?) {
        tf_setTitle(TFLocalizationRuntime.localized(title))
    }
}

private extension UINavigationItem {
    @objc func tf_setTitle(_ title: String?) {
        tf_setTitle(TFLocalizationRuntime.localized(title))
    }
}

private extension UIBarButtonItem {
    @objc func tf_setTitle(_ title: String?) {
        tf_setTitle(TFLocalizationRuntime.localized(title))
    }
}

private extension UITabBarItem {
    @objc func tf_setTitle(_ title: String?) {
        tf_setTitle(TFLocalizationRuntime.localized(title))
    }
}
