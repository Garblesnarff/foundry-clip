# Foundry Clip — Design System

## Overview

Foundry Clip uses the **Foundry shared design system** with customizations for clipboard/memory management theme. All design decisions are grounded in macOS 13+ human interface guidelines (HIG).

## Color Palette

### Primary Colors
- **Forge Black**: `#141210` (background, text)
- **Forge Amber**: `#E8A849` (accents, highlights)
- **Forge Gray**: `#A9A9A9` (secondary text, borders)

### Semantic Colors
- **Success**: `#34C759` (pinned, saved)
- **Warning**: `#FF9500` (sensitive data, expiring)
- **Error**: `#FF3B30` (deletion, critical alerts)
- **Info**: `#A2845E` (forge bronze, secondary info)

### Light & Dark Mode
- **Light Mode**: White backgrounds (`#FFFFFF`), dark text
- **Dark Mode**: Charcoal backgrounds (`#1C1C1E`), light text
- **System**: Respects macOS appearance setting

## Typography

### Font Stack
- **UI (body text)**: DM Sans 13pt, weight 400
- **UI (labels)**: DM Sans 12pt, weight 500
- **Code & Technical**: JetBrains Mono 11pt, weight 400
- **Titles (rare)**: Playfair Display 18pt, weight 700

### Text Styles (SwiftUI)
- `.headline`: Title-level text (section headers)
- `.subheadline`: Secondary text (timestamps, labels)
- `.body`: Normal text (list items, descriptions)
- `.caption`: Small text (metadata, hints)
- `.caption2`: Tiny text (timestamps, badges)
- `.monospacedDigit`: For codes, numbers

### Line Height
- Body: 1.5x font size
- Headlines: 1.2x font size

## Spacing

### Padding & Margins (in points)
- `2pt`: Minimal spacing (badge padding)
- `4pt`: Tight spacing (icon-to-text)
- `8pt`: Standard spacing (list item padding)
- `12pt`: Component spacing (sections)
- `16pt`: Major spacing (layout sections)
- `20pt`: Large spacing (top-level sections)

## Icons

### Icon Set
- **Primary**: SF Symbols 5.0 (built-in, Apple's system icons)
- **Size**: 16×16pt (standard), 14×14pt (compact), 12×12pt (mini)
- **Weight**: Regular (default), Semibold (emphasis)
- **Color**: Inherits from text color, override with `.foregroundColor`

### Common Icons
- Copy: `"doc.on.doc"`
- Paste: `"doc.text.fill"`
- Pin: `"pin.fill"` (active), `"pin"` (inactive)
- Delete: `"trash"`
- Search: `"magnifyingglass"`
- Settings: `"gear"`
- Bookmark: `"bookmark.fill"`
- Sensitive: `"lock.fill"` (red), `"exclamationmark.triangle"` (yellow)
- File: `"folder"`
- Image: `"photo"`
- Link: `"link"`
- Clock: `"clock"`

## Components

### Buttons

#### Primary Button
- Background: Forge Amber (`#E8A849`)
- Text: Forge Black (`#141210`)
- Padding: 8pt (vertical), 16pt (horizontal)
- Corner radius: 6pt
- Font: DM Sans 13pt semibold
- State: Normal, Pressed (opacity 0.8), Disabled (opacity 0.5)

```swift
Button("Copy") {
    // action
}
.buttonStyle(.borderedProminent)
.tint(Color(red: 0.91, green: 0.52, blue: 0.29)) // Forge Amber
```

#### Secondary Button
- Background: Clear / light gray
- Text: Forge Black / Gray
- Border: 1pt, Forge Gray
- Padding: 8pt (vertical), 16pt (horizontal)
- Corner radius: 6pt

```swift
Button("Cancel") {
    // action
}
.buttonStyle(.bordered)
```

#### Icon Button (Toolbar)
- Background: Transparent
- Icon: 16pt, Forge Gray
- Hover: Background opacity 0.1
- Size: 32×32pt (touch target)

### Text Fields

- Background: White / Light Gray
- Border: 1pt, Forge Gray
- Corner radius: 4pt
- Padding: 8pt
- Font: DM Sans 13pt
- Placeholder: Forge Gray 50% opacity
- Focus: Blue outline (macOS default)

### Lists & Tables

- Row height: 44pt (minimum touch target)
- Padding: 8pt (vertical), 12pt (horizontal)
- Separator: 1pt Forge Gray, 10% opacity
- Hover: Background opacity 0.05
- Selection: Blue background (macOS default)

### Popovers & Modals

- Background: White / System background
- Shadow: 2pt blur, 0.2 opacity
- Border radius: 8pt
- Padding: 16pt
- Title: Headline style
- Divider: 1pt Forge Gray, 20% opacity

## Interaction Patterns

### Hover States
- **Interactive elements**: 10% opacity background highlight
- **Buttons**: Subtle shadow increase
- **Lists**: Row background highlight (0.05 opacity)

### Selected States
- **Active tab**: Forge Amber background (0.1 opacity)
- **Selected list item**: Blue background (macOS default)
- **Pinned item**: Forge Amber dot indicator

### Disabled States
- **All interactive**: 50% opacity
- **Text**: Forge Gray 50%
- **Icons**: Forge Gray 50%

### Loading States
- **Spinner**: SF Symbols `"circle.fill"` rotated (0.5s animation)
- **Progress**: Indeterminate progress bar, Forge Amber color

## Dark Mode Adjustments

When dark mode is active:
- **Text colors**: Invert (light text on dark)
- **Background**: Charcoal (`#1C1C1E`) instead of white
- **Accents**: Forge Amber remains unchanged
- **Borders**: Light gray (20% opacity) on dark backgrounds

Example (SwiftUI):
```swift
@Environment(\.colorScheme) var colorScheme

var backgroundColor: Color {
    colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
}
```

## Spacing & Layout

### Popover Dimensions
- **Default size**: 400pt (width) × 600pt (height)
- **Minimum**: 300pt × 400pt
- **Maximum**: 800pt × 900pt (resizable)

### Tab Bar
- **Height**: 40pt
- **Item width**: Equal distribution
- **Divider**: 1pt Forge Gray

### Search Bar
- **Height**: 32pt
- **Padding**: 8pt (all sides)
- **Icon size**: 16pt

### List Rows
- **Height**: 44pt (minimum)
- **Leading icon**: 12×12pt
- **Trailing actions**: 16pt icons, 8pt spacing

## Animations

### Transitions
- **Duration**: 200–300ms for most animations
- **Curve**: Easing InOut (`.easeInOut`)
- **Tab switch**: Fade (200ms)
- **List row**: Slide + fade (150ms)

### Micro-interactions
- **Button press**: Scale down 0.95, fade in hover state (100ms)
- **Pin toggle**: Scale 1.0 → 1.2 → 1.0 (200ms)
- **Delete animation**: Fade out + slide right (300ms)
- **Loading spinner**: Continuous rotation (1s per rotation)

## Accessibility

### Color Contrast
- **Text on background**: 7:1 WCAG AAA minimum
- **UI components**: 3:1 WCAG AA minimum
- **Test**: Use Contrast app or built-in macOS tools

### Dynamic Type
- All text uses system-defined text styles (not fixed sizes)
- Minimum 16pt text for body (readability)
- Icons scale with content size preference

### Keyboard Navigation
- **Tab order**: Left-to-right, top-to-bottom
- **Focus indicator**: 2pt blue outline (macOS default)
- **Keyboard shortcuts**: ⌘C, ⌘D, ⌘P (defined in AGENTS.md)

### VoiceOver
- **All interactive elements**: Labeled with `accessibilityLabel`
- **Icons**: Always have labels (no silent icons)
- **Lists**: Each row is a distinct VoiceOver item

Example (SwiftUI):
```swift
Button(action: { /* copy */ }) {
    Image(systemName: "doc.on.doc")
}
.accessibilityLabel("Copy to clipboard")
```

## Forge Language & Theming

### Copy Language
- Buttons: "Copy", "Delete", "Pin", "Save as Snippet"
- Placeholders: "Search clips & snippets"
- Error messages: "The forge has cooled: [details]"
- Success: "Clipped." / "Clip recalled." / "Forged!"

### Status Indicators
- **Active**: "The forge is lit" (implied by UI)
- **Syncing**: "Forging..." (spinner + text)
- **Error**: "The forge has cooled" (red banner)
- **Sensitive**: "Sensitive clip — expiring in 30s" (yellow badge)

### UI Copy Tone
- Professional but approachable
- Avoid jargon (not "pasteboard", say "clipboard")
- Action-oriented ("Copy now", not "Click here")
- Consistent capitalization (Title Case for buttons)

## Brand Assets

### Logo
- **Mark**: Forge anvil + clipboard icon (combined)
- **Logo**: Mark + "Foundry Clip" wordmark
- **Color**: Forge Amber on transparent
- **Monochrome**: Available for light/dark mode

### Icon (App & Menu Bar)
- **App icon**: 1024×1024pt (rounded, no transparency)
- **Menu bar icon**: 16×16pt (white or black, no padding)
- **Template**: Use SF Symbols or custom SVG

## References

- **macOS HIG**: https://developer.apple.com/design/human-interface-guidelines/macos
- **SF Symbols**: https://www.applesfproducticons.com/
- **Color Contrast**: https://webaim.org/resources/contrastchecker/
- **Foundry Shared Design**: Refer to parent design system (if available)

---

**Last Updated**: 2026-03-15
**Version**: 1.0 (MVP)
