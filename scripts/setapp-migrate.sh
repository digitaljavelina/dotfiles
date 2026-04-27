#!/bin/bash
# Setapp Migration Helper
# Run on your new Mac after installing Setapp

apps=(
  "AirBuddy" "Almighty" "Asset Catalog Creator Pro" "Bartender"
  "BetterZip" "Buildwatch" "CameraBag Pro" "Capto" "CleanMyMac"
  "CleanShot X" "ClearVPN" "Dash" "DevUtils" "Diagrams" "Downie"
  "Dropshare" "Expressions" "Flinto" "Flow" "ForkLift" "Gemini"
  "Glyphfinder" "Home Inventory" "HoudahSpot" "Hustl" "Hype"
  "IconJar" "Image2icon" "iStat Menus" "iThoughtsX" "Lofi Garden"
  "Luminar" "Luminar Neo" "Marked" "MindNode Classic"
  "Mockuuups Studio" "MoneyWiz" "MurmurType" "Nitro PDF Pro"
  "Noizio" "Paletro" "Path Finder" "Paw" "PDF Squeezer" "Permute"
  "Petrify" "PixelSnap" "PopClip" "Prizmo" "Proxyman" "QuickLens"
  "RapidWeaver" "Renamer" "Shimo" "Sip" "Sizzy" "Soulver"
  "Squash" "Structured" "Swift Publisher" "Tab Finder" "TextSniper"
  "TextSoap" "TouchRetouch" "Transloader" "TripMode" "Typeface"
  "Ulysses" "Unclutter" "Unite" "VirtualHostX" "Webfont" "Whisk"
  "WhisperTranscribe" "WiFi Explorer"
)

echo "=== Setapp Migration Helper ==="
echo "Total apps to install: ${#apps[@]}"
echo ""
echo "This will copy each app name to your clipboard."
echo "Paste it into Setapp's search and click Install."
echo ""

for i in "${!apps[@]}"; do
  app="${apps[$i]}"
  num=$((i + 1))
  echo "$app" | pbcopy
  echo "[$num/${#apps[@]}] \"$app\" copied to clipboard"
  echo "    → Paste into Setapp search, click Install"
  read -p "    Press Enter for next app (or 'q' to quit): " input
  if [[ "$input" == "q" ]]; then
    echo "Stopped at app $num. Resume from here next time."
    break
  fi
done

echo ""
echo "Done! Check System Settings → Privacy & Security for any apps needing permissions."