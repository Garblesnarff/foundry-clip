import SwiftUI

/// View displaying saved snippets with search, add, edit, and delete actions.
struct SnippetsView: View {
    let snippets: [Snippet]
    let searchQuery: String
    let onSnippetSelected: (Snippet) -> Void
    let onSnippetDeleted: (Snippet) -> Void
    let onSnippetEdited: (Snippet) -> Void
    let onAddSnippet: () -> Void

    var filteredSnippets: [Snippet] {
        guard !searchQuery.isEmpty else { return snippets }
        let q = searchQuery.lowercased()
        return snippets.filter {
            $0.title.lowercased().contains(q) ||
            $0.content.lowercased().contains(q) ||
            ($0.folder?.lowercased().contains(q) ?? false) ||
            $0.tags.contains { $0.lowercased().contains(q) }
        }
    }

    var body: some View {
        if snippets.isEmpty {
            emptyState
        } else if filteredSnippets.isEmpty {
            EmptyStateView(
                icon: "bookmark",
                title: "No matching snippets",
                subtitle: "Try a different search"
            )
        } else {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredSnippets) { snippet in
                            SnippetRow(
                                snippet: snippet,
                                onSelect: { onSnippetSelected(snippet) },
                                onEdit: { onSnippetEdited(snippet) },
                                onDelete: { onSnippetDeleted(snippet) }
                            )
                        }
                    }
                }
                .background(FoundryColors.background)

                Divider()

                Button(action: onAddSnippet) {
                    Label("New Snippet", systemImage: "plus")
                        .font(.caption)
                        .foregroundColor(FoundryColors.accent)
                }
                .buttonStyle(.plain)
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(FoundryColors.controlBackground)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            EmptyStateView(
                icon: "bookmark",
                title: "No snippets yet",
                subtitle: "Save frequently used text for instant recall"
            )
            Button(action: onAddSnippet) {
                Label("Create Snippet", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(FoundryColors.accent)
        }
    }
}

// MARK: - Snippet Row

private struct SnippetRow: View {
    let snippet: Snippet
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 14))
                .foregroundColor(FoundryColors.accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(snippet.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(FoundryColors.textPrimary)
                    .lineLimit(1)

                Text(snippet.preview)
                    .font(.caption2)
                    .foregroundColor(FoundryColors.textSecondary)
                    .lineLimit(2)

                if let folder = snippet.folder {
                    Label(folder, systemImage: "folder")
                        .font(.caption2)
                        .foregroundColor(FoundryColors.textSecondary)
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(FoundryColors.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Edit")

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(FoundryColors.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Delete")
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
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
