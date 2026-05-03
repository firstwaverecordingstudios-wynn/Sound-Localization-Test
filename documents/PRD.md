# Product Requirement Document
## Sound Localization Test (SLT)
**Version:** 1.8
**Date:** 2026-05-02
**Author:** Claude (Anthropic) in collaboration with the project owner

---

## 1. Project Overview

The Sound Localization Test (SLT) is a MATLAB-based psychoacoustic experiment that assesses a human listener's ability to localize sound sources in the horizontal plane. The program plays a stimulus from one of six spatially arranged speakers — or from a virtual panned position between two speakers — and records where the listener perceives the sound to originate. Results are analyzed and visualized automatically at the end of each session.

---

## 2. Physical System

Six loudspeakers are arranged in a regular hexagonal formation centered on the listener. Speakers are numbered 1–6 clockwise, with Speaker 1 directly in front (0°):

| Speaker | Angle | Position |
|---------|-------|----------|
| 1 | 0° | Front |
| 2 | 60° | Front-Right |
| 3 | 120° | Back-Right |
| 4 | 180° | Back |
| 5 | 240° | Back-Left |
| 6 | 300° | Front-Left |

Audio is routed via a multi-channel audio interface using MATLAB's **Audio Toolbox** (audioPlayerRecorder). MATLAB audio channels 1–6 map directly to speakers 1–6. Psychtoolbox is not required; the Audio Toolbox provides sufficient timing precision for a reaction-time localization experiment where response latency is on the order of hundreds of milliseconds to seconds.

**Driver requirement:** The audio interface must be accessed via its **ASIO driver**, not via Windows MME/DirectSound/WASAPI. Pro audio interfaces (e.g. Focusrite, RME, MOTU) typically expose only their first stereo pair through the Windows-side drivers; the ASIO driver is what surfaces all hardware output channels (≥6 in this case). `tryOpenAudio` enumerates devices via `getAudioDevices(audioPlayerRecorder)` and prefers any device whose name contains "ASIO". The manufacturer's ASIO driver must be installed; for class-compliant interfaces without a vendor ASIO driver, ASIO4ALL is a generic fallback.

**Audio streaming model:** Looped playback is driven by a frame-streaming loop rather than a timer-based re-queue. On each trial, the program pumps fixed-size frames (16384 samples ≈ 340 ms at 48 kHz) into `audioPlayerRecorder` in a tight loop; the ASIO driver's internal buffering paces the loop naturally — each call to `aPR(frame)` blocks until the device is ready for the next frame. Between frames, `drawnow limitrate` services UI events (button clicks, keypresses) so the interface remains responsive throughout playback. This replaces an earlier timer-based re-queue strategy that proved incompatible with the short integer-cycle tone buffers (1–8 ms) used by this experiment.

**Frame size / device buffer matching:** `audioPlayerRecorder` is constructed with `BufferSize = CFG.frameSize` so each `aPR(frame)` call corresponds to exactly one hardware callback. The current value of 16384 samples gives ≈340 ms of per-callback runway. This is deliberately generous: the second rig session (2026-05-02) revealed that aggressive mouse-hover events on uifigure components could occasionally stall the UI thread longer than the previous ≈85 ms (4096-sample) callback runway, starving the device and producing audible audio stutter. The intermediate 8192-sample value reduced but did not eliminate the issue; 16384 samples appears to absorb every stall observed in normal use. The cost is onset latency (~340 ms from `aPR(frame)` call to sound emerging), which remains imperceptible relative to the hundreds-of-milliseconds-to-seconds response times measured in this experiment.

---

## 3. Acoustic & Signal Processing Context

### 3.1 Stimulus Types

- **Pure tones:** Sine waves at 125, 250, 500, 750, or 1000 Hz, looped continuously using integer-cycle buffers (see Section 3.2). A Hann ramp is applied once at stimulus onset and once at stimulus offset to eliminate audible clicks; it is not applied on every loop cycle.
- **Gaussian noise:** White Gaussian noise generated fresh each trial, looped continuously using a crossfade loop (see Section 3.3).

### 3.2 Pure Tone Loop Strategy — Integer-Cycle Buffers

Looping a windowed or arbitrarily-length sine buffer introduces a discontinuity at the loop point — either an amplitude jump or, if a Hann window is used on every cycle, a rhythmic amplitude modulation that pulses at the loop rate. Both are audible and undesirable in a localization experiment.

The correct approach for pure tones is to construct a buffer whose length is exactly an integer number of complete cycles of the tone frequency. At this length, the waveform value and slope at the end of the buffer match the value and slope at the beginning, so the loop point is seamless and completely inaudible.

**Implementation:** For a given sample rate Fs and frequency f, the buffer length in samples is:

```
N = Fs / f          (samples per cycle, must be integer or rationalized)
buffer = sin(2 * pi * f * (0:N-1)' / Fs)
```

If Fs/f is not an integer (e.g., 48000/750 = 64 exactly; 48000/125 = 384 exactly), use the exact value. All five specified frequencies (125, 250, 500, 750, 1000 Hz) divide evenly into 48000 Hz, so integer-cycle buffers are always achievable at this sample rate.

The Hann window is applied separately as a short amplitude ramp (e.g., 100 ms — chosen for a perceptibly smooth onset attack and offset release without delaying response capture) at the very first onset of the stimulus and at the moment the listener responds (final release), using a one-sided half-Hann envelope. It is never applied to the looping buffer itself.

**Playback note:** The integer-cycle buffer is the smallest unit of audio that can loop seamlessly, but it is not the unit delivered to the audio device. The frame-streaming loop concatenates copies of the integer-cycle buffer into larger 16384-sample frames before dispatch (see §2). This does not affect the acoustic correctness of the loop — the integer-cycle guarantee means any two adjacent copies of the buffer splice together seamlessly — but it ensures the frame-streaming loop is delivering frames large enough for the ASIO driver to consume efficiently.

**Ramp placement:** The Hann onset ramp is applied inside the frame-streaming loop to the FIRST dispatched frame only, not upstream to the loop buffer. Applying the ramp to the loop buffer would cause the ramp envelope to repeat at the loop rate (e.g. 1 kHz modulation on a 1000 Hz tone), producing audible harmonic distortion. The offset ramp is applied to ONE final tail frame dispatched after the listener responds — response time has already been captured by that point, so the ~100 ms fade-out (the offset ramp is applied to the last `rampMs` samples of the tail frame) is acoustic polish only and does not affect the timing measurement.

**Silent-pump frame:** Immediately after the ramped tail frame, one additional all-zeros frame is dispatched. `audioPlayerRecorder`'s internal queue means an `aPR(frame)` call returns when the object accepts the frame, not when the hardware has finished playing it; without the silent pump, the inter-trial `reset(aPR)` call would cut off the ramped tail frame mid-playback, producing an audible click. The silent pump occupies the queue slot that `reset()` would otherwise truncate, so the ramped frame plays out in full before being followed by silence (which `reset()` truncates inaudibly). Diagnosed by commenting out the inter-trial `stopAudio` call: with no `reset()`, the click disappears — confirming queue truncation as the cause.

### 3.3 Gaussian Noise Loop Strategy — Crossfade Looping

Gaussian noise has no periodic structure, so integer-cycle alignment is not possible. A seamless loop is constructed using a short equal-power crossfade at the loop boundary:

1. Generate a noise buffer longer than needed (e.g., 2 seconds at the target sample rate).
2. Define a crossfade region of ~10 ms at the end of the buffer.
3. In the crossfade region, fade the tail of the buffer out with a half-cosine ramp while simultaneously fading the head of the buffer in with a complementary half-cosine ramp, maintaining constant total power.
4. The resulting buffer loops with no audible click or amplitude modulation at the join.

**Implementation:**

```
xfade_samples = round(0.01 * Fs);           % 10 ms crossfade
fade_out = cos(linspace(0, pi/2, xfade_samples))';
fade_in  = sin(linspace(0, pi/2, xfade_samples))';
buffer(end-xfade_samples+1:end) = ...
    buffer(end-xfade_samples+1:end) .* fade_out + ...
    buffer(1:xfade_samples) .* fade_in;
buffer = buffer(1:end-xfade_samples);       % trim to loop length
```

### 3.4 Discrete Speaker Mode

A single speaker (1–6) is chosen at random each trial (fully random, repeats allowed). The stimulus plays from that channel at full amplitude.

### 3.5 Continuous Panning Mode — Sine Law Panning

A random integer degree (1–360) is selected each trial. The 360° space is divided into six 60° sectors:

| Sector | Bounding Speakers | Degree Range |
|--------|------------------|--------------|
| 1 | Speakers 1 & 2 | 0° – 60° |
| 2 | Speakers 2 & 3 | 60° – 120° |
| 3 | Speakers 3 & 4 | 120° – 180° |
| 4 | Speakers 4 & 5 | 180° – 240° |
| 5 | Speakers 5 & 6 | 240° – 300° |
| 6 | Speakers 6 & 1 | 300° – 360° |

Amplitude is split using the **sine panning law** (constant power):

```
theta = (degree - sector_start) / 60 * (pi/2)
A_left_speaker  = cos(theta)
A_right_speaker = sin(theta)
```

---

## 4. GUI Design

Aesthetic: teal/cyan header banners, soft pink input fields, white panel backgrounds, light blue overall background, bold green Start button. All body text (labels, field text, instructions) is rendered in pure black (RGB [0 0 0]) for maximum legibility against the light panel backgrounds.

### 4.1 Intro GUI

| Element | Type | Details |
|---------|------|---------|
| Stimulus Selection | Dropdown | 125 Hz, 250 Hz, 500 Hz, 750 Hz, 1000 Hz, Gaussian Noise |
| Number of Trials | Numeric input | Positive integer |
| Pause Time | Numeric input | Seconds |
| Mode Selection | Dropdown | Discrete Speakers / Continuous Panning |
| Description | Text field | Used as figure subheader in results |
| Sweep Duration | Numeric input | Seconds (default 10). Used by the optional continuous panning sweep in Calibrate (§4.6); ignored otherwise. Placed at the bottom of the parameter panel since it feeds Calibrate, not Start. |
| Start | Button | Launches Subject ID prompt then experiment |
| Calibrate | Button | Launches calibration routine, including an optional continuous panning sweep (§4.6) |

### 4.2 Calibration Routine

Cycles through speakers 1–6. For each: displays active channel, plays stimulus continuously, waits for button click to advance. Button label is dynamic:

- **Speakers 1–5:** Button reads "Next Speaker". Clicking stops the current tone, advances to the next speaker, and starts the next tone.
- **Speaker 6:** Once the tone begins playing through Speaker 6, the button label changes to "Done". Clicking "Done" stops audio and closes the Calibration GUI, returning control to the Intro GUI.

All body text in the Calibration GUI is pure black for legibility.

**Post-calibration sweep prompt:** After the "Done" click on Speaker 6 (or after the user closes the calibration window mid-sequence with at least one speaker checked), a modal `uiconfirm` dialog appears: *"Run continuous panning sweep?"* with **Yes** / **No** buttons (No is the default for cancel-safety). **No** closes the calibration window and returns to the Intro GUI — the v1.4 behavior. **Yes** launches the continuous panning sweep described in §4.6, reusing the calibration window for the sweep UI and the already-open audio device handle.

**Implementation note on the advance flag:** The "advance to next speaker" flag is stored in `calFig.UserData.nextDone` rather than in a local variable of the calibration function. MATLAB anonymous-function closures capture locals by value at creation time, so the streaming-loop termination predicate (which is an anonymous function reading the flag) would be frozen at the initial flag value for the life of the closure. Storing the flag on a handle object (the figure) makes it reference-semantic: both the button-click callback and the closure see the same current value. This is a general pattern for shared mutable state between UI callbacks and streaming loops.

### 4.3 Experiment Screen — Discrete Speakers Mode

- Neutral/black background
- Instruction text displayed prominently at the top: *"Press a number 1–6 or click a speaker button to indicate where you are perceiving the sound from."*
- Speaker orientation diagram rendered in the main area: same hexagonal geometry as the Continuous Panning ring, with a top-down listener head icon at center (nose pointing toward Speaker 1 at 0°) and the six speaker positions arranged at 0°, 60°, 120°, 180°, 240°, 300°.
- Each of the six speaker positions is rendered as a large, visually obvious clickable button labeled with its number (1–6). Buttons are noticeably larger than the speaker markers used in the Continuous Panning ring, since they are the primary interactive target in this mode.
- Trial counter displayed
- Response capture accepts either a keypress (1–6) or a click on the corresponding speaker button — both are equivalent inputs. Stimulus stops on response.
- Live countdown timer between trials

### 4.4 Experiment Screen — Continuous Panning Mode

- Neutral/black background
- Instruction text displayed prominently at the top: *"Click within the ring to indicate where you are perceiving the sound from."*
- Trial counter displayed
- Interactive circular ring (0–360°) for click response
- Stops stimulus on click; records degree
- Live countdown timer between trials

### 4.5 Subject ID Prompt

Modal dialog on Start. Session filename: SubjectID_YYYYMMDD_HHMMSS.

### 4.6 Continuous Panning Sweep

Optional acoustic-validation routine triggered by **Yes** on the modal prompt at the end of speaker calibration (§4.2). Provides a perceptual end-to-end check that the sine-law panning chain (`computePanAmplitudes` → `buildOutputBuffer` → the audio device's six output channels → the physical speakers) is working as expected: a continuously-panned virtual source should be heard gliding smoothly around the listener with no audible jumps, holes, or amplitude pumping at sector boundaries.

**Stimulus:** Whatever is selected in the Intro GUI's Stimulus dropdown (tone or noise) at the moment Calibrate was clicked. The same `loopBuf` used for the speaker check is reused — the sweep modulates only the per-channel amplitudes, not the underlying mono content.

**Sweep trajectory:** One pass from 0° to 360°, clockwise (matching the speaker numbering: 0° → Speaker 1 front, 60° → Speaker 2 front-right, etc.). Total duration is set by the **Sweep Duration** field on the Intro GUI (default 10 s).

**Per-frame amplitude update:** Unlike the rest of the streaming path, which builds a fixed-amplitude `outBuf` once per trial, the sweep recomputes `computePanAmplitudes(currentDeg, CFG.speakerAngles)` for each frame and rebuilds the per-channel output frame in the streaming loop. `currentDeg` is computed as a linear function of the cumulative samples dispatched divided by the total samples in the sweep, so the angle advance is exactly synchronized to the audio. At the default frame size (16384 samples ≈ 340 ms) and a 10 s sweep, that is ≈30 amplitude updates spread across the sweep — fine enough that the source glides rather than steps. Implemented as a separate `streamPanSweep` function rather than generalizing `streamAudio`, to keep the well-tested fixed-amplitude path unchanged.

**UI:** Reuses the calibration window. The speaker-number label is replaced with *"Continuous Panning Sweep"* and a live degree readout (*"Panning: 173°"*); the advance button label changes to *"Stop Sweep"* and aborts the sweep early when clicked. After the sweep completes (or is stopped), the offset ramp + silent-pump dispatch (§3.2) runs as for any other stimulus, audio stops, the calibration window closes, and control returns to the Intro GUI.

---

## 5. Experiment Logic

1. Subject ID collected.
2. Trial loop: select location → build loop buffer → build 6-channel output → apply onset Hann ramp → stream frames to device while polling for response → on response, apply offset Hann ramp to a final tail frame → stop streaming → record data → countdown pause.
3. After final trial: compute and display results.

---

## 6. Results

### 6.1 Summary Statistics

- **Total accuracy** (Discrete): % trials with correct speaker selected.
- **Average angular error:** mean absolute angular difference (degrees), circular wraparound accounted for.
- **Average response time:** mean seconds from stimulus onset to response.

These statistics are surfaced in three places: (a) the Results summary window stats label, (b) a third text line on each heatmap below title and description subtitle (see §6.2), and (c) the CSV header comment block (see §6.3).

### 6.2 Heatmap Visualizations

Two circular heatmap figures are generated: one for angular error, one for response time. Color scale: **green = low, yellow = mid, red = high**.

**Discrete Speakers mode:** 6 solid wedges of 60° each. Each wedge is centered on its speaker angle (0°, 60°, 120°, 180°, 240°, 300°) so the speaker angle bisects the wedge. Hard boundaries between wedges. Value printed inside each wedge.

**Continuous Panning mode:** 36 wedge bins of 10° each, running from center to rim. Each bin centered on its degree (0°, 10°, 20°, ... 350°), colored by the average metric for trials in that bin. The 6 speaker positions are labeled around the outside (e.g., "1 · 0°") with intermediate tick marks and degree labels at 30° intervals (30°, 90°, 150°, 210°, 270°, 330°).

**Both modes:** A top-down listener head icon (circle with eyes, ears, and a forward-pointing nose) is rendered at center, nose pointing toward Speaker 1 (0°, front). Speaker labels appear at r=158 px from center. The Description field from the Intro GUI is used as a figure subheader. Titles reflect content clearly.

**Stats subtitle line:** Below the description subtitle, each heatmap displays a third text line containing the session summary statistics. Style is smaller and lighter than the description subtitle but still legible.

- **Discrete mode:** *"Accuracy: XX.X%   Mean Angular Error: XX.X°   Mean Response Time: X.XX s"*
- **Continuous mode:** *"Mean Angular Error: XX.X°   Mean Response Time: X.XX s"* (accuracy is omitted because there is no "correct" speaker for a panned virtual position).

### 6.3 Data Export

- **CSV:** one row per trial — Trial Number, Stimulus Location, Response, Angular Error (°), Response Time (s). The CSV is preceded by a `#`-prefixed header comment block recording session metadata and summary statistics. The block contains, one field per line:

  ```
  # Sound Localization Test — Session Results
  # Subject: <SubjectID>
  # Date: <YYYY-MM-DD HH:MM:SS>
  # Stimulus: <stim label>
  # Mode: <Discrete Speakers | Continuous Panning>
  # Description: <description string>
  # Accuracy: XX.X%               (Discrete only — line omitted entirely for Continuous)
  # Mean Angular Error: XX.X deg
  # Mean Response Time: X.XX s
  ```

  The `#` prefix is the conventional CSV comment marker. Excel ignores the lines as malformed rows (they appear in the first column but do not interfere with the data table); MATLAB's `readtable(path, 'CommentStyle', '#')` skips them cleanly.

- **Figures:** both heatmaps saved as .png.
- All files saved to results/ with session filename.

---

## 7. Code Standards

- Highly readable: clear names, logical structure, generous section headers and inline comments.
- Physics/acoustics-forward: comments explain acoustic meaning, not just syntax.
- Efficient: vectorized where appropriate.
- Accessible: followable by someone with minimal software experience.

---

*Document status: PRD v1.8 (2026-05-02) folds in three changes from the second rig session and one new feature: (a) the silent-pump frame appended after the offset ramp tail frame to prevent the inter-trial `reset(aPR)` from cutting off the ramped frame and producing an audible click (§3.2); (b) frame size bumped 4096 → 16384 (≈340 ms) to give more UI-stall headroom against uifigure mouse-hover events that exceeded the previous ≈85 ms callback runway (§2); (c) ramp duration set to 100 ms to match the operator's preferred onset attack and offset release feel (§3.2); and (d) a new optional Continuous Panning Sweep in Calibrate (§4.6), driven by a new Sweep Duration field on the Intro GUI (§4.1), as a perceptual end-to-end validation of the sine-law panning chain. SLT.m is currently at v1.4 (with operator-applied interim adjustments to `frameSize` and `rampMs`); the v1.5 implementation closes Section 13 of TASKS. Open items remain: TASK 11.5 (channel routing — user has informally verified at the rig) and TASK 12.10 (offline acoustic-logic regression).*
