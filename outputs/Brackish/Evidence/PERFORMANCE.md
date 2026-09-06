# Performance evidence and limits

Target: iPhone 16, native display scale, 60 Hz / 16.67 ms frame budget. Available
execution: iOS 26.5 iPhone 16 simulator on an M3 Ultra Mac Studio, 256 GB RAM.
No available physical phone; no sustained physical-device 60 fps claim is supported.

The initial 45-second CADisplayLink capture (`motion-cadence-simulator.json`) covered
onboarding, native sheets, map navigation and photo work, while an Instruments
attachment was attempted. The median and p95 were 16.67 ms, p99 was 63.46 ms,
maximum 468.83 ms; 103 of 2,356 callbacks exceeded 25 ms.

The next capture (`motion-cadence-final.json`) was made without Instruments during
a full recorded workflow: median 16.67 ms, p95 22.51 ms, p99 62.67 ms, maximum
406.83 ms; 105 of 2,339 callbacks exceeded 25 ms. These intervals include native
system sheets, their transitions and capture/test overhead. They are callback
cadence, not GPU render times or an FPS benchmark. The two captures are not a
controlled before/after optimization comparison. Their long tails prevent a
claim of consistently meeting a 16.67 ms budget.

Photo file reads and downsampling now run in an actor instead of in SwiftUI body
evaluation on the main actor. Thumbnails are bounded to 1,200 pixels and cached
with a 32 MB cost limit. Long content sections use LazyVStack. Loading has stable
image frames; canceled tasks do not replace newer previews. The rendered journeys
were rerun after these changes. This avoids known sources of main-thread work,
but does not establish a quantified speedup from the mixed-scene samples above.

`xctrace` with the Animation Hitches template returned 'Hitches is not supported
on this platform.' The actual tool result is preserved in
`animation-instrument-limit.txt`; the failed trace is not described as valid
hitch evidence. Real device Instruments/Metal rendering, thermals, memory pressure,
power and sustained scroll/hitch measurements remain release checks.

Core ML's 36-image evaluation uses `.cpuOnly` on the simulator to avoid an
unsupported simulator MPSGraph path. On devices it requests `.all`. The recorded
simulator inference median was 144.08 ms, p95 151.62 ms, maximum 715.20 ms including
cold initialization. See `model-inference-timing.json`. This is not iPhone latency.

The recorded app output is 1178×2556 pixels. The shareable walkthrough is resized
for delivery; its nominal video frame rate must not be confused with measured
application FPS. Haptics are implemented but cannot be felt or verified on a
simulator. Authored animations consult Reduce Motion; physical spoken VoiceOver
and motion preference acceptance remain explicitly pending.

A later 45-second walkthrough callback capture (`motion-cadence-walkthrough.json`)
recorded median/p95 16.67 ms, p99 54.63 ms, maximum 399.87 ms and 72/2,421
intervals above 25 ms. It is still not a rendered-FPS measurement. At the final
live review the computer-use tool reported a locked desktop. Recordings show
transition-frame artifacts, so visual motion acceptance is pending an unlocked
foreground review; no cause or 60 fps success is inferred.
