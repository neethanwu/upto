import SwiftUI

struct StatusPopoverView: View {
    @Bindable var monitor: StatusMonitor
    @State private var showingAddForm = false
    @State private var refreshAngle: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.04).padding(.horizontal, 14)
            serviceContent
            Divider().opacity(0.04).padding(.horizontal, 14)
            footer
        }
        .frame(width: 320)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 5) {
                LogoMark()
                    .frame(width: 10, height: 10)
                Text("upto")
                    .font(.system(size: 14, weight: .bold))
            }

            Spacer()

            HStack(spacing: 4) {
                if let lastChecked = monitor.lastRefreshTime {
                    Text(relativeTime(lastChecked))
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                HeaderButton {
                    withAnimation(.linear(duration: 0.5)) {
                        refreshAngle += 360
                    }
                    monitor.refresh()
                } label: {
                    RefreshIcon()
                        .frame(width: 13, height: 13)
                        .rotationEffect(.degrees(refreshAngle))
                }

                HeaderButton {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Service Content

    @ViewBuilder
    private var serviceContent: some View {
        if monitor.services.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(monitor.services.enumerated()), id: \.element.id) { index, service in
                        ServiceRowView(service: service) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                monitor.removeService(at: IndexSet(integer: index))
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 380)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("No services")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Add a status page to monitor")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Footer (fixed height, fade transition)

    private var footer: some View {
        ZStack {
            // Add Service button
            HStack(spacing: 5) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("Add Service")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
            }
            .foregroundStyle(.secondary)
            .opacity(showingAddForm ? 0 : 1)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.2)) {
                    showingAddForm = true
                }
            }

            // Add form
            AddServiceView(monitor: monitor, isShowing: $showingAddForm)
                .opacity(showingAddForm ? 1 : 0)
                .allowsHitTesting(showingAddForm)
        }
        .frame(height: 32)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .animation(.easeOut(duration: 0.2), value: showingAddForm)
    }

    private func relativeTime(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "<1m ago" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }
}

// MARK: - Header Button

struct HeaderButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: Label
    @State private var isHovering = false
    @Environment(\.colorScheme) private var colorScheme

    private var hoverOpacity: Double {
        colorScheme == .dark ? 0.06 : 0.05
    }

    var body: some View {
        Button(action: action) {
            label
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(
                    isHovering ? Color.primary.opacity(hoverOpacity) : .clear,
                    in: RoundedRectangle(cornerRadius: 6)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovering)
    }
}

// MARK: - Logo Mark (Triangle)

struct LogoMark: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            let path = Path { p in
                p.move(to: CGPoint(x: size.width / 2, y: 0))
                p.addLine(to: CGPoint(x: size.width, y: size.height))
                p.addLine(to: CGPoint(x: 0, y: size.height))
                p.closeSubpath()
            }
            context.fill(path, with: .color(.primary.opacity(colorScheme == .dark ? 0.85 : 0.8)))
        }
    }
}

// MARK: - Refresh Icon (Pier-style)

struct RefreshIcon: View {
    @Environment(\.colorScheme) private var colorScheme

    private var iconColor: Color {
        colorScheme == .dark
            ? Color(red: 0x98/255, green: 0x98/255, blue: 0x9D/255)
            : Color(red: 0x86/255, green: 0x86/255, blue: 0x8B/255)
    }

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 16, size.height / 16)
            context.scaleBy(x: scale, y: scale)

            let shading = GraphicsContext.Shading.color(iconColor)
            let stroke = StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)

            context.stroke(
                Path { p in
                    p.addArc(center: CGPoint(x: 8, y: 8), radius: 6,
                             startAngle: .degrees(180), endAngle: .degrees(316),
                             clockwise: false)
                }, with: shading, style: stroke)

            context.stroke(
                Path { p in
                    p.addArc(center: CGPoint(x: 8, y: 8), radius: 6,
                             startAngle: .degrees(0), endAngle: .degrees(136),
                             clockwise: false)
                }, with: shading, style: stroke)

            context.stroke(
                Path { p in
                    p.move(to: CGPoint(x: 12, y: 2))
                    p.addLine(to: CGPoint(x: 13, y: 4))
                    p.addLine(to: CGPoint(x: 11, y: 4.5))
                }, with: shading, style: stroke)

            context.stroke(
                Path { p in
                    p.move(to: CGPoint(x: 4, y: 14))
                    p.addLine(to: CGPoint(x: 3, y: 12))
                    p.addLine(to: CGPoint(x: 5, y: 11.5))
                }, with: shading, style: stroke)
        }
    }
}
