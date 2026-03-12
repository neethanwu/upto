import AppKit
import Combine
import Foundation
import Observation

@MainActor
@Observable
final class ServerMonitor {
    var servers: [DevServer] = []
    var isScanning = false

    private var timer: AnyCancellable?
    private let scanInterval: TimeInterval = 2

    init() {
        startPolling()
    }

    private func startPolling() {
        Task { await scan() }

        timer = Timer.publish(every: scanInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    await self.scan()
                }
            }
    }

    func refresh() async {
        await scan()
    }

    func kill(server: DevServer) {
        // Try killing the process group first so parent + children all terminate
        let pgid = getpgid(server.pid)
        if pgid > 0 {
            Foundation.kill(-pgid, SIGTERM)
        } else {
            Foundation.kill(server.pid, SIGTERM)
        }
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers.remove(at: index)
        }
    }

    func openInBrowser(server: DevServer) {
        guard let url = URL(string: "http://localhost:\(server.port)") else { return }
        NSWorkspace.shared.open(url)
    }

    private func scan() async {
        guard !isScanning else { return }
        isScanning = true
        defer { isScanning = false }

        do {
            let scannedPorts = try await PortScanner.scan()
            var newServers: [DevServer] = []

            for scanned in scannedPorts {
                if let existing = servers.first(where: {
                    $0.pid == scanned.pid && $0.port == scanned.port
                }) {
                    newServers.append(existing)
                    continue
                }

                let resolved = await ProcessResolver.resolve(pid: scanned.pid)
                let projectPath = resolved?.projectPath ?? ""
                let projectName = resolved?.projectName ?? scanned.processName
                let gitBranch = !projectPath.isEmpty
                    ? GitBranchReader.branch(at: projectPath)
                    : nil
                let startTime = await ProcessResolver.startTime(pid: scanned.pid) ?? Date()

                newServers.append(DevServer(
                    id: UUID(),
                    pid: scanned.pid,
                    port: scanned.port,
                    processName: scanned.processName,
                    projectName: projectName,
                    projectPath: projectPath,
                    gitBranch: gitBranch,
                    startTime: startTime
                ))
            }

            servers = newServers
        } catch {
            // Scan failed — keep existing state
        }
    }
}
