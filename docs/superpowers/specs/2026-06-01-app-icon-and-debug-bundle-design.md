# Real Time Quote App Icon And Debug Bundle Design

## Overview

This spec defines a small packaging pass for `Real Time Quote` so the app feels more complete outside Xcode. The goal is to add a recognizable macOS app icon and produce a double-clickable `Debug .app` bundle that Tony can launch directly from Finder.

## Goals

- Create a new app icon for `Real Time Quote`
- Make the icon feel like a live crypto quote tool, not a generic utility
- Keep the icon readable in Finder, Dock, and app switcher sizes
- Wire the icon into the macOS app bundle so the built app shows the correct icon everywhere
- Produce a `Debug .app` build artifact that can be launched by double-clicking

## Non-Goals

- Installing the app into `/Applications`
- Creating a signed Release build
- Creating a `.dmg`, installer, or notarized distribution flow
- Adding multiple icon themes or user-selectable icon variants

## User Experience

The app should appear in Finder and the Dock with a polished icon that immediately suggests real-time market data. The icon should use a dark trading-screen visual language, include `RTQ`, and incorporate restrained green / red quote cues without becoming visually noisy.

After the build step, Tony should be able to open the generated `.app` directly from Finder without opening Xcode.

## Design

### Icon Direction

The icon will follow a terminal-style quote aesthetic:

- dark background
- `RTQ` as the central identifier
- subtle green and red market-motion accents
- clean composition that still reads well at small sizes

The icon should feel native to macOS rather than like a web banner or exchange screenshot. It should prioritize clarity over detail.

### Asset Integration

The icon will be added through the app's asset catalog in the standard macOS app icon slot. The project should reference the icon through normal Xcode asset configuration so no custom runtime loading is required.

If the project does not yet have a full app icon asset structure, this work should add the minimum required asset layout for a standard macOS app icon set.

### Build Output

The build flow will produce a `Debug .app` bundle in a predictable location under the repo, such as:

- `Build/Debug/RealTimeQuote.app`

If Xcode's build output needs to land elsewhere for technical reasons, the implementation should still end with a clear, stable path that can be shared with Tony.

## Implementation Notes

- Prefer generating the icon from a single high-resolution master image, then deriving the required macOS icon sizes from it
- Keep generated icon assets checked into the repo if they are required for the app to build correctly on another machine
- Avoid introducing a packaging script unless the existing build flow truly needs one
- Preserve the current project structure and keep this change narrowly scoped to icon assets and build output usability

## Verification

Implementation is complete when all of the following are true:

1. The app builds successfully from the Xcode project
2. The generated `.app` bundle shows the new icon in Finder
3. Launching the `.app` by double-clicking opens `Real Time Quote`
4. The final handoff includes the exact path to the generated `.app`

## Risks And Mitigations

- macOS icon assets can be tedious if sizes are incomplete
  - Mitigation: generate from one master image and fill the expected macOS icon slots systematically
- The default Xcode output path may be inconvenient for everyday use
  - Mitigation: choose or document a predictable build location for the Debug bundle
- A visually dense icon may look muddy in small sizes
  - Mitigation: keep the composition bold and simple, with only a few distinct elements
