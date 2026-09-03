import SwiftUI

struct CompletionToggle: View {
    let checked: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(checked ? TokyoNightTheme.success : TokyoNightTheme.surfaceElevated)
                    .overlay(
                        Circle()
                            .stroke(
                                checked
                                    ? TokyoNightTheme.success
                                    : (isHovered ? TokyoNightTheme.accent : TokyoNightTheme.textMuted),
                                lineWidth: 1.5
                            )
                    )

                if checked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(TokyoNightTheme.onSuccess)
                }
            }
            .frame(width: 22, height: 22)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(checked ? "标记为未完成" : "标记为已完成")
        .accessibilityLabel(checked ? "标记为未完成" : "标记为已完成")
    }
}
