import Foundation

enum HeaderOp: String, Codable, CaseIterable, Identifiable {
    case set, add, remove
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct HeaderAction: Identifiable, Codable, Equatable {
    var id: UUID = .init()
    var op: HeaderOp = .set
    var name: String = ""
    var value: String = ""
}

struct Rule: Identifiable, Codable, Equatable {
    var id: UUID = .init()
    var enabled: Bool = true
    var name: String = ""
    var urlPatterns: [String] = []
    var headerActions: [HeaderAction] = []

    var urlPreview: String {
        switch urlPatterns.count {
        case 0: return "No patterns"
        case 1: return urlPatterns[0]
        default: return "\(urlPatterns[0]) +\(urlPatterns.count - 1)"
        }
    }
}
