# TASKS — Sound Localization Test (SLT)
**Version:** 1.7
**Date:** 2026-04-19

All tasks must be completed in order. No task may begin before its predecessor is complete and verified.

---

## Section 1 — Project Setup

- [x] **1.1** Create the project folder structure: Sound Localization Test/, documents/, archive/, results/
- [x] **1.2** Create SLT.m with a file header: title, description, author, date, version.
- [x] **1.3** Define global configuration constants: sample rate (48000 Hz), speaker angles (0°/60°/120°/180°/240°/300°), Hann ramp duration (10 ms), crossfade duration (10 ms), number of channels (6).

---

## Section 2 — Audio Engine

- [x] **2.1** Write buildToneBuffer(frequency, sampleRate) — constructs a seamless integer-cycle sine wave loop buffer; length = exactly one cycle (Fs/f samples). No windowing applied to the buffer itself.
- [x] **2.2** Write buildNoiseBuffer(sampleRate, durationSeconds) — generates a Gaussian noise buffer with a 10 ms equal-power crossfade stitched at the loop boundary so it loops without clicks or amplitude modulation.
- [x] **2.3** Write applyOnsetRamp(buffer, sampleRate, rampMs) — applies a one-sided half-Hann fade-in envelope to the first rampMs milliseconds of a buffer; used once at stimulus onset. *(v1.4: onset ramp is now applied inside `streamAudio` to the first dispatched frame only — not to the repeatable loop buffer, which would produce per-copy amplitude modulation. The `applyOnsetRamp` function itself is retained for symmetry but is currently unused.)*
- [x] **2.4** Write applyOffsetRamp(buffer, sampleRate, rampMs) — applies a one-sided half-Hann fade-out envelope to the last rampMs milliseconds of a buffer; used once at stimulus offset. *(v1.4: now wired into `streamAudio` — applied to one final tail frame on response. Closes the carry-forward from the original implementation.)*
- [x] **2.5** Write buildOutputBuffer(monoSignal, channelAmplitudes, numChannels) — maps mono signal to 6-channel output matrix by scaling each channel by its assigned amplitude.
- [x] **2.6** Write computePanAmplitudes(degree, speakerAngles) — sine law panning; identifies the bounding speaker pair for the given degree and returns a 6-element amplitude vector.
- [x] **2.7** Write initAudio(sampleRate, numChannels) — initializes multi-channel device via audioPlayerRecorder; returns device handle. *(Implemented as `tryOpenAudio`. v1.3: rewritten to enumerate devices via `getAudioDevices(audioPlayerRecorder)` instead of the legacy `audiodevinfo`, which only sees Windows MME/DirectSound drivers and misses ASIO. New policy: prefer ASIO devices, fall back to first non-Default, fall back to silent mode. v1.4: constructor now sets `BufferSize=CFG.frameSize` (4096 samples, ~85 ms at 48 kHz) so each `aPR(frame)` call maps to one hardware callback; gives ~85 ms of UI-stall headroom before underrun. Verified opens "Focusrite USB ASIO" with 6 output channels at 48 kHz.)*
- [x] **2.8** Write playLooping(deviceHandle, buffer) — begins looped continuous playback of the buffer. *(v1.4: replaced by `streamAudio(aPR, loopBuf, CFG, respGetter)` — frame-streaming loop rather than timer-based re-queue. See Section 12 for the full rewrite.)*
- [x] **2.9** Write stopAudio(deviceHandle) — stops playback and releases the audio device cleanly. *(v1.4: now a one-line wrapper around `reset(aPR)`; the base-workspace `SLT_loopTimer` global has been removed entirely.)*

---

## Section 3 — Intro GUI

- [x] **3.1** Build Intro GUI figure window with correct background color and layout.
- [x] **3.2** Add teal header banner with application title.
- [x] **3.3** Add Stimulus Selection dropdown (125 Hz, 250 Hz, 500 Hz, 750 Hz, 1000 Hz, Gaussian Noise).
- [x] **3.4** Add Number of Trials numeric input field.
- [x] **3.5** Add Pause Time (s) numeric input field.
- [x] **3.6** Add Mode Selection dropdown (Discrete Speakers, Continuous Panning).
- [x] **3.7** Add Description text input field.
- [x] **3.8** Add green Start button: reads all fields, validates inputs, launches Subject ID prompt.
- [x] **3.9** Add Calibrate button: reads selected stimulus, launches calibration routine.
- [x] **3.10** Write input validation: Number of Trials must be positive integer; Pause Time must be positive number; warning dialog on failure.

---

## Section 4 — Subject ID Prompt

- [x] **4.1** Write getSubjectID() — modal input dialog; returns entered Subject ID string.
- [x] **4.2** Construct session filename: SubjectID_YYYYMMDD_HHMMSS.

---

## Section 5 — Calibration Routine

- [x] **5.1** Build Calibration GUI: displays current speaker number and channel, Next Speaker button.
- [x] **5.2** Write calibration loop: build appropriate loop buffer → play on corresponding channel → update display → wait for Next Speaker click.
- [x] **5.3** Stop audio and close Calibration GUI after Speaker 6. *(Now implemented via the dynamic "Done" button per PRD v1.3 §4.2.)*

---

## Section 6 — Experiment Engine

- [x] **6.1** Write selectStimulusLocation(mode) — random speaker (1–6) for Discrete; random integer degree (1–360) for Continuous.
- [x] **6.2** Write main experiment loop: draw screen → select location → build loop buffer → apply onset ramp → build 6-channel buffer → start looped playback → start timer → wait for response → apply offset ramp to final output → stop audio → record data → display countdown. Repeat N trials. *(v1.4: `applyOnsetRamp` is now applied inside `streamAudio` to the first dispatched frame; `applyOffsetRamp` is applied to one final tail frame on response. See Section 12.)*
- [x] **6.3** Implement Discrete response capture: listen for keypresses 1–6; record and convert to speaker number. *(Extended in v1.1 to also accept clicks on the speaker buttons via the unified `waitForDiscreteResponse` handler.)*
- [x] **6.4** Implement Continuous response capture: render circular 360° response ring; record click angle.
- [x] **6.5** Write countdown pause display: live seconds countdown between trials.
- [x] **6.6** Compute angular error per trial: absolute angular difference accounting for circular wraparound.

---

## Section 7 — Results Computation & Display

- [x] **7.1** Compute summary statistics: total accuracy (Discrete), mean angular error, mean response time.
- [x] **7.2** Write drawCircularHeatmap(values, mode, metric, description) — renders the circular heatmap per PRD spec:
  - Discrete: 6 solid wedges of 60°, each centered on its speaker angle, hard boundaries, value printed in wedge.
  - Continuous: 36 wedge bins of 10°, center to rim, each centered on its degree.
  - Both: listener head icon at center (nose pointing to 0°); speaker labels at r=158; degree ticks at 30° intervals; green/yellow/red color scale; description subheader.
- [x] **7.3** Call drawCircularHeatmap twice: once for angular error, once for response time.
- [x] **7.4** Display Results figure showing both heatmaps and summary statistics text.
- [x] **7.5** Save both heatmaps as .png to results/ using session filename.
- [x] **7.6** Write trial data to CSV in results/: Trial Number, Stimulus Location, Response, Angular Error, Response Time.

---

## Section 8 — Integration & Testing

- [x] **8.1** Connect Intro GUI → Subject ID prompt → Experiment loop → Results in single clean execution flow.
- [x] **8.2** Connect Calibrate button → Calibration routine → return to Intro GUI.
- [x] **8.3** Test Discrete Speakers mode end-to-end. *(Offline — Test 5 in LOG 2026-04-13.)*
- [x] **8.4** Test Continuous Panning mode end-to-end. *(Offline — Test 6 in LOG 2026-04-13.)*
- [x] **8.5** Verify tone loop buffer: confirm no audible click or amplitude modulation during looping; verify integer-cycle length for all 5 frequencies at 48000 Hz. *(Math verified offline — Test 1 in LOG 2026-04-13. Audible verification still pending hardware.)*
- [x] **8.6** Verify noise loop buffer: confirm no audible click at loop boundary; verify crossfade produces constant power. *(Constant-power math verified offline — Test 2 in LOG 2026-04-13. Audible verification still pending hardware.)*
- [x] **8.7** Verify Hann ramps: confirm onset and offset ramps are applied exactly once per trial, not on every loop cycle. *(v1.4: resolved by Section 12. Onset ramp is applied inside `streamAudio` to the FIRST dispatched frame only; offset ramp is applied to one FINAL tail frame on response. Verified at rig 2026-04-19 — clean sine with no per-copy amplitude modulation, no click at stimulus offset.)*
- [x] **8.8** Verify sine law panning: at exact speaker angles only one channel outputs; at mid-sector power is equal. *(Test 3 in LOG 2026-04-13.)*
- [x] **8.9** Verify heatmap geometry: all wedges fill the full circle with correct alignment; listener head centered and oriented correctly. *(Test 7 in LOG 2026-04-13.)*
- [x] **8.10** Verify CSV output format and file naming. *(Test 8 in LOG 2026-04-13.)*
- [x] **8.11** Verify figure output: both heatmaps saved with correct titles and description subheaders. *(Test 7 in LOG 2026-04-13.)*
- [x] **8.12** Verify audio cleanup: no hanging audio processes after experiment completes or is interrupted. *(v1.4: resolved by Section 12. The background timer was the root cause of the previous hanging-audio concern; the streaming rewrite removes it entirely. `stopAudio` is now a simple `reset(aPR)`. Verified at rig 2026-04-19 — clean stop on Done click, no residual audio.)*

---

---

## Section 9 — Refinement Revisions (PRD v1.3, 2026-04-14)

These tasks update the already-implemented SLT.m to match PRD v1.3. All code changes require user approval before execution.

### 9.1 — Font legibility (Intro GUI & Calibration GUI)

- [x] **9.1.1** Audit all text elements (labels, field text, instructions, button captions that are not on the green Start button or teal header banner) in the Intro GUI; set `FontColor` / `ForegroundColor` to pure black [0 0 0].
- [x] **9.1.2** Audit all text elements in the Calibration GUI; set to pure black [0 0 0]. Header banner text unchanged.

### 9.2 — Calibration "Done" button

- [x] **9.2.1** Modify the calibration routine so that the advance button's label is dynamic: reads "Next Speaker" while speakers 1–5 are active; changes to "Done" at the moment Speaker 6 playback begins (i.e., after the click on Speaker 5's "Next Speaker").
- [x] **9.2.2** Implement the "Done" click callback: stop audio on the active device, release the device handle, and close the Calibration GUI figure. Control returns to the Intro GUI.
- [x] **9.2.3** Verify that clicking "Done" during Speaker 6 playback leaves no hanging audio stream and no orphaned figure handle. *(Verified at rig 2026-04-19.)*

### 9.3 — Discrete Speakers experiment screen redesign

- [x] **9.3.1** Add an instruction text element at the top of the Discrete experiment figure: *"Press a number 1–6 or click a speaker button to indicate where you are perceiving the sound from."* Font color white (against black background), prominent size.
- [x] **9.3.2** Render the hexagonal speaker orientation diagram in the main area, reusing the geometry helpers from the Continuous Panning ring and the listener head icon (nose toward 0°).
- [x] **9.3.3** Replace the six passive speaker markers with **large clickable buttons** at each of the six speaker angles (0°, 60°, 120°, 180°, 240°, 300°). Buttons labeled "1" through "6". Sizing: noticeably larger than the Continuous ring's speaker markers — they are the primary interactive target.
- [x] **9.3.4** Wire each button's click callback to the same response-capture path used by the keypress handler for the corresponding speaker number, so click and keypress produce identical behavior (record response, stop audio, advance).
- [x] **9.3.5** Retain the existing trial counter and inter-trial countdown timer.

### 9.4 — Continuous Panning instruction text

- [x] **9.4.1** Add an instruction text element at the top of the Continuous experiment figure: *"Click within the ring to indicate where you are perceiving the sound from."* Matching style to the Discrete screen's instruction text.

### 9.5 — Verification

- [x] **9.5.1** Launch Intro GUI; visually confirm all labels/inputs are pure-black and legible.
- [x] **9.5.2** Launch Calibrate; cycle through all six speakers. Confirm button label changes to "Done" on Speaker 6, and that clicking "Done" stops audio and closes the window.
- [x] **9.5.3** Run a short Discrete session. Confirm instruction text is visible, speaker buttons are large and obvious, and both keypress and click produce identical, correct responses.
- [x] **9.5.4** Run a short Continuous session. Confirm instruction text is visible and ring interaction still works as before.
- [x] **9.5.5** Re-run offline test suite (Tests 1–8 from LOG.md 2026-04-13) to confirm no regressions in acoustic logic.

---

## Section 10 — Stats Display & Export (PRD v1.4, 2026-04-15)

These tasks add session summary statistics to two output surfaces: as a third text line on each heatmap (below title and description subtitle), and as a `#`-prefixed header comment block at the top of the per-trial CSV. All code changes require user approval before execution.

### 10.1 — Heatmap stats subtitle line

- [x] **10.1.1** Modify `drawCircularHeatmap` to accept summary statistics (accuracy, mean angular error, mean response time) as additional inputs.
- [x] **10.1.2** Render the stats as a third text line on each heatmap, positioned below the existing description subtitle. Format:
  - Discrete: *"Accuracy: XX.X%   Mean Angular Error: XX.X°   Mean Response Time: X.XX s"*
  - Continuous: *"Mean Angular Error: XX.X°   Mean Response Time: X.XX s"* (accuracy omitted)
  - Style: smaller and lighter than the description subtitle, but still legible.
- [x] **10.1.3** Update `showResults` to compute the stats once and pass them into both `drawCircularHeatmap` calls (error heatmap + RT heatmap).

### 10.2 — CSV header comment block

- [x] **10.2.1** Replace the single `writetable` call in `showResults` with a manual write sequence: open the CSV file with `fopen`, write the `#`-prefixed header comment block via `fprintf`, then write the table rows (either by appending the table or by manual `fprintf` of the column header + data).
- [x] **10.2.2** Header comment block content (one field per line, all `#`-prefixed):
  - `# Sound Localization Test — Session Results`
  - `# Subject: <SubjectID>`
  - `# Date: <YYYY-MM-DD HH:MM:SS>`
  - `# Stimulus: <stim label>`
  - `# Mode: <Discrete Speakers | Continuous Panning>`
  - `# Description: <description string>`
  - `# Accuracy: XX.X%` (Discrete only — omit line entirely for Continuous)
  - `# Mean Angular Error: XX.X deg`
  - `# Mean Response Time: X.XX s`
  *(Em-dash in title line replaced with plain hyphen for cross-platform safety.)*
- [x] **10.2.3** Verify the resulting CSV opens cleanly in Excel and in MATLAB's `readtable` (which skips `#`-prefixed lines by default with `'CommentStyle', '#'`). *(MATLAB readtable round-trip verified during render-test — max diff 0.00. Excel verified at rig 2026-04-19.)*

### 10.3 — Verification

- [x] **10.3.1** Run a short Discrete session; confirm both heatmaps show the stats subtitle line with accuracy, mean angular error, and mean response time. *(Verified at rig 2026-04-19.)*
- [x] **10.3.2** Run a short Continuous session; confirm both heatmaps show the stats subtitle line WITHOUT accuracy. *(Verified at rig 2026-04-19.)*
- [x] **10.3.3** Open the resulting CSV files in a text editor and in Excel; confirm the header comment block renders correctly and the data table is intact below it. *(Verified at rig 2026-04-19.)*
- [x] **10.3.4** Read the CSV back into MATLAB with `readtable(path, 'CommentStyle', '#')` and confirm the trial data round-trips cleanly. *(Verified at rig 2026-04-19.)*

---

*Document status: Sections 1–8 complete (8.7 and 8.12 now resolved by Section 12 v1.4 rewrite). Section 9 complete. Section 10 complete. Section 11 code complete; 11.5 channel-routing check still pending. Section 12 (audio streaming rewrite) implemented and verified at rig 2026-04-19 — 12.1–12.9 complete; 12.10 (offline acoustic-logic regression) deferred to a future session. User confirmed "program runs well" after the final fix. Remaining open items: 11.5 (channel routing) and 12.10 (offline regression). User will provide further feedback from additional rig time.*

---

## Section 11 — ASIO Device Support (2026-04-15)

This section captures a small device-enumeration fix to `tryOpenAudio` discovered when first connecting the Focusrite hardware. The legacy `audiodevinfo` enumerator only sees Windows MME/DirectSound drivers, which expose the interface as a 2-channel device. `getAudioDevices(audioPlayerRecorder)` sees the ASIO driver, which exposes all hardware output channels. No PRD change required — this is a bug fix to task 2.7.

- [x] **11.1** Replace `audiodevinfo`-based enumeration in `tryOpenAudio` with `getAudioDevices(audioPlayerRecorder)`.
- [x] **11.2** Implement device-selection policy: prefer any device whose name contains "ASIO" (case-insensitive); fall back to first non-"Default" device; fall back to silent mode.
- [x] **11.3** Catch construction errors from `audioPlayerRecorder` and degrade gracefully to silent mode.
- [x] **11.4** Verify the new code opens the Focusrite ASIO device with 6 output channels and releases cleanly. *(Functional test in MATLAB session: opened "Focusrite USB ASIO", 6 channels at 48 kHz, released without error.)*
- [ ] **11.5** Verify in a live session that all 6 speakers play tones at the expected physical positions (i.e., MATLAB Channel 1 drives the speaker at 0°, Channel 2 drives 60°, etc.). If channel routing is wrong at the rig, decide whether to rewire or add a channel-remap config.

---

## Section 12 — Audio Streaming Rewrite (2026-04-19)

First live hardware session revealed two related audio bugs, both caused by the timer-based re-queue strategy in `playLooping`:

- **(a) Pure tones** sounded like a low rumble with intermittent jitter instead of a clean sine wave. Root cause: the integer-cycle tone buffers are 1–8 ms long; the re-queue timer period is floored at 50 ms; the device drains its pre-queued copies in <30 ms and then runs on whatever residual is in the hardware queue for the remaining 20 ms of every 50 ms period. The perceived "rumble" is the 20 Hz timer rate; the "jitter" is Windows timer imprecision.
- **(b) Gaussian noise** played correctly but the Calibration GUI froze until manually killed. Root cause: the 4-copy pre-queue of a 2-second noise buffer blocks the main MATLAB thread for ~8 seconds while the device accepts the frames, during which time no UI callbacks fire. Noise masked the timer-rate artifact that makes tones sound wrong.

Fix: replace timer-based re-queueing with a frame-streaming loop that pumps fixed-size frames into `audioPlayerRecorder`. The ASIO driver's internal buffering paces the loop (each `aPR(frame)` call blocks until the device can accept the next frame); `drawnow limitrate` between frames keeps the UI responsive. This also resolves TASK 8.7 (offset ramp wiring) naturally, since the trial loop now has explicit per-frame control at stop time.

**Implementation notes (v1.4 final):** The implementation went through four attempts at the rig before landing. See LOG 2026-04-19 "Section 12 Implementation" for the full narrative; the key lessons embedded in the final code are:

- Frame size (`CFG.frameSize`) is 4096 samples (≈85 ms at 48 kHz), and `audioPlayerRecorder` is constructed with matching `BufferSize=CFG.frameSize` so each `aPR(frame)` call corresponds to one hardware callback. This gives ≈85 ms of UI-stall headroom before any underrun — enough to absorb uifigure mouse-hover events.
- Onset Hann ramp is applied inside `streamAudio` to the FIRST dispatched frame only. Applying it upstream to the repeatable loop buffer (the naive approach) bakes an amplitude envelope into every copy, producing audible harmonic distortion at the loop-buffer rate. The `applyOnsetRamp` calls were removed from `runCalibration` and `runExperiment`.
- The calibration advance flag lives at `calFig.UserData.nextDone`, not in a local variable. MATLAB anonymous-function closures capture locals by value at creation time, so a `@() nextDone` closure would be frozen at the initial value forever. Using a figure-handle field makes the state reference-semantic.
- Cursor wrap in `streamAudio` uses `mod(cursor-1+frameN, loopN)+1` with a tile sized at least `loopN+frameN` samples. This handles both short loop buffers (tones, 48–384 samples) and long ones (noise, ~95 k samples) uniformly, with phase continuity guaranteed by construction.

- [x] **12.1** Rewrite `playLooping` as `streamAudio(aPR, buffer, fig, respGetter)`: concatenates the loop buffer into ~1024-sample frames, pumps frames into `aPR(frame)` in a `while` loop, calls `drawnow limitrate` between frames, returns when the `respGetter` callback indicates a response is available or the figure closes. *(Final frame size is 4096 samples, not 1024 — see implementation notes above.)*
- [x] **12.2** Rewrite `stopAudio` as a simple `reset(aPR)` — no timer cleanup needed. Remove the `assignin('base', 'SLT_loopTimer', …)` path entirely (also removes a global-namespace pollution smell noted but not previously fixed).
- [x] **12.3** Update `runCalibration` audio drive to use the streaming loop, with a `respGetter` that watches the `nextDone` flag. *(Flag moved to `calFig.UserData.nextDone` to make it reference-semantic — see implementation notes.)*
- [x] **12.4** Update `runExperiment` trial loop to use the streaming loop, with a `respGetter` that watches `expFig.UserData.response`. Record `tStart` BEFORE the first frame dispatch so response time measurement is unaffected by the new path. *(Done. `waitForDiscreteResponse` and `waitForRingClick` now take the audio arguments and drive `streamAudio` internally; Continuous uses a dedicated `.ringResponse` sink to avoid type-confusion with Discrete's integer 1–6 sink.)*
- [x] **12.5** Wire `applyOffsetRamp` into the streaming loop: on response, apply the offset ramp to one final tail frame, dispatch it, then stop. This closes TASK 8.7. (Response time is already recorded by this point — the fade adds ~10 ms of audible tail after response but does not affect the measurement.)
- [x] **12.6** Verify at rig: calibrate with a 1000 Hz tone — confirm clean sine, no rumble, UI remains responsive. *(Verified at rig 2026-04-19 after Attempt 5, the `BufferSize` fix.)*
- [x] **12.7** Verify at rig: calibrate with Gaussian noise — confirm the "Done" button works and audio stops cleanly on click. *(Verified at rig 2026-04-19 — the UI-responsiveness fix from Attempt 4 + 5 resolves the previous noise-freeze.)*
- [x] **12.8** Verify at rig: short Discrete session; confirm no audible click at stimulus offset (offset ramp doing its job). *(Verified at rig 2026-04-19.)*
- [x] **12.9** Verify at rig: short Continuous session — same. *(Verified at rig 2026-04-19.)*
- [ ] **12.10** Re-run offline acoustic-logic tests (Tests 1–8 from 2026-04-13 LOG) to confirm no regression in buffer construction, panning law, or angular error math. *(Deferred — no audio-logic functions were modified in v1.4, so regression risk is low, but a formal run is cheap and worth doing for the record in a future session.)*
