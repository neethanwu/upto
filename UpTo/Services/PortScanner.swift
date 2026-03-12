import Foundation

struct ScannedPort: Sendable {
    let pid: Int32
    let port: UInt16
    let processName: String
}

enum PortScanner {
    /// Known dev server process names — only these are shown
    private static let devProcesses: Set<String> = [
        "node", "next-server", "vite", "npm", "npx",
        "python", "python3", "uvicorn", "gunicorn", "flask",
        "ruby", "puma", "rails", "thin", "unicorn",
        "java", "gradle", "mvn",
        "go", "air",
        "php", "php-fpm", "artisan",
        "deno", "bun",
        "cargo", "trunk",
        "dotnet",
        "hugo", "jekyll", "gatsby",
        "ng", "webpack", "esbuild", "turbo",
    ]

    static func scan() async throws -> [ScannedPort] {
        let output = try await ShellExecutor.run(
            "/usr/sbin/lsof",
            arguments: ["-iTCP", "-sTCP:LISTEN", "-nP"]
        )
        return parse(output)
    }

    private static func parse(_ output: String) -> [ScannedPort] {
        var seen = Set<UInt16>()
        var results: [ScannedPort] = []

        let lines = output.split(separator: "\n").dropFirst() // skip header
        for line in lines {
            let cols = line.split(separator: " ", omittingEmptySubsequences: true)
            guard cols.count >= 10 else { continue }

            let processName = String(cols[0])
            guard let pid = Int32(cols[1]) else { continue }
            let name = String(cols[8])
            guard let portStr = name.split(separator: ":").last,
                  let port = UInt16(portStr) else { continue }

            // Only include known dev server processes
            let lowerName = processName.lowercased()
            guard devProcesses.contains(lowerName) else { continue }

            guard !seen.contains(port) else { continue }
            seen.insert(port)

            results.append(ScannedPort(pid: pid, port: port, processName: processName))
        }

        return results.sorted { $0.port < $1.port }
    }
}
