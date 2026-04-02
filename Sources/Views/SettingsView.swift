import SwiftUI

/// Settings panel for Foundry Clip.
struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        List {
            Section("General") {
                HStack {
                    Text("Theme")
                        .foregroundColor(FoundryColors.textPrimary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { settingsManager.settings?.theme ?? "system" },
                        set: { settingsManager.updateTheme($0) }
                    )) {
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                        Text("System").tag("system")
                    }
                    .pickerStyle(.menu)
                }

                Toggle("Launch at Login", isOn: Binding(
                    get: { settingsManager.settings?.launchAtLogin ?? false },
                    set: { settingsManager.updateLaunchAtLogin($0) }
                ))

                Toggle("Show Source App", isOn: Binding(
                    get: { settingsManager.settings?.showSourceApp ?? true },
                    set: { settingsManager.updateShowSourceApp($0) }
                ))
            }

            Section("Clipboard") {
                HStack {
                    Text("History Limit")
                        .foregroundColor(FoundryColors.textPrimary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { settingsManager.settings?.historyLimit ?? 50 },
                        set: { settingsManager.updateHistoryLimit($0) }
                    )) {
                        Text("50").tag(Int32(50))
                        Text("100").tag(Int32(100))
                        Text("250").tag(Int32(250))
                        Text("500").tag(Int32(500))
                    }
                    .pickerStyle(.menu)
                }

                Toggle("Auto-Expire Sensitive", isOn: Binding(
                    get: { settingsManager.settings?.autoExpireSensitive ?? true },
                    set: { settingsManager.updateAutoExpireSensitive($0) }
                ))

                Toggle("Blur Sensitive Previews", isOn: Binding(
                    get: { settingsManager.settings?.blurSensitivePreviews ?? true },
                    set: { settingsManager.updateBlurSensitivePreviews($0) }
                ))

                Toggle("Clear History on Quit", isOn: Binding(
                    get: { settingsManager.settings?.clearHistoryOnQuit ?? false },
                    set: { settingsManager.updateClearHistoryOnQuit($0) }
                ))
            }

            Section("About") {
                HStack {
                    Text("Version")
                        .foregroundColor(FoundryColors.textPrimary)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(FoundryColors.textSecondary)
                }
            }
        }
        .listStyle(.inset)
        .background(FoundryColors.background)
    }
}
