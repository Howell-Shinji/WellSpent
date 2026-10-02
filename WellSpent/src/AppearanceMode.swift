import SwiftUI
import AppKit

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    var systemImage: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light:
            let name: NSAppearance.Name = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
                ? .accessibilityHighContrastAqua
                : .aqua
            return NSAppearance(named: name)
        case .dark:
            let name: NSAppearance.Name = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
                ? .accessibilityHighContrastDarkAqua
                : .darkAqua
            return NSAppearance(named: name)
        }
    }
}
