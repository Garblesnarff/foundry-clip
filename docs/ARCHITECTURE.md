# Foundry Clip — Architecture & Technical Deep Dive

## System Overview

```
┌─────────────────────────────────────────────────────┐
│         macOS Menu Bar Application                 │
│  (Runs in background, accessible via ⌘⇧V)         │
└─────────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
    ┌────────┐   ┌──────────────┐   ┌──────────┐
    │UI Layer│   │ Business     │   │ Persistence
    │        │   │ Logic        │   │ & Sync
    │Views   │   │              │   │
    │        │   │ Managers     │   │ Core Data
    └────────┘   │              │   │ CloudKit
                 │ Services     │   │ SQLite
                 └──────────────┘   └──────────┘
```

## Architecture Layers

### 1. UI Layer (SwiftUI Views)

**Location**: `Sources/Views/`, `Sources/ContentView.swift`

**Key files**:
- `ContentView.swift`: Main popover container, tab management
- `HistoryListView.swift`: Scrollable history list
- `SnippetsView.swift`: Snippets tab UI
- `SettingsView.swift`: Settings & preferences panel
- `Components/`: Reusable UI components (buttons, icons, etc.)

**Responsibilities**:
- Display UI (popover window, tabs, lists, inputs)
- React to user interactions (clicks, typing, etc.)
- Bind to observable managers (ClipboardManager, SettingsManager)
- Use SwiftUI modifiers for styling (Forge design system)

**Data flow (UI → Business)**:
1. User clicks item in HistoryListView
2. View calls `clipboardManager.copyItemToPasteboard(item)`
3. Manager updates clipboard, view updates state
4. Popover closes (handled by AppDelegate)

### 2. Business Logic Layer

**Location**: `Sources/ClipboardManager.swift`, `Sources/SettingsManager.swift`, `Sources/SensitivityDetector.swift`

#### ClipboardManager
- **Responsibilities**:
  - Monitor NSPasteboard for changes (via timer)
  - Extract clipboard items (text, images, files, etc.)
  - Detect duplicates and sensitive data
  - Schedule auto-expiry for sensitive items
  - Store/retrieve items from Core Data
  - Copy items back to pasteboard
  - Manage history with limits (free/Pro)

- **Key methods**:
  - `startMonitoring()`: Begin polling clipboard
  - `stopMonitoring()`: Stop monitoring
  - `checkPasteboard()`: Poll loop, detect changes
  - `extractClipboardItem()`: Parse all pasteboard types
  - `addHistoryItem()`: Store to Core Data
  - `copyItemToPasteboard()`: Restore item to clipboard
  - `deleteItem()`, `clearAllHistory()`: History cleanup

- **Threading**: Main thread for UI updates, background for Core Data

#### SettingsManager
- **Responsibilities**:
  - Load/save user preferences (Core Data)
  - Manage Pro tier status
  - Gate Pro features (iCloud, unlimited history, etc.)
  - Notify views of setting changes (@Published)

- **Key settings**:
  - `globalHotkey`: Editable hotkey (default ⌘⇧V)
  - `historyLimit`: Free (50), Pro (1000+)
  - `autoExpireSensitive`: Toggle sensitive auto-delete
  - `sensitiveTimeout`: Duration before deletion (default 30s)
  - `iCloudSyncEnabled`: Pro feature toggle
  - `ignoreApps`: Bundle IDs to skip monitoring

#### SensitivityDetector
- **Responsibilities**:
  - Match text against regex patterns (passwords, tokens, SSH keys, etc.)
  - Flag sensitive items
  - Provide match details (pattern name, severity)

- **Patterns**:
  - Password: `(?:password|pwd|passcode|passwd)\s*[=:]`
  - API key: `(?:api[_-]?key|apikey|api_secret|secret[_-]?key)\s*[=:]`
  - Bearer token: `(?:bearer|token|auth[_-]?token)\s+[A-Za-z0-9\-._~+/]+=*`
  - SSH key: `-----BEGIN.*KEY-----`
  - Credit card: `\b\d{13,19}\b`
  - SSN: `\b\d{3}-\d{2}-\d{4}\b`

### 3. Data Layer (Core Data + CloudKit)

**Location**: `Sources/DataStore.swift`, `Sources/Models/`

#### DataStore (Singleton)
- **Responsibilities**:
  - Initialize NSPersistentCloudKitContainer
  - Provide CRUD operations for ClipboardItem, Snippet, Settings
  - Handle iCloud sync via CloudKit
  - Manage background contexts (thread safety)
  - Implement conflict resolution for sync

- **Methods**:
  - `saveClipboardItem(item)`: Insert or update
  - `fetchClipboardItems(limit)`: Query with limit
  - `deleteClipboardItem(id)`: Remove from DB
  - `clearAllClipboardItems()`: Batch delete
  - `syncWithiCloud()`: Trigger manual sync
  - `deleteItemsOlderThan(days)`: Cleanup (scheduled)

#### Core Data Models

**ClipboardItem** (NSManagedObject)
```
- id: UUID (primary key)
- timestamp: Date (indexed for sorting)
- changeCount: Int32 (for dedup)
- content: String (text content)
- contentData: Data (binary: images, RTF, HTML)
- contentType: String (enum: text, richText, image, file, url, html)
- sourceApp: String (optional, app bundle ID)
- isSensitive: Bool (flagged by detector)
- isPinned: Bool (user-pinned)
- size: Int64 (content size in bytes)
```

**Snippet** (NSManagedObject)
```
- id: UUID (primary key)
- title: String (required)
- content: String (required)
- folder: String (optional, for hierarchy)
- tags: [String] (transient or separate Tag entity)
- keyboardShortcut: String (optional, Pro feature)
- createdDate: Date
- updatedDate: Date
```

**Settings** (NSManagedObject, singleton)
```
- id: UUID
- globalHotkey: String
- historyLimit: Int32
- autoExpireSensitive: Bool
- sensitiveTimeout: Int32
- launchAtLogin: Bool
- runInBackground: Bool
- theme: String (light/dark/system)
- iCloudSyncEnabled: Bool
- cloudRetention: Int32 (days)
- showSourceApp: Bool
- clearHistoryOnQuit: Bool
- blurSensitivePreviews: Bool
- ignoreApps: [String] (JSON-serialized)
```

#### CloudKit Integration (iCloud Sync)

**NSPersistentCloudKitContainer** automatically:
- Syncs Core Data changes to CloudKit
- Merges remote changes from CloudKit
- Handles offline → online transitions
- Manages conflict resolution (last-write-wins by default)

**Configuration**:
- Container identifier: `iCloud.com.foundry.clip`
- Public database: Off (no sharing)
- Private database: On (user's data only)
- Encrypted: Yes (CloudKit default)

**Conflict Resolution**:
- Editing conflict (same item edited on 2 Macs): Last-write-wins (timestamp)
- Addition conflict (new items on 2 Macs): Both synced (append)
- Deletion conflict (delete on one Mac, edit on other): Deletion wins

## Data Flow Diagrams

### Clipboard Capture Flow
```
1. Timer.scheduledTimer (every 0.5s)
   ↓
2. checkPasteboard()
   - Read NSPasteboard.changeCount
   - If changed: extractClipboardItem()
   ↓
3. extractClipboardItem()
   - Check pasteboard types (NSString, NSRTF, TIFF, fileURL, HTML)
   - Extract content + metadata (source app, size, timestamp)
   ↓
4. SensitivityDetector.isSensitive()
   - Match content against regex patterns
   - Flag if password, token, API key, etc.
   ↓
5. isDuplicate()
   - Compare with last item
   - Skip if identical within 10s
   ↓
6. addHistoryItem()
   - Create ClipboardItem object
   - Save to Core Data via DataStore
   - Update @Published historyItems (UI refresh)
   ↓
7. (If sensitive) scheduleAutoExpiry()
   - DispatchQueue.main.asyncAfter(30s)
   - deleteItem() → Core Data deletion
```

### Copy-Back Flow
```
1. User clicks history item in UI
   ↓
2. HistoryListView calls clipboardManager.copyItemToPasteboard(item)
   ↓
3. ClipboardManager.copyItemToPasteboard()
   - Clear NSPasteboard
   - Switch on item.contentType
   - Restore content to pasteboard
   ↓
4. Item is now in system clipboard
   - User can ⌘V in any app
   ↓
5. Popover closes (UI responsibility)
```

### iCloud Sync Flow
```
1. User enables iCloud sync in Settings (Pro only)
   ↓
2. Core Data observes changes (saveClipboardItem, etc.)
   ↓
3. NSPersistentCloudKitContainer detects change
   ↓
4. CloudKit sync (automatic, batched every few seconds)
   - Uploads new ClipboardItems to iCloud
   - Uploads Snippet changes
   - Uploads Settings changes
   ↓
5. On second Mac with app open:
   - CloudKit push notification received
   - Core Data merges remote changes
   - @Published properties update
   - UI refreshes automatically
   ↓
6. Conflict resolution (if same item edited on both Macs)
   - Timestamp comparison
   - Last-write-wins applied
```

## Threading Model

### Main Thread (UI Updates)
- All UI work: views, SwiftUI state, @Published updates
- Global hotkey registration
- NSPasteboard reads (should be fast)

### Background Threads (DataStore)
- Core Data: Always use `newBackgroundContext()` for writes
- iCloud sync: CloudKit handles its own threads
- Sensitive data timer: DispatchQueue.main.asyncAfter

### Key Pattern
```swift
@MainActor
final class ClipboardManager: ObservableObject {
    @Published var historyItems: [ClipboardItem] = []

    func addHistoryItem(_ item: ClipboardItem) {
        Task {
            try await dataStore.saveClipboardItem(item)
            await loadHistory() // Back to main thread
        }
    }
}
```

## Performance Optimizations

### Search (Fuzzy Matching)
- **Algorithm**: Levenshtein distance or trigram-based
- **Target**: <100ms for 5000 items
- **Optimization**: Only search text/URL types, skip large items
- **Caching**: Cache search results (debounce 100ms)

### Image Thumbnails
- **Generation**: Lazy-load, background thread
- **Size**: 32×32pt (list view), 300×300pt (preview)
- **Caching**: Store in Core Data as Data blob
- **Avoid**: Never render full-resolution images in lists

### Clipboard Polling
- **Interval**: 0.5 seconds (not 10ms, too frequent)
- **Batching**: Group multiple copies into single batch if within 1s
- **Filtering**: Skip if changeCount unchanged

### Core Data
- **Indexing**: Index on `timestamp` and `isPinned` for sorting
- **Predicates**: Use efficient NSPredicate (e.g., `timestamp > date`)
- **Fetching**: Batch fetch with `fetchLimit`, `fetchOffset`
- **Memory**: Faulting enabled (unload unused objects)

### iCloud Sync
- **Batching**: CloudKit batches changes automatically (every few seconds)
- **Selective**: Only sync if user enables (Pro feature)
- **Offline**: Works locally, syncs when reconnected
- **Conflict**: Rare (last-write-wins resolution fast)

## Error Handling Strategy

### User-Facing Errors (Alerts)
```swift
do {
    try await clipboardManager.startMonitoring()
} catch {
    // Show alert: "The forge could not be lit: [error]"
}
```

### Silent Failures (Logging)
```swift
guard let item = extractClipboardItem() else {
    os_log("⚠️ Could not extract clipboard item", log: osLog, type: .warning)
    return // Continue monitoring, don't crash
}
```

### Sensitive Data Warnings (UI Badge)
```swift
if item.isSensitive {
    // Show red "lock" icon + expiry countdown
}
```

### iCloud Sync Errors (Status Indicator)
```swift
Task {
    do {
        try await dataStore.syncWithiCloud()
    } catch {
        // Show yellow status in menu bar
        // Auto-retry in background
    }
}
```

## Security Considerations

### Sensitive Data
- **Detection**: Regex patterns (passwords, tokens, SSH keys)
- **Storage**: Flagged in Core Data (isSensitive = true)
- **Display**: Blurred preview until user clicks
- **Expiry**: Auto-delete after 30 seconds (configurable)
- **Sync**: NOT synced to iCloud (sensitive items deleted before sync)

### File Handling
- **Large files**: Store by reference (fileURL), not full copy
- **Sandboxing**: Use Foundation APIs only (no shell scripts)
- **Permissions**: Respect file access (don't copy restricted files)

### Encryption
- **Local**: FileVault (user controls, not our code)
- **iCloud**: CloudKit default encryption (encrypted at rest, in transit)
- **Passwords**: Never stored in logs, only flagged with "[redacted]"

### Privacy
- **Analytics**: None (privacy-first)
- **Logs**: No sensitive content logged (use `[redacted]`)
- **Network**: Only iCloud (optional, Pro feature)
- **User control**: Clear history, ignore apps, disable sync

## Extension Points (Future)

### Plugins
- Custom sensitivity patterns (Pro feature)
- Custom sync backends (replace CloudKit)
- Custom keyboard shortcut handlers

### Integrations
- Slack: Share snippet to Slack channel
- GitHub Gist: Backup snippets to Gist
- Web extension: Capture web clippings
- iOS app: Access history on iPhone/iPad (future)

## Testing Strategy

### Unit Tests
- `PasteboardMonitor`: Mock NSPasteboard, verify change detection
- `SensitivityDetector`: Known regex patterns, test edge cases
- `FuzzySearch`: Known query/result pairs, latency benchmarks
- `DataStore`: In-memory Core Data store

### Integration Tests
- iCloud sync: 2 Core Data stores, sync across
- Full pipeline: Copy item, search, restore, delete

### UI Tests
- Popover open/close
- Tab navigation
- Search typing + filtering
- Copy to pasteboard

### Performance Tests
- Search latency: 5000 items < 100ms
- Memory: Idle < 200 MB, full history < 500 MB
- CPU: Idle < 5%, monitoring < 10%

## Deployment

### App Store
- Code signing: Standard (Developer ID)
- Entitlements: Accessibility, CloudKit
- Privacy policy: Required before launch
- Screenshots: 5–7 showing key features

### Versioning
- Semantic: MAJOR.MINOR.PATCH
- E.g., 1.0.0 (MVP), 1.1.0 (snippets), 2.0.0 (major UI redesign)

### Feedback Loop
- Crash reports: Apple provided (user opt-in)
- Reviews: Monitor App Store ratings
- Bugs: GitHub issues (if open-sourced) or email

---

**Last Updated**: 2026-03-15
**Version**: 1.0 (MVP scaffolding)
