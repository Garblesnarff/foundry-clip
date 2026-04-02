import Foundation
import SwiftUI
import AppKit
import os.log

/// Centralized manager for clipboard operations, history storage, and monitoring.
@MainActor
final class ClipboardManager: NSObject, ObservableObject {
    @Published var historyItems: [ClipboardItem] = []
    @Published var snippets: [Snippet] = []
    @Published var isMonitoring: Bool = false
    @Published var latestChangeCount: Int32 = 0

    private let pasteboard = NSPasteboard.general
    private var monitorTimer: Timer?
    private let dataStore = DataStore.shared
    private let sensitivityDetector = SensitivityDetector()
    private var sensitiveItemTimers: [UUID: Timer] = [:]

    nonisolated private static let monitorInterval: TimeInterval = 0.5

    override init() {
        super.init()
        loadHistory()
        loadSnippets()
    }

    // MARK: - Monitoring

    /// Starts monitoring the system pasteboard for copy/cut/paste events.
    func startMonitoring() async throws {
        guard !isMonitoring else { return }

        isMonitoring = true
        latestChangeCount = Int32(pasteboard.changeCount)

        await MainActor.run {
            self.monitorTimer = Timer.scheduledTimer(withTimeInterval: Self.monitorInterval, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.checkPasteboard()
                }
            }
        }

        os_log("Clipboard monitor started", log: osLog, type: .info)
    }

    /// Stops monitoring the system pasteboard.
    func stopMonitoring() async {
        isMonitoring = false
        monitorTimer?.invalidate()
        monitorTimer = nil
        os_log("Clipboard monitor stopped", log: osLog, type: .info)
    }

    // MARK: - Pasteboard Polling

    private func checkPasteboard() {
        let currentChangeCount = Int32(pasteboard.changeCount)

        // Skip if no change
        guard currentChangeCount != latestChangeCount else { return }

        latestChangeCount = currentChangeCount

        // Extract item from pasteboard
        guard var item = extractClipboardItem() else {
            os_log("⚠️ Could not extract clipboard item", log: osLog, type: .default)
            return
        }

        // Check if sensitive (passwords, tokens, etc.)
        if sensitivityDetector.isSensitive(item) {
            item.isSensitive = true
            os_log("⚠️ Sensitive clip detected: auto-expiring in 30 seconds", log: osLog, type: .default)
            scheduleAutoExpiry(for: item)
        }

        // Check for duplicates
        if !isDuplicate(item) {
            addHistoryItem(item)
            os_log("📋 Clip captured: %{public}@ (%{public}@)", log: osLog, type: .info, item.contentTypeDescription, item.sourceApp ?? "Unknown")
        }
    }

    // MARK: - Item Extraction

    /// Extracts a ClipboardItem from the current pasteboard state.
    private func extractClipboardItem() -> ClipboardItem? {
        let types = pasteboard.types ?? []

        // Try plain text first
        if types.contains(.string), let content = pasteboard.string(forType: .string), !content.isEmpty {
            // Check if it looks like a URL
            if let url = URL(string: content.trimmingCharacters(in: .whitespacesAndNewlines)),
               url.scheme == "http" || url.scheme == "https" {
                return ClipboardItem(
                    content: content,
                    contentType: .url,
                    sourceApp: getSourceApp(),
                    size: Int64(content.utf8.count)
                )
            }

            return ClipboardItem(
                content: content,
                contentType: .text,
                sourceApp: getSourceApp(),
                size: Int64(content.utf8.count)
            )
        }

        // Try rich text (RTF)
        if types.contains(.rtf), let data = pasteboard.data(forType: .rtf) {
            return ClipboardItem(
                content: "[RTF Document]",
                contentData: data,
                contentType: .richText,
                sourceApp: getSourceApp(),
                size: Int64(data.count)
            )
        }

        // Try image
        if let imageData = extractImageData() {
            let thumbnail = generateThumbnail(from: imageData)
            return ClipboardItem(
                content: "[Image]",
                contentData: imageData,
                contentType: .image,
                sourceApp: getSourceApp(),
                size: Int64(imageData.count),
                thumbnailData: thumbnail
            )
        }

        // Try file URLs
        if types.contains(.fileURL), let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            let fileList = urls.map { $0.lastPathComponent }.joined(separator: ", ")
            var totalSize: Int64 = 0
            for url in urls {
                if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = attrs[.size] as? Int64 {
                    totalSize += size
                }
            }
            return ClipboardItem(
                content: fileList,
                contentData: try? NSKeyedArchiver.archivedData(withRootObject: urls, requiringSecureCoding: true),
                contentType: .file,
                sourceApp: getSourceApp(),
                size: totalSize
            )
        }

        // Try HTML
        if types.contains(.html), let data = pasteboard.data(forType: .html) {
            let htmlString = String(data: data, encoding: .utf8) ?? "[HTML]"
            return ClipboardItem(
                content: "[HTML Document]",
                contentData: data,
                contentType: .html,
                sourceApp: getSourceApp(),
                size: Int64(data.count)
            )
        }

        return nil
    }

    /// Extracts image data from the pasteboard.
    private func extractImageData() -> Data? {
        // Try TIFF
        if let data = pasteboard.data(forType: .tiff) {
            return data
        }

        // Try PNG
        if let data = pasteboard.data(forType: .png) {
            return data
        }

        return nil
    }

    /// Generates a thumbnail from image data.
    private func generateThumbnail(from imageData: Data) -> Data? {
        guard let image = NSImage(data: imageData) else { return nil }

        let thumbnailSize = NSSize(width: 32, height: 32)
        let thumbnail = NSImage(size: thumbnailSize)

        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: thumbnailSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        thumbnail.unlockFocus()

        guard let tiffData = thumbnail.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else { return nil }

        return bitmapRep.representation(using: .png, properties: [:])
    }

    /// Gets the source application from the pasteboard.
    private func getSourceApp() -> String {
        return NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
    }

    // MARK: - Duplicate Detection

    private func isDuplicate(_ item: ClipboardItem) -> Bool {
        guard let lastItem = historyItems.first else { return false }

        // Check if identical content and captured within 10 seconds
        let timeDiff = abs(item.timestamp.timeIntervalSince(lastItem.timestamp))
        return lastItem.content == item.content && timeDiff < 10
    }

    // MARK: - History Management

    /// Adds an item to clipboard history.
    func addHistoryItem(_ item: ClipboardItem) {
        Task {
            do {
                try await dataStore.saveClipboardItem(item)
                await loadHistory()
            } catch {
                os_log("⚠️ Failed to save clipboard item: %{public}@", log: osLog, type: .error, error.localizedDescription)
            }
        }
    }

    /// Loads history from Core Data.
    func loadHistory() {
        Task {
            do {
                let settings = try await dataStore.fetchOrCreateSettings()
                let items = try await dataStore.fetchClipboardItems(limit: settings.historyLimit)
                await MainActor.run {
                    self.historyItems = items
                }
            } catch {
                os_log("⚠️ Failed to load history: %{public}@", log: osLog, type: .error, error.localizedDescription)
            }
        }
    }

    /// Loads snippets from Core Data.
    func loadSnippets() {
        Task {
            do {
                let items = try await dataStore.fetchSnippets()
                await MainActor.run {
                    self.snippets = items
                }
            } catch {
                os_log("⚠️ Failed to load snippets: %{public}@", log: osLog, type: .error, error.localizedDescription)
            }
        }
    }

    /// Copies a history item back to the pasteboard.
    func copyItemToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.contentType {
        case .text:
            pasteboard.setString(item.content, forType: .string)
        case .richText:
            if let data = item.contentData {
                pasteboard.setData(data, forType: .rtf)
            }
        case .image:
            if let data = item.contentData {
                pasteboard.setData(data, forType: .tiff)
            }
        case .file:
            if let data = item.contentData,
               let urls = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data) as? [URL] {
                pasteboard.writeObjects(urls.map { $0 as NSURL })
            }
        case .url:
            pasteboard.setString(item.content, forType: .string)
        case .html:
            if let data = item.contentData {
                pasteboard.setData(data, forType: .html)
            }
        }

        os_log("📋 Clip recalled: %{public}@", log: osLog, type: .info, item.contentTypeDescription)
    }

    /// Deletes a history item.
    func deleteItem(_ item: ClipboardItem) {
        // Cancel auto-expiry timer if present
        sensitiveItemTimers[item.id]?.invalidate()
        sensitiveItemTimers.removeValue(forKey: item.id)

        Task {
            do {
                try await dataStore.deleteClipboardItem(item.id)
                await loadHistory()
                os_log("Clip deleted", log: osLog, type: .info)
            } catch {
                os_log("⚠️ Failed to delete clip: %{public}@", log: osLog, type: .error, error.localizedDescription)
            }
        }
    }

    /// Clears all history.
    func clearAllHistory() async throws {
        try await dataStore.clearAllClipboardItems()
        await loadHistory()
        os_log("History cleared", log: osLog, type: .info)
    }

    /// Toggles pinned status for an item.
    func togglePinned(_ item: ClipboardItem) {
        let newPinnedState = !item.isPinned
        Task {
            do {
                try await dataStore.updateClipboardItemPinned(item.id, isPinned: newPinnedState)
                await loadHistory()
                os_log("Clip pinned state changed: %{public}@", log: osLog, type: .info, newPinnedState ? "pinned" : "unpinned")
            } catch {
                os_log("⚠️ Failed to update pin state: %{public}@", log: osLog, type: .error, error.localizedDescription)
            }
        }
    }

    // MARK: - Sensitive Data Handling

    private func scheduleAutoExpiry(for item: ClipboardItem) {
        let timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.deleteItem(item)
            }
        }
        sensitiveItemTimers[item.id] = timer
    }

    // MARK: - Snippets Management

    /// Adds or updates a snippet.
    func saveSnippet(_ snippet: Snippet) {
        Task {
            do {
                try await dataStore.saveSnippet(snippet)
                await loadSnippets()
                os_log("Snippet saved: %{public}@", log: osLog, type: .info, snippet.title)
            } catch {
                os_log("⚠️ Failed to save snippet: %{public}@", log: osLog, type: .error, error.localizedDescription)
            }
        }
    }

    /// Deletes a snippet.
    func deleteSnippet(_ snippet: Snippet) {
        Task {
            do {
                try await dataStore.deleteSnippet(snippet.id)
                await loadSnippets()
                os_log("Snippet deleted", log: osLog, type: .info)
            } catch {
                os_log("⚠️ Failed to delete snippet: %{public}@", log: osLog, type: .error, error.localizedDescription)
            }
        }
    }

    /// Creates a snippet from a clipboard item.
    func createSnippetFromItem(_ item: ClipboardItem, title: String, folder: String? = nil, tags: [String] = []) {
        let snippet = Snippet(
            title: title,
            content: item.content,
            folder: folder,
            tags: tags
        )
        saveSnippet(snippet)
    }
}
