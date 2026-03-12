import AppKit

enum MenuBarIcon {

    static func statusImage(for status: HealthStatus, serverCount: Int = 0) -> NSImage {
        let color: NSColor = switch status {
        case .operational: .systemGreen
        case .degraded: .systemOrange
        case .majorOutage: .systemRed
        case .unknown: .systemGray
        }
        return dualTriangleImage(serviceColor: color, serversActive: serverCount > 0)
    }

    private static func dualTriangleImage(serviceColor: NSColor, serversActive: Bool) -> NSImage {
        let size = NSSize(width: 24, height: 24)
        let image = NSImage(size: size, flipped: true) { rect in
            // Coordinates mapped from the 72-unit logo viewBox to 24px
            let scale = 24.0 / 72.0

            // Up-triangle (service health) — colored
            let upPath = NSBezierPath()
            upPath.move(to: NSPoint(x: 22 * scale, y: 14 * scale))
            upPath.line(to: NSPoint(x: 40 * scale, y: 42 * scale))
            upPath.line(to: NSPoint(x: 4 * scale, y: 42 * scale))
            upPath.close()
            serviceColor.setFill()
            upPath.fill()

            // Down-triangle (servers) — blue when active, very dim when inactive
            let downPath = NSBezierPath()
            downPath.move(to: NSPoint(x: 50 * scale, y: 58 * scale))
            downPath.line(to: NSPoint(x: 32 * scale, y: 30 * scale))
            downPath.line(to: NSPoint(x: 68 * scale, y: 30 * scale))
            downPath.close()

            if serversActive {
                // macOS dark: #0A84FF, light: #007AFF
                let blue = NSColor(red: 0x0A/255, green: 0x84/255, blue: 0xFF/255, alpha: 0.85)
                blue.setFill()
            } else {
                let dim = NSColor.labelColor.withAlphaComponent(0.12)
                dim.setFill()
            }
            downPath.fill()

            return true
        }
        image.isTemplate = false
        return image
    }
}
