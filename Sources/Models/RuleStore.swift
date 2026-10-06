import Foundation
import Combine

final class RuleStore: ObservableObject {
    static let shared = RuleStore()

    @Published var rules: [Rule] = [] { didSet { scheduleSave() } }
    @Published var selectedRuleId: UUID?
    @Published var proxyEnabled: Bool = false {
        didSet {
            if proxyEnabled { ProxyManager.shared.start() }
            else { ProxyManager.shared.stop() }
        }
    }

    private let storeURL: URL
    private var saveTask: DispatchWorkItem?

    private init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ProxyRules")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storeURL = dir.appendingPathComponent("rules.json")
        load()
    }

    func addRule() {
        let rule = Rule(name: "New Rule")
        rules.append(rule)
        selectedRuleId = rule.id
    }

    func deleteRule(_ rule: Rule) {
        rules.removeAll { $0.id == rule.id }
        if selectedRuleId == rule.id {
            selectedRuleId = rules.first?.id
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let task = DispatchWorkItem { [weak self] in self?.save() }
        saveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(rules) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let loaded = try? JSONDecoder().decode([Rule].self, from: data)
        else { return }
        rules = loaded
    }
}
