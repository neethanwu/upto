import Foundation

struct GoogleCloudProvider: StatusProvider {

    func parseStatus(from data: Data, url: URL) throws -> ServiceStatusResult? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let incidents = try decoder.decode([GoogleIncident].self, from: data)

        // Filter for active incidents affecting Gemini/Vertex AI
        let geminiKeywords = ["gemini", "vertex", "ai studio", "generative ai", "generative language"]
        let activeIncidents = incidents.filter { incident in
            guard incident.end == nil else { return false }
            return incident.affectedProducts.contains { product in
                geminiKeywords.contains { keyword in
                    product.title.localizedCaseInsensitiveContains(keyword)
                }
            }
        }

        let overall: HealthStatus
        var components: [ComponentStatus] = []

        if activeIncidents.isEmpty {
            overall = .operational
            components = [ComponentStatus(name: "Gemini API", status: .operational)]
        } else {
            let hasOutage = activeIncidents.contains { $0.statusImpact == "SERVICE_OUTAGE" }
            overall = hasOutage ? .majorOutage : .degraded

            // Build components from affected products
            var seen = Set<String>()
            for incident in activeIncidents {
                let status: HealthStatus = incident.statusImpact == "SERVICE_OUTAGE" ? .majorOutage : .degraded
                for product in incident.affectedProducts {
                    if seen.insert(product.title).inserted {
                        components.append(ComponentStatus(name: product.title, status: status))
                    }
                }
            }
        }

        return ServiceStatusResult(
            serviceName: "Gemini",
            overallStatus: overall,
            components: components,
            statusPageURL: "https://status.cloud.google.com"
        )
    }
}

// MARK: - Google Cloud JSON Models

private struct GoogleIncident: Codable {
    let id: String
    let begin: String
    let end: String?
    let externalDesc: String
    let severity: String
    let statusImpact: String
    let affectedProducts: [AffectedProduct]

    struct AffectedProduct: Codable {
        let title: String
        let id: String
    }
}
