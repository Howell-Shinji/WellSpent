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

enum TokyoNightTheme {
    // Tokyo Night / Tokyo Night Light color roles.
    static let background = adaptive(light: 0xE6E7ED, dark: 0x1A1B26)
    static let chrome = adaptive(light: 0xDADCE5, dark: 0x16161E)
    static let surface = adaptive(light: 0xF1F2F6, dark: 0x24283B)
    static let surfaceElevated = adaptive(light: 0xFAFAFC, dark: 0x292E42)
    static let border = adaptive(light: 0xC4C8D8, dark: 0x3B4261)

    static let textPrimary = adaptive(light: 0x343B58, dark: 0xC0CAF5)
    static let textSecondary = adaptive(light: 0x40434F, dark: 0xA9B1D6)
    // Lifted from the original low-contrast comment colors so 12 pt UI copy
    // remains readable against both the canvas and task surfaces.
    static let textMuted = adaptive(light: 0x596078, dark: 0x8992BD)

    static let accent = adaptive(light: 0x2959AA, dark: 0x7AA2F7)
    static let accentSoft = adaptive(light: 0xCBD5EE, dark: 0x3D59A1)
    static let success = adaptive(light: 0x385F0D, dark: 0x9ECE6A)
    static let danger = adaptive(light: 0x8C4351, dark: 0xF7768E)
    static let onAccent = adaptive(light: 0xF7F7FA, dark: 0x1A1B26)
    static let onSuccess = adaptive(light: 0xF7F7FA, dark: 0x1A1B26)

    static let spacingXS: CGFloat = 6
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 20

    static let radiusS: CGFloat = 7
    static let radiusM: CGFloat = 10
    static let radiusL: CGFloat = 14
    static let hairline: CGFloat = 1

    static func title() -> Font {
        .system(size: 21, weight: .semibold, design: .rounded)
    }

    static func body() -> Font {
        .system(size: 16, weight: .regular, design: .default)
    }

    static func bodyStrong() -> Font {
        .system(size: 16, weight: .medium, design: .default)
    }

    static func small() -> Font {
        .system(size: 12.5, weight: .medium, design: .default)
    }

    static func counter() -> Font {
        .system(size: 12, weight: .semibold, design: .monospaced)
    }

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        let dynamicColor = NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [
                .accessibilityHighContrastDarkAqua,
                .darkAqua,
                .accessibilityHighContrastAqua,
                .aqua
            ])
            let usesDarkPalette = match == .darkAqua || match == .accessibilityHighContrastDarkAqua
            return makeNSColor(usesDarkPalette ? dark : light)
        }
        return Color(nsColor: dynamicColor)
    }

    private static func makeNSColor(_ hex: UInt32) -> NSColor {
        NSColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

struct ThemeDivider: View {
    var body: some View {
        Rectangle()
            .fill(TokyoNightTheme.border.opacity(0.72))
            .frame(height: TokyoNightTheme.hairline)
    }
}
