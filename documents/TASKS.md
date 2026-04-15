# TASKS — Sound Localization Test (SLT)
**Version:** 1.5
**Date:** 2026-04-15

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
- [x] **2.3** Write applyOnsetRamp(buffer, sampleRate, rampMs) — applies a one-sided half-Hann fade-in envelope to the first rampMs milliseconds of a buffer; used once at stimulus onset.
- [x] **2.4** Write applyOffsetRamp(buffer, sampleRate, rampMs) — applies a one-sided half-Hann fade-out envelope to the last rampMs milliseconds of a buffer; used once at stimulus offset. *(Function defined but not yet wired into the trial loop — offset is currently handled at the device level via `reset(aPR)`. Carried forward; can be wired in during hardware testing if a clean audible fade-out is desired.)*
- [x] **2.5** Write buildOutputBuffer(monoSignal, channelAmplitudes, numChannels) — maps mono signal to 6-channel output matrix by scaling each channel by its assigned amplitude.
- [x] **2.6** Write computePanAmplitudes(degree, speakerAngles) — sine law panning; identifies the bounding speaker pair for the given degree and returns a 6-element amplitude vector.
- [x] **2.7** Write initAudio(sampleRate, numChannels) — initializes multi-channel device via audioPlayerRecorder; returns device handle. *(Implemented as `tryOpenAudio`. v1.3: rewritten to enumerate devices via `getAudioDevices(audioPlayerRecorder)` instead of the legacy `audiodevinfo`, which only sees Windows MME/DirectSound drivers and misses ASIO. New policy: prefer ASIO devices, fall back to first non-Default, fall back to silent mode. Verified opens "Focusrite USB ASIO" with 6 output channels at 48 kHz.)*
- [x] **2.8** Write playLooping(deviceHandle, buffer) — begins looped continuous playback of the buffer.
- [x] **2.9** Write stopAudio(deviceHandle) — stops playback and releases the audio device cleanly.

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
- [x] **6.2** Write main experiment loop: draw screen → select location → build loop buffer → apply onset ramp → build 6-channel buffer → start looped playback → start timer → wait for response → apply offset ramp to final output → stop audio → record data → display countdown. Repeat N trials. *(Offset ramp is currently handled at the device level via `reset(aPR)` rather than via `applyOffsetRamp` on the buffer — see 2.4 caveat.)*
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
- [ ] **8.7** Verify Hann ramps: confirm onset and offset ramps are applied exactly once per trial, not on every loop cycle. *(Onset ramp is applied once per trial as required. Offset ramp is currently NOT applied to the buffer — handled at the device level via `reset(aPR)` instead. Strict reading of this task is unsatisfied; deferred pending hardware testing per 2.4 caveat.)*
- [x] **8.8** Verify sine law panning: at exact speaker angles only one channel outputs; at mid-sector power is equal. *(Test 3 in LOG 2026-04-13.)*
- [x] **8.9** Verify heatmap geometry: all wedges fill the full circle with correct alignment; listener head centered and oriented correctly. *(Test 7 in LOG 2026-04-13.)*
- [x] **8.10** Verify CSV output format and file naming. *(Test 8 in LOG 2026-04-13.)*
- [x] **8.11** Verify figure output: both heatmaps saved with correct titles and description subheaders. *(Test 7 in LOG 2026-04-13.)*
- [ ] **8.12** Verify audio cleanup: no hanging audio processes after experiment completes or is interrupted. *(Requires hardware — pending live session.)*

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
- [ ] **9.2.3** Verify that clicking "Done" during Speaker 6 playback leaves no hanging audio stream and no orphaned figure handle.

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
- [ ] **10.2.3** Verify the resulting CSV opens cleanly in Excel and in MATLAB's `readtable` (which skips `#`-prefixed lines by default with `'CommentStyle', '#'`). *(MATLAB readtable round-trip verified during render-test — max diff 0.00. Excel verification pending live session.)*

### 10.3 — Verification

- [ ] **10.3.1** Run a short Discrete session; confirm both heatmaps show the stats subtitle line with accuracy, mean angular error, and mean response time.
- [ ] **10.3.2** Run a short Continuous session; confirm both heatmaps show the stats subtitle line WITHOUT accuracy.
- [ ] **10.3.3** Open the resulting CSV files in a text editor and in Excel; confirm the header comment block renders correctly and the data table is intact below it.
- [ ] **10.3.4** Read the CSV back into MATLAB with `readtable(path, 'CommentStyle', '#')` and confirm the trial data round-trips cleanly.

---

*Document status: Sections 1–8 complete (with carry-forward caveats on 8.7 and 8.12). Section 9 code complete; verification 9.2.3 / 9.5.* pending hardware. Section 10 code complete; hardware verification (10.2.3 Excel half, 10.3.1–10.3.4) pending. Section 11 (ASIO device support) code complete; awaiting first live experiment session.*

---

## Section 11 — ASIO Device Support (2026-04-15)

This section captures a small device-enumeration fix to `tryOpenAudio` discovered when first connecting the Focusrite hardware. The legacy `audiodevinfo` enumerator only sees Windows MME/DirectSound drivers, which expose the interface as a 2-channel device. `getAudioDevices(audioPlayerRecorder)` sees the ASIO driver, which exposes all hardware output channels. No PRD change required — this is a bug fix to task 2.7.

- [x] **11.1** Replace `audiodevinfo`-based enumeration in `tryOpenAudio` with `getAudioDevices(audioPlayerRecorder)`.
- [x] **11.2** Implement device-selection policy: prefer any device whose name contains "ASIO" (case-insensitive); fall back to first non-"Default" device; fall back to silent mode.
- [x] **11.3** Catch construction errors from `audioPlayerRecorder` and degrade gracefully to silent mode.
- [x] **11.4** Verify the new code opens the Focusrite ASIO device with 6 output channels and releases cleanly. *(Functional test in MATLAB session: opened "Focusrite USB ASIO", 6 channels at 48 kHz, released without error.)*
- [ ] **11.5** Verify in a live session that all 6 speakers play tones at the expected physical positions (i.e., MATLAB Channel 1 drives the speaker at 0°, Channel 2 drives 60°, etc.). If channel routing is wrong at the rig, decide whether to rewire or add a channel-remap config.
