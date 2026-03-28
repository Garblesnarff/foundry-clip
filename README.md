# Foundry Clip

**The forge remembers everything.**

A native macOS clipboard history and snippets manager. Copy anything, find it instantly, sync across your Macs.

## Quick Start

### Install & Launch

1. **Build from source** (requires Xcode 15+):
   ```bash
   open foundry-clip.xcodeproj
   # Build & Run (⌘R)
   ```

2. **Or download from App Store** (when released)

### First Run

- Grant **Accessibility** permission (System Settings → Privacy → Accessibility)
- Press **⌘⇧V** to open Foundry Clip
- Copy something → it appears in history
- Search, pin, or save as snippet

## Features

### Clipboard History
- **Automatic**: Everything you copy (text, images, files, links) is saved
- **Searchable**: Spotlight-style fuzzy search across all items
- **Recent first**: Latest copies at the top
- **Configurable**: Choose to keep 50–5000 items

### Snippets
- **Reusable templates**: Save code, email signatures, boilerplate text
- **Organized**: Group by folders and tags
- **Quick access**: Copy to clipboard with one click
- **Synced**: Available on all your Macs (Pro)

### Smart Features
- **Privacy**: Passwords & tokens auto-delete after 30 seconds
- **Pinned**: Keep your most-used clips at the top
- **Duplicates**: Same item copied twice? Stored only once
- **Rich previews**: See images, formatted text, and file names

### iCloud Sync (Pro)
- **Seamless**: History and snippets sync across all your Macs
- **Encrypted**: All data encrypted in transit and at rest
- **Offline**: Works locally even if iCloud is down
- **Configurable**: Choose what syncs and how long to keep items

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **⌘⇧V** | Open Foundry Clip |
| **Esc** | Close popup |
| **↑/↓** | Navigate history |
| **⌘C** | Copy selected item (or click) |
| **⌘1, ⌘2, ...** | Copy pinned snippet (Pro) |
| **⌘,** | Open Settings |

## Pricing

### Free (Foundry Clip)
- Clipboard history (last 50 items)
- Local search & filtering
- 3 pinned snippets max
- Sensitive data protection
- Ad-free

### Pro ($4.99/year)
- Everything in Free +
- Unlimited history
- iCloud sync (all Macs)
- Unlimited snippets
- Snippet folders & tags
- Advanced filters (by date, app, type)
- Cloud backup (30-day retention)
- Priority support

## Settings

### General
- **Launch at login**: Yes/No
- **Run in background**: Yes/No (always recommended)

### Clipboard
- **History limit**: 50 / 100 / 250 / 500 / 1000 / 5000 items
- **Auto-expire sensitive**: Yes/No
- **Sensitive data timeout**: 30 seconds (customizable)
- **Ignore apps**: Add apps where Clip won't capture clipboard

### Hotkey
- **Global hotkey**: Default ⌘⇧V (customize to any key combo)

### Sync (Pro)
- **iCloud sync**: On/Off
- **Cloud retention**: 7 / 14 / 30 / 90 days
- **Sync on cellular**: Yes/No

### Privacy
- **Show source app**: Yes/No (shows which app you copied from)
- **Clear on quit**: Yes/No
- **Blur sensitive previews**: Yes/No

### Appearance
- **Theme**: Light / Dark / System
- **Thumbnail size**: Small / Medium / Large

## Privacy & Security

**We don't collect any data.** Foundry Clip is entirely local.

- All clipboard data stays on your Mac
- iCloud sync is end-to-end encrypted
- Sensitive data (passwords, tokens, API keys) is automatically detected and auto-deleted
- No analytics, no telemetry, no tracking
- Open source (MIT License)

See [Privacy Policy](docs/PRIVACY.md) for full details.

## Troubleshooting

### ⌘⇧V doesn't open Clip
1. Check **System Settings → Privacy → Accessibility**
2. Foundry Clip should be in the list and toggled On
3. Restart Foundry Clip if you just enabled it

### Items not being captured
- Some apps (password managers, banking apps) intentionally block clipboard access
- Check **Settings → Clipboard → Ignore apps** — is the app listed?
- Try the test: Open TextEdit, type something, copy it. Does it appear in Clip?

### iCloud sync not working
1. Sign into iCloud (System Settings → [Your Name] → iCloud)
2. Check **Settings → Sync → iCloud sync** is On
3. Check network connectivity
4. If still stuck, try: Sign out of iCloud, wait 30s, sign back in

### Performance is slow
- If you have >5000 items, reduce the history limit (Settings → Clipboard)
- Disable iCloud sync temporarily to check if it's the culprit
- Restart Foundry Clip

## Development

For developers contributing to foundry-clip:

- **Architecture**: See [ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Design system**: See [DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)
- **Agent workflow**: See [AGENTS.md](AGENTS.md)
- **Roadmap**: See [TODO.md](TODO.md)

**Build & Run**:
```bash
open foundry-clip.xcodeproj
# Then ⌘R in Xcode
```

**Run Tests**:
```bash
xcodebuild test -scheme foundry-clip
```

## License

MIT License. See [LICENSE](LICENSE) for full text.

### Acknowledgments

Inspired by:
- **Maccy** (p0deje/Maccy) — macOS clipboard manager (MIT License)
- **Windows Clipboard History** (Win+V)
- Community feedback from Foundry beta testers

## Support

- **Email**: support@foundry.local (when released)
- **GitHub Issues**: foundry-clip/issues
- **Twitter**: @forgetheapp

---

**Made with ⚒️ by Foundry.**

The forge remembers everything you copy.
