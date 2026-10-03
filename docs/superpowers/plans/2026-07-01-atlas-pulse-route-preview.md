# Atlas Pulse Route Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the route preview into a more cinematic, chapter-based route playback while keeping the map clear and information-first.

**Architecture:** Keep all first-pass changes inside the preview web assets. The JavaScript timeline will be refactored into clearer phases per segment, the HTML will expose lightweight containers for subtitle-style cues, and the CSS will restyle labels, overlays, and transport headers to support the new motion language.

**Tech Stack:** SwiftUI host app, bundled HTML/CSS/JavaScript renderer, SVG animation, Xcode build verification.

---

### Task 1: Add Preview Overlay Structure

**Files:**
- Modify: `RealTimeQuote/Resources/RoutePreview/route-preview.html`
- Test: `RealTimeQuoteTests/RoutePreviewBridgeTests.swift`

- [ ] Add lightweight overlay containers for transport and segment cue text inside the preview shell.
- [ ] Keep existing bridge bootstrap and segment payload injection unchanged.
- [ ] Verify the HTML still contains the bridge bootstrap strings used by the existing tests.

### Task 2: Rework Segment Playback Phases

**Files:**
- Modify: `RealTimeQuote/Resources/RoutePreview/route-preview.js`

- [ ] Refactor segment playback into consistent phases: pre-light, travel, arrival hold, and handoff fade.
- [ ] Add transient transport title handling and chapter-like subtitle updates per segment.
- [ ] Keep export-time frame rendering support intact by routing both interactive playback and export playback through the same phased renderer.

### Task 3: Upgrade Visual Styling

**Files:**
- Modify: `RealTimeQuote/Resources/RoutePreview/route-preview.css`

- [ ] Restyle the preview overlay, subtitle cards, and transport title to feel more cinematic and less like raw UI labels.
- [ ] Reduce base map prominence while slightly increasing route prominence.
- [ ] Add restrained motion-friendly styles such as fades and soft transforms without introducing noisy effects.

### Task 4: Verify Preview Integration

**Files:**
- Modify if needed: `RealTimeQuoteTests/RoutePreviewBridgeTests.swift`

- [ ] Run a build to ensure bundled preview assets still compile into the app.
- [ ] Keep existing bridge tests passing or update them only if HTML structure assertions need to reflect the new overlay containers.
- [ ] Confirm no Swift export-path code needs changes for the first pass.
