# Foundry Clip — Development Roadmap

Status legend: 🔲 To Do | 🟡 In Progress | ✅ Done | ⚠️ Blocked

## Phase 1: MVP (Foundation & Core Features)

### Project Setup
- 🔲 Create Xcode project (SwiftUI, macOS 13+ target)
- 🔲 Setup Git repository + gitignore
- 🔲 Create app bundle identifier (com.foundry.clip or similar)
- 🔲 Add app icon + menu bar icon (SF Symbols)
- 🔲 Setup development signing & team ID

### Core Data Models
- 🔲 Create `ClipboardItem` entity
  - timestamp: Date
  - content: String (for text)
  - contentData: Data (for binary: images, rich text)
  - contentType: String (enum: text, image, rtf, file, url, html)
  - sourceApp: String (optional, from NSPasteboard)
  - isSensitive: Bool
  - isPinned: Bool
  - size: Int64
  - changeCount: Int32 (for dedup detection)
- 🔲 Create `Snippet` entity
  - title: String
  - content: String
  - folder: String (optional)
  - tags: [String] (transient or separate Tag entity)
  - keyboardShortcut: String (optional)
  - createdDate: Date
  - updatedDate: Date
- 🔲 Create `Settings` entity
  - globalHotkey: String (default "cmd+shift+v")
  - historyLimit: Int32 (default 50)
  - autoExpireSensitive: Bool (default true)
  - sensitiveTimeout: Int32 (default 30 seconds)
  - launchAtLogin: Bool
  - runInBackground: Bool
  - theme: String (enum: light, dark, system)
  - iCloudSyncEnabled: Bool (Pro feature)
  - cloudRetention: Int32 (days, default 30)
  - ignoreApps: [String] (JSON array)
- 🔲 Setup Core Data stack in `DataStore.swift`
  - NSPersistentCloudKitContainer (for iCloud support)
  - Migration strategy for future schema changes
  - Test with in-memory store

### Clipboard Monitoring
- 🔲 Create `PasteboardMonitor` class
  - Initialize NSPasteboard.general
  - Setup DispatchSourceTimer or change notifier
  - Detect copy/cut/paste events
  - Handle all pasteboard types (NSString, NSRTF, TIFF, fileURL, HTML)
  - Call callback with ClipboardItem
- 🔲 Create `ClipboardHistory` manager
  - `addItem(ClipboardItem)` → store in Core Data
  - `fetchRecent(limit: Int)` → query Core Data
  - `deleteItem(id: UUID)` → remove from DB
  - `clearAll()` → delete all history
  - `checkDuplicate(item)` → avoid storing exact duplicates within 10s
- 🔲 Create `SensitivityDetector` class
  - Regex patterns: password, api_key, secret, token, ssh key, credit card, SSN
  - `isSensitive(String) -> Bool`
  - `detectSensitiveData(item)` → flag and mark
  - Auto-expiry timer for sensitive items

### Menu Bar App & UI Shell
- 🔲 Create `FoundryClipApp.swift` (@main entry point)
  - Setup menu bar icon (16×16 px)
  - Show app icon in menu bar
  - Click menu bar → open popover
- 🔲 Create `PopupView.swift` (main UI container)
  - Popover window (400×600 px default, resizable)
  - Tab bar: History | Snippets | Settings
  - SearchBar at top
  - Dynamic content based on active tab
  - Close on Esc, click-outside
- 🔲 Create `HistoryListView.swift`
  - Scrollable list of history items
  - Item row: icon (by type) + preview text + timestamp + pin button
  - Click item → copy to pasteboard + close popup
  - Right-click → context menu (copy, delete, pin, save as snippet)
  - Pagination: load more on scroll

### Search & Filtering (Basic)
- 🔲 Create `SearchBar.swift`
  - Text input, real-time search (debounce 100ms)
  - Basic substring matching (not fuzzy yet)
  - Filter by type (text/image/file)
- 🔲 Create `ItemPreview.swift` (detail card)
  - Show selected item in larger format
  - Text: full content, syntax highlighting if code
  - Image: full thumbnail (max 300×300)
  - File: icon + filename + size
  - Actions: copy, delete, pin, save as snippet

### Settings Panel (MVP Version)
- 🔲 Create `SettingsView.swift`
  - General: theme (light/dark/system), launch at login, run in background
  - Clipboard: history limit (50, 100, 250, 500, 1000), auto-expire sensitive (yes/no), timeout
  - Hotkey: editable field for global hotkey
  - About: version, feedback link
  - Save settings to Core Data on change
  - Reload app state when settings change (e.g., history limit)

### Global Hotkey Setup
- 🔲 Create `Hotkey.swift`
  - Register global hotkey (default ⌘⇧V)
  - Load from Settings, re-register on startup
  - On hotkey press: bring app to foreground, show popover
  - Handle hotkey changes in Settings
  - Graceful fallback if hotkey already taken (warning UI)

### Logging & Error Handling
- 🔲 Create `Logging.swift`
  - Forge language: "Honing the blade...", "Clipped.", "The forge has cooled", etc.
  - os_log integration
  - Structured logging (no sensitive data in logs)
- 🔲 Error handling throughout
  - Custom Error types (PasteboardError, DataStoreError, HotKeyError)
  - User-facing error messages (Forge language)
  - Graceful degradation (e.g., if iCloud fails, fall back to local)

### Testing (MVP)
- 🔲 Unit tests for PasteboardMonitor
  - Mock NSPasteboard, test item detection
- 🔲 Unit tests for ClipboardHistory
  - Test add, fetch, delete, clear operations
  - Test duplicate detection
- 🔲 Unit tests for SensitivityDetector
  - Test regex patterns (passwords, tokens, etc.)
- 🔲 Integration tests for Core Data
  - In-memory store, test CRUD operations
- 🔲 UI tests for PopupView
  - Test search, copy, delete, pin actions

### Documentation (MVP)
- 🔲 Update CLAUDE.md with current status
- 🔲 Write ARCHITECTURE.md (overview, data flow, key decisions)
- 🔲 Write API_REFERENCE.md (Core Data schema, public functions)

### Milestone 1: MVP Complete
- ✅ Can copy items, see them in popup, copy back to pasteboard
- ✅ Search works (basic substring)
- ✅ Settings persist
- ✅ Hotkey works (⌘⇧V opens popup)
- ✅ Free tier limit: 50 items enforced
- ✅ Sensitive data detection + auto-expiry works
- ✅ No crashes in 1-hour stress test (copy 100+ items)

---

## Phase 2: Search, Snippets, & Rich Features

### Fuzzy Search
- 🔲 Create `FuzzySearch.swift`
  - Implement fuzzy matching algorithm (levenshtein or trigram)
  - `fuzzyMatch(query: String, against items: [ClipboardItem]) -> [ClipboardItem]`
  - Ranking: recent items + pinned items ranked higher
  - Case-insensitive, accent-insensitive
- 🔲 Integrate into SearchBar
  - Real-time fuzzy search as user types
  - Update results <100ms
  - Highlight matching substrings

### Advanced Filtering
- 🔲 Extend SearchBar with filter options
  - Filter by type (text, image, file, url, html)
  - Filter by date (today, last 7 days, last 30 days, custom range)
  - Filter by source app
  - Combined filters (e.g., "images from last 7 days from Figma")
- 🔲 Pro feature gate: advanced filters only visible if Pro purchased

### Rich Preview & Rendering
- 🔲 Create `ImageProcessing.swift`
  - Generate image thumbnails (32×32 px for list, 300×300 px for preview)
  - Lazy-load full images only when selected
  - Handle HEIC, PNG, TIFF, JPEG
- 🔲 Rich text rendering
  - Detect RTF, HTML; render with formatting
  - Show first 100 characters for text items
  - Syntax highlighting for code (basic, not Highlighter.js)
- 🔲 File preview
  - Show file icon (system icon by type)
  - Filename + size
  - Drag to drop elsewhere (enable drag from popover)

### Snippets Management
- 🔲 Create `SnippetsView.swift`
  - Tab: Snippets
  - List of user-created snippets (title + folder + tags)
  - Search snippets alongside history
  - Click to copy to pasteboard
  - Right-click → Edit, Delete, Move
- 🔲 Create `SnippetEditor.swift` (modal)
  - Title input
  - Content textarea (rich text capable)
  - Folder dropdown (or create new folder inline)
  - Tags input (comma-separated, auto-complete)
  - Keyboard shortcut picker (Pro feature)
  - Save / Cancel buttons
- 🔲 Create snippet CRUD in ClipboardHistory
  - `addSnippet(Snippet)`
  - `fetchSnippets(folder: String?)` — optional folder filter
  - `updateSnippet(Snippet)`
  - `deleteSnippet(id: UUID)`
  - `searchSnippets(query: String)` — fuzzy search in snippets
- 🔲 Save history item as snippet
  - Right-click on history item → "Save as snippet"
  - Opens SnippetEditor with content pre-filled
- 🔲 Snippet folders
  - Display as tree/hierarchical list
  - Create/rename/delete folder UI in SnippetEditor
  - Limit: 5 folders free, unlimited (Pro)

### Snippet Tags
- 🔲 Tag management
  - Allow user to add tags to snippets (e.g., "swift", "boilerplate", "email")
  - Auto-complete from existing tags
  - Limit: 10 unique tags (usage unlimited)
  - Filter snippets by tag in UI
- 🔲 Tag search
  - Search snippets by tag (e.g., "tag:swift" or multi-select UI)

### Pinned Items
- 🔲 Create pinning UI
  - Pin icon on history items (click to pin/unpin)
  - Pinned items bubble to top of list
  - Separate "Pinned" section (optional visual)
  - Max 3 pinned free, unlimited (Pro)
- 🔲 Enforce pin limits
  - Free tier: warn when trying to pin >3
  - Pro: allow unlimited
  - Enforce in Core Data predicate

### Testing (Phase 2)
- 🔲 Tests for fuzzy search
  - Known query/result pairs
  - Performance test: <100ms for 5000 items
- 🔲 Tests for snippet CRUD
  - Create, read, update, delete
  - Folder/tag operations
- 🔲 Tests for rich preview
  - Image loading, thumbnail generation
  - RTF parsing, syntax highlighting
- 🔲 UI tests for snippets tab
  - Create snippet, edit, delete, copy

### Milestone 2: Search & Snippets Complete
- ✅ Fuzzy search works, <100ms even with 1000+ items
- ✅ Create/edit/delete snippets
- ✅ Snippet folders and tags
- ✅ Copy history item as snippet
- ✅ Pinned items (free tier: max 3)
- ✅ Rich preview (images, RTF, files)
- ✅ Advanced filters (Pro)

---

## Phase 3: Privacy, Features, & UX Polish

### Keyboard Shortcuts
- 🔲 Global shortcuts for pinned snippets (⌘1, ⌘2, ⌘3, etc.)
  - Load pinned snippets on startup
  - Register hotkeys for first 10 pinned snippets
  - Copy snippet to pasteboard on hotkey (don't open popup)
- 🔲 Shortcuts in popup
  - ⌘C: copy selected item
  - ⌘D: delete selected item
  - ⌘P: pin/unpin selected item
  - ⌘S: save as snippet
  - ↑/↓: navigate history/snippets
  - Esc: close popup

### Ignore Apps
- 🔲 Settings: "Ignore apps" list
  - User adds apps (e.g., "1Password", "Keychain") where clipboard won't be captured
  - Read app bundle identifier from NSPasteboard metadata
  - Skip capture if source app is in ignore list
  - Free tier: 3 ignore apps max; Pro: unlimited
- 🔲 Suggested ignore list
  - Common password managers, banking apps pre-populated
  - User can add more

### Privacy & Source App Tracking
- 🔲 Settings toggle: "Show source app"
  - Default: yes (show "from Figma", "from Xcode", etc.)
  - User can disable (privacy-focused)
  - Extract NSPasteboard source app and display in history item
- 🔲 Clear history on quit
  - Settings toggle: "Clear history on quit"
  - Default: no
  - On app exit, delete all history items if enabled

### Advanced Sensitivity Detection
- 🔲 Custom sensitive patterns (Pro feature)
  - User can add custom regex patterns (e.g., company project codes)
  - Regex validation in UI
  - Store in Settings entity
- 🔲 Regex patterns for Pro users
  - Expand beyond basic password/token detection
  - Email patterns, phone number patterns, internal codes
- 🔲 Blur preview for sensitive items
  - Sensitive items show "Sensitive clip detected" instead of content
  - User can click to reveal (with warning)

### Duplicate Detection
- 🔲 Improve duplicate detection
  - Check not just exact string match, but similar content
  - Fuzzy duplicate matching (e.g., same URL with different tracking params)
  - User setting: "Ignore duplicates" yes/no

### Status Indicator & Notifications
- 🔲 Menu bar status indicator
  - Green dot: monitoring active
  - Yellow dot: iCloud sync in progress (Pro)
  - Red dot: error state
  - Tooltip shows last item copied
- 🔲 Notifications
  - On sensitive data detection: "Sensitive clip detected — expiring in 30s"
  - On iCloud sync error (Pro): "Sync failed, retrying..."
  - On clipboard capture: optional toast notification (toggle in settings)

### Testing (Phase 3)
- 🔲 Tests for keyboard shortcuts
  - Verify hotkey registration, collision handling
- 🔲 Tests for ignore apps
  - Mock NSPasteboard source app
  - Verify skip capture
- 🔲 Tests for advanced sensitivity
  - Custom regex patterns
  - Edge cases (false positives)

### Milestone 3: Privacy & UX Polish Complete
- ✅ Keyboard shortcuts work (pinned snippets, popup shortcuts)
- ✅ Ignore apps list works (free: 3, Pro: unlimited)
- ✅ Source app tracking toggle
- ✅ Clear on quit toggle
- ✅ Custom sensitivity patterns (Pro)
- ✅ Blur for sensitive items
- ✅ Notifications work
- ✅ Status indicator in menu bar

---

## Phase 4: iCloud Sync & Monetization

### CloudKit Integration
- 🔲 Setup CloudKit container
  - Create CloudKit container in Xcode (Signing & Capabilities)
  - Add CloudKit entitlements to app
  - Generate public database schema
- 🔲 Configure NSPersistentCloudKitContainer
  - Setup in DataStore.swift
  - Enable automatic sync for ClipboardItem, Snippet entities
  - Configure conflict resolution policy
- 🔲 Test CloudKit sync
  - Sync on 2+ test Macs
  - Verify items appear within 10s on second Mac
  - Test offline (unplug network, verify local works)
  - Test reconnect (network restored, verify catch-up)

### iCloud Sync Features
- 🔲 Selective sync toggle
  - Settings: "iCloud sync" on/off
  - Only Pro users see this toggle
  - Warn user before disabling (data on cloud remains)
- 🔲 Cloud retention policy
  - Settings: Cloud retention (7, 14, 30, 90 days)
  - Cleanup job: delete items older than retention
  - Run cleanup daily at 2 AM (off-peak)
- 🔲 Sync indicator
  - Show in menu bar: "Syncing..." (yellow), "In sync" (green)
  - User can manually trigger sync (Settings button)

### Conflict Resolution
- 🔲 Last-write-wins for edits
  - If user edits same snippet on 2 Macs simultaneously
  - Keep the one with latest updateDate
  - Log conflict in debug logs
- 🔲 Append for new items
  - If different new items created on 2 Macs, both sync
  - No conflicts for new clipboard captures

### StoreKit 2 (In-App Purchase)
- 🔲 Setup StoreKit in Xcode
  - Create In-App Purchase product: "foundry-clip-pro" (subscription, annual)
  - Set price: $4.99/year (US region, adjust per region)
  - Setup App Store Connect
- 🔲 Create purchase flow
  - Button in Settings: "Upgrade to Pro" or "Manage Subscription"
  - Present StoreKit purchase UI (native)
  - Verify receipt locally or via App Store API
- 🔲 Feature gates
  - Store Pro status in Settings entity
  - Check `settings.isProUser` before allowing Pro features
  - Gates: unlimited history, iCloud sync, advanced filters, custom patterns, unlimited snippets, pinned shortcuts

### Pro Paywall & Upsell
- 🔲 Free tier limit warnings
  - User copies item #51: "Free users can save 50 items. Upgrade to Pro for unlimited." + "Upgrade" button
  - User tries to create 4th snippet (free: 3): "Upgrade to Pro for unlimited snippets." + "Upgrade" button
- 🔲 Settings upsell
  - Pro features in Settings show lock icon + "Pro" badge
  - Click to trigger upgrade flow

### Testing (Phase 4)
- 🔲 Integration test: CloudKit sync
  - Use StoreKit testing in Xcode
  - Simulate 2 Macs, verify sync
- 🔲 Unit tests: Pro feature gates
  - Mock StoreKit, verify gates work
- 🔲 Tests: In-app purchase flow
  - Test successful purchase, failed purchase, pending, user cancels

### Milestone 4: iCloud & Pro Complete
- ✅ CloudKit integration working
- ✅ iCloud sync works across 2+ Macs
- ✅ In-app purchase flow works
- ✅ Pro features properly gated
- ✅ Free tier limits enforced
- ✅ Cloud retention & cleanup working

---

## Phase 5: Polish, Performance, & App Store Release

### Performance Optimization
- 🔲 Profile search latency
  - Xcode Instruments: Time Profiler
  - Optimize fuzzy search algorithm if needed
  - Target: <100ms for 5000 items
- 🔲 Memory optimization
  - Lazy-load image thumbnails (don't load all at once)
  - Paginate history list (load 50 at a time)
  - Monitor memory with Xcode
  - Target: <200 MB idle, <500 MB with full history
- 🔲 CPU optimization
  - NSPasteboard monitoring: reduce polling frequency if needed
  - CloudKit sync: batch operations, don't sync on every change
  - Target: <5% CPU idle

### Error Handling & Edge Cases
- 🔲 Handle large items
  - Images >50 MB: warn user
  - Files: store by reference, not full copy
  - Out-of-disk-space: graceful error message
- 🔲 Handle missing data
  - Corrupted ClipboardItem: skip, log error
  - Missing source app: show "Unknown app"
  - Missing image file: show placeholder
- 🔲 Handle app crashes
  - Resume from crash gracefully
  - Don't lose data on hard shutdown
  - Test with `kill -9` and app restart

### App Store Submission
- 🔲 Code signing & entitlements
  - Verify App ID, team ID correct
  - Add entitlements: Accessibility, CloudKit, File Access
  - Test on non-development Mac (if available)
- 🔲 Privacy policy
  - Write comprehensive privacy policy
  - Upload to website (e.g., foundry.local/privacy)
  - Link in App Store metadata
- 🔲 App Store metadata
  - App name: "Foundry Clip"
  - Subtitle: "Clipboard history that remembers everything"
  - Description: Full feature list, Pro tier details
  - Keywords: clipboard, history, snippets, productivity, macOS
  - Screenshots: 5–7 showing key features (popover, snippets, settings)
  - Preview video: 15–30 seconds showing workflow
- 🔲 Testing on sandbox
  - Create sandbox Apple ID
  - Test in-app purchase flow
  - Verify StoreKit receipt validation
- 🔲 Submit to App Store
  - Build archive (Xcode: Product → Archive)
  - Upload via Xcode Organizer or App Store Connect
  - Fill in review notes (mention Accessibility permission required)
  - Wait for review (~2–5 days)

### Documentation & Marketing
- 🔲 Update all docs
  - CLAUDE.md: mark all features complete
  - ARCHITECTURE.md: final review, add performance notes
  - README.md: add App Store download link
  - API_REFERENCE.md: final API reference
- 🔲 Create marketing materials
  - Landing page: foundry.local/clip
  - Blog post: "Introducing Foundry Clip: Your Mac's Memory"
  - Social media assets: Twitter/X, Product Hunt, Reddit
  - Demo video: GIF + YouTube (30–60 seconds)
- 🔲 Launch playbook
  - Day 1: App Store release
  - Day 2–7: Social media campaign, beta feedback
  - Week 2+: Paid ads (if budget allows), press outreach

### Testing (Phase 5)
- 🔲 Full QA test plan
  - Test all features on 2–3 real Macs (different hardware)
  - Test with 1000+ items in history (performance)
  - Test iCloud sync with network interruptions
  - Test Pro purchase & feature gates
  - Accessibility testing (VoiceOver, etc.)
- 🔲 Stress testing
  - Copy 100+ items rapidly
  - Search with 5000 items
  - Sync across 3+ Macs simultaneously
  - Monitor memory/CPU
- 🔲 User acceptance testing
  - Have 5–10 beta testers use for 2 weeks
  - Collect feedback on UX, performance, bugs
  - Iterate based on feedback

### Milestone 5: App Store Release
- ✅ App passes App Store review
- ✅ All features working on real hardware
- ✅ Performance targets met (<100ms search, <5% CPU idle)
- ✅ Privacy policy published
- ✅ Marketing materials ready
- ✅ First-day app store listing live

---

## Phase 6: Post-Launch & Iteration

### Analytics & Monitoring (No Tracking)
- 🔲 Basic health monitoring (if any)
  - Crash reports via Apple (optional, user can disable)
  - No behavioral analytics (privacy-first)
  - Monitor App Store reviews for common issues

### User Feedback Loop
- 🔲 In-app feedback
  - Settings: "Send feedback" button → email form
  - In-app error reporting
- 🔲 Community engagement
  - Respond to App Store reviews
  - GitHub issues (if open-sourced)
  - Twitter/X mentions

### Bug Fixes & Maintenance
- 🔲 Patch 1.0.1, 1.0.2, etc.
  - Fix reported bugs within 2 weeks
  - Test on multiple macOS versions
  - Maintain >99% stability target

### Future Features (Post-Launch)
- 🔲 Brainstorm & prioritize
  - AirDrop integration (share clips across Macs)
  - Slack/Discord integration (share snippets)
  - Web extension (capture clips from browser)
  - Backup/restore (manual export/import)
  - Advanced analytics (Pro, opt-in)
- 🔲 Community contributions
  - If open-sourced on GitHub
  - Accept PRs, maintain contributor guide

---

## Summary Table

| Phase | Focus | Duration | Key Milestones |
|-------|-------|----------|-----------------|
| 1 | MVP: History, settings, hotkey | 2 weeks | Clipboard monitor works, popover functional |
| 2 | Search, snippets, rich features | 2 weeks | Fuzzy search <100ms, snippets CRUD complete |
| 3 | Privacy, polish, keyboard shortcuts | 2 weeks | Sensitivity detection works, UX refined |
| 4 | iCloud sync, Pro, monetization | 2 weeks | CloudKit sync working, in-app purchase functional |
| 5 | Performance, testing, App Store | 2+ weeks | App Store submission passed |
| 6 | Post-launch, bugs, iterations | Ongoing | Community feedback loop, maintenance |

**Total estimated time**: 9–12 weeks from project start to App Store launch.

---

**Last Updated**: 2026-03-15
**Status**: Scaffolding phase — all tasks pending initial implementation
