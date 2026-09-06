# Accessibility review and audit boundaries

The native iOS 26.5 XCTest contrast audit reported offscreen SwiftUI text and
custom labels as failures. We did not describe the raw audit as a clean pass.
The captured issue crops are in accessibility-review/.

- The selected Journal label's actual screenshot colors were background
  RGB(232,218,200), foreground RGB(133,51,25): WCAG contrast **6.15:1**.
  Its semantic hierarchy was improved to one named button with a selected trait;
  the repeated child-label issue no longer appears in the latest hierarchy.
- The 'Write a new entry' label was still flagged after scrolling. Its captured
  interior background mode was RGB(9,35,37), foreground RGB(237,230,213):
  **13.20:1**, above both AA and AAA text thresholds. This one exact contrast
  issue is acknowledged as a reviewed false positive in the test issue handler.
  It is not a blanket suppression of contrast failures. An independent unit test
  computes relative luminance from the real theme colors and checks essential text.
- The audit also includes text outside the actual scroll viewport, where no glyph
  pixels exist. The test audits two scroll positions and handles only such
  clipped items for review in another position. Every exception is logged.
- The test continues to fail on other visible contrast, element-detection,
  description and trait problems. Full physical VoiceOver spoken-output testing
  was not possible without an available device and remains a release check.

At the largest Dynamic Type setting, the first visual review exposed word-broken
navigation labels. The final navigation chrome caps its caption scaling at the
largest standard category and keeps labels on one line, like a compact system
navigation control. All reading content and editor text retain full accessibility
scaling. Buttons keep named VoiceOver labels and normal touch targets. The largest
text-size navigation/editor journey is separately tested and captured.
