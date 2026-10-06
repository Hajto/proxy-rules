# ProxyRules

Mac menu bar app that intercepts HTTP/HTTPS traffic and rewrites request headers based on configurable rules. Wraps [mitmproxy](https://mitmproxy.org/).

## Requirements

- macOS 13+
- Xcode 15+
- Homebrew

## Build

```bash
brew install mitmproxy xcodegen
xcodegen generate
open ProxyRules.xcodeproj
```

In Xcode: select the **ProxyRules** target → **Signing & Capabilities** → pick your **Team** (free Apple ID works). Then hit **⌘R**.

No entitlements or special permissions needed.

## First Run

1. Enable the proxy via the menu bar toggle
2. mitmproxy starts on `localhost:8080` and becomes the system HTTP/HTTPS proxy
3. A dialog appears to install the mitmproxy CA certificate — click **Open Certificate**
4. In Keychain Access: double-click the certificate → Trust → **Always Trust**
5. Rules defined in the app are now applied to all matching traffic

## How It Works

- Rules are saved to `~/Library/Application Support/ProxyRules/rules.json`
- A Python addon at `~/Library/Application Support/ProxyRules/addon.py` is loaded by `mitmdump`
- The addon hot-reloads rules on every request (mtime check — no restart needed)
- Each rule matches URLs against its patterns (glob, `*` wildcard) and applies header actions in order
- Header ops: **Set** (replace or create), **Add** (append), **Remove** (delete)
- Turning the proxy off clears the system proxy settings on all network interfaces

## Notes

- The certificate prompt appears once. To re-trigger it, delete the `certInstallPrompted` key from `UserDefaults` (via `defaults delete com.yourname.ProxyRules certInstallPrompted`).
- The system proxy is cleared on stop and on app quit (termination handler). If the app crashes hard, run `networksetup -setwebproxystate Wi-Fi off` manually.
