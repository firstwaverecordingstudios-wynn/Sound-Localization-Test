# Product Requirement Document
## Sound Localization Test (SLT)
**Version:** 1.5
**Date:** 2026-04-15
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

The Hann window is applied separately as a short amplitude ramp (e.g., 10 ms) at the very first onset of the stimulus and at the moment the listener responds (final release), using a one-sided half-Hann envelope. It is never applied to the looping buffer itself.

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
| Start | Button | Launches Subject ID prompt then experiment |
| Calibrate | Button | Launches calibration routine |

### 4.2 Calibration Routine

Cycles through speakers 1–6. For each: displays active channel, plays stimulus continuously, waits for button click to advance. Button label is dynamic:

- **Speakers 1–5:** Button reads "Next Speaker". Clicking stops the current tone, advances to the next speaker, and starts the next tone.
- **Speaker 6:** Once the tone begins playing through Speaker 6, the button label changes to "Done". Clicking "Done" stops audio and closes the Calibration GUI, returning control to the Intro GUI.

All body text in the Calibration GUI is pure black for legibility.

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

---

## 5. Experiment Logic

1. Subject ID collected.
2. Trial loop: select location → build loop buffer → apply onset Hann ramp → play stimulus → start timer → listener responds → apply offset Hann ramp → stop audio → record data → countdown pause.
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

*Document status: PRD v1.5 reflects implemented behaviour. SLT.m is at v1.3. Pending hardware verification of channel routing (TASKS 11.5) and remaining live-session checks (8.7, 8.12, 9.x, 10.3.x).*
