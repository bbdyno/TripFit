//
//  TFTypography.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import CoreText
import UIKit

public enum TFTypography {
    public static var largeTitle: UIFont { scaledFont(size: 34, weight: .bold, textStyle: .largeTitle) }
    public static var title: UIFont { scaledFont(size: 24, weight: .bold, textStyle: .title2) }
    public static var subtitle: UIFont { scaledFont(size: 20, weight: .semibold, textStyle: .title3) }
    public static var headline: UIFont { scaledFont(size: 17, weight: .semibold, textStyle: .headline) }
    public static var body: UIFont { scaledFont(size: 16, weight: .medium, textStyle: .body) }
    public static var bodyRegular: UIFont { scaledFont(size: 16, weight: .regular, textStyle: .body) }
    public static var caption: UIFont { scaledFont(size: 13, weight: .semibold, textStyle: .caption1) }
    public static var footnote: UIFont { scaledFont(size: 12, weight: .medium, textStyle: .caption2) }
    public static var button: UIFont { scaledFont(size: 17, weight: .bold, textStyle: .headline) }

    private static let baseFontPostScriptName = "PlusJakartaSans-Regular"

    private static func scaledFont(size: CGFloat, weight: UIFont.Weight, textStyle: UIFont.TextStyle) -> UIFont {
        let base = tripFitFont(size: size, weight: weight) ?? UIFont.systemFont(ofSize: size, weight: weight)
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        return metrics.scaledFont(for: base)
    }

    private static func tripFitFont(size: CGFloat, weight: UIFont.Weight) -> UIFont? {
        guard let base = UIFont(name: baseFontPostScriptName, size: size) else {
            return nil
        }

        guard
            let axes = CTFontCopyVariationAxes(base as CTFont) as? [[CFString: Any]],
            let weightAxis = axes.first(where: { axis in
                if let name = axis[kCTFontVariationAxisNameKey] as? String,
                   name.lowercased().contains("weight") {
                    return true
                }
                return false
            }),
            let axisIdentifier = weightAxis[kCTFontVariationAxisIdentifierKey] as? NSNumber,
            let minValue = weightAxis[kCTFontVariationAxisMinimumValueKey] as? NSNumber,
            let maxValue = weightAxis[kCTFontVariationAxisMaximumValueKey] as? NSNumber
        else {
            return base
        }

        let targetValue = mappedAxisValue(
            for: weight,
            axisMin: CGFloat(truncating: minValue),
            axisMax: CGFloat(truncating: maxValue)
        )
        let variations: [NSNumber: CGFloat] = [axisIdentifier: targetValue]
        let descriptor = base.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): variations,
        ])
        return UIFont(descriptor: descriptor, size: size)
    }

    private static func mappedAxisValue(for weight: UIFont.Weight, axisMin: CGFloat, axisMax: CGFloat) -> CGFloat {
        let cssWeight: CGFloat
        switch weight {
        case ..<UIFont.Weight.ultraLight:
            cssWeight = 100
        case UIFont.Weight.ultraLight..<UIFont.Weight.light:
            cssWeight = 250
        case UIFont.Weight.light..<UIFont.Weight.regular:
            cssWeight = 350
        case UIFont.Weight.regular..<UIFont.Weight.medium:
            cssWeight = 400
        case UIFont.Weight.medium..<UIFont.Weight.semibold:
            cssWeight = 500
        case UIFont.Weight.semibold..<UIFont.Weight.bold:
            cssWeight = 600
        case UIFont.Weight.bold..<UIFont.Weight.heavy:
            cssWeight = 700
        case UIFont.Weight.heavy..<UIFont.Weight.black:
            cssWeight = 800
        default:
            cssWeight = 900
        }

        if axisMax - axisMin > 100 {
            return Swift.max(Swift.min(cssWeight, axisMax), axisMin)
        } else {
            let normalized = (cssWeight - 100) / 800
            return axisMin + ((axisMax - axisMin) * normalized)
        }
    }
}
