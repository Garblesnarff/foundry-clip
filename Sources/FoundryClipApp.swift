import SwiftUI
import AppKit
import HotKey
import LaunchAtLogin
import os.log

/// Foundry Clip — The forge remembers everything.
///
/// Main entry point for the native macOS clipboard history and snippets manager.
/// Sets up menu bar app, registers global hotkey, and initializes clipboard monitoring.
@main
struct FoundryClipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Foundry Clip", systemImage: "doc.on.clipboard.fill") {
            ContentView()
                .environmentObject(appDelegate.clipboardManager)
                .environmentObject(appDelegate.settingsManager)
                .frame(width: 400, height: 600)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Application delegate: manages lifecycle, hotkey setup, and background monitoring.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let clipboardManager = ClipboardManager()
    let settingsManager = SettingsManager()
    private var hotKey: HotKey?
    private var popover: NSPopover?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        os_log("🔥 Honing the blade... (app launched)", log: osLog, type: .info)

        // Load settings from Core Data
        Task {
            await settingsManager.loadSettings()
        }

        // Start clipboard monitoring in background
        Task {
            do {
                try await clipboardManager.startMonitoring()
                os_log("Clipboard monitor activated", log: osLog, type: .info)
            } catch {
                os_log("⚠️ The forge could not be lit: %{public}@", log: osLog, type: .error, error.localizedDescription)
            }
        }

        // Register global hotkey
        registerGlobalHotkey()

        // Check accessibility permission
        checkAccessibilityPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        os_log("The forge cools. Shutting down.", log: osLog, type: .info)

        // Stop monitoring
        Task {
            await clipboardManager.stopMonitoring()
        }

        // Optional: clear history on quit if enabled
        if settingsManager.settings?.clearHistoryOnQuit ?? false {
            Task {
                try? await clipboardManager.clearAllHistory()
                os_log("History cleared on quit", log: osLog, type: .info)
            }
        }
    }

    // MARK: - Hotkey Management

    private func registerGlobalHotkey() {
        // Default hotkey: ⌘⇧V
        hotKey = HotKey(key: .v, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            self?.togglePopover()
        }
        os_log("Global hotkey registered: ⌘⇧V", log: osLog, type: .info)
    }

    private func togglePopover() {
        if let popover = NSApp.windows.first(where: { $0.isVisible && $0.styleMask.contains(.fullSizeContentView) })?.contentViewController as? NSHostingController<ContentView> {
            popover.view.window?.orderOut(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Accessibility Permission Check

    private func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "Foundry Clip needs Accessibility permission to monitor your clipboard and respond to global hotkey. Please enable it in System Settings > Privacy > Accessibility."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Not Now")

                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
        }
    }
}

// MARK: - Logging

let osLog = OSLog(subsystem: "com.foundry.clip", category: "default")

// MARK: - Preview

#if DEBUG
#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
        .environmentObject(SettingsManager())
}
#endif
