# TASKS — Sound Localization Test (SLT)
**Version:** 1.3
**Date:** 2026-04-14

All tasks must be completed in order. No task may begin before its predecessor is complete and verified.

---

## Section 1 — Project Setup

- [ ] **1.1** Create the project folder structure: Sound Localization Test/, documents/, archive/, results/
- [ ] **1.2** Create SLT.m with a file header: title, description, author, date, version.
- [ ] **1.3** Define global configuration constants: sample rate (48000 Hz), speaker angles (0°/60°/120°/180°/240°/300°), Hann ramp duration (10 ms), crossfade duration (10 ms), number of channels (6).

---

## Section 2 — Audio Engine

- [ ] **2.1** Write buildToneBuffer(frequency, sampleRate) — constructs a seamless integer-cycle sine wave loop buffer; length = exactly one cycle (Fs/f samples). No windowing applied to the buffer itself.
- [ ] **2.2** Write buildNoiseBuffer(sampleRate, durationSeconds) — generates a Gaussian noise buffer with a 10 ms equal-power crossfade stitched at the loop boundary so it loops without clicks or amplitude modulation.
- [ ] **2.3** Write applyOnsetRamp(buffer, sampleRate, rampMs) — applies a one-sided half-Hann fade-in envelope to the first rampMs milliseconds of a buffer; used once at stimulus onset.
- [ ] **2.4** Write applyOffsetRamp(buffer, sampleRate, rampMs) — applies a one-sided half-Hann fade-out envelope to the last rampMs milliseconds of a buffer; used once at stimulus offset.
- [ ] **2.5** Write buildOutputBuffer(monoSignal, channelAmplitudes, numChannels) — maps mono signal to 6-channel output matrix by scaling each channel by its assigned amplitude.
- [ ] **2.6** Write computePanAmplitudes(degree, speakerAngles) — sine law panning; identifies the bounding speaker pair for the given degree and returns a 6-element amplitude vector.
- [ ] **2.7** Write initAudio(sampleRate, numChannels) — initializes multi-channel device via audioPlayerRecorder; returns device handle.
- [ ] **2.8** Write playLooping(deviceHandle, buffer) — begins looped continuous playback of the buffer.
- [ ] **2.9** Write stopAudio(deviceHandle) — stops playback and releases the audio device cleanly.

---

## Section 3 — Intro GUI

- [ ] **3.1** Build Intro GUI figure window with correct background color and layout.
- [ ] **3.2** Add teal header banner with application title.
- [ ] **3.3** Add Stimulus Selection dropdown (125 Hz, 250 Hz, 500 Hz, 750 Hz, 1000 Hz, Gaussian Noise).
- [ ] **3.4** Add Number of Trials numeric input field.
- [ ] **3.5** Add Pause Time (s) numeric input field.
- [ ] **3.6** Add Mode Selection dropdown (Discrete Speakers, Continuous Panning).
- [ ] **3.7** Add Description text input field.
- [ ] **3.8** Add green Start button: reads all fields, validates inputs, launches Subject ID prompt.
- [ ] **3.9** Add Calibrate button: reads selected stimulus, launches calibration routine.
- [ ] **3.10** Write input validation: Number of Trials must be positive integer; Pause Time must be positive number; warning dialog on failure.

---

## Section 4 — Subject ID Prompt

- [ ] **4.1** Write getSubjectID() — modal input dialog; returns entered Subject ID string.
- [ ] **4.2** Construct session filename: SubjectID_YYYYMMDD_HHMMSS.

---

## Section 5 — Calibration Routine

- [ ] **5.1** Build Calibration GUI: displays current speaker number and channel, Next Speaker button.
- [ ] **5.2** Write calibration loop: build appropriate loop buffer → play on corresponding channel → update display → wait for Next Speaker click.
- [ ] **5.3** Stop audio and close Calibration GUI after Speaker 6.

---

## Section 6 — Experiment Engine

- [ ] **6.1** Write selectStimulusLocation(mode) — random speaker (1–6) for Discrete; random integer degree (1–360) for Continuous.
- [ ] **6.2** Write main experiment loop: draw screen → select location → build loop buffer → apply onset ramp → build 6-channel buffer → start looped playback → start timer → wait for response → apply offset ramp to final output → stop audio → record data → display countdown. Repeat N trials.
- [ ] **6.3** Implement Discrete response capture: listen for keypresses 1–6; record and convert to speaker number.
- [ ] **6.4** Implement Continuous response capture: render circular 360° response ring; record click angle.
- [ ] **6.5** Write countdown pause display: live seconds countdown between trials.
- [ ] **6.6** Compute angular error per trial: absolute angular difference accounting for circular wraparound.

---

## Section 7 — Results Computation & Display

- [ ] **7.1** Compute summary statistics: total accuracy (Discrete), mean angular error, mean response time.
- [ ] **7.2** Write drawCircularHeatmap(values, mode, metric, description) — renders the circular heatmap per PRD spec:
  - Discrete: 6 solid wedges of 60°, each centered on its speaker angle, hard boundaries, value printed in wedge.
  - Continuous: 36 wedge bins of 10°, center to rim, each centered on its degree.
  - Both: listener head icon at center (nose pointing to 0°); speaker labels at r=158; degree ticks at 30° intervals; green/yellow/red color scale; description subheader.
- [ ] **7.3** Call drawCircularHeatmap twice: once for angular error, once for response time.
- [ ] **7.4** Display Results figure showing both heatmaps and summary statistics text.
- [ ] **7.5** Save both heatmaps as .png to results/ using session filename.
- [ ] **7.6** Write trial data to CSV in results/: Trial Number, Stimulus Location, Response, Angular Error, Response Time.

---

## Section 8 — Integration & Testing

- [ ] **8.1** Connect Intro GUI → Subject ID prompt → Experiment loop → Results in single clean execution flow.
- [ ] **8.2** Connect Calibrate button → Calibration routine → return to Intro GUI.
- [ ] **8.3** Test Discrete Speakers mode end-to-end.
- [ ] **8.4** Test Continuous Panning mode end-to-end.
- [ ] **8.5** Verify tone loop buffer: confirm no audible click or amplitude modulation during looping; verify integer-cycle length for all 5 frequencies at 48000 Hz.
- [ ] **8.6** Verify noise loop buffer: confirm no audible click at loop boundary; verify crossfade produces constant power.
- [ ] **8.7** Verify Hann ramps: confirm onset and offset ramps are applied exactly once per trial, not on every loop cycle.
- [ ] **8.8** Verify sine law panning: at exact speaker angles only one channel outputs; at mid-sector power is equal.
- [ ] **8.9** Verify heatmap geometry: all wedges fill the full circle with correct alignment; listener head centered and oriented correctly.
- [ ] **8.10** Verify CSV output format and file naming.
- [ ] **8.11** Verify figure output: both heatmaps saved with correct titles and description subheaders.
- [ ] **8.12** Verify audio cleanup: no hanging audio processes after experiment completes or is interrupted.

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

- [ ] **9.5.1** Launch Intro GUI; visually confirm all labels/inputs are pure-black and legible.
- [ ] **9.5.2** Launch Calibrate; cycle through all six speakers. Confirm button label changes to "Done" on Speaker 6, and that clicking "Done" stops audio and closes the window.
- [ ] **9.5.3** Run a short Discrete session. Confirm instruction text is visible, speaker buttons are large and obvious, and both keypress and click produce identical, correct responses.
- [ ] **9.5.4** Run a short Continuous session. Confirm instruction text is visible and ring interaction still works as before.
- [ ] **9.5.5** Re-run offline test suite (Tests 1–8 from LOG.md 2026-04-13) to confirm no regressions in acoustic logic.

---

*Document status: Awaiting user approval before implementation begins.*
