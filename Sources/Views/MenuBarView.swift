import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var store: RuleStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Toggle("Proxy Enabled", isOn: $store.proxyEnabled)

        Divider()

        Button("Open Rules…") {
            openWindow(id: "rules")
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        Button("Quit") {
            NSApp.terminate(nil)
        }
    }
}
