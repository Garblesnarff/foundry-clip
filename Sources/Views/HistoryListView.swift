import SwiftUI

/// View displaying the list of clipboard history items.
struct HistoryListView: View {
    let items: [ClipboardItem]
    let searchQuery: String
    let onItemSelected: (ClipboardItem) -> Void
    let onItemDeleted: (ClipboardItem) -> Void
    let onItemPinned: (ClipboardItem) -> Void
    let onSaveAsSnippet: (ClipboardItem) -> Void

    var filteredItems: [ClipboardItem] {
        guard !searchQuery.isEmpty else { return items }
        return fuzzySearch(query: searchQuery, in: items)
    }

    var pinnedItems: [ClipboardItem] {
        filteredItems.filter { $0.isPinned }
    }

    var regularItems: [ClipboardItem] {
        filteredItems.filter { !$0.isPinned }
    }

    var body: some View {
        if filteredItems.isEmpty {
            EmptyStateView(
                icon: "doc.on.clipboard",
                title: searchQuery.isEmpty ? "No clips yet" : "No matching clips",
                subtitle: searchQuery.isEmpty ? "The forge remembers everything" : "Try a different search"
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Pinned items section
                    if !pinnedItems.isEmpty {
                        Section {
                            ForEach(pinnedItems) { item in
                                HistoryItemRow(
                                    item: item,
                                    onSelect: { onItemSelected(item) },
                                    onDelete: { onItemDeleted(item) },
                                    onPin: { onItemPinned(item) },
                                    onSaveAsSnippet: { onSaveAsSnippet(item) }
                                )
                            }
                        } header: {
                            SectionHeader(title: "Pinned", icon: "pin.fill")
                        }
                    }

                    // Regular items
                    ForEach(regularItems) { item in
                        HistoryItemRow(
                            item: item,
                            onSelect: { onItemSelected(item) },
                            onDelete: { onItemDeleted(item) },
                            onPin: { onItemPinned(item) },
                            onSaveAsSnippet: { onSaveAsSnippet(item) }
                        )
                    }
                }
            }
            .background(FoundryColors.background)
        }
    }

    // Simple fuzzy search implementation
    private func fuzzySearch(query: String, in items: [ClipboardItem]) -> [ClipboardItem] {
        let lowercasedQuery = query.lowercased()
        return items.filter { item in
            item.content.lowercased().contains(lowercasedQuery) ||
            (item.sourceApp?.lowercased().contains(lowercasedQuery) ?? false)
        }.sorted { lhs, rhs in
            // Pinned items first
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            // Then by timestamp
            return lhs.timestamp > rhs.timestamp
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(FoundryColors.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - History Item Row

struct HistoryItemRow: View {
    let item: ClipboardItem
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onPin: () -> Void
    let onSaveAsSnippet: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: item.contentType.icon)
                .font(.system(size: 14))
                .foregroundColor(FoundryColors.textSecondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    // Sensitive badge
                    if item.isSensitive {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }

                    // Pinned badge
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(FoundryColors.accent)
                    }

                    Text(item.preview)
                        .font(.caption)
                        .foregroundColor(FoundryColors.textPrimary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(FoundryColors.textSecondary)

                    if let sourceApp = item.sourceApp {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(FoundryColors.textSecondary)
                        Text(sourceApp)
                            .font(.caption2)
                            .foregroundColor(FoundryColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                Button(action: onPin) {
                    Image(systemName: item.isPinned ? "pin.slash" : "pin")
                        .font(.system(size: 12))
                        .foregroundColor(item.isPinned ? FoundryColors.accent : FoundryColors.textSecondary)
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "Unpin" : "Pin")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(FoundryColors.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .background(FoundryColors.background)
        .onTapGesture(perform: onSelect)
        .contextMenu {
            Button(action: onSelect) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Button(action: onPin) {
                Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            Button(action: onSaveAsSnippet) {
                Label("Save as Snippet", systemImage: "bookmark")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(FoundryColors.textSecondary)
            Text(title)
                .font(.headline)
                .foregroundColor(FoundryColors.textPrimary)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(FoundryColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FoundryColors.background)
    }
}

#if DEBUG
#Preview {
    HistoryListView(
        items: [
            ClipboardItem(content: "Test clip 1", contentType: .text, size: 100),
            ClipboardItem(content: "Test clip 2", contentType: .text, isPinned: true, size: 100),
        ],
        searchQuery: "",
        onItemSelected: { _ in },
        onItemDeleted: { _ in },
        onItemPinned: { _ in },
        onSaveAsSnippet: { _ in }
    )
}
#endif
