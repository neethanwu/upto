import SwiftUI

struct ServiceRowView: View {
    let service: MonitoredService
    let onDelete: () -> Void
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false
    @State private var isPulsing = false

    private var hoverBgOpacity: Double {
        colorScheme == .dark ? 0.06 : 0.05
    }

    private var statusColor: Color {
        switch service.overallStatus {
        case .operational: .green
        case .degraded: .orange
        case .majorOutage: .red
        case .unknown: .gray
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Pulse status dot
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .scaleEffect(isPulsing ? 1.35 : 1.0)
                .opacity(isPulsing ? 0.7 : 1.0)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: isPulsing
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(service.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(service.overallStatus.label)
                        .font(.system(size: 10))
                        .foregroundStyle(statusColor.opacity(0.8))
                }

                Text(shortURL(service.statusPageURL))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            // Action buttons on hover
            HStack(spacing: 3) {
                RowActionButton(label: "Open", style: .open) {
                    if let url = URL(string: service.statusPageURL) {
                        openURL(url)
                    }
                }

                RowActionButton(label: "Delete", style: .delete) {
                    onDelete()
                }
            }
            .opacity(isHovering ? 1 : 0)
            .animation(.easeOut(duration: 0.15), value: isHovering)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            isHovering ? Color.primary.opacity(hoverBgOpacity) : .clear
        )
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onAppear { isPulsing = true }
    }

    private func shortURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else { return urlString }
        return host
    }
}

// MARK: - Row Action Button

private enum RowActionStyle {
    case open, delete
}

private struct RowActionButton: View {
    let label: String
    let style: RowActionStyle
    let action: () -> Void
    @State private var isHovering = false
    @Environment(\.colorScheme) private var colorScheme

    private var hoverColor: Color {
        switch style {
        case .open:
            return .accentColor
        case .delete:
            return colorScheme == .dark
                ? Color(red: 1, green: 0x45/255, blue: 0x3A/255)
                : Color(red: 1, green: 0x3B/255, blue: 0x30/255)
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(isHovering ? hoverColor : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    isHovering
                        ? hoverColor.opacity(colorScheme == .dark ? 0.1 : 0.06)
                        : .clear,
                    in: RoundedRectangle(cornerRadius: 5)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovering)
    }
}
