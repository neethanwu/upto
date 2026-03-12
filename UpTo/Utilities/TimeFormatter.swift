import Foundation

enum TimeFormatter {
    /// Formats a TimeInterval into a human-readable uptime string.
    /// Examples: "<1m", "2m", "1h 3m", "2d 1h"
    static func format(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)

        guard totalSeconds >= 60 else {
            return "<1m"
        }

        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days > 0 {
            return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
        }
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}
