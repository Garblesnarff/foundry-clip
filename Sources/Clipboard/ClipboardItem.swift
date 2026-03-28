import Foundation

// MARK: - ClipboardItem Model

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let changeCount: Int32
    let content: String
    var contentData: Data?
    let contentType: ContentType
    let sourceApp: String?
    var isSensitive: Bool
    var isPinned: Bool
    let size: Int64
    var thumbnailData: Data?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        changeCount: Int32 = 0,
        content: String,
        contentData: Data? = nil,
        contentType: ContentType,
        sourceApp: String? = nil,
        isSensitive: Bool = false,
        isPinned: Bool = false,
        size: Int64,
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.changeCount = changeCount
        self.content = content
        self.contentData = contentData
        self.contentType = contentType
        self.sourceApp = sourceApp
        self.isSensitive = isSensitive
        self.isPinned = isPinned
        self.size = size
        self.thumbnailData = thumbnailData
    }

    enum ContentType: String, Codable {
        case text
        case richText
        case image
        case file
        case url
        case html

        var icon: String {
            switch self {
            case .text: return "doc.text"
            case .richText: return "doc.richtext"
            case .image: return "photo"
            case .file: return "folder"
            case .url: return "link"
            case .html: return "globe"
            }
        }
    }

    var contentTypeDescription: String {
        switch contentType {
        case .text: return "text"
        case .richText: return "rich text"
        case .image: return "image"
        case .file: return "file"
        case .url: return "URL"
        case .html: return "HTML"
        }
    }

    var preview: String {
        if isSensitive {
            return "🔒 Sensitive clip — expiring soon"
        }
        let maxLength = 100
        return content.count > maxLength ? String(content.prefix(maxLength)) + "…" : content
    }

    var formattedSize: String {
        if size < 1024 {
            return "\(size) B"
        } else if size < 1024 * 1024 {
            return String(format: "%.1f KB", Double(size) / 1024)
        } else {
            return String(format: "%.1f MB", Double(size) / (1024 * 1024))
        }
    }
}
