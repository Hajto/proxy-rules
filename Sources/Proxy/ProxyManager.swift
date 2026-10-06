import AppKit
import Foundation

final class ProxyManager {
    static let shared = ProxyManager()

    private let port = 8080
    private var process: Process?
    private let addonURL: URL
    private let certURL = URL(fileURLWithPath: NSHomeDirectory() + "/.mitmproxy/mitmproxy-ca-cert.pem")

    private init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ProxyRules")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addonURL = dir.appendingPathComponent("addon.py")
        writeAddon()
    }

    func start() {
        guard process == nil else { return }
        guard let mitmdump = findMitmdump() else {
            showAlert(
                title: "mitmproxy not found",
                message: "Install via Homebrew:\n\nbrew install mitmproxy"
            )
            return
        }

        let p = Process()
        p.executableURL = mitmdump
        p.arguments = ["--listen-port", "\(port)", "--quiet", "-s", addonURL.path]
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async { self?.process = nil }
        }

        do {
            try p.run()
            process = p
        } catch {
            showAlert(title: "Failed to start proxy", message: error.localizedDescription)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            DispatchQueue.global().async { self.setSystemProxy(on: true) }
            self.promptCertIfNeeded()
        }
    }

    func stop() {
        DispatchQueue.global().async { [weak self] in self?.setSystemProxy(on: false) }
        process?.terminate()
        process = nil
    }

    // MARK: - Private

    private func findMitmdump() -> URL? {
        ["/opt/homebrew/bin/mitmdump", "/usr/local/bin/mitmdump"]
            .map { URL(fileURLWithPath: $0) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private func setSystemProxy(on: Bool) {
        for svc in networkServices() {
            if on {
                run("/usr/sbin/networksetup", "-setwebproxy", svc, "127.0.0.1", "\(port)")
                run("/usr/sbin/networksetup", "-setsecurewebproxy", svc, "127.0.0.1", "\(port)")
            } else {
                run("/usr/sbin/networksetup", "-setwebproxystate", svc, "off")
                run("/usr/sbin/networksetup", "-setsecurewebproxystate", svc, "off")
            }
        }
    }

    private func networkServices() -> [String] {
        let out = output("/usr/sbin/networksetup", "-listallnetworkservices")
        return out.components(separatedBy: "\n")
            .dropFirst() // first line is "An asterisk (*) denotes..."
            .filter { !$0.isEmpty }
            .map(String.init)
    }

    private func promptCertIfNeeded() {
        guard FileManager.default.fileExists(atPath: certURL.path) else { return }
        let key = "certInstallPrompted"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let alert = NSAlert()
            alert.messageText = "Trust HTTPS Certificate"
            alert.informativeText = "To inspect HTTPS traffic, trust the mitmproxy certificate in Keychain Access.\n\nAfter it opens, double-click it and set Trust → Always Trust."
            alert.addButton(withTitle: "Open Certificate")
            alert.addButton(withTitle: "Later")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(self.certURL)
            }
        }
    }

    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @discardableResult
    private func run(_ path: String, _ args: String...) -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = Array(args)
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
        p.waitUntilExit()
        return p.terminationStatus
    }

    private func output(_ path: String, _ args: String...) -> String {
        let p = Process()
        let pipe = Pipe()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = Array(args)
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        try? p.run()
        p.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    private func writeAddon() {
        let code = #"""
import json, pathlib, fnmatch
from mitmproxy import http

RULES_PATH = (
    pathlib.Path.home()
    / "Library"
    / "Application Support"
    / "ProxyRules"
    / "rules.json"
)


class RuleEngine:
    def __init__(self):
        self._mtime = 0
        self.rules = []

    def _reload(self):
        try:
            mtime = RULES_PATH.stat().st_mtime
            if mtime != self._mtime:
                self.rules = json.loads(RULES_PATH.read_text())
                self._mtime = mtime
        except Exception:
            pass

    def request(self, flow: http.HTTPFlow) -> None:
        self._reload()
        url = flow.request.pretty_url
        for rule in self.rules:
            if not rule.get("enabled"):
                continue
            patterns = rule.get("urlPatterns", [])
            if not any(fnmatch.fnmatch(url, p) for p in patterns):
                continue
            for action in rule.get("headerActions", []):
                op = action.get("op")
                name = action.get("name", "")
                val = action.get("value", "")
                if not name:
                    continue
                if op == "set":
                    flow.request.headers[name] = val
                elif op == "add":
                    flow.request.headers.add(name, val)
                elif op == "remove":
                    flow.request.headers.pop(name, None)


addons = [RuleEngine()]
"""#
        try? code.write(to: addonURL, atomically: true, encoding: .utf8)
    }
}
