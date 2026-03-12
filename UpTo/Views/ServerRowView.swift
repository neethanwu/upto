import SwiftUI

struct ServerRowView: View {
    let server: DevServer
    let onOpen: () -> Void
    let onKill: () -> Void

    @State private var isHovering = false
    @State private var isPulsing = false
    @State private var isKilling = false
    @Environment(\.colorScheme) private var colorScheme

    private var statusGreen: Color {
        colorScheme == .dark
            ? Color(red: 0x30/255, green: 0xD1/255, blue: 0x58/255)
            : Color(red: 0x2D/255, green: 0xB8/255, blue: 0x4D/255)
    }

    private var pulseMinOpacity: Double {
        colorScheme == .dark ? 0.3 : 0.5
    }

    private var hoverBgOpacity: Double {
        colorScheme == .dark ? 0.06 : 0.05
    }

    var body: some View {
        HStack(spacing: 10) {
            // Port column (68pt fixed)
            HStack(spacing: 6) {
                Circle()
                    .fill(statusGreen)
                    .frame(width: 6, height: 6)
                    .opacity(isPulsing ? pulseMinOpacity : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
                    .onAppear { isPulsing = true }

                Text(":\(String(server.port))")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .tracking(-0.3)
            }
            .frame(width: 68, alignment: .leading)

            // Info column
            VStack(alignment: .leading, spacing: 1) {
                Text(server.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let branch = server.gitBranch {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 9, weight: .medium))

                        Text(branch)
                            .font(.system(size: 10, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right column: uptime or actions
            ZStack {
                Text(TimeFormatter.format(server.uptime))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .opacity(isHovering ? 0 : 1)

                HStack(spacing: 3) {
                    ServerActionButton(label: "Kill", style: .kill) {
                        isKilling = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onKill()
                        }
                    }
                    ServerActionButton(label: "Open", style: .open, action: onOpen)
                }
                .opacity(isHovering ? 1 : 0)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(isHovering ? Color.primary.opacity(hoverBgOpacity) : .clear)
        .opacity(isKilling ? 0.3 : 1.0)
        .scaleEffect(isKilling ? 0.98 : 1.0)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .animation(.easeOut(duration: 0.2), value: isKilling)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Server Action Button

private enum ServerActionStyle {
    case kill, open
}

private struct ServerActionButton: View {
    let label: String
    let style: ServerActionStyle
    let action: () -> Void
    @State private var isHovering = false
    @Environment(\.colorScheme) private var colorScheme

    private var hoverColor: Color {
        switch style {
        case .kill:
            return colorScheme == .dark
                ? Color(red: 1, green: 0x45/255, blue: 0x3A/255)
                : Color(red: 1, green: 0x3B/255, blue: 0x30/255)
        case .open:
            return .accentColor
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: style == .open ? .medium : .regular))
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
