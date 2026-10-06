import SwiftUI

@main
struct ProxyRulesApp: App {
    @StateObject private var store = RuleStore.shared

    var body: some Scene {
        Window("Proxy Rules", id: "rules") {
            ContentView()
                .environmentObject(store)
        }
        .defaultSize(width: 860, height: 580)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(store)
        } label: {
            Image(systemName: store.proxyEnabled
                  ? "network.badge.shield.half.filled"
                  : "network")
        }
    }
}
