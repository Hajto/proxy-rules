# Handoff Notes

This app was designed and scaffolded in a single session. Here's what exists, what was decided, and what still needs work.

## What's built

- **SwiftUI macOS app** (menu bar + rules window) targeting macOS 13+
- **`RuleStore`** — `ObservableObject` singleton, persists rules as JSON to `~/Library/Application Support/ProxyRules/rules.json`, debounced saves
- **`ProxyManager`** — launches `mitmdump` as a subprocess, sets system HTTP/HTTPS proxy via `networksetup` on all active network interfaces, writes the Python addon on startup
- **`addon.py`** — mitmproxy addon that hot-reloads rules on each request (mtime check), applies header set/add/remove to matching requests using glob pattern matching
- **Full rule editor UI** — sidebar list with per-rule toggle, detail panel with name, multiple URL patterns, ordered header actions

## Architecture decisions

**Why mitmproxy instead of custom proxy?**
TLS MITM from scratch requires generating per-host certs signed by a local CA. mitmproxy does this correctly and is battle-tested. The tradeoff is a Python runtime dependency (`brew install mitmproxy`).

**Why `mitmdump` not `mitmproxy`?**
`mitmproxy` is a TUI app — not usable headlessly. `mitmdump` is the headless variant, same engine, takes the same `-s` addon flag.

**Why `networksetup` not `NETransparentProxyProvider`?**
`NETransparentProxyProvider` (Network Extension) requires an entitlement from Apple (takes weeks to get). `networksetup` sets the system proxy in Network preferences — works for ~95% of traffic (everything using `NSURLSession`/`CFNetwork`). CLI tools and apps that ignore system proxy settings are the exception.

**Why glob (`fnmatch`) not regex for URL patterns?**
Non-technical users. `api.example.com/v1/*` is readable; `^https?://api\.example\.com/v1/.*$` is not.

**Hot-reload mechanism**
The addon checks `RULES_PATH.stat().st_mtime` on every request. If it changed, it reloads. This means rule changes in the UI apply within one request with no subprocess restart.

## Known gaps / what's missing

- **`project.yml` may need Info.plist tweaks** — if xcodegen complains about the plist, create a bare `Info.plist` in the project root (Xcode will generate one, or copy from any macOS app template)
- **No proxy cleanup on crash** — if the app force-quits, system proxy stays set. A launch agent or `atexit` handler could fix this. For now: `networksetup -setwebproxystate Wi-Fi off`
- **No support for response rewriting** — the addon only hooks `request()`. Adding `response()` would let you rewrite response headers or bodies
- **No HTTPS body inspection** — cert needs to be trusted first; if it isn't, HTTPS connections fail rather than pass through. A fallback `--ssl-insecure` flag was intentionally omitted (it weakens security model)
- **Single port (8080)** — hardcoded. Could be a preference if 8080 conflicts
- **No per-rule logging** — useful for debugging whether a rule fired. Could write to a log file and surface it in the UI
- **App sandbox is OFF** — required to run subprocesses and call `networksetup`. This means no App Store distribution. Distribute via direct download or notarized DMG

## File map

```
Sources/ProxyRulesApp.swift       @main, Window + MenuBarExtra
Sources/Models/Rule.swift         Rule, HeaderAction, HeaderOp
Sources/Models/RuleStore.swift    ObservableObject, persistence, proxy toggle
Sources/Proxy/ProxyManager.swift  mitmdump process + networksetup + addon writer
Sources/Views/ContentView.swift   NavigationSplitView root
Sources/Views/SidebarView.swift   Rule list, toolbar (proxy toggle + add)
Sources/Views/RuleRow.swift       Single row: dot + name + url + toggle
Sources/Views/RuleDetailView.swift Name, URL patterns, header actions, delete
Sources/Views/MenuBarView.swift   Menu: toggle, open window, quit
project.yml                       xcodegen config → generates ProxyRules.xcodeproj
```
