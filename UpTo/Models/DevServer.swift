import Foundation

struct DevServer: Identifiable, Equatable {
    let id: UUID
    let pid: Int32
    let port: UInt16
    let processName: String
    let projectName: String
    let projectPath: String
    let gitBranch: String?
    let startTime: Date

    var displayName: String {
        projectName
    }

    var uptime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    static func == (lhs: DevServer, rhs: DevServer) -> Bool {
        lhs.pid == rhs.pid && lhs.port == rhs.port
    }
}
