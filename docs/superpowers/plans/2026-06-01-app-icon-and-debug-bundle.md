# Real Time Quote App Icon And Debug Bundle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a polished `RTQ` macOS app icon and produce a double-clickable `Debug .app` bundle for `Real Time Quote`.

**Architecture:** The implementation will add a single master icon image plus derived macOS app icon assets inside the app asset catalog, then keep build output predictable by building the existing Xcode target into a repo-local `Build/Debug` location. No runtime code paths should change beyond the app bundle metadata that points Finder and Dock at the new icon.

**Tech Stack:** SwiftUI macOS app, Xcode asset catalogs, shell image tooling (`sips`, `iconutil` if needed), `xcodebuild`

---

## File Structure

- Modify: `RealTimeQuote.xcodeproj/project.pbxproj`
  - Keep any asset references or build-setting updates needed for the app icon and repo-local build output.
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/Contents.json`
  - Define the macOS icon set slots and filenames.
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_16x16.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_32x32.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_128x128.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_256x256.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_512x512.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIconMaster.png`
  - High-resolution source image used to derive the icon set.
- Test: repo-local build artifact at `Build/Debug/RealTimeQuote.app`
  - Final deliverable path for Finder launch.

### Task 1: Inspect existing asset setup and app metadata

**Files:**
- Modify: `RealTimeQuote.xcodeproj/project.pbxproj`
- Test: `RealTimeQuote/Assets.xcassets`

- [ ] **Step 1: Inspect current asset catalog and app target settings**

Run:

```bash
find RealTimeQuote -maxdepth 3 \( -name "*.xcassets" -o -name "Info.plist" \) -print
```

Expected: discover whether an asset catalog already exists and whether an `AppIcon.appiconset` is already present.

- [ ] **Step 2: Inspect the target build settings for asset usage**

Run:

```bash
xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -showBuildSettings | rg "ASSETCATALOG|INFOPLIST|PRODUCT_BUNDLE_IDENTIFIER"
```

Expected: confirm the app target uses an asset catalog and record any existing `ASSETCATALOG_COMPILER_APPICON_NAME`.

- [ ] **Step 3: Commit reconnaissance notes only if the project needs a structural asset fix**

```bash
git status --short
```

Expected: no code changes yet. If edits were not needed, skip commit and continue.

### Task 2: Create the icon master image and derived macOS icon assets

**Files:**
- Create: `RealTimeQuote/Assets.xcassets/AppIconMaster.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_16x16.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_32x32.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_128x128.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_256x256.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_512x512.png`
- Create: `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png`

- [ ] **Step 1: Add the master image**

Create a 1024x1024 PNG at:

```text
RealTimeQuote/Assets.xcassets/AppIconMaster.png
```

Visual requirements:

- near-black background
- centered `RTQ`
- restrained green and red quote accents
- simple composition that reads at dock scale

Expected: one source-of-truth image exists before any resizing.

- [ ] **Step 2: Create the macOS app icon asset manifest**

Write `RealTimeQuote/Assets.xcassets/AppIcon.appiconset/Contents.json` with:

```json
{
  "images" : [
    { "filename" : "icon_16x16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon_16x16@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon_32x32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon_32x32@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon_128x128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon_128x128@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon_256x256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon_256x256@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon_512x512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon_512x512@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 3: Generate the derived icon PNGs from the master**

Run:

```bash
mkdir -p RealTimeQuote/Assets.xcassets/AppIcon.appiconset
sips -z 16 16 RealTimeQuote/Assets.xcassets/AppIconMaster.png --out RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_16x16.png
sips -z 32 32 RealTimeQuote/Assets.xcassets/AppIconMaster.png --out RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png
sips -z 32 32 RealTimeQuote/Assets.xcassets/AppIconMaster.png --out RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_32x32.png
sips -z 64 64 RealTimeQuote/Assets.xcassets/AppIconMaster.png --out RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png
sips -z 128 128 RealTimeQuote/Assets.xcassets/AppIconMaster.png --out RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_128x128.png
sips -z 256 256 RealTimeQuote/Assets.xcassets/AppIconMaster.png --out RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png
sips -z 256 256 RealTimeQuote/Assets.xcassets/AppIconMaster.png --out RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_256x256.png
sips -z 512 512 RealTimeQuote/Assets.xcassets/AppIconMaster.png --out RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png
sips -z 512 512 RealTimeQuote/Assets.xcassets/AppIconMaster.png --out RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_512x512.png
cp RealTimeQuote/Assets.xcassets/AppIconMaster.png RealTimeQuote/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png
```

Expected: every required macOS icon slot has a concrete PNG file.

- [ ] **Step 4: Commit the icon assets**

```bash
git add RealTimeQuote/Assets.xcassets/AppIconMaster.png RealTimeQuote/Assets.xcassets/AppIcon.appiconset
git commit -m "feat: add Real Time Quote app icon assets"
```

### Task 3: Wire the app icon into the Xcode target

**Files:**
- Modify: `RealTimeQuote.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write the failing verification command**

Run:

```bash
xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -showBuildSettings | rg "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon"
```

Expected: if the project is not already wired correctly, the command should fail to match.

- [ ] **Step 2: Add the minimal project setting**

Ensure the app target build settings include:

```text
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
```

Expected: the Xcode target points at the standard `AppIcon.appiconset`.

- [ ] **Step 3: Re-run verification**

Run:

```bash
xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -showBuildSettings | rg "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon"
```

Expected: one or more matching lines for the target.

- [ ] **Step 4: Commit the target wiring**

```bash
git add RealTimeQuote.xcodeproj/project.pbxproj
git commit -m "chore: wire macOS app icon asset"
```

### Task 4: Produce the double-clickable Debug app bundle

**Files:**
- Test: `Build/Debug/RealTimeQuote.app`

- [ ] **Step 1: Build into a repo-local output path**

Run:

```bash
mkdir -p Build
xcodebuild -project RealTimeQuote.xcodeproj -scheme RealTimeQuote -configuration Debug -destination 'platform=macOS' -derivedDataPath Build/DerivedData build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Materialize a stable Finder-friendly app path**

Run:

```bash
mkdir -p Build/Debug
rm -rf Build/Debug/RealTimeQuote.app
cp -R Build/DerivedData/Build/Products/Debug/RealTimeQuote.app Build/Debug/RealTimeQuote.app
```

Expected: `Build/Debug/RealTimeQuote.app` exists and is launchable by double-clicking.

- [ ] **Step 3: Verify the app bundle exists at the handoff path**

Run:

```bash
test -d Build/Debug/RealTimeQuote.app && echo "APP_READY"
```

Expected: `APP_READY`

- [ ] **Step 4: Commit any build-helper project changes only if needed**

```bash
git status --short
```

Expected: no new tracked source changes from the build itself. If none, skip commit.

### Task 5: Manual icon and launch verification

**Files:**
- Test: `Build/Debug/RealTimeQuote.app`

- [ ] **Step 1: Launch the built app bundle**

Run:

```bash
open Build/Debug/RealTimeQuote.app
```

Expected: `Real Time Quote` opens without needing Xcode.

- [ ] **Step 2: Verify the Finder-visible icon**

Check in Finder or with desktop automation that:

- `Build/Debug/RealTimeQuote.app` shows the new `RTQ` icon
- the Dock icon matches the new app icon while the app is running

Expected: both Finder and Dock show the updated icon.

- [ ] **Step 3: Commit the final verified state**

```bash
git status --short
```

Expected: only intentional source assets or project metadata remain tracked.
