import SwiftUI

struct AddServiceView: View {
    var monitor: StatusMonitor
    @Binding var isShowing: Bool
    @State private var urlText = ""
    @State private var isAdding = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Status page URL", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption))
                    .onSubmit { addService() }

                Button {
                    addService()
                } label: {
                    if isAdding {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Add")
                            .font(.caption)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAdding)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }

    private func addService() {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var urlString = trimmed
        if !urlString.hasPrefix("http") {
            urlString = "https://\(urlString)"
        }
        guard URL(string: urlString) != nil else {
            errorMessage = "Invalid URL"
            return
        }

        // Check for duplicates
        if monitor.services.contains(where: { $0.url == urlString || $0.statusPageURL == urlString }) {
            errorMessage = "Already monitoring this service"
            return
        }

        isAdding = true
        errorMessage = nil

        // Detect provider type by trying known patterns
        Task {
            let service = await detectAndCreateService(urlString)
            await MainActor.run {
                monitor.addService(service)
                isAdding = false
                urlText = ""
                withAnimation { isShowing = false }
            }
        }
    }

    private func detectAndCreateService(_ urlString: String) async -> MonitoredService {
        // Try Atlassian Statuspage first
        let atlassianURL = urlString.hasSuffix("/")
            ? "\(urlString)api/v2/summary.json"
            : "\(urlString)/api/v2/summary.json"

        if let url = URL(string: atlassianURL),
           let (data, response) = try? await URLSession.shared.data(from: url),
           let http = response as? HTTPURLResponse,
           (200...299).contains(http.statusCode),
           let result = try? AtlassianProvider().parseStatus(from: data, url: url) {
            return MonitoredService(
                name: result.serviceName,
                url: urlString,
                dataURL: atlassianURL,
                providerType: .atlassian,
                statusPageURL: result.statusPageURL
            )
        }

        // Try RSS feed
        let rssURL = urlString.hasSuffix("/")
            ? "\(urlString)feed.xml"
            : "\(urlString)/feed.xml"

        if let url = URL(string: rssURL),
           let (data, _) = try? await URLSession.shared.data(from: url),
           String(data: data, encoding: .utf8)?.contains("<rss") == true {
            return MonitoredService(
                name: "Custom",
                url: urlString,
                dataURL: rssURL,
                providerType: .xaiRSS,
                statusPageURL: urlString
            )
        }

        // Fallback: treat as-is
        return MonitoredService(
            name: "Custom",
            url: urlString,
            dataURL: urlString,
            providerType: .htmlFallback,
            statusPageURL: urlString
        )
    }
}
