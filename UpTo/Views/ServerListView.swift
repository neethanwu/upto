import SwiftUI

struct ServerListView: View {
    var monitor: ServerMonitor

    var body: some View {
        if monitor.servers.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(monitor.servers) { server in
                        ServerRowView(
                            server: server,
                            onOpen: { monitor.openInBrowser(server: server) },
                            onKill: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    monitor.kill(server: server)
                                }
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 380)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("No servers running")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Start a dev server to see it here")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
