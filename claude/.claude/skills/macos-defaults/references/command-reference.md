# macOS System Configuration Command Reference

## defaults

Command line interface to a user's defaults (property list preferences).

```
defaults [-currentHost | -host <hostname>] followed by:
  read                                 shows all defaults
  read <domain>                        shows defaults for given domain
  read <domain> <key>                  shows defaults for given domain, key
  read-type <domain> <key>             shows the type for the given domain, key
  write <domain> <domain_rep>          writes domain (overwrites existing)
  write <domain> <key> <value>         writes key for domain
  rename <domain> <old_key> <new_key>  renames old_key to new_key
  delete <domain>                      deletes domain
  delete <domain> <key>                deletes key in domain
  import <domain> <path to plist>      writes all of the keys in path to domain
  export <domain> <path to plist>      saves domain as a binary plist to path
  domains                              lists all domains
  find <word>                          lists all entries containing word
```

### Value Types
```
-string <string_value>
-data <hex_digits>
-int[eger] <integer_value>
-float <floating-point_value>
-bool[ean] (true | false | yes | no)
-date <date_rep>
-array <value1> <value2> ...
-array-add <value1> <value2> ...
-dict <key1> <value1> <key2> <value2> ...
-dict-add <key1> <value1> ...
```

### Domain Formats
```
<domain_name>                          e.g., com.apple.dock
-app <application_name>                e.g., -app Safari
-globalDomain  (or NSGlobalDomain)     system-wide settings
/path/to/file                          direct plist path (omit .plist)
```

### Tips
- `defaults domains | tr ',' '\n'` — List all domains
- `defaults read <domain>` — Read all keys in a domain
- `defaults read-type <domain> <key>` — Check value type
- `defaults find <word>` — Search all domains for a word
- `defaults -currentHost write` — Write to current host only (per-machine)
- `defaults delete <domain> <key>` — Remove a key (reset to default)

## PlistBuddy

Read and write values to plists. Useful for complex nested structures.

```
/usr/libexec/PlistBuddy [-cxh] <file.plist>
    -c "<command>"    execute command
    -x                output as XML
    -h                help
```

### Commands
```
Print [<Entry>]                    Print value of Entry
Set <Entry> <Value>                Set value at Entry
Add <Entry> <Type> [<Value>]       Add Entry with Type and optional Value
Delete <Entry>                     Delete Entry
Copy <EntrySrc> <EntryDst>         Copy property
Merge <file.plist> [<Entry>]       Merge file contents into Entry
Import <Entry> <file>              Import file contents as Entry
```

### Entry Format
Entries use colon-delimited paths. Array items are zero-indexed.
```
:CFBundleShortVersionString
:CFBundleDocumentTypes:2:CFBundleTypeExtensions
:DesktopViewSettings:IconViewSettings:showItemInfo
```

### Types
`string`, `array`, `dict`, `bool`, `real`, `integer`, `date`, `data`

### Example
```bash
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
```

## pmset

Power management settings.

```
sudo pmset -a <setting> <value>    # all power sources
sudo pmset -c <setting> <value>    # charger/AC
sudo pmset -b <setting> <value>    # battery
```

### Common Settings
| Setting | Values | Description |
|---|---|---|
| `lidwake` | `0`/`1` | Wake on lid open |
| `autorestart` | `0`/`1` | Restart on power loss |
| `displaysleep` | minutes | Display sleep timeout |
| `sleep` | minutes / `0` | System sleep timeout |
| `standbydelay` | seconds | Time before standby |
| `hibernatemode` | `0`/`3`/`25` | 0=off, 3=safe sleep, 25=hibernate |
| `disksleep` | minutes | Disk sleep timeout |
| `halfdim` | `0`/`1` | Display dim before sleep |

### Tips
- `pmset -g` — Show current settings
- `pmset -g ps` — Show power source info

## systemsetup

Machine-level system settings. Requires sudo.

```bash
sudo systemsetup -settimezone "America/New_York"
sudo systemsetup -setcomputersleep Off
sudo systemsetup -setdisplaysleep 15
sudo systemsetup -setrestartfreeze on
sudo systemsetup -setremotelogin on
sudo systemsetup -setwakeonnetworkaccess on
```

### Tips
- `sudo systemsetup -listtimezones` — List all timezones
- `sudo systemsetup -printCommands` — List all commands

## scutil

System configuration parameters.

```bash
sudo scutil --set ComputerName "MyMac"
sudo scutil --set HostName "MyMac"
sudo scutil --set LocalHostName "MyMac"
scutil --get ComputerName
scutil --dns       # show DNS config
scutil --proxy     # show proxy config
```

## nvram

Firmware NVRAM variables.

```bash
sudo nvram SystemAudioVolume=" "     # disable boot sound
nvram -p                             # print all variables
sudo nvram -d <variable>             # delete a variable
```

## mdutil

Spotlight indexing control.

```bash
sudo mdutil -i on /                  # enable indexing
sudo mdutil -i off /                 # disable indexing
sudo mdutil -E /                     # erase and rebuild index
sudo mdutil -s /                     # print indexing status
```

## chflags

File flags (visibility, immutability).

```bash
chflags nohidden ~/Library           # show ~/Library
chflags hidden ~/Library             # hide ~/Library
sudo chflags nohidden /Volumes       # show /Volumes
```

## launchctl

Service/daemon management.

```bash
launchctl load -w <plist>            # load and enable
launchctl unload -w <plist>          # unload and disable
launchctl list                       # list all services
```

## Discovery Technique: Diff Before/After

When a setting has no known `defaults write` command, use this approach:

```bash
# 1. Capture current state
defaults read > /tmp/before.txt

# 2. Change the setting in System Settings GUI

# 3. Capture new state
defaults read > /tmp/after.txt

# 4. Find what changed
diff /tmp/before.txt /tmp/after.txt
```

For specific domains:
```bash
defaults read com.apple.dock > /tmp/dock-before.txt
# Change a Dock setting
defaults read com.apple.dock > /tmp/dock-after.txt
diff /tmp/dock-before.txt /tmp/dock-after.txt
```
