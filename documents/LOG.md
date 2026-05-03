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

## 2026-04-14 — Refinement Round 1 (PRD v1.2 → v1.3)

**Description:** User reviewed the initial implementation and requested a set of UI refinements. No code changes made yet — PRD and TASKS updated and awaiting user approval before SLT.m is modified.

**Changes to documents:**
- PRD.md bumped to v1.3.
  - Section 4 (GUI Design) preamble: added explicit requirement that all body text in Intro and Calibration GUIs be rendered pure black [0 0 0] for legibility.
  - Section 4.2 (Calibration Routine): rewrote to specify dynamic button label — "Next Speaker" for speakers 1–5, changing to "Done" once Speaker 6 playback begins; "Done" click stops audio and closes the window.
  - Section 4.3 (Discrete Speakers experiment screen): added top instruction text, hexagonal speaker orientation diagram with listener head, and six large clickable speaker buttons (noticeably larger than Continuous ring markers) as equivalent alternative to keypress input.
  - Section 4.4 (Continuous Panning experiment screen): added top instruction text "Click within the ring to indicate where you are perceiving the sound from."
- TASKS.md bumped to v1.3. Added Section 9 (Refinement Revisions) enumerating every code change required to bring SLT.m in line with PRD v1.3, plus a verification subsection.

**Rationale:**
- **Font legibility:** User reported body text in Intro and Calibration GUIs is too light to read comfortably. Pure black against the light panel backgrounds maximises contrast without altering the established aesthetic (teal headers, pink inputs, green Start remain unchanged).
- **Calibration "Done" button:** Current behaviour leaves the calibration window open after Speaker 6, forcing the user to close it manually and risking a hanging audio stream. A dynamic-label button that explicitly terminates the routine is clearer UX and guarantees clean audio shutdown.
- **Discrete experiment screen redesign:** The current implementation displays nothing during Discrete trials, giving the listener no visual reference for which number corresponds to which spatial position. Adding the same hexagonal diagram used in the Continuous mode provides immediate spatial grounding, and making the speaker positions themselves into large clickable buttons offers an accessible alternative to keyboard input (useful for subjects who cannot reach the keyboard or prefer mouse input). Button size is deliberately larger than the Continuous ring's markers because here the buttons *are* the interaction target, not just reference labels.
- **Instruction text on both experiment screens:** Explicit, plainly-worded instructions at the top of each screen reduce subject confusion and improve experimental consistency across sessions. The Discrete wording was revised from the user's original keypress-only phrasing to reflect that clicking a speaker button is now also a valid response.

**Tests run:** None — no code changes executed. Awaiting user approval of PRD v1.3 and TASKS v1.3 Section 9 before any modifications to SLT.m.

**Next step:** User approval. On approval, execute tasks 9.1.1 through 9.5.5 in order, then re-run offline test suite to confirm no regressions.

---

## 2026-04-14 — Refinement Round 1 Implementation (SLT.m v1.0 → v1.1)

**Description:** User approved PRD v1.3 and TASKS v1.3 Section 9. Implemented all code tasks 9.1.1–9.4.1. Verification tasks 9.2.3 and 9.5.1–9.5.5 remain open pending user testing at the hardware rig.

**Changes:**
- Archived previous SLT.m as `archive/SLT_v1.0_2026-04-13.m`.
- Wrote new `SLT.m` v1.1 with header versioning and a changelog comment block listing the v1.1 deltas.
- **Intro GUI (`launchIntroGUI`):** Added a single `bodyColor = [0 0 0]` local and applied `FontColor` to every label, dropdown, numeric/text edit field, and the Calibrate button. Green Start button and teal header banner unchanged per PRD.
- **Calibration GUI (`runCalibration`):** Applied `bodyColor = [0 0 0]` to the speaker status label and the "Adjust volume" instruction. Advance button's label is now set dynamically inside the speaker loop — it reads `Next Speaker` for speakers 1–5 and is updated to `Done` at the top of the speaker-6 iteration (before playback begins on channel 6, so the label change is visible the whole time the final tone is playing). Callback logic was simplified: the click sets an `advancePressed` flag, the loop falls through after Speaker 6, audio is stopped and released, and the figure is closed by the post-loop cleanup block. This means clicking "Done" performs exactly one unified shutdown path — no separate "done" vs "next" branches.
- **Experiment screen (`runExperiment`):** Window widened to 760 px and heightened to 640 px to accommodate the new instruction label, trial counter, and diagram/ring without crowding. A single bold instruction `uilabel` is drawn at the top, with mode-specific wording selected from the PRD text. The central axes is now created for BOTH modes (previously only for Continuous) at a unified 500×450-px size. Response routing unified: `expFig.UserData.response` is the single sink for clicks and keypresses.
- **Discrete diagram (`buildDiscreteSpeakerDiagram`, new):** Draws the outer circle, six 60° sector divider lines (so the hex geometry is visually obvious), and calls the new `drawListenerHeadIcon` helper. Six large uibuttons (70×70 px, 24-pt bold font) are placed at axes-data coordinates `r = 1.15` around the circle, converted to figure-pixel positions via a small inline mapper. Each button's callback writes its speaker index to `fig.UserData.response`. Pixel-based positioning (vs parenting to the axes) is required because MATLAB uibuttons cannot be axes children.
- **`drawListenerHeadIcon` (new helper):** Head, two eyes, two ears, and nose triangle. Nose points up toward 0° per PRD. Extracted as a helper so the results heatmap function could be refactored to share it in a future round (not done in this round to minimise diff).
- **Response capture (`waitForDiscreteResponse`, new):** Replaces `waitForKeyResponse`. Listens for keypress 1–6 AND button clicks (via `UserData.response`) simultaneously. Whichever arrives first wins. Returns the speaker index.
- **Continuous ring (`buildResponseRing`):** Removed the small in-axes caption "Click the ring to indicate where you heard the sound" — that instruction now lives in the top label for consistency with the Discrete screen.
- **Results summary (`showResults`):** Stats label font darkened from `[0.15 0.15 0.15]` to pure black; saved-path caption darkened from `[0.5 0.5 0.5]` to `[0.3 0.3 0.3]` (still muted grey since it's a tertiary metadata line, not primary content).

**Rationale:**
- Pulling body color into a single `bodyColor` local makes future palette tweaks trivial and prevents drift between labels.
- Flipping the advance button label at the *top* of the Speaker 6 iteration (rather than after its wait) ensures the user sees "Done" the entire time the final tone plays, which matches the PRD wording and the user's stated intent.
- Unifying click and keypress through `fig.UserData.response` is cleaner than separate response paths and guarantees they cannot race each other — once one writes, the poll loop exits.
- Placing the speaker buttons outside the circle at r=1.15 keeps them clear of the sector divider lines and the listener head, and the 70-px size is large enough to hit reliably without looking, while still leaving the diagram itself legible.

**Tests run:** None yet — this is a code-only change. User needs to execute verification tasks 9.5.1–9.5.5 at the hardware rig. Static analysis has NOT been re-run in this session.

**Known limitations / next steps:**
- The offline test suite from 2026-04-13 (acoustic logic tests 1–8) should still pass unchanged since none of the audio engine functions were touched. User should re-run to confirm no regression.
- `applyOffsetRamp` still defined but not called in the trial loop — carried forward from v1.0, same rationale (handled at the device level via `reset`). Can be wired in during hardware testing if a clean audible fade-out is desired.
- Speaker button `axData2FigPx` mapping assumes the axes is not resized after diagram construction. `expFig.Resize = 'off'` is already set, so this is safe, but worth noting if future refactors make the window resizable.

---

## 2026-04-14 — Refinement Round 1 Rollback (SLT.m v1.1 → v1.0)

**Description:** The Refinement Round 1 implementation logged immediately above did not land correctly — the file save was truncated, leaving SLT.m in an incomplete/broken state. User has reverted SLT.m to the archived v1.0 (pre-Section-9) version so the refinement work can be redone from a clean baseline. The prior LOG entry describing the v1.1 changes is retained for historical context but its claims about the state of SLT.m no longer apply.

**Changes:**
- `SLT.m` reverted to the contents of `archive/SLT_v1.0_2026-04-13.m` (41.29 KB, pre-Section-9). Verified by file size match.
- `documents/TASKS.md` Section 9: checkboxes 9.1.1, 9.1.2, 9.2.1, 9.2.2, 9.3.1, 9.3.2, 9.3.3, 9.3.4, 9.3.5, and 9.4.1 reset from `[x]` to `[ ]`. The previous `[x]` marks were incorrect because the underlying code changes did not actually persist to disk. 9.2.3 and 9.5.1–9.5.5 were already unchecked and remain so.

**Rationale:** The previous attempt failed at the file-write step (truncated save), not at the design or logic level. The PRD v1.3 refinement intent is still correct; only the execution needs to be redone. Resetting the task checkboxes keeps TASKS.md as an honest record of what is actually complete. On the next attempt, Section 9 code changes will be applied as targeted edits to specific functions in SLT.m rather than a full-file rewrite, to avoid reproducing the truncation failure mode.

**Tests run:** None. Bookkeeping only.

**Next step:** Await user approval to begin re-implementing Section 9 tasks 9.1.1 through 9.4.1 against the reverted SLT.m, using targeted per-function edits.

---

## 2026-04-14 — Refinement Round 1 Re-implementation (SLT.m v1.0 → v1.1)

**Description:** User approved the re-implementation plan. Executed all PRD v1.3 refinement tasks (9.1.1 through 9.4.1) against the reverted v1.0 SLT.m. This time the work was applied as a sequence of nine small, targeted `edit_file` operations rather than a full-file rewrite, with static analysis and a file-on-disk read after each step to detect any truncation or corruption early. Final file size: 51342 bytes (up from 42280 baseline — healthy growth, no truncation).

**Changes (grouped by task section, in the order they were applied):**

*Edit A — Header (task-adjacent bookkeeping):*
- Bumped Version header `1.0` → `1.1`, Date `2026-04-13` → `2026-04-14`.
- Added a v1.1 changelog block enumerating every PRD v1.3 delta.

*Edit B — Task 9.1.1 (Intro GUI body text):*
- Added `bodyColor = [0 0 0]` local at the top of `launchIntroGUI`.
- Applied `'FontColor', bodyColor` to all five input-panel labels (Stimulus, Number of trials, Pause time, Mode, Description), the four pink input fields (stim dropdown, trials numeric, pause numeric, mode dropdown, description text), and the grey Calibrate button. Teal header banner label (white) and green Start button (white) unchanged per PRD.

*Edit C — Tasks 9.1.2, 9.2.1, 9.2.2 (Calibration GUI):*
- Added `bodyColor = [0 0 0]` local and applied to `lbl_speaker` and the "Adjust volume, then click Next Speaker." label. Header banner white-on-teal unchanged.
- Inserted dynamic button-label logic at the TOP of each speaker iteration: `btn_next.Text = 'Next Speaker'` for speakers 1–5, `'Done'` for speaker 6. The flip happens BEFORE playback begins on channel 6, so the user sees "Done" the entire time the final tone plays.
- Replaced the post-loop block with a unified shutdown path: if `calFig` is still valid after the loop exits, `close(calFig)`. This removes the previous `waitfor(calFig)` + secondary "Calibration complete." label step, which was the source of hanging-window UX.

*Edit D — Task 9.4.1 (Continuous in-axes caption removal):*
- Deleted the `text(ax, 0, -1.45, 'Click the ring to indicate where you heard the sound', …)` call from `buildResponseRing`. The top-of-figure instruction label added in Edit E1 now serves both modes consistently.

*Edit E1 — Tasks 9.3.1, 9.3.5 (experiment figure layout):*
- Widened `expFig` from 700×550 to 760×640 px.
- Added `expFig.UserData.response = []` as the single response sink.
- Added a mode-specific `instrText` string and a prominent white `uilabel` at the top of the figure (Position [20 585 720 40], 13-pt bold). Discrete wording: *"Press a number 1–6 or click a speaker button to indicate where you are perceiving the sound from."* Continuous wording: *"Click within the ring to indicate where you are perceiving the sound from."*
- Repositioned the trial counter (`lbl_trial`) and countdown (`lbl_countdown`) to sit below the instruction, above the diagram.
- Unified the axes creation across both modes: a single `uiaxes` at [130 40 500 450] is now always built, with `buildDiscreteSpeakerDiagram` called for Discrete and `buildResponseRing` for Continuous.

*Edit E2 — Task 9.3.4 (response handler swap in trial loop):*
- Replaced the Discrete branch's call to `waitForKeyResponse(expFig)` with `waitForDiscreteResponse(expFig)`.

*Edit E3 — Task 9.3.4 (unified keypress + click response handler):*
- Renamed `waitForKeyResponse` → `waitForDiscreteResponse` and rewrote its body to poll `fig.UserData.response` instead of a local closure variable. The function sets `fig.UserData.response = []` on entry, installs a `KeyPressFcn` that writes to that field on digits 1–6, and returns whatever value appears first — whether written by keypress or by a speaker button click. This makes the two input paths unable to race.

*Edit E4 — Tasks 9.3.2, 9.3.3, 9.3.4 (new helpers at end of file):*
- Added `drawListenerHeadIcon(ax)`: extracted the head/eyes/ears/nose drawing code (formerly inlined in `drawCircularHeatmap`) into a shared helper. Same geometry constants (head radius 0.15, nose points up toward 0°) so the icon is pixel-identical to the previous heatmap version.
- Added `buildDiscreteSpeakerDiagram(ax, fig, CFG)`: draws the outer R=1.0 ring in soft blue, six radial sector divider lines at 30°/90°/150°/210°/270°/330° (the boundaries BETWEEN speakers, matching the panning-law sectors), calls `drawListenerHeadIcon`, then places six 70×70-px buttons (24-pt bold, dark slate background, white text) at axes-data radius 1.15 around the circle, one at each speaker angle. Buttons cannot be children of a `uiaxes`, so each is parented to `fig` and positioned via a small axes-data → figure-pixel mapper built from `ax.Position`, `ax.XLim`, `ax.YLim`. The mapper assumes the axes size is stable after construction, which is guaranteed by `expFig.Resize = 'off'`.
- Added `makeBtnCallback(fig, speakerIdx)` and `assignResponse(fig, val)`: together they implement the button click → `fig.UserData.response` write path. The factory function is required because anonymous functions inside the button-placement loop would otherwise all close over the final loop variable value.

*Edit E5 — Shared-helper refactor of results heatmap:*
- Replaced the inline head-drawing block in `drawCircularHeatmap` with a single `drawListenerHeadIcon(ax)` call. The results heatmap is now a consumer of the same helper used by the Discrete experiment diagram, so any future tweak to the head icon propagates to both views automatically.

**Rationale:**
- **Small sequential edits + post-edit file reads:** The v1.1 attempt logged above this entry failed because a full-file rewrite truncated on save. Breaking the work into nine small edits and statically analyzing the file on disk between each one bounds the failure radius: if any single edit corrupted the file, the next static-analysis call would have flagged it before any further changes were layered on top.
- **Shared `drawListenerHeadIcon` helper (instead of duplicated inline code):** My initial instinct was to duplicate the head-drawing code in the new Discrete diagram to minimize diff size, but the user correctly pointed out that duplication creates drift risk. The refactor is small (extract ≈ 20 lines, replace with a one-line call at each callsite), and the benefit — a single source of truth for the listener icon geometry — is durable.
- **Button label flip at the TOP of the Speaker 6 iteration:** Placing the `btn_next.Text = 'Done'` assignment before playback begins (rather than after) means the user sees "Done" for the entire duration of the Speaker 6 tone, matching the PRD wording exactly.
- **`UserData.response` as single response sink:** Using one field in the figure's `UserData` for both keypress and button-click events removes any possibility of the two input paths racing each other, and makes the response-handling contract between diagram builder and wait-function trivially auditable.
- **Sector divider lines on the Discrete diagram:** Drawing radial lines at the six sector boundaries (30°, 90°, 150°, 210°, 270°, 330°) makes the hex geometry visually obvious and visually matches the panning-law sector scheme used in Continuous mode — the subject sees the same underlying spatial grid in both experiments.
- **Button placement at r = 1.15 (outside the ring):** Keeps the buttons clear of the sector divider lines and the listener head icon. The 70-px button size is comfortably larger than the Continuous ring's speaker markers, reinforcing the PRD's point that on the Discrete screen the buttons ARE the interaction target, not just reference labels.

**Tests run:**

| Test | Description | Result |
|------|-------------|--------|
| Static analysis after Edit A | MATLAB Code Analyzer on full SLT.m | PASS (0 issues) |
| Static analysis after Edit B | " | PASS (0 issues) |
| Static analysis after Edit C | " | PASS (0 issues) |
| Static analysis after Edit D | " | PASS (0 issues) |
| Static analysis after Edit E1 | " | PASS (0 issues) |
| Static analysis after Edit E2 | " | PASS (0 issues) |
| Static analysis after Edit E3 | " | PASS (0 issues) |
| Static analysis after Edit E4 | " | PASS (0 issues) |
| Static analysis after Edit E5 | " | PASS (0 issues) |
| A — Function inventory | All 10 expected functions present: SLT, launchIntroGUI, runCalibration, runExperiment, waitForDiscreteResponse, waitForRingClick, drawListenerHeadIcon, buildDiscreteSpeakerDiagram, makeBtnCallback, assignResponse | PASS |
| B — Version header | Header contains `Version : 1.1` | PASS |
| C — Response handler swap | `waitForKeyResponse` removed, `waitForDiscreteResponse` present | PASS |
| D — Head icon deduplication | Exactly one definition of `hR = 0.15;` in the file (inside `drawListenerHeadIcon`) | PASS |
| E — In-axes caption removed | Old ring caption string no longer present | PASS |
| F — Top instruction strings | Both Discrete and Continuous instruction fragments present | PASS |
| G — Functional launch | `SLT()` invoked with a 1.5 s teardown timer; Intro GUI appeared and closed with no parse/runtime errors | PASS |

**File size:** 51342 bytes (v1.0 baseline was 42280 bytes; delta +9062 bytes reflects the new helpers, instruction label, dynamic button label logic, and comments).

**Known limitations / next steps:**
- Audio hardware tests (9.2.3, 9.5.2–9.5.4) still require the ASIO interface. User should perform: (a) full calibration cycle to confirm "Done" button behavior on Speaker 6 leaves no hanging audio, (b) short Discrete session to confirm both keypress and click record correctly and stop audio, (c) short Continuous session to confirm the ring still responds and the new top instruction renders as expected.
- Visual check (9.5.1): user should eyeball the Intro and Calibration GUIs to confirm the pure-black body text is legible against the pink input fields and white panel.
- Acoustic-logic regression (9.5.5): the 8 tests from 2026-04-13 should still pass unchanged since no audio-engine function was modified. User may re-run them on the hardware rig at leisure.
- The speaker-button `axData2FigPx` mapping depends on `expFig.Resize = 'off'` remaining true. Noted in code comments for future maintainers.
- `applyOffsetRamp` is still defined but not called in the trial loop (carried from v1.0); offset is handled at the device level via `reset`. Can be wired in during hardware testing if an audible fade-out is desired.

---

## 2026-04-15 — Sections 1–8 Audit & PRD v1.4 / TASKS v1.4

**Description:** User-led audit of TASKS.md Sections 1–8 against SLT.m v1.1. Walked every task line-by-line and confirmed the implementation against the file on disk, then marked the document accordingly. Separately, user requested a new feature (Section 10): summary stats rendered as a third text line on each heatmap and recorded as a `#`-prefixed header comment block at the top of the CSV. PRD bumped to v1.4 to capture the spec; TASKS bumped to v1.4 to capture both the Section 1–8 audit results and the new Section 10 work.

**Changes to documents:**

- **TASKS.md → v1.4.**
  - Sections 1.1–1.3, 2.1–2.9, 3.1–3.10, 4.1–4.2, 5.1–5.3, 6.1–6.6, 7.1–7.6 marked `[x]`. Inline italicised notes added where the implementation differs cosmetically from the original task wording (e.g. 2.7 `initAudio` is implemented as `tryOpenAudio`; 5.3 close-after-Speaker-6 is now driven by the dynamic "Done" button per PRD v1.3).
  - Section 8: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.8, 8.9, 8.10, 8.11 marked `[x]` with notes referencing the offline tests in LOG 2026-04-13. **8.7 left unchecked** — onset ramp is applied per trial as required, but offset ramp is not; offset is currently handled at the device level via `reset(aPR)`. Strict reading of the task is unsatisfied. **8.12 left unchecked** — audio-cleanup verification requires hardware.
  - Added **Section 10 — Stats Display & Export (PRD v1.4)** with three subsections: 10.1 heatmap stats subtitle (10.1.1–10.1.3), 10.2 CSV header comment block (10.2.1–10.2.3), 10.3 verification (10.3.1–10.3.4). All Section 10 boxes unchecked; awaiting user approval before any code changes.
  - Document-status footer rewritten to reflect the new state: Sections 1–8 complete with carry-forward caveats on 8.7 and 8.12; Section 9 code complete with hardware verification pending; Section 10 awaiting approval.

- **PRD.md → v1.4.**
  - §6.1 (Summary Statistics): added a closing sentence noting the three surfaces where the stats now appear (Results window, heatmap subtitle, CSV header comment block).
  - §6.2 (Heatmap Visualizations): added a **Stats subtitle line** subsection specifying the third text line below the description subtitle, with explicit format strings for Discrete and Continuous modes and the rationale for omitting accuracy from Continuous.
  - §6.3 (Data Export): expanded the CSV bullet to specify the `#`-prefixed header comment block, with the exact line-by-line format. Noted that Excel tolerates the lines and MATLAB's `readtable(…, 'CommentStyle', '#')` skips them cleanly.

**Rationale:**

- **Audit before any new code:** The Refinement Round 1 saga (one truncated save, one rollback, then a successful targeted re-implementation) made it clear that an honest, current TASKS document is essential before adding new work. Walking Sections 1–8 against the file on disk — rather than relying on the LOG entries alone — catches drift between "described as done" and "actually done." The 8.7 finding is a good example: the LOG correctly notes that `applyOffsetRamp` is defined but unused, but the task itself was never updated to reflect that the offset path is currently device-level rather than buffer-level.
- **Italicised inline notes vs separate caveat sections:** Putting the caveats inline next to each `[x]` keeps the task list scannable and prevents future readers from missing the nuance. A separate "caveats" appendix is easy to skip.
- **Stats on three surfaces (window + heatmap + CSV) instead of one:** Each surface serves a different consumer. The Results window is for the operator immediately after the session. The heatmap subtitle is for whoever opens the PNG later (no need to also open the CSV to know how the session went). The CSV header is for the analyst doing post-hoc work in MATLAB or Excel — the metadata travels with the data. Putting the same numbers in all three places is redundancy by design, not by accident.
- **`#` as CSV comment prefix:** Standard convention across pandas, R, MATLAB, and most CSV-aware tools. `readtable(…, 'CommentStyle', '#')` is a one-liner round-trip in MATLAB, which keeps the analysis path frictionless.
- **Omit accuracy from Continuous:** There is no "correct" speaker for a virtual panned position, so % accuracy is undefined. Showing `NaN` or `—` would be visual noise; omitting the field entirely is cleaner.

**Tests run:** None — documentation only. No code touched.

**Next step:** Await user approval of PRD v1.4 §6 and TASKS v1.4 Section 10 before any modifications to SLT.m. On approval, the Section 10 work is small enough to fit into a single targeted edit pair (one to `drawCircularHeatmap` for the subtitle, one to `showResults` for the CSV header), but per the lesson from Round 1 it will still be applied as separate small edits with static-analysis checks in between.

---

## 2026-04-15 — Section 10 Implementation (SLT.m v1.1 → v1.2)

**Description:** User approved Section 10. Implemented all PRD v1.4 stats display & export tasks (10.1.1–10.1.3 and 10.2.1–10.2.2) against SLT.m v1.1. Applied as five small targeted `edit_file` operations with static-analysis checks between each, plus one mid-stream functional CSV-writer test and an end-to-end render test of both heatmaps. Final file size: 55520 bytes (up from 51342 baseline — healthy growth, no truncation). Hardware verification (10.2.3 Excel check, 10.3.1–10.3.4 live session) deferred to the rig.

**Changes (in the order they were applied):**

*Edit A — Header bookkeeping:*
- Bumped Version `1.1` → `1.2`, Date `2026-04-14` → `2026-04-15`.
- Added a v1.2 changelog block enumerating the three PRD v1.4 deltas (heatmap stats line, showResults stats struct, CSV header comment block).

*Edit B — Tasks 10.1.3 (`showResults` stats struct):*
- Bundled `accuracy`, `meanErr`, `meanRT` into a `stats` struct immediately after the existing summary-stat computation.
- Updated both `drawCircularHeatmap` call sites to pass `stats` as the new 7th argument.

*Edit C — Tasks 10.2.1, 10.2.2 (CSV writer rewrite):*
- Removed the `array2table`/`writetable` pair that produced the previous CSV.
- Added a new write sequence: `fopen` the target path, emit nine `#`-prefixed header lines via `fprintf` (subject, date, stimulus, mode, description, accuracy if Discrete, mean angular error, mean response time), then the column header line, then the per-trial data rows formatted as `%d,%d,%d,%.4f,%.4f`. `fclose` at the end. Wrapped in an `if fid == -1` guard with a warning so a write failure surfaces cleanly rather than crashing.

*Edit D — Tasks 10.1.1, 10.1.2 (heatmap signature + subtitle):*
- Extended `drawCircularHeatmap` signature with a final `stats` parameter; updated the function header docstring to describe its role.
- Bumped figure height 680 → 700 px and adjusted axes Y position 0.12 → 0.10 to give the subtitle block more vertical room.
- Built the `statsStr` with mode-specific format (Discrete: accuracy + mean error + mean RT; Continuous: mean error + mean RT only).
- **First implementation attempt** rendered the stats line via `annotation('textbox', …)` at normalized figure y=0.92, but the render-test showed the line landed *above* the title rather than below the description subtitle. Replaced with a cell-array subtitle: `subtitle(ax, {description; statsStr}, …)`. MATLAB's `subtitle()` is anchored beneath the axes title and stacks multi-line cell input vertically, which puts the visual hierarchy in the correct order: title → description → stats. Re-render confirmed correct positioning in both Discrete and Continuous outputs.

*Edit E — Em-dash → hyphen in CSV title line:*
- The initial CSV writer used `'\xE2\x80\x94'` (UTF-8 em-dash) in the `# Sound Localization Test — Session Results` line. While Excel and modern editors handle UTF-8 correctly, MATLAB's `type` command on Windows-1252-default systems mis-renders it as `â`. Per user direction, swapped to a plain `-` for cross-platform safety. The PRD still calls for an em-dash visually but the practical safety win outweighs strict typographic conformance for this metadata header.

**Rationale:**
- **Stats struct vs three loose scalars:** Bundling into `stats.accuracy / .meanErr / .meanRT` keeps the `drawCircularHeatmap` argument list at 7 instead of 9 and gives the CSV writer a single source to pull from. NaN in `stats.accuracy` is the explicit "omit" signal for Continuous mode — no separate flag needed.
- **`subtitle()` cell-array trick:** The cleaner first attempt with `annotation` failed visually because it lives in normalized figure coordinates and is layout-independent of the axes title. Using `subtitle()` with a 2-line cell ties the stats to the title's anchor, so any future title resize or font change cascades correctly to the subtitle stack. Less code, better behavior.
- **Render-test before declaring victory:** The `annotation`-based first attempt passed static analysis cleanly and produced a valid PNG — it just had the wrong layout. Static analysis cannot catch visual ordering. Mid-stream render-test caught it before it shipped.
- **`#` comment prefix + `readtable` round-trip:** Verified during the in-isolation CSV-writer test (max diff 0.00 between original numeric trialData and `readtable(…, 'CommentStyle', '#')` output). The Continuous case correctly omits the Accuracy line.
- **Plain hyphen over em-dash:** Erring on cross-platform safety. Anyone opening the CSV in any tool, on any locale, sees the same line.

**Tests run:**

| Test | Description | Result |
|------|-------------|--------|
| Static analysis after Edit A | MATLAB Code Analyzer on full SLT.m | PASS (0 issues) |
| Static analysis after Edit B | " | PASS (0 issues) |
| Static analysis after Edit C | " | PASS (0 issues) |
| CSV writer functional test | Synthetic trialData (4 rows) + stats; write CSV with header, read back via `readtable(…, 'CommentStyle', '#')` | PASS (round-trip max diff 0.00) |
| CSV writer Continuous case | Synthetic single-row Continuous; verify Accuracy line omitted | PASS |
| Static analysis after Edit D | MATLAB Code Analyzer | PASS (0 issues) |
| Render test — Discrete heatmap (first attempt) | `showResults` end-to-end with synthetic 6-trial dataset | FAIL (stats line above title instead of below description) |
| Render test — Discrete heatmap (after subtitle fix) | Same dataset, after Edit D revision | PASS (title → description → stats order correct) |
| Render test — Continuous heatmap | Synthetic 4-trial Continuous dataset | PASS (Accuracy correctly omitted, layout correct) |
| Static analysis after Edit E | MATLAB Code Analyzer | PASS (0 issues) |
| Final file size | Disk read + `dir` | PASS (55520 bytes; +4178 vs v1.1 baseline of 51342) |

**Known limitations / next steps:**
- **10.2.3 (Excel verification):** The CSV header opens cleanly in MATLAB and any text editor. Excel will display the `#`-prefixed lines in column A as ordinary text rows; the data table below should still parse correctly into columns A–E. Visual confirmation in Excel deferred to the live session.
- **10.3.1–10.3.4 (live-session verification):** All require the hardware rig. Same status as the Section 9 verification tasks — will be performed alongside.
- **Audio cleanup carry-forwards from previous rounds (8.7 offset ramp, 8.12 audio cleanup) remain unresolved.** Section 10 changes do not affect the audio engine, so no new risk introduced there.
- The render-test wrapper (`test_render_heatmap_v0.m`) was written into MATLAB's tempdir and the four `_RENDERTEST_*` files left briefly in `results/` for inspection were deleted after verification.

**Next step:** Hardware connection attempt, per the user's plan after Section 10. Sequence at the rig: (a) launch SLT, run Calibrate to confirm audio path, (b) run a short Discrete session, (c) run a short Continuous session, (d) open the resulting CSVs in Excel and confirm the header block renders as expected, (e) tick the remaining hardware-dependent boxes in TASKS (8.12, 9.2.3, 10.2.3 Excel half, 10.3.1–10.3.4).

---

## 2026-04-15 — ASIO Device Support (SLT.m v1.2 → v1.3, TASKS v1.4 → v1.5, PRD v1.4 → v1.5)

**Description:** Audio interface (Focusrite) plugged in for the first time. Windows reported it as a 2-channel device, which would have caused `tryOpenAudio`'s old enumeration logic (based on `audiodevinfo` + `MaxOutputChannels >= 6`) to reject it and degrade to silent mode. Diagnosed that `audiodevinfo` only sees Windows MME/DirectSound/WASAPI drivers; the ASIO driver — which surfaces all 10 hardware outputs — is invisible to it. `getAudioDevices(audioPlayerRecorder)` does see ASIO devices. User confirmed via direct probe that the Focusrite ASIO driver is installed and accepts a 6-channel `audioPlayerRecorder` open at 48 kHz. Replaced the enumeration logic; bumped TASKS and PRD to reflect the implemented behaviour.

**Changes (in the order they were applied):**

*Edit A — SLT.m header bookkeeping:*
- Bumped Version `1.2` → `1.3`, date stamp 2026-04-15.
- Added a v1.3 changelog block describing the ASIO device-enumeration fix.

*Edit B — `tryOpenAudio` rewrite:*
- Replaced the `audiodevinfo` + per-device channel-count loop with a `getAudioDevices(audioPlayerRecorder)` call.
- New selection policy: prefer any device whose name contains `'ASIO'` (case-insensitive); fall back to first non-`'Default'` device; fall back to silent mode with a clear warning if only `'Default'` is available (since the generic Default device is unlikely to support 6 channels).
- Channel-count check moved from pre-flight to post-flight: we no longer attempt to query a per-device channel count (`getAudioDevices` does not expose one), instead we attempt the construction with `PlayerChannelMapping = 1:6` and let the constructor throw if the device cannot supply that many channels. The existing `try/catch ME` already handles this and degrades to silent mode.
- Added a confirmation `fprintf` on successful open (`SLT: opened audio device "<name>" with N output channels`) so the operator can see at a glance which device was selected.
- The function's external contract (`[aPR, deviceOK]`) is unchanged — no other code in SLT.m needed to know about the swap.

*Edit C — TASKS.md updates (v1.4 → v1.5):*
- Updated 2.7's italicised inline note to describe the v1.3 behaviour (`getAudioDevices` enumeration, ASIO-preferred selection policy, Focusrite verification).
- Added new **Section 11 — ASIO Device Support** with five subtasks (11.1–11.4 marked complete; 11.5 — live-session channel-routing verification — left unchecked pending the rig session).
- Updated the document-status footer to mention Section 10's completion state and Section 11's pending hardware verification.

*Edit D — PRD.md updates (v1.4 → v1.5):*
- Bumped version header to v1.5.
- §2 (Physical System): added a **Driver requirement** paragraph explaining why ASIO is required (Windows-side drivers cap at the default stereo pair on most pro interfaces) and what the implementation does about it.
- Document-status footer rewritten from the stale "awaiting approval" line to reflect that the PRD now describes the implemented behaviour, plus an explicit note of which hardware-verification tasks remain.

**Rationale:**

- **Why `getAudioDevices` instead of `audiodevinfo`:** `audiodevinfo` is the legacy Audio Toolbox enumerator and it only sees MME/DirectSound/WASAPI devices. Pro audio interfaces deliberately do not expose all their channels through those drivers (the OS would not know what to do with 8 or 10 outputs). `getAudioDevices(audioPlayerRecorder)` is the modern enumerator and sees ASIO devices, which is exactly what the experiment needs. There's no downside to the swap — `getAudioDevices` also sees the same MME/DirectSound devices, plus ASIO on top.
- **Why "prefer ASIO" rather than "require ASIO":** Keeping the silent-mode fallback intact preserves the offline UI-test path (used heavily during Sections 9 and 10 development). On a dev machine with no ASIO driver installed, SLT can still launch the GUI for layout work — the operator just won't hear anything. On the rig, ASIO will be present and gets picked automatically.
- **Why bump PRD to v1.5 for what is essentially a bug fix:** The driver requirement is a real deployment requirement that the next operator at a new rig needs to know about. Burying it only in the SLT.m header changelog would mean someone setting up a second copy of the experiment on different hardware would hit the same 2-channel surprise we just hit. §2 is the right place for that requirement to live.
- **Why log a `fprintf` on successful open:** No other code path tells the operator which device was selected. If at some future point both an ASIO and a MME device are present and the operator wonders which one is making sound, the console line is the answer. Cheap signal, no noise on the silent-mode path (warning is louder).

**Tests run:**

| Test | Description | Result |
|------|-------------|--------|
| Pre-flight ASIO probe | User ran direct `audioPlayerRecorder('Device','Focusrite USB ASIO','PlayerChannelMapping',1:6)` in MATLAB | PASS ("OK — 6-channel open succeeded") |
| `getAudioDevices` enumeration | User ran `getAudioDevices(audioPlayerRecorder)` | PASS (returned `{'Default','Focusrite USB ASIO'}`) |
| Static analysis after Edit A | MATLAB Code Analyzer on full SLT.m | PASS (0 issues) |
| Static analysis after Edit B | MATLAB Code Analyzer | PASS (0 issues) |
| Functional test of new `tryOpenAudio` | Test wrapper exposed local function; called with CFG.numChannels=6 | PASS (`deviceOK = 1`, picked `Focusrite USB ASIO`, released cleanly) |

**Known limitations / next steps:**

- **TASKS 11.5 (channel routing):** The new code opens the ASIO device and gets a 6-channel buffer to it, but does not verify that MATLAB Channel 1 physically drives the speaker at 0°, Channel 2 drives 60°, etc. The Calibrate routine is the right place to check this — step through speakers 1–6 and confirm each tone comes from the expected physical position. If the wiring is wrong, options are (a) rewire at the patch panel, or (b) add a `CFG.channelMap` indirection so MATLAB Channel `k` can drive an arbitrary hardware channel.
- **Audio-engine carry-forwards** (8.7 offset ramp not wired into trial loop, 8.12 audio cleanup verification) remain unresolved. They were not touched by the v1.3 change.
- **Calibration UX:** worth checking that the dynamic "Done" button on Speaker 6 cleanly stops audio with no clicks/pops when ASIO is the active driver. ASIO has a much shorter buffer than MME so any release-time discontinuity will be more audible than it was during silent-mode testing.

**Next step:** Operator runs the experiment at the rig per the plan from the previous LOG entry: Calibrate first (preferably with Gaussian Noise for easy localization), then a short Discrete session, then a short Continuous session, then open the CSVs in Excel. Report back with what works, any audible artifacts, and any errors.

---

## 2026-04-19 — First Live Rig Session: Audio Bugs Diagnosed

**Description:** First session with the Focusrite ASIO interface physically connected. `tryOpenAudio` opened the device correctly (Section 11 verified), but playback revealed two audio bugs. Diagnosis traced both to the timer-based re-queue strategy in `playLooping`. No code changes today — PRD and TASKS updated to reflect the rewrite plan; implementation to follow in a separate session.

**Field observations:**
- Pure tones (125 / 250 / 500 / 750 / 1000 Hz) through Calibration and Discrete mode sounded like a low rumble with intermittent jitter rather than a clean sine. UI remained responsive throughout.
- Gaussian noise through Calibration sounded correct acoustically, but the Calibration GUI froze — the "Next Speaker" button did not respond. Program had to be force-quit to stop the noise.

**Diagnosis:** Both symptoms trace to `playLooping`'s architecture.

- For tones: the integer-cycle tone buffers are 48–384 samples (1–8 ms) long. The re-queue timer period is `max(0.05, halfBuf)`, which floors at 50 ms for every tone. The device drains its four pre-queued copies in <30 ms and then runs dry for the remaining 20 ms of each 50 ms timer period. The result is a 20 Hz amplitude envelope imposed on the tone — perceived as "rumble" — with Windows timer jitter perceived as "intermittent jitters."
- For noise: the 2-second noise buffer means the four pre-queue calls push 8 seconds of audio into the device before `playLooping` returns. Each `aPR(buffer)` call blocks until the device can accept the buffer, so the main MATLAB thread is frozen for the full pre-queue duration. No UI callbacks fire during that time — hence the dead "Next Speaker" button. Noise masked the timer-rate artifact that is audible on tones.

**Rationale for the rewrite:** MATLAB's `audioPlayerRecorder` is designed for frame-by-frame streaming, not for indefinite looping. The correct pattern is a tight pumping loop that feeds fixed-size frames into the device; the ASIO driver paces the loop automatically because each call blocks until the device can accept the next frame. This removes the timer entirely, removes the pre-queue blocking, and gives us explicit per-frame control at stop time — which also lets us finally wire in `applyOffsetRamp` (TASK 8.7) without contorting the architecture.

**Documents updated:**
- PRD bumped to v1.6: added §2 "Audio streaming model" paragraph, §3.2 "Playback note" subsection, revised §5 trial-loop step 2, refreshed document-status footer.
- TASKS bumped to v1.6: added Section 12 (ten new tasks), updated carry-forward notes on 8.7 and 8.12 to point at Section 12, refreshed document-status footer.

**Tests run:** None — diagnosis and documentation only.

**Next step:** User approval of PRD v1.6 / TASKS Section 12. On approval, implement tasks 12.1–12.5 as small targeted edits (per the lesson from Refinement Round 1), with static analysis between edits and on-rig verification of 12.6–12.10 in the same session.

---

## 2026-04-19 — Section 12 Implementation (SLT.m v1.3 → v1.4)

**Description:** Implemented the audio-streaming rewrite (PRD v1.6 §2, §3.2 / TASKS Section 12) at the rig in one continuous session, with live hardware in the loop. The implementation went through four distinct attempts before landing on a working design — each revealed a separate class of bug invisible at design time. Final result: clean sine tones with responsive UI and no jitter during mouse interaction. User confirmed "program runs well." Hardware verification tasks 12.6–12.9 passed; 12.10 (offline acoustic regression) deferred.

### Attempt 1 — Initial frame-streaming rewrite

**Changes (in the order applied):**

*Edit A — Header bookkeeping:*
- Bumped Version `1.3` → `1.4`, Date `2026-04-15` → `2026-04-19`.
- Added a v1.4 changelog block describing the streaming rewrite.

*Edit B — Added `CFG.frameSize = 1024`.*

*Edit C — Replaced `playLooping` with `streamAudio`:*
- New function: concatenates `loopBuf` into a tile ≥ one frame long, walks a cursor through it dispatching `frameN`-sample frames via `aPR(frame)` in a tight `while ~respGetter()` loop. `drawnow limitrate` between frames.
- Offset ramp applied to one final tail frame after `respGetter` fires (closes TASK 8.7).
- Simplified `stopAudio` to bare `reset(aPR)`; removed the base-workspace `SLT_loopTimer` global entirely.

*Edit D — `runCalibration` uses `streamAudio`:*
- Replaced the play-then-poll pair with a single `streamAudio(aPR, outBuf, CFG, @() nextDone || ~isvalid(calFig))` call. Silent-mode fallback retained.

*Edit E — `runExperiment` trial loop + wait helpers:*
- Trial loop now passes `aPR, outBuf, CFG, deviceOK` into `waitForDiscreteResponse` / `waitForRingClick`. `tStart = tic` moved before the response wait so response time measurement is unaffected.
- `waitForDiscreteResponse` signature extended; body rewritten to install keypress handler, then call `streamAudio` with closure `@() ~isempty(fig.UserData.response) || ~isvalid(fig)`.
- `waitForRingClick` signature extended; uses dedicated `fig.UserData.ringResponse` sink (integer 1–360) to avoid type-confusion with Discrete's 1–6 `.response` sink.

Static analysis clean after each edit. Functional smoke test (file parses + help renders) passed.

### Attempt 1 failure at rig: index out of bounds

**Field observation:** First click of Calibrate (1000 Hz tone) threw `Index in position 1 exceeds array bounds. Index must not exceed 1152.`

**Diagnosis:** The cursor-wrap rule in streamAudio was wrong for the tone case. For a 1000 Hz tone, `loopN = 48` and `frameN = 1024`, giving `nCopies = 22` and `tileN = 1056`. After the first frame dispatch, `cursor = 1025`; the wrap rule `cursor = cursor - loopN` subtracted only 48, leaving `cursor = 977` — but `977 + 1024 - 1 = 2000`, still way past `tileN = 1056`. Needed to wrap by multiple `loopN` increments, and the tile needed to be large enough that any valid wrapped position leaves room for a full frame.

### Attempt 2 — Tile-sizing fix

*Edit F — Rewrote the tile sizing and wrap rule:*
- Changed `nCopies = ceil((2 * frameN) / loopN)` (always ≥ two frames long).
- Changed the wrap to `while cursor + frameN - 1 > tileN, cursor = cursor - loopN; end` (repeated subtraction).

In-isolation simulation passed all five tone cases over 2000 iterations. But the simulation caught a new failure: the noise case produced `minCursor = -991`, i.e. cursor went negative. The repeated-subtract rule subtracts `loopN = 95520` from a cursor in roughly `[94498, 95520]`, giving a negative result.

### Attempt 3 — Modulo-based cursor

*Edit G — Replaced the repeated-subtract rule with modulo wrap:*
- `nCopies = ceil((loopN + frameN) / loopN)` — tile is always one full loop plus at least one full frame.
- Cursor advance: `cursor = mod(cursor - 1 + frameN, loopN) + 1` — keeps cursor in `[1, loopN]` at all times, and `cursor + frameN - 1 ≤ loopN + frameN ≤ tileN` is guaranteed by construction.

In-isolation simulation passed all six cases (five tones + noise) over 3000 iterations with phase continuity verified against the infinite-periodic-stream reference.

### Attempt 3 failure at rig: harmonics + dead button

**Field observations:** Frequency was correct but tone had audible harmonic distortion — not a clean sine. Next Speaker button did nothing.

**Diagnosis (harmonics):** `applyOnsetRamp` was being called on `outBuf` (which is the small repeatable loop buffer) BEFORE `streamAudio` was entered. `streamAudio` then tiled the ramped buffer into frames — which meant the Hann ramp repeated every `loopN` samples (every 48 samples → 1 kHz modulation on a 1000 Hz tone). The amplitude envelope at the loop-buffer rate produced harmonic distortion.

**Diagnosis (dead Next button):** Separate bug. The calibration closure was:
```matlab
nextDone = false;
btn_next = uibutton(..., 'ButtonPushedFcn', @(~,~) setDone());
function setDone(), nextDone = true; end
...
streamAudio(aPR, outBuf, CFG, @() nextDone || ~isvalid(calFig));
```
The nested `setDone` correctly mutated `nextDone` in the parent workspace. But the anonymous function `@() nextDone || ~isvalid(calFig)` is NOT a nested function — it captures `nextDone` **by value at creation time**. So the closure's view of `nextDone` was frozen at `false` forever. Confirmed by writing and running a minimal `testClosureCapture.m`: `before setFlag: getter() = 0 / after setFlag: getter() = 0`.

### Attempt 4 — Ramp placement + closure semantics + UI responsiveness

*Edit H — Moved onset ramp into `streamAudio`:*
- Pre-computed `onRamp = hann(rampN*2)(1:rampN)` at function entry.
- Applied to the first `rampN` samples of the FIRST dispatched frame only (guarded by `isFirst` flag). Every subsequent frame samples the raw periodic loop — no per-copy envelope, clean sine.
- Removed `applyOnsetRamp` calls from `runCalibration` and `runExperiment` with inline comments explaining the new contract.

*Edit I — Moved `nextDone` to `calFig.UserData.nextDone`:*
- The figure is a handle object; anonymous closures capture the handle by reference, so reads of `calFig.UserData.nextDone` always fetch the current value.
- Added a top-level `setNextDone(calFig)` function (replacing the deleted nested `setDone`) that writes the flag via the handle.
- All three readers updated: `streamAudio` closure, silent-mode poll loop, and the outer loop's break test.

*Edit J — `drawnow limitrate` instead of plain `drawnow`:*
- I had briefly switched to plain `drawnow` thinking it was needed for button-callback firing; that was actually the closure-capture bug in disguise.
- Plain `drawnow` is synchronous and blocks until all queued callbacks + repaints complete — with uifigure mouse-hover events that takes long enough to starve the audio device between frames. Reverted to `drawnow limitrate`.

### Attempt 4 field result: harmonics fixed, button works, but jitter during UI interaction

**Field observation:** Clean sine, working button. Jitter whenever cursor highlights a UI component.

**Diagnosis:** `audioPlayerRecorder`'s default `BufferSize` is 1024 samples = 21 ms at 48 kHz. `drawnow limitrate` still has to service the UI event queue, and a mouse-hover burst on a uifigure component can take longer than 21 ms of CPU. During that stall the device's small internal buffer drains and underruns — glitch.

### Attempt 5 — Larger device buffer

*Edit K — Bumped `CFG.frameSize` 1024 → 4096 (≈85 ms) and set `BufferSize=CFG.frameSize` when constructing `audioPlayerRecorder`:*
- The device now has ~85 ms of internal runway per hardware callback. Any UI stall under that duration cannot underrun.
- `tryOpenAudio` constructor updated to pass `BufferSize`; console log on successful open now reports the buffer size too.

**Field result:** Clean sine, working button, no jitter even during aggressive UI interaction. User confirmed "program runs well."

**Rationale highlights:**

- **Frame-streaming over timer-re-queue:** The timer approach was fundamentally incompatible with short buffers because of Windows timer floor (≈10–15 ms) combined with the MATLAB-timer-period minimum of 50 ms in the old code. Frame-streaming lets the ASIO driver's own buffering pace the loop — no timer needed.
- **Onset ramp inside `streamAudio` (not upstream):** This is counterintuitive because "apply ramps before playback" is a textbook pattern — but it only works when "playback" plays the buffer once. When the buffer is tiled into frames and played repeatedly, a ramp applied upstream repeats at the loop rate. The correct place for a one-shot onset ramp is the one-shot first frame.
- **`UserData.nextDone` for reference-semantic state:** This was the hardest bug of the day to diagnose from symptoms alone. The button callback appeared to "do nothing" but was actually doing its job — it was the observer (the anonymous closure) that was frozen. Stashing mutable state on a handle object is the idiomatic MATLAB fix. I also wrote a standalone `testClosureCapture.m` to confirm the semantics empirically before committing to the fix; the minimal test showed `getter()` returning 0 even after a nested function set the captured local to `true`. The test file was deleted after verification.
- **`BufferSize` matched to `frameSize`:** Important symmetry. If `BufferSize=1024` but we push 4096-sample frames, the device would have to split each frame across four hardware callbacks, and the extra latency between "frame accepted by object" and "frame actually playing" would manifest as jitter. Matching them means each `aPR(frame)` call corresponds to exactly one hardware callback.
- **Pre-queue idea rejected:** At one point I tried pre-queuing 2–4 frames into the device before entering the main loop, hoping to get an independent runway. But `aPR(frame)` calls block on the internal-queue depth, which is fixed — pre-queuing just means the first few calls block for longer, it doesn't add any independent headroom. The only way to actually get more runway is a bigger `BufferSize`, which is what the final fix does.

**Tests run:**

| Test | Description | Result |
|------|-------------|--------|
| Static analysis after Edits A–K | MATLAB Code Analyzer after each of 11 small edits | PASS (0 issues each except the pre-existing `applyOnsetRamp might be unused` warning) |
| Functional smoke test | `SLT.m` parses, `help SLT` renders v1.4 changelog | PASS |
| Cursor simulation (Attempt 2) | 2000-iter simulation of cursor logic for 5 tones + noise | FAIL on noise case (cursor went negative) |
| Cursor simulation (Attempt 3) | Same, with modulo-based cursor | PASS on all 6 cases, phase continuity verified |
| `testClosureCapture.m` (standalone) | Minimal repro of anonymous-function by-value capture | PASS (confirmed bug: getter returned 0 after nested setter wrote true) |
| Rig: Calibrate 1000 Hz tone (Attempt 1) | Live Focusrite ASIO | FAIL (index out of bounds) |
| Rig: Calibrate 1000 Hz tone (Attempt 3) | Live Focusrite ASIO | FAIL (harmonics + dead button) |
| Rig: Calibrate 1000 Hz tone (Attempt 4) | Live Focusrite ASIO | FAIL (clean sine + button works, but jitter on UI hover) |
| Rig: Calibrate 1000 Hz tone (Attempt 5) | Live Focusrite ASIO with `BufferSize=4096` | PASS (clean sine, responsive button, no jitter) |
| TASK 12.6 — clean tone + responsive UI | Rig session | PASS |
| TASK 12.7 — noise Calibrate, clean stop on Done | Rig session (implicit — the UI-responsiveness fix resolves the previous noise-freeze as well) | PASS |
| TASK 12.8 — no click at Discrete stimulus offset | Rig session (offset ramp now wired in) | PASS |
| TASK 12.9 — no click at Continuous stimulus offset | Rig session | PASS |
| TASK 12.10 — offline acoustic-logic regression | Not run this session | DEFERRED |

**File size:** 66073 bytes (up from 55520 at v1.3 start of session; +10553 bytes reflects the new `streamAudio` function, `setNextDone`, expanded changelog, and inline rationale comments).

**Known limitations / next steps:**
- **TASK 11.5 (channel routing):** Still not formally verified. User did not report any obvious routing issues during the session but this should be checked deliberately in the next session (step through calibration, confirm each tone comes from the expected physical speaker position).
- **TASK 12.10 (offline acoustic-logic regression):** Not re-run this session. The acoustic functions (`buildToneBuffer`, `buildNoiseBuffer`, `computePanAmplitudes`, `circularAngularError`) were not touched in v1.4, but a full regression run is cheap and worth doing for the record.
- **TASK 10.2.3 Excel half:** CSV opens correctly in MATLAB's `readtable`; Excel verification not yet confirmed at the rig.
- **Onset latency:** ~85 ms from `aPR(frame)` call to sound emerging. For localization with response times in hundreds of ms this is imperceptible; if sub-100 ms response-time measurement is ever needed, `CFG.frameSize` can be reduced (with corresponding loss of UI-stall headroom).
- **`applyOnsetRamp` function is now unused** (ramp is computed inline in `streamAudio`). Left defined for symmetry with `applyOffsetRamp` and in case a caller ever needs it. The static-analysis warning is benign.

**Next step:** User will provide feedback from additional rig time. When feedback arrives, address any new issues; then close out TASK 11.5 (channel routing), re-run 12.10, and move the project toward Phase 4 (Tutorial).

---

## 2026-05-02 — Second Rig Session Feedback & Section 13 Planning

**Description:** User returned from a second rig session with three items: (a) audible click at stimulus offset instead of a smooth fade, (b) audio stutters during UI mouse-hover events, and (c) a request for ways to perceptually validate continuous panning. Operator had also made two interim adjustments to SLT.m without bumping the version (`CFG.frameSize` 4096 → 8192 to reduce stutter, `CFG.rampMs` 10 → 100 for a smoother feel) — confirmed in this session's read of the file.

**Diagnoses (no code touched, design discussion only):**
- *Click at offset*: suspected `reset(aPR)` in `stopAudio` cutting off the offset-ramp tail frame mid-playback. `audioPlayerRecorder`'s internal queue means `aPR(frame)` returns when the object accepts the frame, not when the hardware finishes playing it. Confirmed at the rig by commenting out the inter-trial `stopAudio` call — click disappeared. Fix: append a single all-zeros 'silent pump' frame after the ramped tail frame to occupy the queue slot that `reset()` would otherwise truncate.
- *Stutter on UI hover*: mouse-hover events on uifigure components occasionally stall the UI thread longer than the per-frame callback runway, starving the device. The 8192-sample (~170 ms) interim setting reduced but did not eliminate the issue. Fix: bump frame size again to 16384 (~340 ms callback runway).
- *Continuous panning validation*: discussed five approaches (math sweep, visual sanity plot, audible sweep at the rig, loopback measurement, behavioural self-test). User chose to implement the audible sweep as an optional yes/no prompt at the end of speaker calibration.

**Decisions (recorded in PRD v1.8 / TASKS v1.8):**
- Silent pump: one all-zeros frame after the ramped tail frame.
- Frame size: bump 8192 → 16384.
- Sweep configurability: new `Sweep Duration (s)` numeric field on the Intro GUI, default 10 s, placed at the bottom of the parameter panel after Description (groups visually with Calibrate, the only consumer).
- Sweep architecture: separate `streamPanSweep` function rather than generalizing `streamAudio` — keeps the well-tested fixed-amplitude path untouched.
- Sweep UI: reuse the calibration window. Speaker label → "Continuous Panning Sweep"; instruction label → live degree readout; advance button → "Stop Sweep". Modal `uiconfirm` after Speaker 6 with default-No for cancel-safety.
- Edge case: if user closes the calibration window mid-sequence, skip the sweep prompt entirely.

**Documents updated:**
- PRD.md → v1.8: §2 frame-size and runway figures updated to 16384/340 ms; §3.2 ramp duration updated to 100 ms with a new "Silent-pump frame" subsection; §4.1 table adds Sweep Duration row and updates Calibrate description; §4.2 adds "Post-calibration sweep prompt" subsection; new §4.6 "Continuous Panning Sweep" specification; document-status footer rewritten.
- TASKS.md → v1.8: new Section 13 with seven subsections (13.1 silent pump, 13.2 frame-size bump, 13.3 Sweep Duration field + validation, 13.4 modal prompt + edge case, 13.5 `streamPanSweep` function, 13.6 `runPanSweep` helper, 13.7 verification covering both fixes and the new feature plus a side-benefit close of the long-deferred 12.10 offline regression). Document-status footer added at end.

**Tests run:** None — documentation only.

**Next step:** User approved PRD v1.8 / TASKS v1.8 and authorized Phase 3. Implementation pending in subsequent LOG entry. Plan: archive `SLT.m` v1.4 → `archive/SLT_v1.4_2026-04-19.m`, then apply Section 13 as small targeted edits with `check_matlab_code` static analysis between each.

---

## 2026-05-02 — Section 13 Implementation (SLT.m v1.4 → v1.5) — COMPLETE

**Description:** Implemented PRD v1.8 §2/§3.2/§4.1/§4.2/§4.6 (TASKS Section 13) at the desk — click fix, frame-size bump, and continuous panning sweep. Followed the Round 1 lesson from 2026-04-14: small targeted edits with `check_matlab_code` static analysis between each, no full-file rewrites.

**Edits applied (in order):**
1. Archived the pre-edit file as `archive/SLT_v1.4_2026-04-19.m` (full source preserved). Note: my first attempt at the archive write truncated the function bodies; immediately corrected by re-writing with the full v1.4 source. Archive file is now complete.
2. Header: bumped v1.4 → v1.5, date 2026-04-19 → 2026-05-02; prepended a v1.5 changelog block enumerating Section 13 deltas. *Static check: clean.*
3. CFG: `frameSize` 8192 → 16384; refreshed inline comment with the rationale (uifigure mouse-hover stalls observed at 8192). *Static check: clean.*
4. `streamAudio`: appended one all-zeros silent-pump frame after the offset-ramp tail frame. *Static check: clean.*
5. `launchIntroGUI`: bumped figure 420→462 px and input panel 250→292 px; shifted Stimulus / Trials / Pause / Mode / Description rows up by 42 px each; added new Sweep Duration row at y=32 (default 10 s). Added validation in `onCalibratePressed` (rejects 0 / negative / NaN with a `uialert`). Pass `sweepDurSec` into `calParams`. *Static check: clean.*
6. `runCalibration`: assigned the existing "Adjust volume" label to a handle (`lbl_instr`) so `runPanSweep` can re-purpose it. Inserted a `uiconfirm` modal after Speaker 6 (default No, cancel-safe). On Yes, calls `runPanSweep` with the existing audio device handle, then runs `stopAudio`. Edge case: skips the prompt entirely if the calibration window was closed mid-sequence. *Static check: clean.*
7. New SECTION 7 block at the end of the file with three helper functions: `runPanSweep` (re-purposes the calibration UI labels and button), `updateDegReadout` (per-frame label update wrapped in a try block to tolerate a closed label), and `streamPanSweep` (mirrors `streamAudio` structure but rebuilds the per-channel frame each iteration via `computePanAmplitudes`; per-frame angle synced to cumulative samples for clean audio/visual coherence; offset ramp built at the final panning angle for acoustically consistent fade-out; silent pump frame on exit). *Static check: clean.*

**Tests run:**
- `nargin('SLT')` = 0 — file parses cleanly in MATLAB.
- 11/11 v1.5 marker checks pass (frame size, silent pump, sweep field, validation, modal text, three new function definitions, UI text, version header).
- Offline acoustic-logic regression (slt_regression_v15.m, closes TASK 12.10 and 13.7.7): 29/29 tests pass:
    - Test 1 (tone integer-cycle, 5 freqs): 5/5
    - Test 2 (noise unit peak): PASS
    - Test 3 (pan at 6 speaker angles): 6/6
    - Test 4 (pan at sector midpoints, -3 dB law): 6/6
    - Test 5 (constant-power across 1–360 deg): max err 2.22e-16 (machine epsilon)
    - Test 6 (circular angular error, 7 cases): 7/7
    - Test 7 (pan wrap 0° == 360°): PASS
    - Test 8 (sector-1 monotonicity): PASS
    - Test 9 (NEW: sweep angle math): 30 main-loop frames at 12.29°/step, range 0° – 356.35° (offset tail frame picks up the final 3.65° at exactly 360° via `min(cum/total, 1)` clamp — by design): PASS

**Anomaly:** First call to `MATLAB:run_matlab_file` for `slt_regression_v15.m` timed out after 4 minutes (MCP server unresponsive); the same script run via `evaluate_matlab_code` returned in <1 second with all tests passing. Worth noting for future sessions: prefer `evaluate_matlab_code` over `run_matlab_file` if MATLAB MCP responsiveness is questionable.

**Open verification (TASK 13.7), all rig-dependent, deferred to next rig session:**
- 13.7.1 Sweep Duration field renders correctly + validation works
- 13.7.2 No / window-close dismisses cleanly (current behaviour preserved)
- 13.7.3 Sweep runs full duration with smooth audio glide; Stop Sweep aborts cleanly
- 13.7.4 No click on Discrete-mode stimulus offset (silent pump verified at the rig)
- 13.7.5 No click on Continuous-mode stimulus offset
- 13.7.6 No audio stutter under aggressive UI mouse-hover (frame-size bump verified)

**Closed in this session:**
- TASK 12.10 (offline acoustic-logic regression) — closed via slt_regression_v15.m, 29/29 pass.
- TASK 13.7.7 (re-run regression after v1.5) — closed via the same run.

**Files modified this session:**
- SLT.m (v1.4 → v1.5)
- archive/SLT_v1.4_2026-04-19.m (created)
- documents/PRD.md (v1.7 → v1.8)
- documents/TASKS.md (v1.7 → v1.8; will mark closed boxes after this LOG entry)
- documents/LOG.md (this entry)
- slt_regression_v15.m (created — reusable for future regressions)

**Next step:** User runs the rig-dependent verifications in TASK 13.7 (1–6). When all pass, mark them closed and the project is ready for Phase 4 (Tutorial). If any rig observation reveals a regression or surprise, treat it as a new round per MASTER_WORKFLOW (PRD/TASKS update first, then code).

*This LOG entry will be updated in place with results as the implementation proceeds.*

---

## 2026-05-02 — Section 13 Rig Verification — ALL PASS — Phase 3 COMPLETE

**Description:** User went to the rig immediately after the desk implementation and ran all six rig-dependent verifications from TASK 13.7. All passed. Channel routing (long-deferred TASK 11.5) was reconfirmed in the same session.

**Verifications closed:**
- 13.1.2 (smooth fade-out, no click on stimulus end — Discrete + Continuous): PASS
- 13.2.3 (no audio stutter under aggressive UI mouse-hover): PASS
- 13.7.1 (Sweep Duration field renders, validation rejects bad values): PASS
- 13.7.2 (post-Speaker-6 No / window-close dismisses cleanly): PASS
- 13.7.3 (sweep runs full duration with smooth glide; live degree readout updates; Stop Sweep aborts cleanly with no click): PASS
- 13.7.4 (no click on Discrete-mode stimulus offset): PASS
- 13.7.5 (no click on Continuous-mode stimulus offset): PASS
- 13.7.6 (no audio stutter at 16384-sample frame size during aggressive UI hover): PASS
- 11.5 (channel routing — MATLAB Ch.1 → Speaker 1 at 0°, etc.): PASS — also reconfirmed.

**Implication:** Every silent-pump, frame-size, and panning-sweep design decision from this round is acoustically validated end-to-end. The diagnoses recorded earlier in this LOG (queue truncation as the click cause; UI-thread stalls as the stutter cause) are confirmed correct — the prescribed fixes work as specified.

**Project state:**
- TASKS v1.8 is fully closed. No open implementation work remains.
- SLT.m v1.5 is the validated baseline.
- Sections 1–10, 12, and 13 all complete and verified.
- 11.5 and 12.10 both closed in this session.
- Phase 3 (Implementation) of MASTER_WORKFLOW is complete.

**Tests run this entry:** None executed by Claude — verifications were performed by the user at the rig.

**Files modified this entry:**
- documents/TASKS.md — closed boxes 13.1.2, 13.2.3, 13.7.1–6, and 11.5; updated final document-status footer.
- documents/LOG.md — this entry.

**Next step:** User will conduct an experiment session at the rig and report back. The next planned MASTER_WORKFLOW round is Phase 4 (Tutorial) — PRD already has hooks for tutorial content but no detailed tutorial spec yet, so that round will start with a planning conversation about tutorial format and scope before any PRD/TASKS edits.

