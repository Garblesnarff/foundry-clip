import Foundation
import SwiftUI
import os.log

/// Manages user settings and preferences for Foundry Clip.
/// Persists to Core Data.
@MainActor
final class SettingsManager: NSObject, ObservableObject {
    @Published var settings: Settings?
    @Published var isProUser: Bool = false

    private let dataStore = DataStore.shared

    override init() {
        super.init()
        Task {
            await loadSettings()
        }
    }

    // MARK: - Loading

    func loadSettings() async {
        do {
            let loaded = try await dataStore.fetchOrCreateSettings()
            await MainActor.run {
                self.settings = loaded
            }
            os_log("Settings loaded", log: osLog, type: .info)
        } catch {
            os_log("⚠️ Could not load settings: %{public}@", log: osLog, type: .error, error.localizedDescription)
            // Create default settings if loading fails
            await MainActor.run {
                self.settings = Settings()
            }
        }
    }

    // MARK: - Updates

    func updateHistoryLimit(_ limit: Int32) {
        settings?.historyLimit = limit
        saveSettings()
        os_log("History limit updated: %d", log: osLog, type: .info, limit)
    }

    func updateGlobalHotkey(_ hotkey: String) {
        settings?.globalHotkey = hotkey
        saveSettings()
        os_log("Global hotkey updated: %{public}@", log: osLog, type: .info, hotkey)
    }

    func updateAutoExpireSensitive(_ enabled: Bool) {
        settings?.autoExpireSensitive = enabled
        saveSettings()
        os_log("Auto-expire sensitive: %{public}@", log: osLog, type: .info, enabled ? "enabled" : "disabled")
    }

    func updateSensitiveTimeout(_ seconds: Int32) {
        settings?.sensitiveTimeout = seconds
        saveSettings()
        os_log("Sensitive timeout updated: %d seconds", log: osLog, type: .info, seconds)
    }

    func updateLaunchAtLogin(_ enabled: Bool) {
        settings?.launchAtLogin = enabled
        saveSettings()
        os_log("Launch at login: %{public}@", log: osLog, type: .info, enabled ? "enabled" : "disabled")
    }

    func updateRunInBackground(_ enabled: Bool) {
        settings?.runInBackground = enabled
        saveSettings()
        os_log("Run in background: %{public}@", log: osLog, type: .info, enabled ? "enabled" : "disabled")
    }

    func updateTheme(_ theme: String) {
        settings?.theme = theme
        saveSettings()
        os_log("Theme updated: %{public}@", log: osLog, type: .info, theme)
    }

    func updateICloudSyncEnabled(_ enabled: Bool) {
        guard isProUser else {
            os_log("⚠️ iCloud sync requires Pro tier", log: osLog, type: .default)
            return
        }
        settings?.iCloudSyncEnabled = enabled
        saveSettings()
        os_log("iCloud sync: %{public}@", log: osLog, type: .info, enabled ? "enabled" : "disabled")
    }

    func updateCloudRetention(_ days: Int32) {
        guard isProUser else { return }
        settings?.cloudRetention = days
        saveSettings()
        os_log("Cloud retention updated: %d days", log: osLog, type: .info, days)
    }

    func updateClearHistoryOnQuit(_ enabled: Bool) {
        settings?.clearHistoryOnQuit = enabled
        saveSettings()
        os_log("Clear history on quit: %{public}@", log: osLog, type: .info, enabled ? "enabled" : "disabled")
    }

    func updateShowSourceApp(_ enabled: Bool) {
        settings?.showSourceApp = enabled
        saveSettings()
        os_log("Show source app: %{public}@", log: osLog, type: .info, enabled ? "enabled" : "disabled")
    }

    func updateBlurSensitivePreviews(_ enabled: Bool) {
        settings?.blurSensitivePreviews = enabled
        saveSettings()
        os_log("Blur sensitive previews: %{public}@", log: osLog, type: .info, enabled ? "enabled" : "disabled")
    }

    func addIgnoreApp(_ bundleId: String) {
        guard var ignoreApps = settings?.ignoreApps else { return }
        if !ignoreApps.contains(bundleId) {
            ignoreApps.append(bundleId)
            settings?.ignoreApps = ignoreApps
            saveSettings()
            os_log("App added to ignore list: %{public}@", log: osLog, type: .info, bundleId)
        }
    }

    func removeIgnoreApp(_ bundleId: String) {
        guard var ignoreApps = settings?.ignoreApps else { return }
        ignoreApps.removeAll { $0 == bundleId }
        settings?.ignoreApps = ignoreApps
        saveSettings()
        os_log("App removed from ignore list: %{public}@", log: osLog, type: .info, bundleId)
    }

    private func saveSettings() {
        guard let settings = settings else { return }
        Task {
            do {
                try await dataStore.updateSettings(settings)
            } catch {
                os_log("⚠️ Failed to save settings: %{public}@", log: osLog, type: .error, error.localizedDescription)
            }
        }
    }
}

// MARK: - Settings Model

struct Settings: Identifiable, Codable, Equatable {
    var id: UUID
    var globalHotkey: String
    var historyLimit: Int32
    var autoExpireSensitive: Bool
    var sensitiveTimeout: Int32
    var launchAtLogin: Bool
    var runInBackground: Bool
    var theme: String
    var iCloudSyncEnabled: Bool
    var cloudRetention: Int32
    var showSourceApp: Bool
    var clearHistoryOnQuit: Bool
    var blurSensitivePreviews: Bool
    var ignoreApps: [String]

    init(id: UUID = UUID()) {
        self.id = id
        self.globalHotkey = "cmd+shift+v"
        self.historyLimit = 50
        self.autoExpireSensitive = true
        self.sensitiveTimeout = 30
        self.launchAtLogin = false
        self.runInBackground = true
        self.theme = "dark"
        self.iCloudSyncEnabled = false
        self.cloudRetention = 30
        self.showSourceApp = true
        self.clearHistoryOnQuit = false
        self.blurSensitivePreviews = true
        self.ignoreApps = []
    }

    /// Creates Settings from a Core Data entity.
    static func from(entity: NSManagedObject) -> Settings {
        var settings = Settings()
        settings.id = entity.value(forKey: "id") as? UUID ?? UUID()
        settings.globalHotkey = entity.value(forKey: "globalHotkey") as? String ?? "cmd+shift+v"
        settings.historyLimit = entity.value(forKey: "historyLimit") as? Int32 ?? 50
        settings.autoExpireSensitive = entity.value(forKey: "autoExpireSensitive") as? Bool ?? true
        settings.sensitiveTimeout = entity.value(forKey: "sensitiveTimeout") as? Int32 ?? 30
        settings.launchAtLogin = entity.value(forKey: "launchAtLogin") as? Bool ?? false
        settings.runInBackground = entity.value(forKey: "runInBackground") as? Bool ?? true
        settings.theme = entity.value(forKey: "theme") as? String ?? "dark"
        settings.iCloudSyncEnabled = entity.value(forKey: "iCloudSyncEnabled") as? Bool ?? false
        settings.cloudRetention = entity.value(forKey: "cloudRetention") as? Int32 ?? 30
        settings.showSourceApp = entity.value(forKey: "showSourceApp") as? Bool ?? true
        settings.clearHistoryOnQuit = entity.value(forKey: "clearHistoryOnQuit") as? Bool ?? false
        settings.blurSensitivePreviews = entity.value(forKey: "blurSensitivePreviews") as? Bool ?? true
        settings.ignoreApps = entity.value(forKey: "ignoreApps") as? [String] ?? []
        return settings
    }

    /// Applies settings to a Core Data entity.
    func apply(to entity: NSManagedObject) {
        entity.setValue(id, forKey: "id")
        entity.setValue(globalHotkey, forKey: "globalHotkey")
        entity.setValue(historyLimit, forKey: "historyLimit")
        entity.setValue(autoExpireSensitive, forKey: "autoExpireSensitive")
        entity.setValue(sensitiveTimeout, forKey: "sensitiveTimeout")
        entity.setValue(launchAtLogin, forKey: "launchAtLogin")
        entity.setValue(runInBackground, forKey: "runInBackground")
        entity.setValue(theme, forKey: "theme")
        entity.setValue(iCloudSyncEnabled, forKey: "iCloudSyncEnabled")
        entity.setValue(cloudRetention, forKey: "cloudRetention")
        entity.setValue(showSourceApp, forKey: "showSourceApp")
        entity.setValue(clearHistoryOnQuit, forKey: "clearHistoryOnQuit")
        entity.setValue(blurSensitivePreviews, forKey: "blurSensitivePreviews")
        entity.setValue(ignoreApps as NSArray, forKey: "ignoreApps")
    }
}

// Import CoreData for NSManagedObject
import CoreData
