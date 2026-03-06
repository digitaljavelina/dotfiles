# Mathias Bynens .macos Reference

Source: https://mths.be/macos (https://github.com/mathiasbynens/dotfiles/blob/main/.macos)

This is the canonical community reference for macOS defaults. Organized by category.

## General UI/UX

```bash
# Disable transparency
defaults write com.apple.universalaccess reduceTransparency -bool true

# Set highlight color (RGB floats)
defaults write NSGlobalDomain AppleHighlightColor -string "0.764700 0.976500 0.568600"

# Sidebar icon size: 1=small, 2=medium, 3=large
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# Scrollbar visibility: WhenScrolling, Automatic, Always
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

# Disable focus ring animation
defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false

# Toolbar title rollover delay
defaults write NSGlobalDomain NSToolbarTitleViewRolloverDelay -float 0

# Window resize speed (Cocoa apps)
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Auto-quit printer app
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable quarantine dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable Resume system-wide
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# Disable automatic termination
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# Help Viewer non-floating
defaults write com.apple.helpviewer DevMode -bool true

# Disable auto-capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable auto period
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
```

## Trackpad, Mouse, Keyboard, Input

```bash
# Tap to click (trackpad)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Bottom right corner = right-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Disable natural scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Bluetooth audio quality
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Full keyboard access (Tab in dialogs): 0=text, 3=all controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Ctrl+scroll zoom
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

# Key repeat instead of press-and-hold
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Key repeat rate (1=fastest)
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Language and locale
defaults write NSGlobalDomain AppleLanguages -array "en" "nl"
defaults write NSGlobalDomain AppleLocale -string "en_GB@currency=EUR"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true
```

## Screen

```bash
# Password after sleep/screensaver
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Screenshot location
defaults write com.apple.screencapture location -string "${HOME}/Desktop"

# Screenshot format: png, jpg, gif, pdf, bmp, tiff
defaults write com.apple.screencapture type -string "png"

# Disable screenshot shadow
defaults write com.apple.screencapture disable-shadow -bool true

# Font smoothing: 0=off, 1=light, 2=medium, 3=strong
defaults write NSGlobalDomain AppleFontSmoothing -int 1

# HiDPI display modes (sudo)
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
```

## Finder

```bash
# Allow quitting (Cmd+Q)
defaults write com.apple.finder QuitMenuItem -bool true

# Disable animations
defaults write com.apple.finder DisableAllAnimations -bool true

# Default location for new windows
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"

# Desktop icons
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Show all extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# POSIX path in title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Folders on top
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search current folder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# No extension change warning
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Spring loading
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# No .DS_Store on network/USB
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Skip disk image verification
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Auto-open on volume mount
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# List view by default: icnv, Nlsv, clmv, glyv
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# No empty trash warning
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# AirDrop over Ethernet
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Expanded File Info panes
defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true
```

## Dock, Dashboard, Hot Corners

```bash
# Hover highlight (stack grid view)
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Icon size
defaults write com.apple.dock tilesize -int 36

# Minimize effect: genie, scale, suck
defaults write com.apple.dock mineffect -string "scale"

# Minimize to app icon
defaults write com.apple.dock minimize-to-application -bool true

# Spring loading for Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show process indicators
defaults write com.apple.dock show-process-indicators -bool true

# No launch animation
defaults write com.apple.dock launchanim -bool false

# Mission Control animation speed
defaults write com.apple.dock expose-animation-duration -float 0.1

# Don't group windows by app
defaults write com.apple.dock expose-group-by-app -bool false

# Don't auto-rearrange Spaces
defaults write com.apple.dock mru-spaces -bool false

# No autohide delay
defaults write com.apple.dock autohide-delay -float 0

# No autohide animation
defaults write com.apple.dock autohide-time-modifier -float 0

# Autohide Dock
defaults write com.apple.dock autohide -bool true

# Hidden apps translucent
defaults write com.apple.dock showhidden -bool true

# No recent apps
defaults write com.apple.dock show-recents -bool false
```

## Safari

```bash
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true
defaults write com.apple.Safari WebKitTabToLinksPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks -bool true
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
defaults write com.apple.Safari HomePage -string "about:blank"
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
defaults write com.apple.Safari ShowFavoritesBar -bool false
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true
defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true
defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false
defaults write com.apple.Safari AutoFillFromAddressBook -bool false
defaults write com.apple.Safari AutoFillPasswords -bool false
defaults write com.apple.Safari AutoFillCreditCardData -bool false
defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true
```

## Mail

```bash
defaults write com.apple.mail DisableReplyAnimations -bool true
defaults write com.apple.mail DisableSendAnimations -bool true
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" "@\U21a9"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "yes"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"
defaults write com.apple.mail DisableInlineAttachmentViewing -bool true
defaults write com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"
```

## Terminal & iTerm 2

```bash
# UTF-8 only
defaults write com.apple.terminal StringEncodings -array 4

# Secure Keyboard Entry
defaults write com.apple.terminal SecureKeyboardEntry -bool true

# No line marks
defaults write com.apple.Terminal ShowLineMarks -int 0

# No iTerm quit prompt
defaults write com.googlecode.iterm2 PromptOnQuit -bool false
```

## Time Machine

```bash
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
```

## Activity Monitor

```bash
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
# Icon type: 5=CPU usage
defaults write com.apple.ActivityMonitor IconType -int 5
# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0
```

## TextEdit

```bash
# Plain text mode
defaults write com.apple.TextEdit RichText -int 0
# UTF-8 encoding
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
```

## Mac App Store & Software Update

```bash
defaults write com.apple.appstore WebKitDeveloperExtras -bool true
defaults write com.apple.appstore ShowDebugMenu -bool true
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
defaults write com.apple.SoftwareUpdate ConfigDataInstall -int 1
defaults write com.apple.commerce AutoUpdate -bool true
defaults write com.apple.commerce AutoUpdateRestartRequired -bool true
```

## Photos

```bash
# No auto-open on device connect
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true
```

## Messages

```bash
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false
```

## Google Chrome

```bash
# Disable trackpad swipe navigation
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
# Disable mouse swipe navigation
defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false
# System print preview
defaults write com.google.Chrome DisablePrintPreview -bool true
# Expand print dialog
defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true
```

## Energy (pmset, not defaults)

```bash
sudo pmset -a lidwake 1
sudo pmset -a autorestart 1
sudo pmset -a displaysleep 15
sudo pmset -c sleep 0          # no sleep on charger
sudo pmset -b sleep 5          # 5min on battery
sudo pmset -a standbydelay 86400
sudo pmset -a hibernatemode 0  # 0=off, 3=default
```

## System (scutil, systemsetup, nvram)

```bash
# Computer name
sudo scutil --set ComputerName "MyMac"
sudo scutil --set HostName "MyMac"
sudo scutil --set LocalHostName "MyMac"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "MyMac"

# Timezone
sudo systemsetup -settimezone "America/New_York"

# Disable boot sound
sudo nvram SystemAudioVolume=" "

# Restart on freeze
sudo systemsetup -setrestartfreeze on

# Login window info
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true
```
