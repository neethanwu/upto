import Foundation

enum ShellError: Error, CustomStringConvertible {
    case timeout
    case launchFailed(Error)

    var description: String {
        switch self {
        case .timeout:
            "Process timed out"
        case .launchFailed(let error):
            "Failed to launch process: \(error)"
        }
    }
}

enum ShellExecutor {
    /// Runs a command and returns stdout with a timeout.
    /// Non-zero exit is not treated as an error since tools like lsof
    /// may exit 1 while still producing valid partial output.
    static func run(
        _ executable: String,
        arguments: [String] = [],
        timeout: TimeInterval = 5
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()

                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: ShellError.launchFailed(error))
                    return
                }

                // Timeout: kill process if it takes too long
                let timer = DispatchSource.makeTimerSource(queue: .global())
                timer.schedule(deadline: .now() + timeout)
                timer.setEventHandler {
                    if process.isRunning {
                        process.terminate()
                    }
                }
                timer.resume()

                process.waitUntilExit()
                timer.cancel()

                let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stdout = String(data: outData, encoding: .utf8) ?? ""

                if process.terminationStatus == 15 { // SIGTERM from our timeout
                    continuation.resume(throwing: ShellError.timeout)
                } else {
                    continuation.resume(returning: stdout)
                }
            }
        }
    }
}
