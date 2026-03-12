import SwiftUI

enum PopoverTab: String, CaseIterable {
    case services = "Services"
    case servers = "Servers"
}

struct StatusPopoverView: View {
    @Bindable var monitor: StatusMonitor
    var serverMonitor: ServerMonitor
    @State private var showingAddForm = false
    @State private var refreshAngle: Double = 0
    @State private var selectedTab: PopoverTab = .services

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            tabBar
            Divider().opacity(0.04).padding(.horizontal, 14)

            switch selectedTab {
            case .services:
                serviceContent
            case .servers:
                ServerListView(monitor: serverMonitor)
            }

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
                    .frame(width: 24, height: 18)
                Text("upto")
                    .font(.system(size: 14, weight: .bold))
            }

            Spacer()

            HStack(spacing: 4) {
                if selectedTab == .services, let lastChecked = monitor.lastRefreshTime {
                    Text(relativeTime(lastChecked))
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                HeaderButton {
                    withAnimation(.linear(duration: 0.5)) {
                        refreshAngle += 360
                    }
                    if selectedTab == .services {
                        monitor.refresh()
                    } else {
                        Task { await serverMonitor.refresh() }
                    }
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

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(PopoverTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        HStack(spacing: 5) {
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundStyle(selectedTab == tab ? .primary : .tertiary)

                            if tab == .servers, serverMonitor.servers.count > 0 {
                                Text("\(serverMonitor.servers.count)")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .frame(width: 16, height: 16)
                                    .background(
                                        Circle().fill(Color(red: 0x0A/255, green: 0x84/255, blue: 0xFF/255))
                                    )
                            }
                        }

                        Rectangle()
                            .fill(selectedTab == tab ? Color.primary : .clear)
                            .frame(height: 1.5)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 4)
    }

    // MARK: - Service Content

    @ViewBuilder
    private var serviceContent: some View {
        if monitor.services.isEmpty {
            emptyState(title: "No services", subtitle: "Add a status page to monitor")
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

    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Footer (adapts per tab)

    private var footer: some View {
        ZStack {
            if selectedTab == .services {
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
            } else {
                // Server count
                HStack(spacing: 5) {
                    Text(serverCountText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .frame(height: 32)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .animation(.easeOut(duration: 0.2), value: showingAddForm)
    }

    private var serverCountText: String {
        let count = serverMonitor.servers.count
        switch count {
        case 0: return "No servers"
        case 1: return "1 server"
        default: return "\(count) servers"
        }
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
            // Map 72-unit viewBox to actual size
            let s = min(size.width, size.height)
            let scale = s / 72.0
            let primaryColor = colorScheme == .dark
                ? Color(red: 0xF5/255, green: 0xF5/255, blue: 0xF7/255)
                : Color(red: 0x1D/255, green: 0x1D/255, blue: 0x1F/255)

            // Up triangle (left) — full opacity
            let upPath = Path { p in
                p.move(to: CGPoint(x: 22 * scale, y: 14 * scale))
                p.addLine(to: CGPoint(x: 40 * scale, y: 42 * scale))
                p.addLine(to: CGPoint(x: 4 * scale, y: 42 * scale))
                p.closeSubpath()
            }
            context.fill(upPath, with: .color(primaryColor))

            // Down triangle (right) — muted
            let downPath = Path { p in
                p.move(to: CGPoint(x: 50 * scale, y: 58 * scale))
                p.addLine(to: CGPoint(x: 32 * scale, y: 30 * scale))
                p.addLine(to: CGPoint(x: 68 * scale, y: 30 * scale))
                p.closeSubpath()
            }
            context.fill(downPath, with: .color(primaryColor.opacity(0.25)))
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
