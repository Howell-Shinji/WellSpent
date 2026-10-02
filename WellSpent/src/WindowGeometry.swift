import AppKit

enum WindowGeometry {
    static func fitted(_ proposed: NSRect, screens: [NSRect]) -> NSRect {
        guard !screens.isEmpty else { return proposed }
        let visible = screens.max { a, b in
            area(proposed.intersection(a)) < area(proposed.intersection(b))
        }!
        let hasIntersection = screens.contains { area(proposed.intersection($0)) > 0 }
        let target = hasIntersection ? visible : screens[0]
        let width = min(max(proposed.width, 320), target.width)
        let height = min(max(proposed.height, 460), target.height)
        let x = hasIntersection ? proposed.minX : target.maxX - width - 40
        let y = hasIntersection ? proposed.minY : target.maxY - height - 40
        return NSRect(x: min(max(x, target.minX), target.maxX - width),
                      y: min(max(y, target.minY), target.maxY - height),
                      width: width, height: height)
    }

    static func isValid(_ frame: NSRect) -> Bool {
        [frame.origin.x, frame.origin.y, frame.width, frame.height].allSatisfy(\.isFinite)
            && frame.width > 0 && frame.height > 0
    }

    private static func area(_ rect: NSRect) -> CGFloat {
        rect.isNull ? 0 : max(0, rect.width) * max(0, rect.height)
    }
}
