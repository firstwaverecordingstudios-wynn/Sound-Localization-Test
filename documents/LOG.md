# LOG — Sound Localization Test (SLT)

---

## 2026-04-13 — Initial Implementation

**Description:** Complete initial implementation of SLT.m written and verified.

**Changes:**
- Created full project folder structure (Sound Localization Test/, documents/, archive/, results/)
- Implemented SLT.m with all 6 sections: Intro GUI, Subject ID Prompt, Calibration Routine, Experiment Engine, Audio Engine, Results
- Static code analysis run; all warnings resolved (unused argument suppressed with ~, try/catch syntax corrected, deprecated datestr/now replaced with datetime)

**Tests run:**

| Test | Description | Result |
|------|-------------|--------|
| 1 | Integer-cycle tone buffer seamlessness (all 5 frequencies at 48000 Hz) | PASS |
| 2 | Noise crossfade power unity (max deviation 2.22e-16), normalisation, buffer length | PASS |
| 3 | Sine law panning — exact speaker angles (100% power, correct channel) and midpoints (equal split, unity power) | PASS |
| 4 | Circular angular error — 6 cases including wraparound at 0°/360° | PASS |
| 5 | End-to-end trial data generation and per-bin accumulation, Discrete mode (6 trials) | PASS |
| 6 | End-to-end trial data generation and per-bin accumulation, Continuous mode (36 trials, 20/36 bins filled) | PASS |
| 7 | Heatmap figure rendering and PNG save — both Discrete and Continuous modes | PASS |
| 8 | CSV output — correct column names and row count | PASS |

**Rationale:** All core acoustic logic (integer-cycle looping, crossfade, sine law panning, angular error) verified mathematically before any hardware testing. GUI and audio hardware testing deferred to live session with interface connected.

**Known limitations / next steps:**
- Audio looping uses a MATLAB timer to re-queue buffers into audioPlayerRecorder — behaviour with real ASIO hardware should be verified on first live run
- applyOffsetRamp is defined but not yet called in the trial loop (offset ramp applied at device level via reset); if a clean audible fade-out is desired this can be wired in during hardware testing
- No audio device present in current MATLAB session; all tests run in silent mode

---
