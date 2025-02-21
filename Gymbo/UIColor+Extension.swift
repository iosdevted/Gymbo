//
//  UIColor+Extension.swift
//  Gymbo
//
//  Created by Rohan Sharma on 7/14/20.
//  Copyright © 2020 Rohan Sharma. All rights reserved.
//

import UIKit

// MARK: - Init
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0,
                  green: CGFloat(green) / 255.0,
                  blue: CGFloat(blue) / 255.0,
                  alpha: 1.0)
    }

    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

// MARK: - Custom Colors
extension UIColor {
    // Special
    static let defaultSelectedBorder = UIColor.systemGreen
    static let defaultUnselectedBorder = UIColor.primaryText
    static let disabledBlack = UIColor.black.withAlphaComponent(0.5)
    static let selectedBackground = UIColor(named: "selectedBackground") ?? .systemGray

    // Primary
    static let primaryBackground = UIColor(named: "primaryBackground") ?? .systemBackground
    static let primaryText = UIColor(named: "primaryText") ?? .label

    // Secondary
    static let secondaryBackground = UIColor(named: "secondaryBackground") ?? .secondarySystemBackground
    static let secondaryText = UIColor(named: "secondaryText") ?? .secondaryLabel

    // Tertiary
    static let tertiaryText = UIColor(named: "tertiaryText") ?? .tertiaryLabel

    // Normal
    static let customBlue = UIColor(rgb: 0x1565C0)
    static let customOrange = UIColor(rgb: 0xFF7400)

    // Light
    static let customLightBlue = UIColor(rgb: 0x34AADC)
    static let customLightGray = UIColor(rgb: 0xBDC3C7)

    // Medium
    // Dark
}
