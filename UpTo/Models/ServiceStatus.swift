import Foundation

enum HealthStatus: String, Codable, Comparable {
    case operational
    case degraded
    case majorOutage
    case unknown

    static func < (lhs: HealthStatus, rhs: HealthStatus) -> Bool {
        let order: [HealthStatus] = [.operational, .unknown, .degraded, .majorOutage]
        let lhsIndex = order.firstIndex(of: lhs) ?? 0
        let rhsIndex = order.firstIndex(of: rhs) ?? 0
        return lhsIndex < rhsIndex
    }

    var label: String {
        switch self {
        case .operational: "Operational"
        case .degraded: "Degraded"
        case .majorOutage: "Major Outage"
        case .unknown: "Unknown"
        }
    }
}

struct ComponentStatus: Codable, Identifiable {
    var id = UUID()
    let name: String
    let status: HealthStatus
}

struct MonitoredService: Codable, Identifiable {
    var id = UUID()
    var name: String
    var url: String
    var dataURL: String
    var providerType: ProviderType
    var overallStatus: HealthStatus = .unknown
    var components: [ComponentStatus] = []
    var lastChecked: Date?
    var statusPageURL: String

    enum ProviderType: String, Codable {
        case atlassian
        case googleCloud
        case xaiRSS
        case htmlFallback
    }
}

struct ServiceStatusResult {
    let serviceName: String
    let overallStatus: HealthStatus
    let components: [ComponentStatus]
    let statusPageURL: String
}
