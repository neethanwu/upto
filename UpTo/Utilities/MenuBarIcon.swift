import AppKit

enum MenuBarIcon {

    static func statusImage(for status: HealthStatus) -> NSImage {
        let color: NSColor = switch status {
        case .operational: .systemGreen
        case .degraded: .systemOrange
        case .majorOutage: .systemRed
        case .unknown: .systemGray
        }
        return dotImage(color: color)
    }

    private static func dotImage(color: NSColor) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            color.setFill()
            let dotRect = NSRect(x: 4, y: 4, width: 10, height: 10)
            NSBezierPath(ovalIn: dotRect).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}
