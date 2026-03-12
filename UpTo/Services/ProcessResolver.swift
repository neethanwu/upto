import Foundation

enum ProcessResolver {
    /// Resolves a PID to its working directory and derives the project name.
    /// Uses `lsof -a -d cwd -p {pid} -Fn` which is much faster than full `lsof -p`.
    static func resolve(pid: Int32) async -> (projectPath: String, projectName: String)? {
        guard let output = try? await ShellExecutor.run(
            "/usr/sbin/lsof",
            arguments: ["-a", "-d", "cwd", "-p", "\(pid)", "-Fn"],
            timeout: 3
        ) else {
            return nil
        }

        // Output format: lines with "n" prefix contain the path
        for line in output.split(separator: "\n") {
            if line.hasPrefix("n/") {
                let path = String(line.dropFirst()) // remove "n" prefix
                let name = URL(fileURLWithPath: path).lastPathComponent
                return (projectPath: path, projectName: name)
            }
        }

        return nil
    }

    /// Gets the process start time for uptime calculation.
    static func startTime(pid: Int32) async -> Date? {
        guard let output = try? await ShellExecutor.run(
            "/bin/ps",
            arguments: ["-o", "lstart=", "-p", "\(pid)"],
            timeout: 3
        ) else {
            return nil
        }

        let dateString = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !dateString.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // ps lstart format: "Mon Jan  6 14:23:45 2025"
        formatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"

        let normalized = dateString.replacingOccurrences(of: "  ", with: " ")
        return formatter.date(from: normalized)
    }
}
