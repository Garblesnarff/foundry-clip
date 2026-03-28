# Foundry Clip — Clipboard History + Snippets Manager

## What This Is

**Foundry Clip** is a native macOS clipboard history and snippets manager built for developers, writers, and power users. It captures everything you copy (text, images, rich text, files, URLs), makes it searchable with fuzzy matching, and provides instant recall via a global hotkey (⌘⇧V). Think of it as Windows' Win+V clipboard manager but deeply integrated with macOS, with iCloud sync, sensitive data protection, and rich snippet management.

## Problem & Target

**Problem**: macOS clipboard is ephemeral. You copy something, close your app, and it's gone forever. Developers switch contexts constantly; writers juggle quotes and snippets across projects.

**Target Users**:
- Software developers (context switching, code snippets, commands)
- Writers & journalists (quotes, research snippets, boilerplate text)
- Designers & creatives (color codes, URLs, asset paths)
- Power users who copy 100+ items daily

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Platform** | macOS 13+ (Apple Silicon native) | M1/M2/M3/M4 optimized, native performance |
| **UI Framework** | SwiftUI (iOS/macOS unified) | Modern, responsive, system-native look |
| **Build System** | Xcode 15+ | Native build, App Store / direct distribution |
| **Core Features** | Foundation APIs | NSPasteboard monitoring, Core Data, Spotlight search |
| **Sync** | CloudKit (iCloud) | Encrypted cloud sync for history & snippets |
| **Database** | Core Data + SQLite | Local persistence + iCloud sync |
| **Hotkey** | Keyboard Maestro / SwiftKeys | Global ⌘⇧V activation (or user-configurable) |

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│              macOS Menu Bar Application                    │
│  (Lives in menu bar, global hotkey ⌘⇧V opens popover)    │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │            SwiftUI Popover Window                   │ │
│  │  ┌────────────────────────────────────────────────┐ │ │
│  │  │ Search Bar (Spotlight-style fuzzy search)      │ │ │
│  │  └────────────────────────────────────────────────┘ │ │
│  │  ┌────────────────────────────────────────────────┐ │ │
│  │  │ Clipboard History (scrollable, thumbnails)    │ │ │
│  │  │  • Item 1 (text) — pinned                     │ │ │
│  │  │  • Item 2 (image) — 32x32 px thumbnail       │ │ │
│  │  │  • Item 3 (RTF) — first 100 chars            │ │ │
│  │  │  • [Load More...]                             │ │ │
│  │  └────────────────────────────────────────────────┘ │ │
│  │  ┌────────────────────────────────────────────────┐ │ │
│  │  │ Snippets (Pinned / Folders / Tags)            │ │ │
│  │  │  • "import Foundation" — Swift boilerplate   │ │ │
│  │  │  • "—" — email signature                      │ │ │
│  │  │  • [+ New Snippet]                            │ │ │
│  │  └────────────────────────────────────────────────┘ │ │
│  │  ┌────────────────────────────────────────────────┐ │ │
│  │  │ Tabs: History | Snippets | Settings           │ │ │
│  │  └────────────────────────────────────────────────┘ │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
├────────────────────────────────────────────────────────────┤
│ Background Daemon (Core Components Below)                │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │        Clipboard Monitor (NSPasteboard)            │ │
│  │  • Detects copy/cut/paste events                  │ │
│  │  • Filters: sensitive data, duplicates, size     │ │
│  │  • Stores in Core Data (local)                   │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │        Core Data + iCloud Sync (CloudKit)         │ │
│  │  • History (text, images, metadata)              │ │
│  │  • Snippets (content, tags, folders)             │ │
│  │  • Settings (hotkey, history limit)              │ │
│  │  • Encrypted sync over iCloud                    │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │        Privacy & Sensitivity Filter                │ │
│  │  • Regex: passwords, tokens, API keys            │ │
│  │  • Auto-expire in N seconds (default 30s)        │ │
│  │  • Blur preview, warn user                       │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## Port Assignment

- **Menu bar app**: Native, no HTTP ports
- **iCloud sync**: Background via CloudKit (encrypted)
- **Global hotkey**: System-level event monitoring (⌘⇧V)

## Design System

**Forge Aesthetic**: Foundry shared design system adapted for clipboard/memory theme.

- Dark forge aesthetic: charcoal blacks (#141210), amber accents (#E8A849)
- Icons: SF Symbols 5.0
- Fonts: DM Sans (body), JetBrains Mono (monospace for code snippets)
- Forge language (clipboard theme):
  - "Forge a clip" — save a new snippet
  - "Clipped." — item copied to clipboard
  - "Clip recalled." — item restored from history
  - "The forge remembers everything" — onboarding copy
  - "RE-CLIP" — restore previous clip state
  - "Sensitive clip detected" — password/token warning

## Core Features

### 1. Clipboard History
- **Monitors NSPasteboard** for all copy/cut events in real-time
- **Stores multiple types**:
  - Plain text (NSString)
  - Rich text (NSRTF, NSAttributedString)
  - Images (TIFF, PNG, HEIC)
  - Files (fileURL types, draggable)
  - URLs (auto-detect web links)
  - HTML (web clippings)
- **Automatic pagination**: Latest items first, configurable limit (50–5000)
- **Duplicate detection**: Don't store exact duplicates within 10 seconds
- **Metadata**:
  - Timestamp (creation, last accessed)
  - Source app (where copied from)
  - Size (bytes)
  - Type (text, image, file, etc.)
  - Thumbnail preview (for images, first 100 chars for text)

### 2. Fuzzy Search
- **Real-time** as you type
- **Spotlight-style**: searches content + metadata (timestamps, tags, source apps)
- **Weighting**: recent items, pinned items ranked higher
- **Filters**: by type (text/image/file), date range, tags, source app

### 3. Snippets (Pinned Reusable Content)
- **Create snippets** from history items or typed manually
- **Organization**: folders (e.g., "Swift Boilerplate", "Email Templates") + tags
- **Quick access**: tab view, keyboard shortcuts (e.g., ⌘1 → "import Foundation")
- **Copy to clipboard** with one click or hotkey
- **Editing**: in-place inline edit or modal for rich snippets
- **Syncs to iCloud**: access snippets from all Macs

### 4. Sensitive Data Protection
- **Auto-detection** via regex:
  - Passwords: `password\s*=|pwd|passcode` (case-insensitive)
  - API keys: `api[_-]?key|secret[_-]?key|token` (case-insensitive)
  - SSH keys: `-----BEGIN.*KEY-----`
  - Credit card: `^\d{13,19}$`
  - Social security: `^\d{3}-\d{2}-\d{4}$`
- **Auto-expire**: Sensitive items auto-delete after 30 seconds (configurable)
- **Visual warning**: Red "sensitive" badge, blurred preview
- **Opt-out per item**: User can mark item as safe if it's a false positive

### 5. Pinned Items
- **Pin frequently used clips** to top of history
- **Separate "Pinned" section** in popup
- **Bulk operations**: un-pin, delete, export
- **Pin limits**: Free tier (3), Pro tier (unlimited)

### 6. iCloud Sync
- **CloudKit**: Encrypted, automatic sync across all user's Macs
- **Selective sync**: User toggles iCloud on/off in settings
- **Conflict resolution**: Last-write-wins for edits; append for new items
- **Offline support**: Local history available even if iCloud is down
- **Retention**: Configurable cloud retention (default 30 days)

### 7. Settings & Customization
- **Global hotkey**: Editable, default ⌘⇧V (allow any key combo)
- **History limit**: 50, 100, 250, 500, 1000, 5000 items
- **Auto-expire sensitive**: Yes/No + custom timeout (seconds)
- **Startup behavior**: Launch at login, run in background
- **iCloud sync**: On/Off
- **Privacy**: Show source app, clear history on quit, ignore apps (list)
- **Appearance**: Light/Dark/System theme
- **Performance**: Max image size in history, thumbnail size

## Monetization

### Free Tier (Foundry Clip)
- ✅ Clipboard history (last 50 items)
- ✅ Local search & filtering
- ✅ Basic snippets (3 pinned max)
- ✅ Sensitive data detection
- ✅ Basic settings
- ❌ iCloud sync
- ❌ Unlimited history
- ❌ Snippet folders & tags
- ❌ Advanced privacy controls

### Pro Tier ($4.99/year or $0.99/month)
- ✅ Everything in Free
- ✅ Unlimited history (configurable)
- ✅ iCloud sync (all Macs)
- ✅ Unlimited pinned snippets
- ✅ Snippet folders & tags
- ✅ Advanced filters (by date, source app, type)
- ✅ Cloud backup (30-day retention, configurable)
- ✅ Scheduled cleanup rules
- ✅ Priority support

**Implementation**: In-app purchase (StoreKit 2), local feature flags, Core Data predicate filtering for limits.

## File Structure

```
foundry-clip/
├── CLAUDE.md                           # This file
├── AGENTS.md                           # Workflow for agents
├── README.md                           # User-facing quickstart
├── PRD.md                              # Product requirements
├── TODO.md                             # Development roadmap
├── foundry-clip.xcodeproj/
│   └── (Xcode project, auto-generated)
├── Sources/
│   ├── FoundryClipApp.swift            # @main entry point, menu bar app
│   ├── AppDelegate.swift               # Lifecycle, hotkey setup
│   ├── Clipboard/
│   │   ├── PasteboardMonitor.swift     # NSPasteboard watcher
│   │   ├── ClipboardHistory.swift      # History CRUD logic
│   │   ├── SensitivityDetector.swift   # Privacy patterns + filters
│   │   └── ClipboardModels.swift       # Data models (ClipboardItem, etc.)
│   ├── Views/
│   │   ├── PopupView.swift             # Main popover window
│   │   ├── SearchBar.swift             # Spotlight-style search input
│   │   ├── HistoryListView.swift       # Scrollable history list
│   │   ├── ItemPreview.swift           # Item detail/preview card
│   │   ├── SnippetsView.swift          # Snippets tab
│   │   ├── SnippetEditor.swift         # New/edit snippet modal
│   │   ├── SettingsView.swift          # Settings panel
│   │   └── Components/                 # Reusable UI components
│   │       ├── PinnedBadge.swift
│   │       ├── SensitiveBadge.swift
│   │       ├── TypeIcon.swift
│   │       └── BlurredPreview.swift
│   ├── Sync/
│   │   ├── CloudKitManager.swift       # iCloud/CloudKit integration
│   │   ├── SyncModels.swift            # Codable sync entities
│   │   └── SyncQueue.swift             # Background sync queue
│   ├── Utils/
│   │   ├── Hotkey.swift                # Global hotkey registration
│   │   ├── FuzzySearch.swift           # Fuzzy matching algorithm
│   │   ├── ImageProcessing.swift       # Thumbnail generation
│   │   ├── DataStore.swift             # Core Data stack + helpers
│   │   └── Logging.swift               # Forge language logging
│   └── Models/
│       ├── ClipboardItem+CoreData.swift
│       ├── Snippet+CoreData.swift
│       ├── Settings+CoreData.swift
│       └── Extensions.swift
├── docs/
│   ├── DESIGN_SYSTEM.md                # Foundry design system ref
│   ├── ARCHITECTURE.md                 # Detailed architecture & decisions
│   ├── PRIVACY.md                      # Privacy & security model
│   ├── SYNC.md                         # iCloud/CloudKit sync flow
│   └── API_REFERENCE.md                # Core Data schema + functions
└── Tests/
    ├── ClipboardMonitorTests.swift
    ├── SensitivityDetectorTests.swift
    ├── FuzzySearchTests.swift
    └── SyncTests.swift
```

## Core Dependencies

```swift
// Package.swift (if using SwiftPM, or Cocoapods for iOS compat)
dependencies: [
    // SwiftUI is built-in (macOS 13+)
    // Foundation: NSPasteboard, Core Data, CloudKit — all built-in
    // No external dependencies for MVP
]
```

## Development Phases

### Phase 1: MVP (Week 1-2)
- [x] Xcode project scaffold + SwiftUI app shell
- [x] NSPasteboard monitoring (detect copy events)
- [x] Core Data schema (ClipboardItem, Snippet, Settings)
- [x] Menu bar app + popover window (⌘⇧V hotkey)
- [x] History list view with basic search
- [x] Copy item back to pasteboard
- [x] Settings panel (hotkey, history limit)

### Phase 2: Features (Week 3-4)
- [ ] Rich preview (images, RTF, HTML)
- [ ] Fuzzy search with ranking
- [ ] Snippets management (CRUD, folders, tags)
- [ ] Sensitivity detector (passwords, tokens, auto-expire)
- [ ] Pinned items section
- [ ] Duplicate detection

### Phase 3: Sync & Pro (Week 5-6)
- [ ] CloudKit integration (iCloud sync)
- [ ] StoreKit 2 (Pro in-app purchase)
- [ ] Pro feature gates (unlimited history, sync, advanced filters)
- [ ] Cloud backup & retention settings
- [ ] Conflict resolution

### Phase 4: Polish (Week 7+)
- [ ] Performance tuning (large history, sync speed)
- [ ] Advanced filters (source app, date range, type)
- [ ] Keyboard shortcuts (pinned snippets: ⌘1, ⌘2, etc.)
- [ ] Notifications (on sensitive data, sync status)
- [ ] App Store submission (codesigning, entitlements, privacy policy)

## Key Implementation Notes

### NSPasteboard Monitoring
- Use `DispatchSourceTimer` or `NSPasteboardChangeNotification` to detect clipboard changes
- Check `NSPasteboard.general.changeCount` every 100ms to avoid polling overhead
- Handle multiple types: `NSString`, `NSRTFPboardType`, `TIFF`, `fileURL`, `public.html`, etc.

### Core Data + CloudKit
- Enable `NSPersistentCloudKitContainer` for automatic sync
- Add `CloudKit` entitlement to app bundle
- Use `@Environment(\.managedObjectContext)` in SwiftUI views
- Handle offline gracefully with local-only fallback

### Global Hotkey (⌘⇧V)
- Use `PTHotKey` (third-party) or Carbon Events API (deprecated but still works)
- Alternatively, use Keyboard Maestro automation (simpler for users, external tool)
- Store user-selected hotkey in Settings model, re-register on app launch

### Sensitivity Detection
- Regex patterns for passwords, tokens, API keys, SSH keys, credit cards, SSN
- Flag items immediately on capture; store "sensitive" boolean in Core Data
- Auto-delete after timer (e.g., 30 seconds); warn user if they copy again
- Allow user to override ("Don't warn for this item")

### Thumbnails & Performance
- Generate image thumbnails (32×32px) on background queue, cache in Core Data blob
- Text preview: first 100 characters, truncate with "…"
- Lazy-load rich text & HTML on selection (don't render until user views)

### Fuzzy Search
- Simple levenshtein distance or trigram-based matching
- Rank by recency + pinned status + word-boundary matches
- Real-time search as user types (debounce 100ms)

## Critical Security & Privacy Notes

1. **No network without permission**: Don't sync to iCloud unless user enables it in settings
2. **Sensitive data**: Auto-detect passwords, tokens, API keys; warn & auto-expire
3. **Encryption**: CloudKit is encrypted by default; local SQLite can be FileVault-protected
4. **User control**: Clear history, ignore apps, custom retention policies
5. **Transparency**: Show what's being synced, when, and to where (Xcode Signing & Capabilities)
6. **Compliance**: GDPR/CCPA friendly — no tracking, no analytics by default

## Legal & Licensing

- **License**: MIT (original code, not based on Maccy — if we reference it, note that)
- **No third-party code**: Built from scratch, uses only macOS Framework APIs
- **Attribution**: None required for App Store

## Success Criteria

1. ✅ Clipboard history captures all copy events (text, images, files, rich text)
2. ✅ Popover opens with ⌘⇧V, closes with Esc or click-outside
3. ✅ Search finds items in <100ms even with 1000+ items
4. ✅ Copy item from history back to pasteboard with 1 click
5. ✅ Snippets save and recall via folders + tags
6. ✅ Sensitive data auto-expires after 30 seconds
7. ✅ iCloud sync seamless across 2+ Macs (Pro feature)
8. ✅ Pro in-app purchase works and unlocks features
9. ✅ App runs in background 24/7, <5% CPU when idle
10. ✅ App Store submission (code-signed, privacy policy, entitlements correct)

---

**Status**: Scaffolding phase (Xcode project created, CLAUDE.md drafted)
**Last Updated**: 2026-03-15
**Lead**: Claude Agent (foundry-clip)
