# Foundry Clip — Product Requirements Document

## Executive Summary

**Foundry Clip** is a native macOS clipboard history and snippets manager for developers, writers, and power users. It captures everything you copy, makes it searchable with instant recall (⌘⇧V), organizes snippets with folders/tags, and syncs across your Macs via iCloud. Free tier: 50-item history. Pro ($4.99/year): unlimited history + iCloud + snippets.

**Target Launch**: Q2 2026 (App Store)

---

## 1. Product Goals

### Primary Goals
1. **Solve clipboard ephemeralness**: Users never lose a copied item again
2. **Provide instant recall**: Search history in <100ms, even with thousands of items
3. **Replace manual snippet management**: Stop copy-pasting from Gists, notes, docs
4. **Sync seamlessly**: All Macs stay in sync; accessible anywhere
5. **Protect privacy**: Auto-detect and expire sensitive data (passwords, tokens)

### Success Metrics
- **Retention**: 60%+ of users still active after 30 days
- **Daily Active**: 70%+ of installs use it daily
- **Search latency**: <100ms for queries on 1000+ items
- **Crash rate**: <0.1%
- **Pro conversion**: 15%+ of free users upgrade to Pro
- **App Store rating**: 4.5+ stars, <5% 1-star reviews

---

## 2. User Personas

### Persona 1: Dev (Sarah)
- **Role**: Full-stack engineer, 7 years experience
- **Need**: Juggle code snippets, config, API keys, SSH commands across 3 projects
- **Pain**: Copies something, switches projects, forgets where it came from
- **Solution**: Search history for "database url", pin "docker-compose up", create "Swift boilerplate" snippet
- **Monetization**: Likely Pro user (unlimited history, iCloud sync across work + home Mac)

### Persona 2: Writer (Marcus)
- **Role**: Freelance journalist, writes for multiple publications
- **Need**: Reuse quotes, facts, boilerplate intro/outro paragraphs
- **Pain**: Manually searches Notion, Google Docs for snippets; loses good quotes to time
- **Solution**: Snippets folder "quotes", search by date range, cloud sync across devices
- **Monetization**: Likely Pro user (snippets organization, iCloud)

### Persona 3: Designer (Alex)
- **Role**: Product designer, works on mobile + web projects
- **Need**: Track color codes, Figma URLs, design tokens, brand guidelines
- **Pain**: Copies hex code, forgets which project it's from; scattered across apps
- **Solution**: History with source-app filter, snippets folder "colors", pin frequently-used tokens
- **Monetization**: Mixed (free user, occasional copier) — education discount could help

### Persona 4: Power User (Jordan)
- **Role**: Entrepreneur, multi-tasker, uses 20+ apps daily
- **Need**: Quick access to frequently-used phrases, links, commands
- **Pain**: Clipboard manager they tried was slow; never switched back
- **Solution**: Lightning-fast search, keyboard shortcuts (⌘1 = first snippet), privacy
- **Monetization**: Likely Pro user (unlimited history, privacy features)

---

## 3. Core Features

### 3.1 Clipboard History
**What**: Automatic capture of everything copied to the system pasteboard.

**Behavior**:
- Monitors NSPasteboard continuously
- Captures: plain text, rich text (RTF), images (TIFF, PNG, HEIC), files (fileURL), URLs, HTML
- Stores with metadata: timestamp, source app, content size, content type
- Displays as a scrollable list (newest first)
- User can copy any historical item back to pasteboard with 1 click
- User can delete individual items or clear all history

**Constraints**:
- Free tier: max 50 items; Pro: unlimited (default 1000, configurable up to 5000)
- Large items (>50MB images, >100MB files) are stored by reference (fileURL), not full copy
- Duplicates within 10 seconds are skipped (don't store same item twice)
- Sensitive data (passwords, API keys) is flagged and auto-deleted after 30s

**Acceptance Criteria**:
- [ ] Clipboard capture runs continuously without user action
- [ ] History list loads in <500ms even with 1000+ items
- [ ] Copy-back to pasteboard works for all supported types
- [ ] Duplicates are not stored
- [ ] Pagination: can load more items on scroll

---

### 3.2 Fuzzy Search
**What**: Spotlight-style search across clipboard history.

**Behavior**:
- Real-time search as user types (debounce 100ms)
- Searches: item content, source app, timestamp, item type
- Ranking: recent items ranked higher, pinned items at top
- Filtering: by date range, source app, item type (text/image/file)
- Results update live as query changes

**Constraints**:
- Search must complete in <100ms even with 5000+ items
- Free tier: basic search only; Pro: advanced filters (date, app, type)

**Acceptance Criteria**:
- [ ] Search updates as user types
- [ ] Results ranked by relevance + recency
- [ ] <100ms latency on 5000 items
- [ ] Filters work correctly

---

### 3.3 Snippets (Reusable Clips)
**What**: User-created reusable text, code, templates saved with metadata.

**Behavior**:
- User can manually create a snippet (+ button in UI)
- Or convert history item to snippet (context menu: "Save as snippet")
- Snippet properties: title, content, tags, folder, keyboard shortcut (Pro)
- Snippets stored in Core Data, synced to iCloud (Pro)
- Copy snippet to clipboard with 1 click or hotkey
- Edit snippet in-place or via modal
- Organize with folders (nested) and tags
- Search snippets alongside history

**Constraints**:
- Free tier: max 3 pinned snippets; Pro: unlimited
- Snippet folders: max 5 folders free; unlimited (Pro)
- Tags: max 10 unique tags (unlimited usage)

**Acceptance Criteria**:
- [ ] Create snippet from scratch
- [ ] Save history item as snippet
- [ ] Folders and tags work
- [ ] Copy to clipboard from snippet
- [ ] Edit inline or modal
- [ ] Hotkeys work (Pro)
- [ ] Free tier limits enforced

---

### 3.4 Pinned Items
**What**: Star/favorite items to keep them at the top of history and snippets.

**Behavior**:
- User pins a history item (pin icon, or keyboard shortcut)
- Pinned items float to top of list
- Can unpin with same gesture
- Max 3 pinned items free; unlimited (Pro)
- Pinned items persist across sessions

**Constraints**:
- Limit enforced: free users can't pin >3
- Pinned items: not affected by auto-expiry (unless sensitive)

**Acceptance Criteria**:
- [ ] Pin/unpin via UI
- [ ] Pinned items appear at top
- [ ] Limit enforced

---

### 3.5 Sensitive Data Protection
**What**: Auto-detect passwords, API keys, tokens, SSNs; warn and auto-expire.

**Behavior**:
- Regex patterns on capture: password, api_key, secret, token, ssh key, credit card, SSN
- If sensitive: flag item with badge, add red "sensitive" indicator
- Auto-expire: delete after 30s (configurable in settings)
- User warned on capture: "Sensitive clip detected — will expire in 30 seconds"
- User can mark item as "not sensitive" if false positive
- Sensitive items: preview is blurred/hidden until user requests

**Constraints**:
- Free: basic sensitive detection; Pro: custom sensitive patterns
- Patterns: case-insensitive, common variations

**Acceptance Criteria**:
- [ ] Passwords detected and flagged
- [ ] API keys detected and flagged
- [ ] Auto-expiry works
- [ ] Warning shown to user
- [ ] User can override

---

### 3.6 iCloud Sync (Pro Feature)
**What**: Sync clipboard history and snippets across all user's Macs via CloudKit.

**Behavior**:
- User enables iCloud sync in settings (Pro only)
- Core Data syncs to iCloud via NSPersistentCloudKitContainer
- History items synced automatically
- Snippets synced automatically
- Sync is bidirectional: changes on Mac A appear on Mac B in <10s
- Offline support: works locally if iCloud is down
- Conflict resolution: last-write-wins for edits; append for new items
- Cloud retention: configurable (7, 14, 30, 90 days)

**Constraints**:
- User must be signed into iCloud
- Requires CloudKit entitlements
- Encrypted by default (iCloud E2E)
- Sensitive items (auto-expiring) don't sync (deleted locally before sync)

**Acceptance Criteria**:
- [ ] iCloud sync setup (CloudKit container)
- [ ] History syncs across 2+ Macs
- [ ] Snippets sync across Macs
- [ ] Offline works locally
- [ ] Conflict resolution sensible
- [ ] Cloud retention works

---

### 3.7 Global Hotkey (⌘⇧V)
**What**: System-wide keyboard shortcut to open Foundry Clip popup.

**Behavior**:
- Default: ⌘⇧V
- User can customize to any key combo (Settings → Hotkey)
- Hotkey opens popover window near cursor or menu bar
- Popover closes on Esc, click-outside, or item selection
- Hotkey re-registers on app launch

**Constraints**:
- Must not interfere with other apps' hotkeys
- Graceful fallback if hotkey is already taken (show warning)

**Acceptance Criteria**:
- [ ] ⌘⇧V opens popup
- [ ] Hotkey customizable
- [ ] Popup closes appropriately
- [ ] Hotkey persists across sessions

---

### 3.8 Settings Panel
**What**: User configuration for history, hotkey, sync, privacy, appearance.

**Tabs**:
1. **General**: Launch at login, run in background, theme
2. **Clipboard**: History limit, auto-expire sensitive, timeout, ignore apps
3. **Hotkey**: Edit global hotkey
4. **Sync** (Pro): iCloud toggle, cloud retention, sync cellular
5. **Privacy**: Show source app, clear on quit, blur sensitive previews
6. **About**: Version, feedback, documentation

**Constraints**:
- All settings persist in Core Data
- Pro settings hidden if user is on free tier

**Acceptance Criteria**:
- [ ] All settings save and persist
- [ ] Free tier: limited options
- [ ] Pro tier: advanced options visible
- [ ] Hotkey change works immediately

---

## 4. Feature Tiers

### Free (Foundry Clip)
- ✅ Clipboard history (max 50 items)
- ✅ Local search
- ✅ 3 pinned snippets
- ✅ Basic snippets (no folders/tags)
- ✅ Sensitive data detection
- ✅ Basic settings
- ❌ iCloud sync
- ❌ Unlimited history
- ❌ Snippet folders/tags
- ❌ Advanced filters

### Pro ($4.99/year, or $0.99/month)
- ✅ Everything in Free
- ✅ Unlimited history (default 1000, configurable up to 5000)
- ✅ iCloud sync (across all Macs)
- ✅ Unlimited pinned snippets
- ✅ Snippet folders and tags
- ✅ Advanced filters (date range, source app, type)
- ✅ Cloud backup (7–90 day retention, configurable)
- ✅ Scheduled cleanup rules (remove >N days old, etc.)
- ✅ Keyboard shortcuts for pinned snippets (⌘1, ⌘2, etc.)

**Implementation**: In-app purchase (StoreKit 2), local feature flags, Core Data predicates.

---

## 5. Monetization Strategy

### Pricing Model
- **Free**: Full-featured clipboard history with limits
- **Pro**: $4.99/year (Apple annual subscription)
- **Justification**: Low annual price for high value (iCloud + unlimited history)

### Revenue Goals
- Year 1: 50k installs, 15% Pro conversion = $37,500 ARR (Apple takes 30%)
- Year 2: 200k installs, 18% conversion = $500,000 ARR gross

### Distribution
- **Primary**: App Store (80% revenue)
- **Secondary**: Direct (foundry.local, 10% revenue, no middleman)
- **Affiliate**: Bundle deals with dev tools (10% revenue)

---

## 6. User Experience (UX) Flow

### First Launch
1. App opens, shows onboarding
2. "Grant Accessibility permission" (required for hotkey + pasteboard)
3. "Press ⌘⇧V to open Clip"
4. User copies something; it appears in popup
5. Popup closes on Esc; user can reopen with hotkey

### Daily Use
1. User works, copies items normally
2. Occasionally needs to recall something: ⌘⇧V
3. Searches history, finds item, clicks to copy back
4. Hotkey closes popup; item is in pasteboard; user pastes

### Snippet Creation
1. User has a frequently-copied item (e.g., "import Foundation")
2. Right-click on history item → "Save as snippet"
3. Modal: title, folder, tags, keyboard shortcut (Pro)
4. Next time: ⌘1 (or custom hotkey) to copy snippet instantly

### iCloud Sync (Pro)
1. User enables "iCloud sync" in settings
2. History and snippets upload to CloudKit
3. User opens same app on second Mac
4. History and snippets appear (within 10 seconds)
5. Changes on either Mac sync bidirectionally

---

## 7. Technical Requirements

### Platform & Target
- **macOS 13.0+** (Ventura, Sonoma, Sequoia, etc.)
- **Apple Silicon** (M1, M2, M3, M4 native)
- **Intel** (via Rosetta 2, not optimized but functional)

### Core Dependencies
- **SwiftUI** (built-in, macOS 13+)
- **Foundation** (NSPasteboard, Core Data, CloudKit)
- **Keyboard Maestro** or similar for global hotkey (or Carbon Events if MTL-native)

### Performance Targets
- **Startup**: <2 seconds to show window
- **Search latency**: <100ms for 5000 items
- **Memory**: <200 MB at rest, <500 MB with full history
- **CPU**: <5% idle, <30% during search/sync

### Storage
- **Local**: SQLite Core Data store, ~100 KB per history item (text), ~1 MB per image
- **iCloud**: Same, encrypted at rest and in transit
- **Free tier limit**: 50 items × 100 KB = ~5 MB
- **Pro tier**: Configurable, typically 1000–5000 items = 100–500 MB

---

## 8. Privacy & Security

### Data Collection
- **None**. No analytics, no telemetry, no tracking.
- App ID, in-app purchase history (required for Pro verification) stored locally only.

### Encryption
- **Local storage**: FileVault (user-controlled)
- **CloudKit**: End-to-end encrypted (Apple's default)
- **Sensitive data**: Auto-deleted (not encrypted, removed)

### User Control
- Delete history on quit (toggle)
- Manual clear all
- Ignore specific apps (don't capture from Password Manager, etc.)
- Granular sync settings (choose retention, which Macs sync)

### Compliance
- **GDPR**: No personal data tracking; users own all clipboard data
- **CCPA**: Minimal data collection; no sale to third parties
- **Privacy policy**: In-app + website, full transparency

---

## 9. Competitive Landscape

| Feature | Clip | Maccy | Pasty | ClipMenu |
|---------|------|-------|-------|----------|
| **Free** | Yes | Yes | No | Yes |
| **Clipboard history** | ✅ | ✅ | ✅ | ✅ |
| **iCloud sync** | ✅ Pro | ❌ | ✅ | ❌ |
| **Snippets** | ✅ Pro | ❌ | ✅ | ❌ |
| **Global hotkey** | ✅ | ✅ | ✅ | ✅ |
| **Fuzzy search** | ✅ | ✅ | ✅ | ✅ |
| **macOS native** | ✅ | ✅ | ❌ (Electron) | ✅ |
| **App Store** | ✅ | ❌ | ✅ | ❌ |
| **Price** | Free / $4.99y | Free | $15 | Free |

**Differentiation**:
- **Snippets + iCloud**: Unique combination (Pasty has both but isn't free)
- **Native macOS**: Faster, better OS integration than Electron alternatives
- **Affordable Pro**: $4.99/year is lowest annual price for feature-rich option
- **Privacy-first**: No analytics, no data collection, transparent

---

## 10. Success Metrics

### Engagement
- **DAU/MAU**: 70% of installs active daily
- **Session length**: avg 2–5 minutes per day
- **Search usage**: avg 5+ searches per active user daily
- **Snippet adoption**: 50% of Pro users create >3 snippets

### Quality
- **Crash rate**: <0.1%
- **Stability**: 99.9% uptime (local app, no server)
- **Search latency**: <100ms for 5000 items
- **Sync reliability**: 99.5% successful syncs (iCloud dependency)

### Business
- **Pro conversion**: 15% of free users → Pro within 30 days
- **Retention**: 60% of free → still active after 30 days; 80% of Pro
- **Rating**: 4.5+ stars on App Store
- **NPS**: 50+ (Net Promoter Score)

---

## 11. Roadmap

### Phase 1: MVP (Weeks 1–2)
- [x] Xcode project scaffold
- [x] NSPasteboard monitoring
- [x] Core Data models
- [x] Menu bar app + popover
- [x] History list + copy-back
- [x] Settings panel

### Phase 2: Search & Snippets (Weeks 3–4)
- [ ] Fuzzy search
- [ ] Snippets CRUD
- [ ] Snippet folders & tags
- [ ] Rich preview (images, RTF)
- [ ] Pinned items

### Phase 3: Privacy & Features (Weeks 5–6)
- [ ] Sensitivity detector
- [ ] Auto-expiry
- [ ] Ignore apps
- [ ] Keyboard shortcuts
- [ ] Source app tracking

### Phase 4: iCloud & Pro (Weeks 7–8)
- [ ] CloudKit integration
- [ ] iCloud sync
- [ ] StoreKit 2 (in-app purchase)
- [ ] Pro feature gates
- [ ] Cloud backup

### Phase 5: Polish & Release (Weeks 9+)
- [ ] Performance tuning
- [ ] Advanced filters
- [ ] Error handling & edge cases
- [ ] App Store submission
- [ ] Marketing & launch

---

## 12. Open Questions & Risks

### Questions
- **Q**: Should we support Bluetooth/USB file sharing (AirDrop-style)?
- **A**: No — MVP focuses on clipboard only. Phase 2 feature.

- **Q**: What about keyboard shortcut conflicts with other apps?
- **A**: Graceful fallback: warn user, suggest alternative key combo.

- **Q**: How do we handle very large files (>1 GB)?
- **A**: Store by reference (fileURL), not full content. Warn user if copying large video.

### Risks
- **Hotkey monitoring requires Accessibility permission**: User might not grant it. Mitigation: clear onboarding, fallback to menu bar click.
- **iCloud sync conflicts**: Unlikely but possible. Mitigation: last-write-wins strategy, visual conflict UI.
- **NSPasteboard performance**: Continuous monitoring could drain battery. Mitigation: use efficient change detection, timer-based (not event-based).
- **Sensitive data false positives**: Regex patterns might miss edge cases. Mitigation: user override, feedback loop for pattern improvements.

---

## Conclusion

**Foundry Clip** is a straightforward, high-impact product that solves a real problem for Mac users: clipboard ephemeralness. By combining history, search, snippets, and iCloud sync in a native, privacy-first app, we offer the best clipboard manager experience on macOS.

**Key advantages**:
- Free tier + low-cost Pro ($4.99/y)
- Native macOS performance
- Privacy-first (no analytics, no tracking)
- Unique snippet + iCloud combo
- Sustainable monetization

**Target**: Q2 2026 launch on App Store.
