import Foundation

struct AtlassianProvider: StatusProvider {

    func parseStatus(from data: Data, url: URL) throws -> ServiceStatusResult? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let summary = try decoder.decode(AtlassianSummary.self, from: data)

        let overall = mapIndicator(summary.status.indicator)
        let components = summary.components
            .filter { !($0.group ?? false) && !(($0.onlyShowIfDegraded ?? false) && $0.status == "operational") }
            .map { ComponentStatus(name: $0.name, status: mapComponentStatus($0.status)) }

        return ServiceStatusResult(
            serviceName: summary.page.name,
            overallStatus: overall,
            components: components,
            statusPageURL: summary.page.url
        )
    }

    private func mapIndicator(_ indicator: String) -> HealthStatus {
        switch indicator {
        case "none": .operational
        case "minor": .degraded
        case "major", "critical": .majorOutage
        default: .unknown
        }
    }

    private func mapComponentStatus(_ status: String) -> HealthStatus {
        switch status {
        case "operational": .operational
        case "degraded_performance", "partial_outage", "under_maintenance": .degraded
        case "major_outage": .majorOutage
        default: .unknown
        }
    }
}

// MARK: - Atlassian Statuspage JSON Models

private struct AtlassianSummary: Codable {
    let page: PageInfo
    let status: OverallStatus
    let components: [AtlassianComponent]

    struct PageInfo: Codable {
        let name: String
        let url: String
    }

    struct OverallStatus: Codable {
        let indicator: String
        let description: String
    }

    struct AtlassianComponent: Codable {
        let id: String
        let name: String
        let status: String
        let position: Int?
        let groupId: String?
        let group: Bool?
        let onlyShowIfDegraded: Bool?
    }
}
