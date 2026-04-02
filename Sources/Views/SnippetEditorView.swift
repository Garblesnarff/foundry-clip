import SwiftUI

/// Modal sheet for creating or editing a snippet.
struct SnippetEditorView: View {
    let snippet: Snippet?
    let onSave: (Snippet) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var content: String
    @State private var folder: String
    @State private var tags: String

    init(snippet: Snippet?, onSave: @escaping (Snippet) -> Void, onCancel: @escaping () -> Void) {
        self.snippet = snippet
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: snippet?.title ?? "")
        _content = State(initialValue: snippet?.content ?? "")
        _folder = State(initialValue: snippet?.folder ?? "")
        _tags = State(initialValue: snippet?.tags.joined(separator: ", ") ?? "")
    }

    private var isEditing: Bool { snippet != nil }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty && !content.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Snippet" : "New Snippet")
                    .font(.headline)
                    .foregroundColor(FoundryColors.textPrimary)
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(FoundryColors.textSecondary)
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(FoundryColors.accent)
                    .disabled(!canSave)
            }
            .padding()
            .background(FoundryColors.controlBackground)

            Divider()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    field(label: "Title") {
                        TextField("Untitled Snippet", text: $title)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundColor(FoundryColors.textPrimary)
                    }

                    field(label: "Content") {
                        TextEditor(text: $content)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(FoundryColors.textPrimary)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                    }

                    field(label: "Folder (optional)") {
                        TextField("e.g. Swift Boilerplate", text: $folder)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundColor(FoundryColors.textPrimary)
                    }

                    field(label: "Tags (comma-separated, optional)") {
                        TextField("e.g. swift, boilerplate, import", text: $tags)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundColor(FoundryColors.textPrimary)
                    }
                }
                .padding()
            }
            .background(FoundryColors.background)
        }
        .frame(width: 420, height: 440)
        .background(FoundryColors.background)
    }

    @ViewBuilder
    private func field<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(FoundryColors.textSecondary)

            content()
                .padding(10)
                .background(FoundryColors.controlBackground)
                .cornerRadius(8)
        }
    }

    private func save() {
        let parsedTags = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let saved = Snippet(
            id: snippet?.id ?? UUID(),
            createdDate: snippet?.createdDate ?? Date(),
            updatedDate: Date(),
            title: title.trimmingCharacters(in: .whitespaces),
            content: content.trimmingCharacters(in: .whitespaces),
            folder: folder.trimmingCharacters(in: .whitespaces).isEmpty ? nil : folder.trimmingCharacters(in: .whitespaces),
            tags: parsedTags
        )
        onSave(saved)
    }
}
