% =========================================================================
% SLT.m — Sound Localization Test
% =========================================================================
% A psychoacoustic experiment that plays tones or Gaussian noise from one
% of six spatially arranged speakers (or a panned virtual position) and
% measures the listener's ability to localize the sound source.
%
% Author  : Claude (Anthropic) in collaboration with project owner
% Date    : 2026-04-15
% Version : 1.3
%
% Changelog:
%   v1.3 (2026-04-15) — ASIO device support:
%     - tryOpenAudio now enumerates devices via
%       getAudioDevices(audioPlayerRecorder) instead of audiodevinfo,
%       which only sees Windows MME/DirectSound drivers. The new path
%       sees ASIO devices (e.g. "Focusrite USB ASIO") that expose all
%       hardware output channels, not just the Windows-default stereo
%       pair. ASIO devices are preferred when present; non-default
%       devices are the fallback; silent mode is the last resort.
%   v1.2 (2026-04-15) — PRD v1.4 stats display & export:
%     - drawCircularHeatmap now accepts a stats struct (accuracy, meanErr,
%       meanRT) and renders a third text line below the description
%       subtitle. Continuous mode omits the accuracy field.
%     - showResults bundles stats into a struct and passes to both
%       heatmap calls (error + RT).
%     - CSV output replaced with a manual fprintf sequence: a #-prefixed
%       header comment block (subject, date, stimulus, mode, description,
%       and summary stats) is written before the column header and trial
%       data rows. Round-trips cleanly via
%       readtable(path, 'CommentStyle', '#').
%   v1.1 (2026-04-14) — PRD v1.3 refinements:
%     - Intro & Calibration GUIs: body text rendered pure black [0 0 0]
%       for legibility (teal header + green Start button unchanged).
%     - Calibration: advance button label is dynamic — "Next Speaker" for
%       speakers 1–5, "Done" for speaker 6; "Done" click stops audio,
%       releases device, and closes the window in one unified shutdown.
%     - Experiment screen: single top instruction label (mode-specific text),
%       figure widened to 760×640 px for both modes.
%     - Discrete mode: hex speaker diagram with listener head icon and six
%       large clickable speaker buttons (70×70 px) as an equivalent to
%       keypress input. Click and keypress produce identical behaviour.
%     - Continuous mode: in-axes instruction caption removed (now in top
%       label); ring interaction unchanged.
%     - drawListenerHeadIcon extracted as shared helper used by both the
%       Discrete experiment diagram and the results heatmap.
%   v1.0 (2026-04-13) — Initial implementation.
%
% NOTE: This is the archived v1.3 baseline, captured before the Section 12
% audio streaming rewrite on 2026-04-19. The live file (SLT.m) is being
% modified to use a frame-streaming playback loop in place of the timer
% re-queue strategy in this version's playLooping. Preserved here as a
% rollback point.
% =========================================================================
