import Foundation
import CoreData
import os.log

/// Centralized Core Data manager for Foundry Clip.
/// Handles persistence to local SQLite and iCloud sync via CloudKit.
final class DataStoreController {
    static let shared = DataStoreController()

    let container: NSPersistentContainer

    private init() {
        // Load Core Data model from bundle
        if let modelURL = Bundle.main.url(forResource: "FoundryClip", withExtension: "momd"),
           let model = NSManagedObjectModel(contentsOf: modelURL) {
            container = NSPersistentContainer(name: "FoundryClip", managedObjectModel: model)
        } else {
            // Fallback: create model programmatically
            let model = DataStoreController.createManagedObjectModel()
            container = NSPersistentContainer(name: "FoundryClip", managedObjectModel: model)
        }

        // Configure for iCloud sync (CloudKit)
        let description = container.persistentStoreDescriptions.first
        description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.foundry.clip"
        )

        // Setup container
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                os_log("⚠️ Core Data load failed: %{public}@", log: osLog, type: .error, error.localizedDescription)
            } else {
                os_log("Core Data initialized at: %{public}@", log: osLog, type: .info, storeDescription.url?.path ?? "unknown")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // ClipboardItemEntity
        let clipboardItem = NSEntityDescription()
        clipboardItem.name = "ClipboardItemEntity"
        clipboardItem.managedObjectClassName = "ClipboardItemEntity"

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType

        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"
        timestampAttr.attributeType = .dateAttributeType

        let changeCountAttr = NSAttributeDescription()
        changeCountAttr.name = "changeCount"
        changeCountAttr.attributeType = .integer32AttributeType
        changeCountAttr.defaultValue = 0

        let contentAttr = NSAttributeDescription()
        contentAttr.name = "content"
        contentAttr.attributeType = .stringAttributeType

        let contentDataAttr = NSAttributeDescription()
        contentDataAttr.name = "contentData"
        contentDataAttr.attributeType = .binaryDataAttributeType
        contentDataAttr.allowsExternalBinaryDataStorage = true

        let contentTypeAttr = NSAttributeDescription()
        contentTypeAttr.name = "contentType"
        contentTypeAttr.attributeType = .stringAttributeType

        let sourceAppAttr = NSAttributeDescription()
        sourceAppAttr.name = "sourceApp"
        sourceAppAttr.attributeType = .stringAttributeType
        sourceAppAttr.isOptional = true

        let isSensitiveAttr = NSAttributeDescription()
        isSensitiveAttr.name = "isSensitive"
        isSensitiveAttr.attributeType = .booleanAttributeType
        isSensitiveAttr.defaultValue = false

        let isPinnedAttr = NSAttributeDescription()
        isPinnedAttr.name = "isPinned"
        isPinnedAttr.attributeType = .booleanAttributeType
        isPinnedAttr.defaultValue = false

        let sizeAttr = NSAttributeDescription()
        sizeAttr.name = "size"
        sizeAttr.attributeType = .integer64AttributeType
        sizeAttr.defaultValue = 0

        let thumbnailDataAttr = NSAttributeDescription()
        thumbnailDataAttr.name = "thumbnailData"
        thumbnailDataAttr.attributeType = .binaryDataAttributeType
        thumbnailDataAttr.isOptional = true

        clipboardItem.properties = [idAttr, timestampAttr, changeCountAttr, contentAttr, contentDataAttr, contentTypeAttr, sourceAppAttr, isSensitiveAttr, isPinnedAttr, sizeAttr, thumbnailDataAttr]

        // SnippetEntity
        let snippet = NSEntityDescription()
        snippet.name = "SnippetEntity"
        snippet.managedObjectClassName = "SnippetEntity"

        let snippetIdAttr = NSAttributeDescription()
        snippetIdAttr.name = "id"
        snippetIdAttr.attributeType = .UUIDAttributeType

        let snippetTitleAttr = NSAttributeDescription()
        snippetTitleAttr.name = "title"
        snippetTitleAttr.attributeType = .stringAttributeType

        let snippetContentAttr = NSAttributeDescription()
        snippetContentAttr.name = "content"
        snippetContentAttr.attributeType = .stringAttributeType

        let snippetFolderAttr = NSAttributeDescription()
        snippetFolderAttr.name = "folder"
        snippetFolderAttr.attributeType = .stringAttributeType
        snippetFolderAttr.isOptional = true

        let snippetTagsAttr = NSAttributeDescription()
        snippetTagsAttr.name = "tags"
        snippetTagsAttr.attributeType = .transformableAttributeType
        snippetTagsAttr.valueTransformerName = "NSSecureUnarchiveFromData"
        snippetTagsAttr.isOptional = true

        let snippetKeyboardShortcutAttr = NSAttributeDescription()
        snippetKeyboardShortcutAttr.name = "keyboardShortcut"
        snippetKeyboardShortcutAttr.attributeType = .stringAttributeType
        snippetKeyboardShortcutAttr.isOptional = true

        let snippetCreatedDateAttr = NSAttributeDescription()
        snippetCreatedDateAttr.name = "createdDate"
        snippetCreatedDateAttr.attributeType = .dateAttributeType

        let snippetUpdatedDateAttr = NSAttributeDescription()
        snippetUpdatedDateAttr.name = "updatedDate"
        snippetUpdatedDateAttr.attributeType = .dateAttributeType

        snippet.properties = [snippetIdAttr, snippetTitleAttr, snippetContentAttr, snippetFolderAttr, snippetTagsAttr, snippetKeyboardShortcutAttr, snippetCreatedDateAttr, snippetUpdatedDateAttr]

        // SettingsEntity
        let settings = NSEntityDescription()
        settings.name = "SettingsEntity"
        settings.managedObjectClassName = "SettingsEntity"

        let settingsIdAttr = NSAttributeDescription()
        settingsIdAttr.name = "id"
        settingsIdAttr.attributeType = .UUIDAttributeType

        let globalHotkeyAttr = NSAttributeDescription()
        globalHotkeyAttr.name = "globalHotkey"
        globalHotkeyAttr.attributeType = .stringAttributeType
        globalHotkeyAttr.defaultValue = "cmd+shift+v"

        let historyLimitAttr = NSAttributeDescription()
        historyLimitAttr.name = "historyLimit"
        historyLimitAttr.attributeType = .integer32AttributeType
        historyLimitAttr.defaultValue = 50

        let autoExpireSensitiveAttr = NSAttributeDescription()
        autoExpireSensitiveAttr.name = "autoExpireSensitive"
        autoExpireSensitiveAttr.attributeType = .booleanAttributeType
        autoExpireSensitiveAttr.defaultValue = true

        let sensitiveTimeoutAttr = NSAttributeDescription()
        sensitiveTimeoutAttr.name = "sensitiveTimeout"
        sensitiveTimeoutAttr.attributeType = .integer32AttributeType
        sensitiveTimeoutAttr.defaultValue = 30

        let launchAtLoginAttr = NSAttributeDescription()
        launchAtLoginAttr.name = "launchAtLogin"
        launchAtLoginAttr.attributeType = .booleanAttributeType
        launchAtLoginAttr.defaultValue = false

        let runInBackgroundAttr = NSAttributeDescription()
        runInBackgroundAttr.name = "runInBackground"
        runInBackgroundAttr.attributeType = .booleanAttributeType
        runInBackgroundAttr.defaultValue = true

        let themeAttr = NSAttributeDescription()
        themeAttr.name = "theme"
        themeAttr.attributeType = .stringAttributeType
        themeAttr.defaultValue = "dark"

        let iCloudSyncEnabledAttr = NSAttributeDescription()
        iCloudSyncEnabledAttr.name = "iCloudSyncEnabled"
        iCloudSyncEnabledAttr.attributeType = .booleanAttributeType
        iCloudSyncEnabledAttr.defaultValue = false

        let cloudRetentionAttr = NSAttributeDescription()
        cloudRetentionAttr.name = "cloudRetention"
        cloudRetentionAttr.attributeType = .integer32AttributeType
        cloudRetentionAttr.defaultValue = 30

        let showSourceAppAttr = NSAttributeDescription()
        showSourceAppAttr.name = "showSourceApp"
        showSourceAppAttr.attributeType = .booleanAttributeType
        showSourceAppAttr.defaultValue = true

        let clearHistoryOnQuitAttr = NSAttributeDescription()
        clearHistoryOnQuitAttr.name = "clearHistoryOnQuit"
        clearHistoryOnQuitAttr.attributeType = .booleanAttributeType
        clearHistoryOnQuitAttr.defaultValue = false

        let blurSensitivePreviewsAttr = NSAttributeDescription()
        blurSensitivePreviewsAttr.name = "blurSensitivePreviews"
        blurSensitivePreviewsAttr.attributeType = .booleanAttributeType
        blurSensitivePreviewsAttr.defaultValue = true

        let ignoreAppsAttr = NSAttributeDescription()
        ignoreAppsAttr.name = "ignoreApps"
        ignoreAppsAttr.attributeType = .transformableAttributeType
        ignoreAppsAttr.valueTransformerName = "NSSecureUnarchiveFromData"
        ignoreAppsAttr.isOptional = true

        settings.properties = [settingsIdAttr, globalHotkeyAttr, historyLimitAttr, autoExpireSensitiveAttr, sensitiveTimeoutAttr, launchAtLoginAttr, runInBackgroundAttr, themeAttr, iCloudSyncEnabledAttr, cloudRetentionAttr, showSourceAppAttr, clearHistoryOnQuitAttr, blurSensitivePreviewsAttr, ignoreAppsAttr]

        model.entities = [clipboardItem, snippet, settings]
        return model
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                os_log("⚠️ Core Data save failed: %{public}@", log: osLog, type: .error, error.localizedDescription)
            }
        }
    }
}

// MARK: - DataStore Singleton (API Compatibility)

final class DataStore {
    static let shared = DataStore()
    private let controller = DataStoreController.shared

    private init() {}

    // MARK: - Clipboard Items

    func saveClipboardItem(_ item: ClipboardItem) async throws {
        let context = controller.newBackgroundContext()
        try await context.perform {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "ClipboardItemEntity", into: context)
            entity.setValue(item.id, forKey: "id")
            entity.setValue(item.timestamp, forKey: "timestamp")
            entity.setValue(item.changeCount, forKey: "changeCount")
            entity.setValue(item.content, forKey: "content")
            entity.setValue(item.contentData, forKey: "contentData")
            entity.setValue(item.contentType.rawValue, forKey: "contentType")
            entity.setValue(item.sourceApp, forKey: "sourceApp")
            entity.setValue(item.isSensitive, forKey: "isSensitive")
            entity.setValue(item.isPinned, forKey: "isPinned")
            entity.setValue(item.size, forKey: "size")
            entity.setValue(item.thumbnailData, forKey: "thumbnailData")

            try context.save()
            os_log("Clipboard item saved: %{public}@", log: osLog, type: .debug, item.id.uuidString)
        }
    }

    func fetchClipboardItems(limit: Int32) async throws -> [ClipboardItem] {
        let context = controller.viewContext
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "ClipboardItemEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            request.fetchLimit = Int(limit)

            let results = try context.fetch(request)
            return results.compactMap { entity -> ClipboardItem? in
                guard let id = entity.value(forKey: "id") as? UUID,
                      let timestamp = entity.value(forKey: "timestamp") as? Date,
                      let content = entity.value(forKey: "content") as? String,
                      let contentTypeRaw = entity.value(forKey: "contentType") as? String,
                      let contentType = ClipboardItem.ContentType(rawValue: contentTypeRaw) else {
                    return nil
                }

                let changeCount = entity.value(forKey: "changeCount") as? Int32 ?? 0
                let contentData = entity.value(forKey: "contentData") as? Data
                let sourceApp = entity.value(forKey: "sourceApp") as? String
                let isSensitive = entity.value(forKey: "isSensitive") as? Bool ?? false
                let isPinned = entity.value(forKey: "isPinned") as? Bool ?? false
                let size = entity.value(forKey: "size") as? Int64 ?? 0
                let thumbnailData = entity.value(forKey: "thumbnailData") as? Data

                return ClipboardItem(
                    id: id,
                    timestamp: timestamp,
                    changeCount: changeCount,
                    content: content,
                    contentData: contentData,
                    contentType: contentType,
                    sourceApp: sourceApp,
                    isSensitive: isSensitive,
                    isPinned: isPinned,
                    size: size,
                    thumbnailData: thumbnailData
                )
            }
        }
    }

    func deleteClipboardItem(_ id: UUID) async throws {
        let context = controller.newBackgroundContext()
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "ClipboardItemEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            if let results = try? context.fetch(request), let entity = results.first {
                context.delete(entity)
                try context.save()
            }
        }
    }

    func clearAllClipboardItems() async throws {
        let context = controller.newBackgroundContext()
        try await context.perform {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ClipboardItemEntity")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try context.execute(deleteRequest)
            try context.save()
        }
    }

    func updateClipboardItemPinned(_ id: UUID, isPinned: Bool) async throws {
        let context = controller.newBackgroundContext()
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "ClipboardItemEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            if let results = try? context.fetch(request), let entity = results.first {
                entity.setValue(isPinned, forKey: "isPinned")
                try context.save()
            }
        }
    }

    // MARK: - Snippets

    func saveSnippet(_ snippet: Snippet) async throws {
        let context = controller.newBackgroundContext()
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "SnippetEntity")
            request.predicate = NSPredicate(format: "id == %@", snippet.id as CVarArg)

            let entity: NSManagedObject
            if let existing = try? context.fetch(request).first {
                entity = existing
            } else {
                entity = NSEntityDescription.insertNewObject(forEntityName: "SnippetEntity", into: context)
                entity.setValue(snippet.id, forKey: "id")
                entity.setValue(snippet.createdDate, forKey: "createdDate")
            }

            entity.setValue(snippet.title, forKey: "title")
            entity.setValue(snippet.content, forKey: "content")
            entity.setValue(snippet.folder, forKey: "folder")
            entity.setValue(snippet.tags as NSArray, forKey: "tags")
            entity.setValue(snippet.keyboardShortcut, forKey: "keyboardShortcut")
            entity.setValue(snippet.updatedDate, forKey: "updatedDate")

            try context.save()
        }
    }

    func fetchSnippets(folder: String? = nil) async throws -> [Snippet] {
        let context = controller.viewContext
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "SnippetEntity")
            if let folder = folder {
                request.predicate = NSPredicate(format: "folder == %@", folder)
            }
            request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]

            let results = try context.fetch(request)
            return results.compactMap { entity -> Snippet? in
                guard let id = entity.value(forKey: "id") as? UUID,
                      let title = entity.value(forKey: "title") as? String,
                      let content = entity.value(forKey: "content") as? String,
                      let createdDate = entity.value(forKey: "createdDate") as? Date,
                      let updatedDate = entity.value(forKey: "updatedDate") as? Date else {
                    return nil
                }

                let folder = entity.value(forKey: "folder") as? String
                let tagsArray = entity.value(forKey: "tags") as? [String] ?? []
                let keyboardShortcut = entity.value(forKey: "keyboardShortcut") as? String

                return Snippet(
                    id: id,
                    createdDate: createdDate,
                    updatedDate: updatedDate,
                    title: title,
                    content: content,
                    folder: folder,
                    tags: tagsArray,
                    keyboardShortcut: keyboardShortcut
                )
            }
        }
    }

    func deleteSnippet(_ id: UUID) async throws {
        let context = controller.newBackgroundContext()
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "SnippetEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            if let results = try? context.fetch(request), let entity = results.first {
                context.delete(entity)
                try context.save()
            }
        }
    }

    // MARK: - Settings

    func fetchOrCreateSettings() async throws -> Settings {
        let context = controller.viewContext
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "SettingsEntity")
            request.fetchLimit = 1

            if let entity = try context.fetch(request).first {
                return Settings.from(entity: entity)
            } else {
                // Create default settings
                let entity = NSEntityDescription.insertNewObject(forEntityName: "SettingsEntity", into: context)
                let settings = Settings()
                settings.apply(to: entity)
                try context.save()
                return settings
            }
        }
    }

    func updateSettings(_ settings: Settings) async throws {
        let context = controller.newBackgroundContext()
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "SettingsEntity")
            request.predicate = NSPredicate(format: "id == %@", settings.id as CVarArg)

            let entity: NSManagedObject
            if let existing = try context.fetch(request).first {
                entity = existing
            } else {
                entity = NSEntityDescription.insertNewObject(forEntityName: "SettingsEntity", into: context)
            }

            settings.apply(to: entity)
            try context.save()
        }
    }

    // MARK: - Sync

    func syncWithiCloud() async throws {
        // CloudKit sync is automatic with NSPersistentCloudKitContainer
        controller.saveContext()
        os_log("iCloud sync triggered", log: osLog, type: .info)
    }

    // MARK: - Cleanup

    func deleteItemsOlderThan(days: Int) async throws {
        let context = controller.newBackgroundContext()
        let cutoffDate = Date(timeIntervalSinceNow: -Double(days * 24 * 3600))
        try await context.perform {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ClipboardItemEntity")
            request.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as CVarArg)

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try context.execute(deleteRequest)
            try context.save()
        }
    }
}

// MARK: - Snippet Model

struct Snippet: Identifiable, Codable, Equatable {
    let id: UUID
    let createdDate: Date
    var updatedDate: Date
    var title: String
    var content: String
    var folder: String?
    var tags: [String] = []
    var keyboardShortcut: String?

    init(
        id: UUID = UUID(),
        createdDate: Date = Date(),
        updatedDate: Date = Date(),
        title: String,
        content: String,
        folder: String? = nil,
        tags: [String] = [],
        keyboardShortcut: String? = nil
    ) {
        self.id = id
        self.createdDate = createdDate
        self.updatedDate = updatedDate
        self.title = title
        self.content = content
        self.folder = folder
        self.tags = tags
        self.keyboardShortcut = keyboardShortcut
    }

    var preview: String {
        let maxLength = 100
        return content.count > maxLength ? String(content.prefix(maxLength)) + "…" : content
    }
}
