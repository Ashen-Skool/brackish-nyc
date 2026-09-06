Locked in: cinematic underwater atmosphere, a field-journal mascot, NYC, and one instruction followed by autonomous execution.

The key constraint is **no API keys**. The prompt will require an app that works without service setup, while preventing fake fish identification, invented fishing conditions, or pretend shopping integrations.

Paste this as your `/goal`:
```text
Build and finish an exceptional native iOS fishing app for New York City. Own the entire process: product decisions, research, art direction, implementation, original assets, animation, testing, iteration, documentation, and delivery.

This is an open-source showcase of GPT-6 Astra’s app-design and engineering ability. The user supplies this brief once. Work autonomously until the acceptance criteria are met, using reasonable judgment instead of asking routine questions. Do not stop after planning, scaffolding, a successful build, or the first attractive screen.

PRODUCT AND PERSONALITY

Choose an original name and develop a coherent identity.

The direction is cinematic underwater atmosphere combined with a personal field journal. Create an original mascot that feels like a thoughtful illustrated fishing companion. Give it a name, personality, and purposeful appearances in onboarding, identification, journal entries, and empty states. Keep it charming and restrained.

The design must feel authored by an excellent independent design and animation studio. Avoid generic dashboard layouts, repetitive rounded cards, gratuitous gradients, glass effects everywhere, emoji icons, placeholder copy, and decorative charts. Establish deliberate typography, composition, color, illustration, sound where appropriate, and motion.

Use the built-in Codex image generation capability for original concept art, mascot artwork, illustrations, textures, and other useful assets. Read the applicable skills. Generate visual targets before implementing the interface, preserve prompts and selected assets, and use them as references during iteration.

CORE EXPERIENCE

Deliver three complete, connected journeys:

1. Identify and record a catch.
Capture or import a fish photograph, obtain useful species identification, explore species information, and save an editable journal entry with photo, date, location, notes, and optional measurements.

Identification must perform real analysis. Use a suitably licensed bundled on-device model or another genuinely available approach requiring no user credentials. Investigate feasibility early. Never disguise a mock, random selection, or user-selected species as automated recognition. Support uncertainty, multiple candidates, unsuitable photographs, and manual confirmation. Document supported species and measured limitations.

2. Plan a fishing trip in NYC.
Provide a working map with location permission handling, search, curated fishing locations, spot details, likely species, access information, and equipment guidance. Cover appropriate freshwater and saltwater opportunities within the NYC launch scope.

Let people explore without granting location permission. Make “near me” useful with the device location or a manually selected area. Explain why each recommendation fits; do not claim an objectively “best” spot without supporting evidence.

3. Prepare and remember.
Build useful trip checklists, saved spots, species references, and a beautiful private catch journal. Recommend tackle and explain its purpose. Provide truthful ways to find equipment, such as verified retailer links or map searches. Do not invent inventory, prices, availability, or affiliate relationships.

You may add features that strengthen these journeys. Prioritize depth and finish.

NO REQUIRED KEYS OR ACCOUNTS

The delivered app must launch and provide its core experience without API keys, subscriptions, service accounts, a custom backend, or user registration.

Use native platform capabilities, local persistence, bundled reference content, and genuinely suitable public resources. Never rely on undocumented endpoints, embedded secrets, or services that prohibit this use. Do not initiate paid services or purchases.

Persist user content across launches. Support export and deletion. Design graceful offline behavior, permission denial, unavailable external resources, and recovery from interrupted actions.

CONTENT AND TRUST

Research NYC fishing access, species, and relevant regulations from authoritative sources. Include source links and review dates. Distinguish stable reference material from changing conditions and rules.

Do not fabricate weather, tides, catch reports, access rights, stocking information, or live recommendations. Omit unsupported live features rather than presenting invented data.

Photo identification must not imply that a fish is safe to eat or legal to keep. Avoid exposing precise catch locations by default. Keep photo handling and location use private and explain them clearly.

MOTION AND CRAFT

Develop a consistent motion system with choreography, pacing, interruption behavior, and haptics. Build memorable transitions for onboarding, capture-to-identification, the species reveal, map-to-spot details, and saving a journal entry.

Animations must support direct interaction, respond correctly to canceled gestures, and remain smooth during loading and navigation. Respect Reduce Motion, Dynamic Type, VoiceOver, contrast, and safe areas.

Inspect actual app screenshots and screen recordings against the visual targets. Identify concrete weaknesses, fix them, and repeat. Verify animation quality in motion.

ENGINEERING AND VERIFICATION

Prefer native Swift and SwiftUI, using UIKit or other native frameworks where they materially improve the result. Read applicable project instructions and skills before implementation.

Use the configured Astra model and record the actual model/settings when available; never claim settings were changed without verification. Follow the workspace’s rules for Studio compute, session ownership, and Git synchronization.

Choose a realistic device and OS support target. Build and run the app in the available simulator and on a physical device if one is available. Verify onboarding, camera/photo-library flows, identification, map exploration, saved locations, checklist editing, journal persistence, export, deletion, restart, and failure states.

Use meaningful automated tests for core logic and persistence. Measure scrolling and animation performance using available profiling tools, targeting 60 fps on declared hardware. Clearly distinguish simulator evidence from physical-device measurements.

DELIVERY AND COMPLETION

Deliver:
- A complete Xcode project and reproducible setup instructions.
- Original editable assets, generation prompts, and design references.
- A suitable open-source license and third-party notices, including model and dataset licenses.
- Tests, validation results, screenshots, and a short recorded walkthrough suitable for the showcase video.
- Privacy documentation and a concise release checklist.
- All project work committed and pushed to its GitHub remote in this session.

A clean checkout must build with documented prerequisites and no service credentials.

Treat this as a release candidate, not a prototype. Audit every visible control and eliminate dead ends, fake functionality, placeholder content, and unresolved critical defects.

Do not claim App Store submission, production readiness, recognition accuracy, or performance without evidence. If a requirement cannot be completed with the available tools or resources, pursue reasonable alternatives, complete everything independent of it, and report the precise remaining blocker honestly.

Begin now and carry the work through delivery.
```