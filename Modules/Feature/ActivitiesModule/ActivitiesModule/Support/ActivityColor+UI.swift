import Domain
import UIKit
import DesignTokens

extension ActivityColor {
    var uiColor: UIColor {
        switch self {
        case .red:
            UIColor(hex: 0xE53935)
        case .coral:
            UIColor(hex: 0xFF7F50)
        case .orange:
            UIColor(hex: 0xFB8C00)
        case .amber:
            DesignColor.buttonPrimary
        case .green:
            UIColor(hex: 0x43A047)
        case .teal:
            UIColor(hex: 0x00897B)
        case .lightBlue:
            UIColor(hex: 0x4FC3F7)
        case .blue:
            UIColor(hex: 0x1E88E5)
        case .indigo:
            UIColor(hex: 0x3949AB)
        case .purple:
            UIColor(hex: 0x8E24AA)
        case .lilac:
            UIColor(hex: 0xB39DDB)
        case .pink:
            UIColor(hex: 0xD81B60)
        case .gray:
            UIColor(hex: 0x9E9E9E)
        case .olive:
            UIColor(hex: 0x808000)
        case .brown:
            UIColor(hex: 0x6D4C41)
        }
    }

    var title: String {
        switch self {
        case .red: "Red"
        case .coral: "Coral"
        case .orange: "Orange"
        case .amber: "Amber"
        case .green: "Green"
        case .teal: "Teal"
        case .lightBlue: "Light Blue"
        case .blue: "Blue"
        case .indigo: "Indigo"
        case .purple: "Purple"
        case .lilac: "Lilac"
        case .pink: "Pink"
        case .gray: "Gray"
        case .olive: "Olive"
        case .brown: "Brown"
        }
    }
}
