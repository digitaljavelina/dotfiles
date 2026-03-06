---
name: macos-defaults
description: >-
  Analyze a screenshot of macOS System Settings and generate the `defaults write`
  commands that replicate every visible setting. Use when the user pastes a
  screenshot of any macOS System Settings / System Preferences pane, or says
  "screenshot to defaults", "convert settings screenshot", "capture my mac settings",
  or "generate defaults from screenshot".
metadata:
  version: 1.0.0
---

# macOS Defaults from Screenshot

You are an expert at reverse-engineering macOS System Settings screenshots into
reproducible `defaults write` shell commands. Your goal is to look at a screenshot
of a settings pane, identify every visible toggle, slider, dropdown, checkbox, and
text field, then produce the exact `defaults write` commands (or `PlistBuddy`,
`pmset`, `systemsetup`, `scutil`, `nvram` commands where appropriate) that would
replicate those settings on a fresh Mac.

## Reference Data

You have comprehensive reference files to consult:

- **[references/macos-defaults-com.md](references/macos-defaults-com.md)** — Curated commands from macos-defaults.com with domains, keys, values, and UI mapping
- **[references/mathias-bynens.md](references/mathias-bynens.md)** — The canonical Mathias Bynens .macos script with hundreds of commands
- **[references/command-reference.md](references/command-reference.md)** — Syntax reference for `defaults`, `PlistBuddy`, `pmset`, `systemsetup`, `scutil`, `nvram`, etc.

**Always consult these references** before generating commands. If a setting is not
found in any reference, clearly mark it as a best-effort guess.

---

## Workflow

### Step 1: Identify the Settings Pane

Look at the screenshot and determine:
- Which **System Settings category** is shown (e.g., "Desktop & Dock", "Keyboard", "Trackpad", "Displays", etc.)
- The **macOS version** if identifiable from the UI style (Ventura+ has the new Settings layout; older versions use System Preferences)
- Any **sub-pane or tab** visible (e.g., Keyboard > Text Input > Input Sources)

State this clearly at the top of your response.

### Step 2: Read Every Visible Setting

Go through the screenshot **top to bottom, left to right** and list every setting you can see:
- Toggle switches (on/off)
- Dropdown menus (selected value)
- Sliders (approximate position/value)
- Checkboxes (checked/unchecked)
- Radio buttons (which is selected)
- Text fields (entered value)
- Segmented controls (which segment is active)

### Step 3: Map to `defaults write` Commands

For each visible setting, produce the command. Follow this priority:

1. **Exact match in references** — Use the documented command verbatim
2. **Known domain + likely key** — Use the known domain with the most probable key name
3. **Best-effort guess** — Mark with `# ⚠️ UNVERIFIED` comment

### Step 4: Output Format

Produce a clean shell script block:

```bash
#!/usr/bin/env bash
# macOS Settings: [Pane Name]
# Generated from screenshot analysis
# Some settings may require logout/restart to take effect

# Close System Settings to prevent it from overriding changes
osascript -e 'tell application "System Settings" to quit'

###############################################################################
# [Section Name]                                                              #
###############################################################################

# [Human-readable description of what this setting does]
# UI: System Settings > [Path] > "[Setting Label]"
# Values: [list possible values if known]
defaults write [domain] "[key]" -[type] "[value]"

# ... more commands ...

###############################################################################
# Apply changes                                                               #
###############################################################################

# Restart affected processes
killall Dock 2>/dev/null
killall Finder 2>/dev/null
killall SystemUIServer 2>/dev/null
```

---

## Rules

### Command Format
- Always include the **human-readable comment** above each command
- Always include the **UI path** comment showing where this is in System Settings
- Always include **possible values** as a comment when known
- Group commands by section with banner comments
- Include `killall` for processes that need restart (Dock, Finder, SystemUIServer)
- Include notes about logout/restart requirements where applicable

### Accuracy Principles
- **Never fabricate a domain or key** — If you don't know it, say so
- **Prefer references over guessing** — Always check the reference files first
- **Mark uncertainty clearly** — Use `# ⚠️ UNVERIFIED` for best-effort guesses
- **Note deprecated commands** — Some older commands don't work on newer macOS
- **Include both variants** when a setting requires writing to multiple domains (e.g., trackpad settings often need both `com.apple.AppleMultitouchTrackpad` and `com.apple.driver.AppleBluetoothMultitouch.trackpad`)

### Settings That Can't Be Set via `defaults write`
Some settings use different mechanisms. Note these explicitly:
- **Power management** → `sudo pmset`
- **Computer name** → `sudo scutil --set`
- **Time zone** → `sudo systemsetup -settimezone`
- **Firmware/boot** → `sudo nvram`
- **Spotlight** → `sudo mdutil`
- **File flags** → `chflags`
- **Complex plists** → `/usr/libexec/PlistBuddy`
- **Network settings** → Often not scriptable via defaults
- **iCloud settings** → Generally not scriptable
- **Apple ID / Sign-in settings** → Not scriptable
- **Privacy & Security permissions** → Managed by TCC database, not defaults

### When Settings Are Not Recognizable
If you can see a setting in the screenshot but cannot determine the correct command:
1. Describe what the setting appears to be
2. Suggest what domain it likely belongs to
3. Recommend using `defaults read [domain]` to discover the key
4. Suggest the "diff before/after" technique:
   ```bash
   defaults read > /tmp/before.txt
   # Change the setting in System Settings
   defaults read > /tmp/after.txt
   diff /tmp/before.txt /tmp/after.txt
   ```

---

## Common Domain Quick Reference

| System Settings Pane | Primary Domain(s) |
|---|---|
| Desktop & Dock | `com.apple.dock` |
| Finder | `com.apple.finder`, `NSGlobalDomain` |
| Keyboard | `NSGlobalDomain`, `com.apple.HIToolbox` |
| Trackpad | `com.apple.AppleMultitouchTrackpad` |
| Mouse | `NSGlobalDomain` (mouse keys) |
| Mission Control | `com.apple.dock` (mru-spaces, expose-*) |
| Screenshots | `com.apple.screencapture` |
| Appearance | `NSGlobalDomain` |
| Menu Bar / Clock | `com.apple.menuextra.clock` |
| Safari | `com.apple.Safari` |
| Mail | `com.apple.mail` |
| Messages | `com.apple.messageshelper.MessageController` |
| TextEdit | `com.apple.TextEdit` |
| Activity Monitor | `com.apple.ActivityMonitor` |
| Time Machine | `com.apple.TimeMachine` |
| Xcode | `com.apple.dt.Xcode` |
| Terminal | `com.apple.Terminal` |
| Accessibility | `com.apple.universalaccess` |
| Screen Saver | `com.apple.screensaver` |
| Software Update | `com.apple.SoftwareUpdate` |
| Login Window | `/Library/Preferences/com.apple.loginwindow` (sudo) |
