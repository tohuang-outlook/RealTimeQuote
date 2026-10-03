# Atlas Pulse Route Preview Design

## Goal

Upgrade the route preview from a functional demo into a cleaner, more filmic travel-route presentation that stays information-first while adding stronger pacing at key moments.

## Direction

This design follows the "between documentary and social short video" direction:

- the base state stays restrained and map-led
- transitions feel intentional and chapter-like
- emphasis appears only at departures, arrivals, and transport changes

The result should still read like a route record, not a flashy promo.

## Experience

Each route segment should play as a short scene:

1. camera eases toward the active route region
2. origin marker brightens before movement starts
3. route line draws outward with the transport marker traveling along it
4. destination holds briefly so the viewer can register the arrival
5. scene softens and hands off to the next segment

Multi-stop routes should feel like a sequence of concise chapters instead of one continuous sweep.

## Visual System

### Map

- keep the dark atlas base
- reduce continent contrast slightly so the route line leads the eye
- keep borders only as hints, not as primary graphics

### Route Line

- make the line slightly finer and brighter
- preserve a subtle glow, but avoid exaggerated tails or particles
- use transport color as the dominant accent

### Labels

- replace plain text labels with compact subtitle cards
- cards should have a dark translucent base and tight typography
- keep city names short and legible rather than decorative

### Transport Cue

- show a small transient transport title such as `PLANE`, `TRAIN`, or `CAR`
- this title should appear during the early part of each segment, then fade

## Timing

The first pass should target this cadence per segment:

- `0.0s - 0.4s`: origin highlight and camera settle
- `0.4s - 2.2s`: route draw and marker travel
- `2.2s - 3.0s`: destination hold
- `3.0s - 3.4s`: soft fade toward next segment

Transport types can keep different travel durations, but the chapter structure should remain consistent.

## Technical Scope

Only preview-layer resources change in the first pass:

- `RealTimeQuote/Resources/RoutePreview/route-preview.js`
- `RealTimeQuote/Resources/RoutePreview/route-preview.css`
- `RealTimeQuote/Resources/RoutePreview/route-preview.html`

No changes to:

- Swift export pipeline
- route timing generation in Swift
- ffmpeg fallback or writer logic
- geocoding or trip planning logic

## Non-Goals

The first pass intentionally excludes:

- 3D globe rendering
- particle systems
- audio synchronization
- complex cinematic overlays
- large typography redesign outside the preview

## Validation

Success for this pass means:

- the preview still renders for existing routes
- the route remains readable at a glance
- multi-segment playback feels paced and intentional
- labels and transport cues look closer to subtitles than UI controls
