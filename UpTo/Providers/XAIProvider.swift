import Foundation

struct XAIProvider: StatusProvider {

    func parseStatus(from data: Data, url: URL) throws -> ServiceStatusResult? {
        guard let xml = String(data: data, encoding: .utf8) else { return nil }

        let parser = RSSParser(xml: xml)
        let items = parser.parse()

        // Check for any unresolved incidents
        let activeIncidents = items.filter { !$0.isResolved }

        let overall: HealthStatus
        var components: [ComponentStatus] = []

        if activeIncidents.isEmpty {
            overall = .operational
            components = knownServices.map { ComponentStatus(name: $0, status: .operational) }
        } else {
            // Determine severity from active incidents
            let hasOutage = activeIncidents.contains { $0.severity == "unavailable" || $0.severity == "outage" }
            overall = hasOutage ? .majorOutage : .degraded

            // Build component list from incidents
            var serviceStatuses: [String: HealthStatus] = [:]
            for service in knownServices {
                serviceStatuses[service] = .operational
            }
            for incident in activeIncidents {
                let status: HealthStatus = (incident.severity == "unavailable" || incident.severity == "outage") ? .majorOutage : .degraded
                if let service = matchService(incident.title) {
                    serviceStatuses[service] = max(serviceStatuses[service] ?? .operational, status)
                }
            }
            components = serviceStatuses.sorted { $0.key < $1.key }
                .map { ComponentStatus(name: $0.key, status: $0.value) }
        }

        return ServiceStatusResult(
            serviceName: "xAI",
            overallStatus: overall,
            components: components,
            statusPageURL: "https://status.x.ai"
        )
    }

    private let knownServices = ["Grok (Web)", "Grok in X", "Grok (iOS)", "xAI API"]

    private func matchService(_ title: String) -> String? {
        for service in knownServices {
            if title.localizedCaseInsensitiveContains(service) { return service }
        }
        if title.localizedCaseInsensitiveContains("grok.com") || title.localizedCaseInsensitiveContains("Grok (Web)") {
            return "Grok (Web)"
        }
        if title.localizedCaseInsensitiveContains("iOS") { return "Grok (iOS)" }
        if title.localizedCaseInsensitiveContains("API") || title.localizedCaseInsensitiveContains("console") { return "xAI API" }
        return knownServices.first
    }
}

// MARK: - Simple RSS Parser

private struct RSSItem {
    let title: String
    let categories: [String]
    let severity: String

    var isResolved: Bool {
        categories.contains { $0.lowercased() == "resolved" }
    }
}

private class RSSParser: NSObject, XMLParserDelegate {
    private let xml: String
    private var items: [RSSItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentCategories: [String] = []
    private var insideItem = false

    init(xml: String) {
        self.xml = xml
    }

    func parse() -> [RSSItem] {
        guard let data = xml.data(using: .utf8) else { return [] }
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            insideItem = true
            currentTitle = ""
            currentCategories = []
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        if currentElement == "title" {
            currentTitle += string
        } else if currentElement == "category" {
            currentCategories.append(string.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "item" {
            insideItem = false
            let severity = currentCategories.first { $0 != "resolved" } ?? "unknown"
            items.append(RSSItem(title: currentTitle, categories: currentCategories, severity: severity))
        }
        currentElement = ""
    }
}
