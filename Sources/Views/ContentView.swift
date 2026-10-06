import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: RuleStore

    var selectedIndex: Int? {
        guard let id = store.selectedRuleId else { return nil }
        return store.rules.firstIndex(where: { $0.id == id })
    }

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 232, max: 300)
        } detail: {
            if let idx = selectedIndex {
                RuleDetailView(rule: $store.rules[idx])
                    .id(store.rules[idx].id)
            } else {
                EmptyDetailView()
            }
        }
    }
}

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Select a rule to edit")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
