import SwiftUI

struct ServiceRowView: View {
    let service: MonitoredService
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let url = URL(string: service.statusPageURL) {
                openURL(url)
            }
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(service.name)
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Text(service.overallStatus.label)
                            .font(.caption)
                            .foregroundStyle(statusColor)

                        if let lastChecked = service.lastChecked {
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(lastChecked, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        switch service.overallStatus {
        case .operational: .green
        case .degraded: .orange
        case .majorOutage: .red
        case .unknown: .gray
        }
    }
}
