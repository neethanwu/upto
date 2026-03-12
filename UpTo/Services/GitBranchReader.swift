import Foundation

enum GitBranchReader {
    /// Reads the current git branch from the .git/HEAD file at the given project path.
    static func branch(at projectPath: String) -> String? {
        let headPath = (projectPath as NSString).appendingPathComponent(".git/HEAD")
        guard let content = try? String(contentsOfFile: headPath, encoding: .utf8) else {
            return nil
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Symbolic ref: "ref: refs/heads/main"
        if trimmed.hasPrefix("ref: refs/heads/") {
            return String(trimmed.dropFirst("ref: refs/heads/".count))
        }

        // Detached HEAD: return short SHA
        if trimmed.count >= 7 {
            return String(trimmed.prefix(7))
        }

        return nil
    }
}
