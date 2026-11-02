import SwiftUI
import AppKit

struct FrostedBackground: NSViewRepresentable {
    var opacity: Double

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        let radius = Theme.radiusL
        let mask = NSImage(size: NSSize(width: radius * 2 + 1, height: radius * 2 + 1), flipped: false) { rect in
            NSColor.white.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        mask.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        view.maskImage = mask
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.alphaValue = opacity
    }
}
