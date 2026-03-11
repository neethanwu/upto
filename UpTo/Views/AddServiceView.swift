import SwiftUI

struct AddServiceView: View {
    var monitor: StatusMonitor
    @Binding var isShowing: Bool
    @State private var urlText = ""
    @State private var isAdding = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme

    private var hasInput: Bool {
        !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField("Status page URL or RSS feed...", text: $urlText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.04))
                    )
                    .onSubmit { addService() }

                if isAdding {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 16, height: 16)
                } else {
                    // Confirm
                    IconButton(systemName: "checkmark", color: hasInput ? .green : .secondary) {
                        addService()
                    }
                    .disabled(!hasInput)
                    .opacity(hasInput ? 1 : 0.15)

                    // Dismiss
                    IconButton(systemName: "xmark", color: .secondary) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isShowing = false
                        }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
            }
        }
        .padding(.bottom, 0)
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

        if monitor.services.contains(where: { $0.url == urlString || $0.statusPageURL == urlString }) {
            errorMessage = "Already monitoring this service"
            return
        }

        isAdding = true
        errorMessage = nil

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
        let base = urlString.hasSuffix("/") ? urlString : "\(urlString)/"

        if let url = URL(string: "\(base)api/v2/summary.json"),
           let (data, response) = try? await URLSession.shared.data(from: url),
           let http = response as? HTTPURLResponse,
           (200...299).contains(http.statusCode),
           let result = try? AtlassianProvider().parseStatus(from: data, url: url) {
            return MonitoredService(
                name: result.serviceName,
                url: urlString,
                dataURL: "\(base)api/v2/summary.json",
                providerType: .atlassian,
                statusPageURL: result.statusPageURL
            )
        }

        if let url = URL(string: "\(base)feed.xml"),
           let (data, _) = try? await URLSession.shared.data(from: url),
           String(data: data, encoding: .utf8)?.contains("<rss") == true {
            return MonitoredService(
                name: "Custom",
                url: urlString,
                dataURL: "\(base)feed.xml",
                providerType: .xaiRSS,
                statusPageURL: urlString
            )
        }

        return MonitoredService(
            name: "Custom",
            url: urlString,
            dataURL: urlString,
            providerType: .htmlFallback,
            statusPageURL: urlString
        )
    }
}

// MARK: - Small icon button for add service actions

private struct IconButton: View {
    let systemName: String
    let color: Color
    let action: () -> Void
    @State private var isHovering = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 26, height: 26)
                .background(
                    isHovering
                        ? Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.06)
                        : .clear,
                    in: RoundedRectangle(cornerRadius: 6)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovering)
    }
}
