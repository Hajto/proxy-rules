import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: RuleStore

    var body: some View {
        List(selection: $store.selectedRuleId) {
            ForEach($store.rules) { $rule in
                RuleRow(rule: $rule)
                    .tag(rule.id)
            }
        }
        .navigationTitle("Proxy Rules")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: store.addRule) {
                    Label("Add Rule", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                ProxyToggleView()
            }
        }
    }
}

struct ProxyToggleView: View {
    @EnvironmentObject var store: RuleStore

    var body: some View {
        HStack(spacing: 6) {
            Text(store.proxyEnabled ? "Proxy On" : "Proxy Off")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(store.proxyEnabled ? Color.green : Color.secondary)
            Toggle("", isOn: $store.proxyEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

extension Text {
    func sectionLabel() -> some View {
        self
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}
