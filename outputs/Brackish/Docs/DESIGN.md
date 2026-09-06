# Brackish: art and interaction direction

Brackish is the meeting of river and sea, and of urban life and patient observation.
The identity is a cinematic harbor on the outside and a personal naturalist's
notebook within. Pip, a small watercolor harbor fish, notices rather than cheers.
He appears where a little guidance helps: introduction, photo framing, uncertain
comparison, empty journals and trip preparation. He is decoration or a brief
editorial voice; he never pretends to know the weather or the user's catch.

## Persistent visual targets

Design/visual-target-v1.png was generated before implementation. Its composition,
palette, paper contrast and typography are targets, not an app screenshot. Generated
mockup weather, tide and catch annotations were deliberately not implemented.
The separate harbor, Pip and icon originals are retained at full output resolution.
Only the icon was resized to the required 1024 square; the original remains.
See Design/PROMPTS.md for prompts, tool and provenance.

- Ink: #092426 approximately; deep teal #1F4A47.
- Paper: #F2EB D9 approximately (exact RGB in Views/Theme.swift).
- Rust: #963D1F approximately, used for field indices, selection and the map pins.
- Headings: native system serif; captions/body: native system sans; field indices:
  monospaced. No additional font license or network font download is required.
- Composition: large left-aligned headlines, fine rules, generous margins,
  numbered field marks, flowing editorial lists. No invented graphs or live metrics.
- Primary controls use one strong, full-width capsule. The single tab capsule
  groups four destinations. System sheets, pickers and controls remain recognizable.

## Motion specification

- First arrival: 0.8 second ease-out fade and 10 point settling motion.
- Onboarding chapters: 0.42 second ease-in-out change, driven by the Next/Back
  buttons. There is no timer advancing a page while someone is reading.
- Tab selection: 0.22 second ease-in-out highlight using matched geometry.
- Map area changes: 0.5 second native camera animation; map panning remains direct.
- Photo comparison: a native ProgressView appears while the actor runs. Cancellation
  is real and preserves the photo; results fade into place over 0.35 seconds.
- Species detail, map detail and journal editing use native interactive sheets
  and navigation. Canceled sheet gestures use UIKit/SwiftUI's built-in interpolation.
- Save commits data before haptic feedback and a short 'A moment, kept.' toast.
  A save failure leaves the editor open. The toast does not block touches.
- Light haptics mark navigation/selection; a medium impact marks durable save.
  No sound is added: silent operation is appropriate beside the water.
- Reduce Motion disables authored displacement/camera/selection/reveal animations;
  system transitions follow iOS accessibility settings. No perpetual background
  particle simulation burns the frame budget.

## Accessibility and adaptation

Dynamic Type is honored for body and semantic text; the editorial headline uses
ScaledMetric. Long content scrolls. System photo and permission interfaces remain
native. All tab symbols have text labels, every map place has an equivalent list
entry, and no important information is conveyed by color alone. The mascot is
hidden from accessibility when purely decorative; meaningful notes are combined.
Dark ink on paper and paper on ink are used for essential text. Source links explain
that they open externally. The app works without requesting location at onboarding.

## Iteration findings

The first live review found and corrected a safe-area gap below the underwater
background, a compressed wordmark in iOS 26 toolbar chrome, a crowded introduction,
and a journal action below the fold. The map was changed to muted emphasis and its
editorial caption moved away from Apple Maps attribution. Actual screenshots and
recorded interaction evidence belong in Evidence/, separate from the target board.

Raster assets are flattened but editable PNG originals, not claimed as vector or
hand-layered files. Typography, interface layout, motion and color tokens are fully
editable native Swift source. Generative artwork should not be used as a species
identification diagram; the fish field marks are sourced text.
