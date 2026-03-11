import Foundation

protocol StatusProvider {
    func parseStatus(from data: Data, url: URL) throws -> ServiceStatusResult?
}
