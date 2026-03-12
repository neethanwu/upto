import Foundation
import Combine
import UserNotifications

@Observable
class StatusMonitor {
    var services: [MonitoredService] = []
    var overallStatus: HealthStatus = .unknown
    var isRefreshing = false
    var lastRefreshTime: Date?

    private var cancellable: AnyCancellable?
    private var previousStatuses: [UUID: HealthStatus] = [:]

    private let atlassianProvider = AtlassianProvider()
    private let xaiProvider = XAIProvider()
    private let googleProvider = GoogleCloudProvider()
    private var notificationsAvailable = false

    init() {
        loadServices()
        if services.isEmpty {
            services = Self.defaultServices
            saveServices()
        }
        requestNotificationPermission()
        startPolling()
        refresh()
    }

    // MARK: - Polling

    func startPolling() {
        cancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true

        Task {
            await withTaskGroup(of: (UUID, ServiceStatusResult?).self) { group in
                for service in services {
                    group.addTask { [weak self] in
                        guard let self else { return (service.id, nil) }
                        let result = await self.fetchStatus(for: service)
                        return (service.id, result)
                    }
                }

                for await (id, result) in group {
                    await MainActor.run {
                        guard let index = self.services.firstIndex(where: { $0.id == id }) else { return }
                        let oldStatus = self.services[index].overallStatus
                        if let result {
                            self.services[index].overallStatus = result.overallStatus
                            self.services[index].components = result.components
                        } else {
                            // Keep previous status if fetch failed, but mark unknown if first check
                            if self.services[index].lastChecked == nil {
                                self.services[index].overallStatus = .unknown
                            }
                        }
                        self.services[index].lastChecked = Date()

                        // Notify on state transition
                        let newStatus = self.services[index].overallStatus
                        if oldStatus != newStatus && self.previousStatuses[id] != nil {
                            self.sendNotification(
                                serviceName: self.services[index].name,
                                from: oldStatus,
                                to: newStatus
                            )
                        }
                        self.previousStatuses[id] = newStatus
                    }
                }
            }

            await MainActor.run {
                self.updateOverallStatus()
                self.isRefreshing = false
                self.lastRefreshTime = Date()
                self.saveServices()
            }
        }
    }

    private func fetchStatus(for service: MonitoredService) async -> ServiceStatusResult? {
        guard let url = URL(string: service.dataURL) else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            request.setValue("upto/1.0 (macOS)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }

            let provider: StatusProvider = switch service.providerType {
            case .atlassian: atlassianProvider
            case .xaiRSS: xaiProvider
            case .googleCloud: googleProvider
            case .htmlFallback: atlassianProvider // TODO: HTML fallback
            }

            return try provider.parseStatus(from: data, url: url)
        } catch {
            return nil
        }
    }

    private func updateOverallStatus() {
        if services.isEmpty {
            overallStatus = .unknown
            return
        }
        overallStatus = services.map(\.overallStatus).max() ?? .unknown
    }

    // MARK: - Service Management

    func addService(_ service: MonitoredService) {
        services.append(service)
        saveServices()
        Task { await refreshSingle(service.id) }
    }

    func removeService(at offsets: IndexSet) {
        let ids = offsets.map { services[$0].id }
        services.remove(atOffsets: offsets)
        for id in ids { previousStatuses.removeValue(forKey: id) }
        updateOverallStatus()
        saveServices()
    }

    private func refreshSingle(_ id: UUID) async {
        guard let index = services.firstIndex(where: { $0.id == id }) else { return }
        let result = await fetchStatus(for: services[index])
        await MainActor.run {
            guard let index = self.services.firstIndex(where: { $0.id == id }) else { return }
            if let result {
                self.services[index].overallStatus = result.overallStatus
                self.services[index].components = result.components
                if self.services[index].name.isEmpty || self.services[index].name == "Custom" {
                    self.services[index].name = result.serviceName
                }
            }
            self.services[index].lastChecked = Date()
            self.previousStatuses[id] = self.services[index].overallStatus
            self.updateOverallStatus()
            self.saveServices()
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { [weak self] granted, _ in
            self?.notificationsAvailable = granted
        }
    }

    private func sendNotification(serviceName: String, from oldStatus: HealthStatus, to newStatus: HealthStatus) {
        guard notificationsAvailable else { return }
        let content = UNMutableNotificationContent()
        if newStatus == .operational {
            content.title = "\(serviceName)"
            content.body = "Back to operational"
        } else {
            content.title = "\(serviceName)"
            content.body = newStatus.label
        }
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Persistence

    private func saveServices() {
        if let data = try? JSONEncoder().encode(services) {
            UserDefaults.standard.set(data, forKey: "monitoredServices")
        }
    }

    private func loadServices() {
        guard let data = UserDefaults.standard.data(forKey: "monitoredServices"),
              let decoded = try? JSONDecoder().decode([MonitoredService].self, from: data)
        else { return }
        services = decoded
        for service in services {
            previousStatuses[service.id] = service.overallStatus
        }
    }

    // MARK: - Defaults

    static let defaultServices: [MonitoredService] = [
        MonitoredService(
            name: "Claude",
            url: "https://status.claude.com",
            dataURL: "https://status.claude.com/api/v2/summary.json",
            providerType: .atlassian,
            statusPageURL: "https://status.claude.com"
        ),
        MonitoredService(
            name: "OpenAI",
            url: "https://status.openai.com",
            dataURL: "https://status.openai.com/api/v2/summary.json",
            providerType: .atlassian,
            statusPageURL: "https://status.openai.com"
        ),
        MonitoredService(
            name: "xAI",
            url: "https://status.x.ai",
            dataURL: "https://status.x.ai/feed.xml",
            providerType: .xaiRSS,
            statusPageURL: "https://status.x.ai"
        ),
        MonitoredService(
            name: "Gemini",
            url: "https://status.cloud.google.com",
            dataURL: "https://status.cloud.google.com/incidents.json",
            providerType: .googleCloud,
            statusPageURL: "https://status.cloud.google.com"
        ),
    ]
}
