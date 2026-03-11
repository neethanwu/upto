import AppKit

enum MenuBarIcon {

    static func statusImage(for status: HealthStatus) -> NSImage {
        let color: NSColor = switch status {
        case .operational: .systemGreen
        case .degraded: .systemOrange
        case .majorOutage: .systemRed
        case .unknown: .systemGray
        }
        return triangleImage(color: color)
    }

    private static func triangleImage(color: NSColor) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: true) { rect in
            let path = NSBezierPath()
            // Upward-pointing triangle, centered
            let inset: CGFloat = 2.5
            let bottom = rect.maxY - inset
            let top = rect.minY + inset
            let left = rect.minX + inset
            let right = rect.maxX - inset
            let midX = rect.midX

            path.move(to: NSPoint(x: midX, y: top))
            path.line(to: NSPoint(x: right, y: bottom))
            path.line(to: NSPoint(x: left, y: bottom))
            path.close()

            color.setFill()
            path.fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}
