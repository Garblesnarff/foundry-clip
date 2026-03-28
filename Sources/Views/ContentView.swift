import SwiftUI

/// Main popover view for Foundry Clip.
/// Shows tabs for History, Snippets, and Settings.
struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var activeTab: Tab = .history
    @State private var searchQuery: String = ""
    @State private var showingSnippetEditor = false
    @State private var editingSnippet: Snippet?

    enum Tab {
        case history
        case snippets
        case settings
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar at top
            SearchBar(query: $searchQuery)
                .padding()

            // Tab content
            ZStack {
                switch activeTab {
                case .history:
                    HistoryListView(
                        items: clipboardManager.historyItems,
                        searchQuery: searchQuery,
                        onItemSelected: { item in
                            clipboardManager.copyItemToPasteboard(item)
                            closePopover()
                        },
                        onItemDeleted: { item in
                            clipboardManager.deleteItem(item)
                        },
                        onItemPinned: { item in
                            clipboardManager.togglePinned(item)
                        },
                        onSaveAsSnippet: { item in
                            clipboardManager.createSnippetFromItem(item, title: item.preview)
                        }
                    )
                case .snippets:
                    SnippetsView(
                        snippets: clipboardManager.snippets,
                        searchQuery: searchQuery,
                        onSnippetSelected: { snippet in
                            copySnippetToClipboard(snippet)
                            closePopover()
                        },
                        onSnippetDeleted: { snippet in
                            clipboardManager.deleteSnippet(snippet)
                        },
                        onSnippetEdited: { snippet in
                            editingSnippet = snippet
                            showingSnippetEditor = true
                        },
                        onAddSnippet: {
                            editingSnippet = nil
                            showingSnippetEditor = true
                        }
                    )
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Tab bar at bottom
            TabBarView(activeTab: $activeTab)
        }
        .frame(width: 400, height: 600)
        .background(FoundryColors.background)
        .sheet(isPresented: $showingSnippetEditor) {
            SnippetEditorView(
                snippet: editingSnippet,
                onSave: { snippet in
                    clipboardManager.saveSnippet(snippet)
                    showingSnippetEditor = false
                },
                onCancel: {
                    showingSnippetEditor = false
                }
            )
        }
    }

    private func closePopover() {
        NSApp.keyWindow?.close()
    }

    private func copySnippetToClipboard(_ snippet: Snippet) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(snippet.content, forType: .string)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(FoundryColors.textSecondary)

            TextField("Search clips & snippets", text: $query)
                .textFieldStyle(.plain)
                .font(.body)

            if !query.isEmpty {
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(FoundryColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(FoundryColors.controlBackground)
        .cornerRadius(8)
    }
}

// MARK: - Tab Bar View

struct TabBarView: View {
    @Binding var activeTab: ContentView.Tab

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(
                icon: "clock",
                label: "History",
                isActive: activeTab == .history
            ) {
                activeTab = .history
            }

            Divider()
                .frame(height: 30)

            TabBarItem(
                icon: "bookmark",
                label: "Snippets",
                isActive: activeTab == .snippets
            ) {
                activeTab = .snippets
            }

            Divider()
                .frame(height: 30)

            TabBarItem(
                icon: "gearshape",
                label: "Settings",
                isActive: activeTab == .settings
            ) {
                activeTab = .settings
            }
        }
        .frame(height: 44)
        .background(FoundryColors.controlBackground)
    }
}

// MARK: - Tab Bar Item

struct TabBarItem: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isActive ? FoundryColors.accent : FoundryColors.textSecondary)
        }
        .buttonStyle(.plain)
        .background(isActive ? FoundryColors.accent.opacity(0.15) : Color.clear)
    }
}

#if DEBUG
#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
        .environmentObject(SettingsManager())
}
#endif
