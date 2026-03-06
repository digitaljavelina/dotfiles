# macos-defaults.com Reference

Source: https://macos-defaults.com

## Dock

Domain: `com.apple.dock`
UI: System Settings > Desktop & Dock

| Setting | Key | Type | Default | Values | Restart |
|---|---|---|---|---|---|
| Position | `orientation` | string | `"bottom"` | `"left"`, `"bottom"`, `"right"` | `killall Dock` |
| Icon size | `tilesize` | int | `48` | Any int (pixels) | `killall Dock` |
| Autohide | `autohide` | bool | `false` | `true`/`false` | `killall Dock` |
| Autohide animation | `autohide-time-modifier` | float | `0.5` | `0`=instant, `0.5`=default, `2`=slow | `killall Dock` |
| Autohide delay | `autohide-delay` | float | `0.2` | `0`=no delay | `killall Dock` |
| Show recents | `show-recents` | bool | `true` | `true`/`false` | `killall Dock` |
| Minimize effect | `mineffect` | string | `"genie"` | `"genie"`, `"scale"`, `"suck"` | `killall Dock` |
| Active apps only | `static-only` | bool | `false` | `true`/`false` | `killall Dock` |
| Scroll to Expose | `scroll-to-open` | bool | `false` | `true`/`false` | `killall Dock` |
| Magnification | `magnification` | bool | `false` | `true`/`false` | `killall Dock` |
| Magnification size | `largesize` | int | `64` | Any int (pixels) | `killall Dock` |
| Minimize to app icon | `minimize-to-application` | bool | `false` | `true`/`false` | `killall Dock` |
| Show indicators | `show-process-indicators` | bool | `true` | `true`/`false` | `killall Dock` |
| Launch animation | `launchanim` | bool | `true` | `true`/`false` | `killall Dock` |
| Hidden app translucency | `showhidden` | bool | `false` | `true`/`false` | `killall Dock` |
| Spring loading | `enable-spring-load-actions-on-all-items` | bool | `false` | `true`/`false` | `killall Dock` |
| Hover highlight (stacks) | `mouse-over-hilite-stack` | bool | `false` | `true`/`false` | `killall Dock` |

### Hot Corners

Domain: `com.apple.dock`

Corner values: `0`=no-op, `2`=Mission Control, `3`=App Windows, `4`=Desktop, `5`=Screen Saver Start, `6`=Screen Saver Disable, `7`=Dashboard, `10`=Display Sleep, `11`=Launchpad, `12`=Notification Center, `13`=Lock Screen

| Corner | Key | Modifier Key |
|---|---|---|
| Top Left | `wvous-tl-corner` | `wvous-tl-modifier` |
| Top Right | `wvous-tr-corner` | `wvous-tr-modifier` |
| Bottom Left | `wvous-bl-corner` | `wvous-bl-modifier` |
| Bottom Right | `wvous-br-corner` | `wvous-br-modifier` |

Modifier values: `0`=none, `131072`=Shift, `262144`=Control, `524288`=Option, `1048576`=Command

## Finder

Domain: `com.apple.finder` unless noted
UI: Finder > Settings / System Settings

| Setting | Key | Domain | Type | Default | Values | Restart |
|---|---|---|---|---|---|---|
| Quit Finder | `QuitMenuItem` | com.apple.finder | bool | `false` | `true`/`false` | `killall Finder` |
| Show extensions | `AppleShowAllExtensions` | NSGlobalDomain | bool | `false` | `true`/`false` | `killall Finder` |
| Show hidden files | `AppleShowAllFiles` | com.apple.finder | bool | `false` | `true`/`false` | `killall Finder` |
| Path bar | `ShowPathbar` | com.apple.finder | bool | `false` | `true`/`false` | `killall Finder` |
| Status bar | `ShowStatusBar` | com.apple.finder | bool | `false` | `true`/`false` | `killall Finder` |
| Default view | `FXPreferredViewStyle` | com.apple.finder | string | `"icnv"` | `"icnv"`, `"Nlsv"`, `"clmv"`, `"glyv"` | `killall Finder` |
| Folders on top | `_FXSortFoldersFirst` | com.apple.finder | bool | `false` | `true`/`false` | `killall Finder` |
| Search scope | `FXDefaultSearchScope` | com.apple.finder | string | `"SCev"` | `"SCev"`, `"SCcf"`, `"SCsp"` | `killall Finder` |
| Auto-empty trash (30d) | `FXRemoveOldTrashItems` | com.apple.finder | bool | `false` | `true`/`false` | `killall Finder` |
| Extension change warning | `FXEnableExtensionChangeWarning` | com.apple.finder | bool | `true` | `true`/`false` | `killall Finder` |
| Open in tabs | `FinderSpawnTab` | com.apple.finder | bool | `true` | `true`/`false` | `killall Finder` |
| Save to iCloud | `NSDocumentSaveNewDocumentsToCloud` | NSGlobalDomain | bool | `true` | `true`/`false` | — |
| Title bar icons | `showWindowTitlebarIcons` | com.apple.universalaccess | bool | `false` | `true`/`false` | `killall Finder` |
| Toolbar rollover delay | `NSToolbarTitleViewRolloverDelay` | NSGlobalDomain | float | `0.5` | `0`–`1` | `killall Finder` |
| Sidebar icon size | `NSTableViewDefaultSizeMode` | NSGlobalDomain | int | `2` | `1`=small, `2`=medium, `3`=large | `killall Finder` |
| POSIX path in title | `_FXShowPosixPathInTitle` | com.apple.finder | bool | `false` | `true`/`false` | `killall Finder` |
| Column auto-sizing | `_FXEnableColumnAutoSizing` | com.apple.finder | bool | `false` | `true`/`false` | `killall Finder` |
| Empty Trash warning | `WarnOnEmptyTrash` | com.apple.finder | bool | `true` | `true`/`false` | `killall Finder` |

### New Finder Window Target

| Key | Value | Meaning |
|---|---|---|
| `NewWindowTarget` | `"PfCm"` | Computer |
| `NewWindowTarget` | `"PfVo"` | Volume |
| `NewWindowTarget` | `"PfHm"` | Home |
| `NewWindowTarget` | `"PfDe"` | Desktop |
| `NewWindowTarget` | `"PfDo"` | Documents |
| `NewWindowTarget` | `"PfAF"` | All My Files |
| `NewWindowTarget` | `"PfLo"` | Other (use `NewWindowTargetPath`) |

## Desktop

Domain: `com.apple.finder`

| Setting | Key | Type | Default | Values |
|---|---|---|---|---|
| Show all icons | `CreateDesktop` | bool | `true` | `true`/`false` |
| Folders on top | `_FXSortFoldersFirstOnDesktop` | bool | `false` | `true`/`false` |
| Hard drives | `ShowHardDrivesOnDesktop` | bool | `false` | `true`/`false` |
| External drives | `ShowExternalHardDrivesOnDesktop` | bool | `true` | `true`/`false` |
| Removable media | `ShowRemovableMediaOnDesktop` | bool | `true` | `true`/`false` |
| Connected servers | `ShowMountedServersOnDesktop` | bool | `false` | `true`/`false` |

## Screenshots

Domain: `com.apple.screencapture`

| Setting | Key | Type | Default | Values |
|---|---|---|---|---|
| Shadow | `disable-shadow` | bool | `false` | `true`=no shadow |
| Date in name | `include-date` | bool | `true` | `true`/`false` |
| Location | `location` | string | `"~/Desktop"` | Any path |
| Thumbnail | `show-thumbnail` | bool | `true` | `true`/`false` |
| Format | `type` | string | `"png"` | `"png"`, `"jpg"`, `"pdf"`, `"psd"`, `"gif"`, `"tga"`, `"tiff"`, `"bmp"`, `"heic"` |

## Keyboard

| Setting | Key | Domain | Type | Default | Values |
|---|---|---|---|---|---|
| Press and hold | `ApplePressAndHoldEnabled` | NSGlobalDomain | bool | `true` | `true`=accents, `false`=key repeat |
| Fn key | `AppleFnUsageType` | com.apple.HIToolbox | int | `0` | `0`=nothing, `1`=input source, `2`=emoji, `3`=dictation |
| F-keys as standard | `com.apple.keyboard.fnState` | NSGlobalDomain | bool | `false` | `true`=standard F-keys |
| Keyboard navigation | `AppleKeyboardUIMode` | NSGlobalDomain | int | `0` | `0`=off, `2`=on (Tab focus), `3`=all controls |
| Period with double-space | `NSAutomaticPeriodSubstitutionEnabled` | NSGlobalDomain | bool | `true` | `true`/`false` |
| Auto-capitalization | `NSAutomaticCapitalizationEnabled` | NSGlobalDomain | bool | `true` | `true`/`false` |
| Smart dashes | `NSAutomaticDashSubstitutionEnabled` | NSGlobalDomain | bool | `true` | `true`/`false` |
| Smart quotes | `NSAutomaticQuoteSubstitutionEnabled` | NSGlobalDomain | bool | `true` | `true`/`false` |
| Auto-correct | `NSAutomaticSpellingCorrectionEnabled` | NSGlobalDomain | bool | `true` | `true`/`false` |
| Key repeat rate | `KeyRepeat` | NSGlobalDomain | int | `6` | `1`=fastest, `2`, `6`=default |
| Initial key repeat | `InitialKeyRepeat` | NSGlobalDomain | int | `25` | `10`=shortest, `15`, `25`=default |
| Language indicator | `TSMLanguageIndicatorEnabled` | kCFPreferencesAnyApplication | bool | `true` | `true`/`false` |

## Trackpad

Domain: `com.apple.AppleMultitouchTrackpad`
UI: System Settings > Trackpad

| Setting | Key | Type | Default | Values |
|---|---|---|---|---|
| Click force | `FirstClickThreshold` | int | `1` | `0`=light, `1`=medium, `2`=firm |
| Drag lock | `DragLock` | bool | `false` | `true`/`false` |
| Dragging | `Dragging` | bool | `false` | `true`/`false` |
| Three-finger drag | `TrackpadThreeFingerDrag` | bool | `false` | `true`/`false` |
| Tap to click | `Clicking` | bool | `false` | `true`/`false` |
| Natural scrolling | `com.apple.swipescrolldirection` (NSGlobalDomain) | bool | `true` | `true`=natural |

Note: Trackpad settings often require BOTH domains:
- `com.apple.AppleMultitouchTrackpad`
- `com.apple.driver.AppleBluetoothMultitouch.trackpad`

## Mouse

| Setting | Key | Domain | Type | Default | Values |
|---|---|---|---|---|---|
| Acceleration | `com.apple.mouse.linear` | NSGlobalDomain | bool | `false` | `true`=disable acceleration |
| Speed | `com.apple.mouse.scaling` | NSGlobalDomain | float | `1.0` | `0.0`–`3.0` (higher=faster) |
| Natural scrolling | `com.apple.swipescrolldirection` | NSGlobalDomain | bool | `true` | `true`=natural |

## Mission Control

| Setting | Key | Domain | Type | Default | Values |
|---|---|---|---|---|---|
| Auto-rearrange Spaces | `mru-spaces` | com.apple.dock | bool | `true` | `true`/`false` |
| Group by app | `expose-group-apps` | com.apple.dock | bool | `false` | `true`/`false` |
| Switch to Space | `AppleSpacesSwitchOnActivate` | NSGlobalDomain | bool | `true` | `true`/`false` |
| Separate Spaces | `spans-displays` | com.apple.spaces | bool | `false` | `false`=separate, `true`=span |
| MC animation speed | `expose-animation-duration` | com.apple.dock | float | `1.0` | `0.1`=fast |

## Menu Bar Clock

Domain: `com.apple.menuextra.clock`

| Setting | Key | Type | Default | Values |
|---|---|---|---|---|
| Flash separators | `FlashDateSeparators` | bool | `false` | `true`/`false` |
| Date format | `DateFormat` | string | varies | See Unicode date format tokens |

## Safari

Domain: `com.apple.Safari`

| Setting | Key | Type | Default |
|---|---|---|---|
| Full URL | `ShowFullURLInSmartSearchField` | bool | `false` |
| Home page | `HomePage` | string | `""` |
| Auto-open safe downloads | `AutoOpenSafeDownloads` | bool | `true` |
| Show favorites bar | `ShowFavoritesBar` | bool | `false` |
| Develop menu | `IncludeDevelopMenu` | bool | `false` |
| Do Not Track | `SendDoNotTrackHTTPHeader` | bool | `false` |
| Search suggestions | `SuppressSearchSuggestions` | bool | `false` |

## TextEdit

Domain: `com.apple.TextEdit`

| Setting | Key | Type | Default | Values |
|---|---|---|---|---|
| Rich text mode | `RichText` | bool | `true` | `true`=RTF, `false`=plain text |
| Smart quotes | `SmartQuotes` | bool | `true` | `true`/`false` |

## Appearance (NSGlobalDomain)

| Setting | Key | Type | Default | Values |
|---|---|---|---|---|
| Dark mode | `AppleInterfaceStyle` | string | (absent) | `"Dark"` (delete key for Light) |
| Accent color | `AppleAccentColor` | int | (absent) | `-1`=Graphite, `0`=Red, `1`=Orange, `2`=Yellow, `3`=Green, `5`=Purple, `6`=Pink, `(absent)`=Blue |
| Highlight color | `AppleHighlightColor` | string | (absent) | RGB float triple e.g. `"0.764700 0.976500 0.568600"` |
| Scrollbar visibility | `AppleShowScrollBars` | string | `"Automatic"` | `"WhenScrolling"`, `"Automatic"`, `"Always"` |
| Reduce transparency | `reduceTransparency` (com.apple.universalaccess) | bool | `false` | `true`/`false` |
| Reduce motion | `reduceMotion` (com.apple.universalaccess) | bool | `false` | `true`/`false` |
| Font smoothing | `AppleFontSmoothing` | int | `1` | `0`=off, `1`=light, `2`=medium, `3`=strong |

## Miscellaneous

| Setting | Key | Domain | Type | Default | Values |
|---|---|---|---|---|---|
| Apple Intelligence | `545129924` | com.apple.CloudSubscriptionFeatures.optIn | bool | `true` | `true`/`false` |
| Quarantine popup | `LSQuarantine` | com.apple.LaunchServices | bool | `true` | `true`/`false` |
| Close confirms changes | `NSCloseAlwaysConfirmsChanges` | NSGlobalDomain | bool | `true` | `true`/`false` |
| Keep windows on quit | `NSQuitAlwaysKeepsWindow` | NSGlobalDomain | bool | `true` | `true`/`false` |
| Help Menu floating | `DevMode` | com.apple.helpviewer | bool | `false` | `true`=non-floating |
| Music notifications | `userWantsPlaybackNotifications` | com.apple.Music | bool | `true` | `true`/`false` |
| Expand save panel | `NSNavPanelExpandedStateForSaveMode` | NSGlobalDomain | bool | `false` | `true`/`false` |
| Expand save panel 2 | `NSNavPanelExpandedStateForSaveMode2` | NSGlobalDomain | bool | `false` | `true`/`false` |
| Expand print panel | `PMPrintingExpandedStateForPrint` | NSGlobalDomain | bool | `false` | `true`/`false` |
| Expand print panel 2 | `PMPrintingExpandedStateForPrint2` | NSGlobalDomain | bool | `false` | `true`/`false` |
