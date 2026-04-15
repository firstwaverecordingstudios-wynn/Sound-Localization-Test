% =========================================================================
% SLT.m — Sound Localization Test
% =========================================================================
% A psychoacoustic experiment that plays tones or Gaussian noise from one
% of six spatially arranged speakers (or a panned virtual position) and
% measures the listener's ability to localize the sound source.
%
% Author  : Claude (Anthropic) in collaboration with project owner
% Date    : 2026-04-15
% Version : 1.2
%
% Changelog:
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
% Folder structure:
%   Sound Localization Test/
%   ├── SLT.m
%   ├── documents/
%   ├── archive/
%   └── results/
% =========================================================================

function SLT()

% ── Global configuration constants ───────────────────────────────────────
CFG.sampleRate    = 48000;       % Hz — all 5 tone frequencies divide evenly
CFG.numChannels   = 6;           % one channel per speaker
CFG.rampMs        = 10;          % half-Hann onset/offset ramp duration (ms)
CFG.xfadeMs       = 10;          % noise crossfade duration at loop point (ms)
CFG.noiseDurSec   = 2;           % total noise buffer length before crossfade

% Speaker angles in degrees, clockwise from front (Speaker 1 = 0°)
CFG.speakerAngles = [0, 60, 120, 180, 240, 300];

% Tone frequencies (Hz) corresponding to Stimulus dropdown indices 1–5
CFG.toneFreqs     = [125, 250, 500, 750, 1000];

% Ensure results/ folder exists next to this script
scriptDir      = fileparts(mfilename('fullpath'));
CFG.resultsDir = fullfile(scriptDir, 'results');
if ~exist(CFG.resultsDir, 'dir')
    mkdir(CFG.resultsDir);
end

% Launch the Intro GUI — all further control is event-driven
launchIntroGUI(CFG);

end % SLT


% =========================================================================
%  SECTION 1 — INTRO GUI
% =========================================================================

function launchIntroGUI(CFG)
% Builds and displays the main intro window. Collects all experiment
% parameters before the session begins.

% ── Figure window ─────────────────────────────────────────────────────────
fig = uifigure('Name', 'Sound Localization Test', ...
    'Position', [200 150 520 420], ...
    'Color',    [0.84 0.92 0.97], ...   % light blue
    'Resize',   'off');

% ── Header banner ─────────────────────────────────────────────────────────
hdrPanel = uipanel(fig, ...
    'Position',        [0 370 520 50], ...
    'BackgroundColor', [0.10 0.48 0.54], ...  % teal
    'BorderType',      'none');
uilabel(hdrPanel, ...
    'Text',                'Sound Localization Test', ...
    'Position',            [0 0 520 50], ...
    'HorizontalAlignment', 'center', ...
    'FontSize',            18, 'FontWeight', 'bold', 'FontColor', [1 1 1]);

% ── Parameter input panel ─────────────────────────────────────────────────
% Body text in Intro GUI is pure black for maximum legibility against
% the white panel and pink input fields (PRD v1.3 §4 preamble).
bodyColor = [0 0 0];

inputPanel = uipanel(fig, ...
    'Position',        [20 110 480 250], ...
    'BackgroundColor', [1 1 1], ...
    'BorderType',      'line', ...
    'BorderColor',     [0.75 0.75 0.75]);

% Stimulus Selection
uilabel(inputPanel, 'Text', 'Stimulus:', ...
    'Position', [20 200 120 22], 'FontSize', 12, 'FontColor', bodyColor);
stimItems = {'125 Hz','250 Hz','500 Hz','750 Hz','1000 Hz','Gaussian Noise'};
dd_stim = uidropdown(inputPanel, ...
    'Items',           stimItems, ...
    'Position',        [150 198 200 26], ...
    'BackgroundColor', [0.98 0.84 0.84], ...
    'FontColor',       bodyColor);   % soft pink field, black text

% Number of Trials
uilabel(inputPanel, 'Text', 'Number of trials:', ...
    'Position', [20 158 130 22], 'FontSize', 12, 'FontColor', bodyColor);
ef_trials = uieditfield(inputPanel, 'numeric', ...
    'Value',           20, ...
    'Position',        [150 156 80 26], ...
    'BackgroundColor', [0.98 0.84 0.84], ...
    'FontColor',       bodyColor);

% Pause Time
uilabel(inputPanel, 'Text', 'Pause time (s):', ...
    'Position', [20 116 130 22], 'FontSize', 12, 'FontColor', bodyColor);
ef_pause = uieditfield(inputPanel, 'numeric', ...
    'Value',           2, ...
    'Position',        [150 114 80 26], ...
    'BackgroundColor', [0.98 0.84 0.84], ...
    'FontColor',       bodyColor);

% Mode Selection
uilabel(inputPanel, 'Text', 'Mode:', ...
    'Position', [20 74 120 22], 'FontSize', 12, 'FontColor', bodyColor);
dd_mode = uidropdown(inputPanel, ...
    'Items',           {'Discrete Speakers','Continuous Panning'}, ...
    'Position',        [150 72 200 26], ...
    'BackgroundColor', [0.98 0.84 0.84], ...
    'FontColor',       bodyColor);

% Description (used as figure subheader in results)
uilabel(inputPanel, 'Text', 'Description:', ...
    'Position', [20 32 120 22], 'FontSize', 12, 'FontColor', bodyColor);
ef_desc = uieditfield(inputPanel, 'text', ...
    'Value',           '', ...
    'Position',        [150 30 290 26], ...
    'BackgroundColor', [0.98 0.84 0.84], ...
    'FontColor',       bodyColor);

% ── Buttons ───────────────────────────────────────────────────────────────
uibutton(fig, ...
    'Text',            'Start', ...
    'Position',        [300 55 90 38], ...
    'FontSize',        13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.18 0.69 0.27], ...   % green
    'FontColor',       [1 1 1], ...
    'ButtonPushedFcn', @(~,~) onStartPressed());

uibutton(fig, ...
    'Text',            'Calibrate', ...
    'Position',        [130 55 90 38], ...
    'FontSize',        12, ...
    'BackgroundColor', [0.93 0.93 0.93], ...
    'FontColor',       bodyColor, ...
    'ButtonPushedFcn', @(~,~) onCalibratePressed());

% ── Callbacks ─────────────────────────────────────────────────────────────
    function onStartPressed()
        nTrials  = ef_trials.Value;
        pauseSec = ef_pause.Value;

        % Input validation
        if isnan(nTrials) || nTrials < 1 || mod(nTrials, 1) ~= 0
            uialert(fig, 'Number of trials must be a positive integer.', ...
                'Input Error');
            return;
        end
        if isnan(pauseSec) || pauseSec < 0
            uialert(fig, 'Pause time must be a positive number.', ...
                'Input Error');
            return;
        end

        % Collect parameters into a struct
        params.stimIndex   = dd_stim.ValueIndex;
        params.stimLabel   = dd_stim.Value;
        params.nTrials     = round(nTrials);
        params.pauseSec    = pauseSec;
        params.mode        = dd_mode.Value;
        params.description = ef_desc.Value;

        % Prompt for Subject ID before starting
        subjectID = getSubjectID();
        if isempty(subjectID), return; end
        params.subjectID = subjectID;

        % Build session filename: SubjectID_YYYYMMDD_HHMMSS
        now_dt             = datetime('now', 'Format', 'yyyyMMdd_HHmmss');
        params.sessionName = sprintf('%s_%s', subjectID, char(now_dt));

        close(fig);
        runExperiment(CFG, params);
    end

    function onCalibratePressed()
        calParams.stimIndex = dd_stim.ValueIndex;
        calParams.stimLabel = dd_stim.Value;
        runCalibration(CFG, calParams);
    end

uiwait(fig);
end % launchIntroGUI


% =========================================================================
%  SECTION 2 — SUBJECT ID PROMPT
% =========================================================================

function subjectID = getSubjectID()
% Modal dialog prompting for a Subject ID string.
% Returns an empty string if the user cancels or leaves the field blank.

answer = inputdlg('Enter Subject ID:', 'Subject ID', 1, {''});
if isempty(answer) || isempty(strtrim(answer{1}))
    subjectID = '';
else
    subjectID = strtrim(answer{1});
    subjectID = strrep(subjectID, ' ', '_');  % spaces → underscores
end
end % getSubjectID


% =========================================================================
%  SECTION 3 — CALIBRATION ROUTINE
% =========================================================================

function runCalibration(CFG, params)
% Cycles through speakers 1–6. For each speaker:
%   1. Displays the speaker number, channel, and angle on screen.
%   2. Plays the selected stimulus continuously through that channel.
%   3. Waits for the user to click "Next Speaker" (to adjust volume).
% Closes automatically after Speaker 6.

loopBuf = buildLoopBuffer(CFG, params.stimIndex);

% Body text in Calibration GUI is pure black for legibility (PRD v1.3 §4.2).
% Header banner text (white on teal) is unchanged.
bodyColor = [0 0 0];

% ── Calibration window ────────────────────────────────────────────────────
calFig = uifigure('Name', 'Calibration', ...
    'Position', [250 250 400 260], ...
    'Color',    [0.84 0.92 0.97], ...
    'Resize',   'off');

uipanel(calFig, 'Position', [0 210 400 50], ...
    'BackgroundColor', [0.10 0.48 0.54], 'BorderType', 'none');
uilabel(calFig, 'Text', 'Calibration', ...
    'Position', [0 210 400 50], ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 16, 'FontWeight', 'bold', 'FontColor', [1 1 1]);

lbl_speaker = uilabel(calFig, ...
    'Text',                '', ...
    'Position',            [30 130 340 50], ...
    'HorizontalAlignment', 'center', ...
    'FontSize',            18, 'FontWeight', 'bold', ...
    'FontColor',           bodyColor);

uilabel(calFig, ...
    'Text',                'Adjust volume, then click Next Speaker.', ...
    'Position',            [30 95 340 28], ...
    'HorizontalAlignment', 'center', 'FontSize', 11, ...
    'FontColor',           bodyColor);

nextDone = false;
btn_next = uibutton(calFig, ...
    'Text',            'Next Speaker', ...
    'Position',        [130 42 140 36], ...
    'FontSize',        12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.10 0.48 0.54], 'FontColor', [1 1 1], ...
    'ButtonPushedFcn', @(~,~) setDone());

    function setDone(), nextDone = true; end

[aPR, deviceOK] = tryOpenAudio(CFG);

for spk = 1:CFG.numChannels
    % Dynamic button label: "Next Speaker" for speakers 1–5; at the top of
    % the Speaker 6 iteration (before playback begins) flip it to "Done"
    % so the user sees the terminal label for the entire final tone.
    if spk < CFG.numChannels
        btn_next.Text = 'Next Speaker';
    else
        btn_next.Text = 'Done';
    end

    nextDone = false;
    lbl_speaker.Text = sprintf('Speaker %d  —  Channel %d  (%.0f°)', ...
        spk, spk, CFG.speakerAngles(spk));

    if deviceOK
        amps       = zeros(1, CFG.numChannels);
        amps(spk)  = 1.0;
        outBuf     = buildOutputBuffer(loopBuf, amps, CFG.numChannels);
        outBuf     = applyOnsetRamp(outBuf, CFG.sampleRate, CFG.rampMs);
        playLooping(aPR, outBuf, CFG.sampleRate);
    end

    while ~nextDone && isvalid(calFig)
        pause(0.05);
    end

    if deviceOK, stopAudio(aPR); end
    if ~isvalid(calFig), break; end
end

if deviceOK, release(aPR); end

% Unified shutdown path. Whether the user clicked "Done" on Speaker 6 or
% closed the window manually mid-sequence, we arrive here with audio
% already stopped (inside the loop). Close the figure if it's still open.
if isvalid(calFig)
    close(calFig);
end
end % runCalibration


% =========================================================================
%  SECTION 4 — EXPERIMENT ENGINE
% =========================================================================

function runExperiment(CFG, params)
% Main experiment loop — handles both Discrete and Continuous modes.

nTrials    = params.nTrials;
isDiscrete = strcmp(params.mode, 'Discrete Speakers');

% Pre-allocate trial record
% Columns: [trialNum, stimLocation, response, angularError, responseTime]
trialData = zeros(nTrials, 5);

% Build the loop buffer once; reuse every trial
loopBuf = buildLoopBuffer(CFG, params.stimIndex);

[aPR, deviceOK] = tryOpenAudio(CFG);

% ── Experiment window (near-black, minimal distraction) ───────────────
expFig = uifigure('Name', 'Sound Localization Test', ...
    'Position', [100 100 760 640], ...
    'Color',    [0.05 0.05 0.05], ...
    'Resize',   'off');

% Single sink for response data. Both keypress handlers and Discrete-mode
% speaker-button callbacks write here; the waitForDiscreteResponse /
% waitForRingClick poll loops read from it. Using one field prevents
% keypress-vs-click races.
expFig.UserData.response = [];

% Mode-specific top instruction (PRD v1.3 §4.3 / §4.4).
if isDiscrete
    instrText = ['Press a number 1–6 or click a speaker button ' ...
                 'to indicate where you are perceiving the sound from.'];
else
    instrText = ['Click within the ring to indicate where you are ' ...
                 'perceiving the sound from.'];
end

uilabel(expFig, ...
    'Text',                instrText, ...
    'Position',            [20 585 720 40], ...
    'HorizontalAlignment', 'center', ...
    'FontSize',            13, 'FontWeight', 'bold', ...
    'FontColor',           [1 1 1]);

lbl_trial = uilabel(expFig, ...
    'Text',                '', ...
    'Position',            [0 550 760 30], ...
    'HorizontalAlignment', 'center', ...
    'FontSize',            14, 'FontColor', [0.85 0.85 0.85]);

lbl_countdown = uilabel(expFig, ...
    'Text',                '', ...
    'Position',            [0 520 760 28], ...
    'HorizontalAlignment', 'center', ...
    'FontSize',            13, 'FontColor', [0.65 0.65 0.65]);

% Main diagram axes — unified geometry for both modes. Discrete uses
% it for the hex speaker diagram + buttons; Continuous uses it for the
% clickable response ring. 500×450 px centred in the 760-wide window.
ax = uiaxes(expFig, ...
    'Position', [130 40 500 450], ...
    'Color',    [0.05 0.05 0.05], ...
    'XColor',   'none', 'YColor', 'none');
ax.Toolbar.Visible = 'off';

if isDiscrete
    speakerBtns = buildDiscreteSpeakerDiagram(ax, expFig, CFG);  %#ok<NASGU>
else
    buildResponseRing(ax, CFG);
end

% ── Trial loop ────────────────────────────────────────────────────────────
for t = 1:nTrials
    if ~isvalid(expFig), break; end

    lbl_trial.Text     = sprintf('Trial %d of %d', t, nTrials);
    lbl_countdown.Text = '';

    % Pick a random stimulus location
    stimLoc = selectStimulusLocation(isDiscrete, CFG);

    % Compute per-channel amplitudes
    if isDiscrete
        amps          = zeros(1, CFG.numChannels);
        amps(stimLoc) = 1.0;
    else
        amps = computePanAmplitudes(stimLoc, CFG.speakerAngles);
    end

    % Build multichannel buffer and apply onset ramp
    outBuf = buildOutputBuffer(loopBuf, amps, CFG.numChannels);
    outBuf = applyOnsetRamp(outBuf, CFG.sampleRate, CFG.rampMs);

    if deviceOK, playLooping(aPR, outBuf, CFG.sampleRate); end

    tStart = tic;

    % Collect listener response
    if isDiscrete
        response = waitForDiscreteResponse(expFig);
    else
        response = waitForRingClick(ax, expFig);
    end

    responseTime = toc(tStart);

    if deviceOK, stopAudio(aPR); end

    % Convert locations to degrees for error calculation
    if isDiscrete
        stimDeg    = CFG.speakerAngles(stimLoc);
        responseDeg = CFG.speakerAngles(response);
    else
        stimDeg    = stimLoc;
        responseDeg = response;
    end

    angErr = circularAngularError(stimDeg, responseDeg);
    trialData(t,:) = [t, stimLoc, response, angErr, responseTime];

    % Inter-trial countdown
    if t < nTrials
        showCountdown(lbl_countdown, params.pauseSec, expFig);
    end
end

if deviceOK, release(aPR); end
if isvalid(expFig), close(expFig); end

showResults(CFG, params, trialData, isDiscrete);
end % runExperiment


% ─────────────────────────────────────────────────────────────────────────
function stimLoc = selectStimulusLocation(isDiscrete, CFG)
% Returns a random speaker index (1–6) for Discrete mode, or a random
% integer degree (1–360) for Continuous mode. Both are fully random with
% replacement, so the same location may appear on consecutive trials.

if isDiscrete
    stimLoc = randi(CFG.numChannels);
else
    stimLoc = randi(360);
end
end % selectStimulusLocation


% ─────────────────────────────────────────────────────────────────────────
function response = waitForDiscreteResponse(fig)
% Blocks until the listener either:
%   (a) presses a key in the range 1–6, OR
%   (b) clicks one of the six large speaker buttons on the Discrete diagram.
% Returns the integer speaker number indicated.
%
% Both input paths write to fig.UserData.response, so whichever event fires
% first wins — clicks and keypresses cannot race each other.
%
% Uses the figure's KeyPressFcn to capture keypresses without polling
% the keyboard directly, keeping CPU usage low during the wait.

fig.UserData.response = [];
fig.KeyPressFcn = @captureKey;

    function captureKey(~, evt)
        k = str2double(evt.Key);
        if ~isnan(k) && k >= 1 && k <= 6
            fig.UserData.response = k;
        end
    end

while isempty(fig.UserData.response) && isvalid(fig)
    pause(0.02);
end

if isvalid(fig)
    response = fig.UserData.response;
    fig.KeyPressFcn = '';
else
    response = 1;   % figure was closed; return a benign default
end
end % waitForDiscreteResponse


% ─────────────────────────────────────────────────────────────────────────
function response = waitForRingClick(ax, fig)
% Blocks until the listener clicks anywhere on the response ring axes.
% Converts the click (x,y) into a clock-angle degree (1–360, 0=top, CW).

response = -1;
ax.ButtonDownFcn = @captureClick;

    function captureClick(~, evt)
        cp  = evt.IntersectionPoint(1:2);
        dx  = cp(1);   % x relative to axes centre (0,0)
        dy  = cp(2);   % y relative to axes centre
        % atan2d(dx, dy) gives 0 at top, positive clockwise
        deg = mod(atan2d(dx, dy), 360);
        response = round(deg);
        if response == 0, response = 360; end
    end

while response == -1 && isvalid(fig)
    pause(0.02);
end
ax.ButtonDownFcn = '';
end % waitForRingClick


% ─────────────────────────────────────────────────────────────────────────
function buildResponseRing(ax, CFG)
% Draws the circular 0–360° response ring on ax.
% Convention: 0° = top (Speaker 1 / front), clockwise positive.
% The listener clicks the ring to indicate perceived sound direction.

hold(ax, 'on');
axis(ax, 'equal');
xlim(ax, [-1.5 1.5]);
ylim(ax, [-1.5 1.5]);

% Main ring circle
theta = linspace(0, 2*pi, 361);
plot(ax, sin(theta), cos(theta), '-', ...
    'Color', [0.5 0.7 0.9], 'LineWidth', 1.5);

% Tick marks (every 10°) and degree labels (every 30°)
for deg = 0:10:350
    rad  = deg * pi / 180;
    rIn  = 0.88;
    if mod(deg, 30) == 0, rIn = 0.82; end
    plot(ax, [rIn*sin(rad), sin(rad)], [rIn*cos(rad), cos(rad)], ...
        '-', 'Color', [0.50 0.50 0.50], 'LineWidth', 0.8);
    if mod(deg, 30) == 0
        text(ax, 1.15*sin(rad), 1.15*cos(rad), sprintf('%d°', deg), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontSize', 8, 'Color', [0.65 0.65 0.65]);
    end
end

% Speaker position labels
for s = 1:CFG.numChannels
    rad = CFG.speakerAngles(s) * pi / 180;
    text(ax, 1.38*sin(rad), 1.38*cos(rad), sprintf('Spk %d', s), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.85 0.85 0.85]);
end

% Centre crosshair
plot(ax, 0, 0, '+', 'Color', [0.7 0.7 0.7], 'MarkerSize', 8, 'LineWidth', 1);

% Instruction text now lives in the top label of the experiment figure
% (see runExperiment) so that Discrete and Continuous modes share a
% single consistent instruction surface.

hold(ax, 'off');
end % buildResponseRing


% ─────────────────────────────────────────────────────────────────────────
function showCountdown(lbl, pauseSec, fig)
% Displays a live "Next trial in X.X s" countdown in lbl.

tEnd = tic;
while toc(tEnd) < pauseSec && isvalid(fig)
    lbl.Text = sprintf('Next trial in  %.1f s', pauseSec - toc(tEnd));
    pause(0.05);
end
if isvalid(fig), lbl.Text = ''; end
end % showCountdown


% ─────────────────────────────────────────────────────────────────────────
function err = circularAngularError(stimDeg, responseDeg)
% Returns the minimum absolute angular difference (0–180°) between two
% degree values, correctly accounting for the circular wraparound at 360°.
%
% Example: error between 10° and 350° = 20° (not 340°).

err = abs(mod(stimDeg - responseDeg + 180, 360) - 180);
end % circularAngularError


% =========================================================================
%  SECTION 5 — AUDIO ENGINE
% =========================================================================

function buf = buildLoopBuffer(CFG, stimIndex)
% Dispatcher that builds the correct seamless loop buffer for the selected
% stimulus type. Indices 1–5 = pure tones; index 6 = Gaussian noise.

if stimIndex <= 5
    buf = buildToneBuffer(CFG.toneFreqs(stimIndex), CFG.sampleRate);
else
    buf = buildNoiseBuffer(CFG.sampleRate, CFG.noiseDurSec, CFG.xfadeMs);
end
end % buildLoopBuffer


% ─────────────────────────────────────────────────────────────────────────
function buf = buildToneBuffer(frequency, sampleRate)
% Constructs a seamless integer-cycle sine wave loop buffer.
%
% ACOUSTIC RATIONALE: Looping an arbitrarily-length sine buffer produces
% a discontinuity at the loop point (click) or, if Hann-windowed on every
% cycle, a rhythmic amplitude pulse at the loop rate — both audible and
% distracting. The fix is to make the buffer exactly one complete cycle
% long. At this length the waveform value AND its slope at the last sample
% equal those at the first sample, so the loop splice is perfectly seamless.
%
% All five specified frequencies (125, 250, 500, 750, 1000 Hz) divide
% evenly into 48000 Hz, guaranteeing N is always an integer.
%
% The Hann window is NOT applied here — it is applied once at stimulus
% onset and once at offset only (see applyOnsetRamp / applyOffsetRamp).

N   = sampleRate / frequency;       % exact integer: samples per cycle
t   = (0:N-1)' / sampleRate;        % time vector for exactly one period
buf = sin(2 * pi * frequency * t);  % unit-amplitude sine wave
end % buildToneBuffer


% ─────────────────────────────────────────────────────────────────────────
function buf = buildNoiseBuffer(sampleRate, durationSec, xfadeMs)
% Constructs a Gaussian noise buffer with an equal-power crossfade loop.
%
% ACOUSTIC RATIONALE: Noise has no periodic structure, so integer-cycle
% alignment is impossible. Instead, we stitch the tail of the buffer into
% the head using complementary half-cosine amplitude ramps. Because the
% ramps satisfy cos²(θ) + sin²(θ) = 1 at every sample, total power is
% constant across the crossfade — the loop is inaudible.

N       = round(durationSec * sampleRate);
xN      = round(xfadeMs / 1000 * sampleRate);  % crossfade length (samples)
raw     = randn(N, 1);

% Equal-power crossfade ramps (each spans 0 → π/2)
fade_out = cos(linspace(0, pi/2, xN))';   % 1 → 0  (tail fades out)
fade_in  = sin(linspace(0, pi/2, xN))';   % 0 → 1  (head fades in)

% Blend the tail region with the beginning of the buffer
raw(end-xN+1:end) = raw(end-xN+1:end) .* fade_out + ...
                    raw(1:xN)          .* fade_in;

% Trim the now-redundant head samples (already baked into the tail)
buf = raw(1:end-xN);

% Normalise to unit peak so noise matches tone amplitude
buf = buf / max(abs(buf));
end % buildNoiseBuffer


% ─────────────────────────────────────────────────────────────────────────
function buf = applyOnsetRamp(buf, sampleRate, rampMs)
% Applies a rising half-Hann envelope to the first rampMs ms of each
% channel column of buf (amplitude: 0 → 1).
%
% ACOUSTIC RATIONALE: Even with a seamless loop buffer, the very first
% playback onset may start at a non-zero sample value, causing a click.
% A 10 ms half-Hann ramp eliminates this while being too brief to cause
% perceivable amplitude modulation (auditory system integrates over ~20 ms).

rampN = min(round(rampMs / 1000 * sampleRate), size(buf, 1));
ramp  = hann(rampN * 2);              % full symmetric Hann window
ramp  = ramp(1:rampN);               % rising half only (0 → 1)
buf(1:rampN, :) = buf(1:rampN, :) .* repmat(ramp, 1, size(buf, 2));
end % applyOnsetRamp


% ─────────────────────────────────────────────────────────────────────────
function buf = applyOffsetRamp(buf, sampleRate, rampMs)
% Applies a falling half-Hann envelope to the last rampMs ms of each
% channel column of buf (amplitude: 1 → 0).

rampN = min(round(rampMs / 1000 * sampleRate), size(buf, 1));
ramp  = hann(rampN * 2);
ramp  = ramp(rampN+1:end);           % falling half only (1 → 0)
n     = size(buf, 1);
buf(n-rampN+1:n, :) = buf(n-rampN+1:n, :) .* repmat(ramp, 1, size(buf, 2));
end % applyOffsetRamp


% ─────────────────────────────────────────────────────────────────────────
function outBuf = buildOutputBuffer(monoBuf, channelAmplitudes, ~)
% Distributes a mono audio signal across numChannels output channels by
% scaling each channel by its assigned amplitude coefficient.
%
% ACOUSTIC RATIONALE: All spatial cues in this system are delivered via
% interaural/interchannel level differences (ILD). The amplitude vector
% produced by computePanAmplitudes (or the discrete 0/1 selection) fully
% encodes the intended spatial position for each trial.

outBuf = monoBuf * channelAmplitudes;   % [N×1] * [1×6] → [N×6]
end % buildOutputBuffer


% ─────────────────────────────────────────────────────────────────────────
function amps = computePanAmplitudes(degree, speakerAngles)
% Computes a 6-element channel amplitude vector for a given degree using
% the constant-power sine panning law.
%
% ACOUSTIC RATIONALE: The sine law (cos/sin pair) ensures that the total
% reproduced power is constant as the virtual source moves between
% speakers (cos²θ + sin²θ = 1). Without this, sources panned to the
% midpoint between two speakers would sound quieter than those at speaker
% positions — a loudness artifact that would influence localization.
%
% The 360° space is split into six 60° sectors. Within each sector, the
% pan angle θ ∈ [0, π/2] determines the amplitude split:
%   θ = 0   → all power from the sector's counterclockwise speaker
%   θ = π/4 → equal power (−3 dB) from both speakers
%   θ = π/2 → all power from the sector's clockwise speaker

amps      = zeros(1, length(speakerAngles));
numSpk    = length(speakerAngles);
degree    = mod(degree, 360);              % normalise to [0, 360)

sectorIdx   = floor(degree / 60) + 1;     % which of the 6 sectors (1–6)
spkA        = sectorIdx;                   % counterclockwise bounding speaker
spkB        = mod(sectorIdx, numSpk) + 1; % clockwise bounding speaker

sectorStart = (sectorIdx - 1) * 60;
theta       = (degree - sectorStart) / 60 * (pi / 2);

amps(spkA)  = cos(theta);
amps(spkB)  = sin(theta);
end % computePanAmplitudes


% ─────────────────────────────────────────────────────────────────────────
function [aPR, deviceOK] = tryOpenAudio(CFG)
% Attempts to open a multi-channel audio output device via
% audioPlayerRecorder. If no suitable device is found, returns
% deviceOK = false so the experiment can run in silent (UI-test) mode.

deviceOK = false;
aPR      = [];

try
    info = audiodevinfo;
    if isempty(info.output)
        warning('SLT:noAudio', ...
            'No audio output device found — running in silent mode.');
        return;
    end

    % Find first output device with at least 6 channels
    devID = -1;
    for i = 1:length(info.output)
        if info.output(i).MaxOutputChannels >= CFG.numChannels
            devID = info.output(i).ID;
            break;
        end
    end

    if devID < 0
        warning('SLT:noAudio', ...
            'No %d-channel output device found — running in silent mode.', ...
            CFG.numChannels);
        return;
    end

    devName = audiodevinfo(0, devID, 'Name');
    aPR = audioPlayerRecorder( ...
        'SampleRate',          CFG.sampleRate, ...
        'Device',              devName, ...
        'PlayerChannelMapping', 1:CFG.numChannels);
    deviceOK = true;

catch ME
    warning('SLT:noAudio', 'Audio init failed: %s', ME.message);
end
end % tryOpenAudio


% ─────────────────────────────────────────────────────────────────────────
function playLooping(aPR, buffer, sampleRate)
% Starts continuous looped playback of buffer on the audio device.
%
% audioPlayerRecorder does not natively loop, so we pre-fill its internal
% queue with several copies of the buffer and then use a MATLAB timer to
% re-queue the buffer at regular intervals, keeping the queue full and
% playback continuous until stopAudio() is called.

% Pre-fill the queue to minimise onset latency
for k = 1:4
    aPR(buffer);
end

% Re-queue at half the buffer duration to stay ahead of playback
period = max(0.05, size(buffer, 1) / sampleRate * 0.5);
t = timer('ExecutionMode', 'fixedRate', ...
          'Period',        period, ...
          'TimerFcn',      @(~,~) requeue(aPR, buffer));
start(t);
assignin('base', 'SLT_loopTimer', t);   % store for retrieval by stopAudio

    function requeue(dev, buf)
        try
            dev(buf);   % push another copy into the queue
        catch
            % Device may have been released — timer will be stopped shortly
        end
    end
end % playLooping


% ─────────────────────────────────────────────────────────────────────────
function stopAudio(aPR)
% Halts looped playback: stops and deletes the background timer, then
% resets the audioPlayerRecorder so it is ready for the next trial.

if evalin('base', "exist('SLT_loopTimer','var')")
    t = evalin('base', 'SLT_loopTimer');
    try
        stop(t);
    catch
    end
    try
        delete(t);
    catch
    end
    evalin('base', "clear SLT_loopTimer");
end

try
    reset(aPR);
catch
end
end % stopAudio


% =========================================================================
%  SECTION 6 — RESULTS
% =========================================================================

function showResults(CFG, params, trialData, isDiscrete)
% Computes summary statistics, generates both circular heatmaps, saves
% all output files to results/, and displays a results summary window.

% trialData columns: [trialNum, stimLoc, response, angErr, respTime]
angErrors = trialData(:, 4);
respTimes = trialData(:, 5);
meanErr   = mean(angErrors);
meanRT    = mean(respTimes);

if isDiscrete
    accuracy = 100 * mean(trialData(:,2) == trialData(:,3));
else
    accuracy = NaN;
end

% Bundle into a stats struct so drawCircularHeatmap can render the third
% subtitle line and the CSV header block below can pull from one source.
% Continuous mode passes accuracy = NaN; the heatmap and CSV writer both
% interpret NaN as "omit this field" rather than printing it.
stats.accuracy = accuracy;
stats.meanErr  = meanErr;
stats.meanRT   = meanRT;

% ── Per-location aggregates for heatmaps ─────────────────────────────────
if isDiscrete
    % Accumulate by speaker index (1–6)
    nBins     = 6;
    errPerBin = accumarray(trialData(:,2), angErrors, [nBins 1], @mean, NaN);
    rtPerBin  = accumarray(trialData(:,2), respTimes, [nBins 1], @mean, NaN);
else
    % Accumulate by 10° bin (bin 1 = 1°–10°, ..., bin 36 = 351°–360°)
    nBins  = 36;
    binIdx = min(max(ceil(mod(trialData(:,2)-1, 360) / 10) + 1, 1), 36);
    errPerBin = accumarray(binIdx, angErrors, [nBins 1], @mean, NaN);
    rtPerBin  = accumarray(binIdx, respTimes, [nBins 1], @mean, NaN);
end

% ── Generate and save heatmaps ────────────────────────────────────────────
sessionPath = fullfile(CFG.resultsDir, params.sessionName);

fig_err = drawCircularHeatmap(errPerBin, isDiscrete, 'Angular Error (°)', ...
    params.description, CFG, params.stimLabel, stats);
saveas(fig_err, [sessionPath '_heatmap_error.png']);

fig_rt = drawCircularHeatmap(rtPerBin, isDiscrete, 'Response Time (s)', ...
    params.description, CFG, params.stimLabel, stats);
saveas(fig_rt, [sessionPath '_heatmap_RT.png']);

% ── Save CSV ──────────────────────────────────────────────────────────────
% PRD v1.4 §6.3 — the per-trial CSV is preceded by a #-prefixed header
% block carrying session metadata and summary stats. The # prefix is the
% conventional CSV comment marker: Excel tolerates the lines (they appear
% in column A as malformed rows but do not interfere with the data table)
% and MATLAB's readtable(…, 'CommentStyle', '#') skips them cleanly so
% the data round-trips without preprocessing.
%
% writetable cannot prepend comment lines, so we open the file directly
% with fopen and write everything via fprintf in one pass.

csvPath = [sessionPath '.csv'];
fid = fopen(csvPath, 'w');
if fid == -1
    warning('SLT:csvOpen', 'Could not open %s for writing.', csvPath);
else
    % --- Header comment block ------------------------------------------
    fprintf(fid, '# Sound Localization Test - Session Results\n');
    fprintf(fid, '# Subject: %s\n', params.subjectID);
    fprintf(fid, '# Date: %s\n', char(datetime('now', ...
        'Format', 'yyyy-MM-dd HH:mm:ss')));
    fprintf(fid, '# Stimulus: %s\n', params.stimLabel);
    fprintf(fid, '# Mode: %s\n', params.mode);
    fprintf(fid, '# Description: %s\n', params.description);
    if isDiscrete
        % Accuracy is undefined for Continuous (no "correct" speaker for
        % a panned virtual position), so the line is omitted entirely
        % rather than printed as NaN — keeps the header clean.
        fprintf(fid, '# Accuracy: %.1f%%\n', stats.accuracy);
    end
    fprintf(fid, '# Mean Angular Error: %.1f deg\n', stats.meanErr);
    fprintf(fid, '# Mean Response Time: %.2f s\n', stats.meanRT);

    % --- Column header + data rows -------------------------------------
    fprintf(fid, ['TrialNumber,StimulusLocation,Response,' ...
                  'AngularError_deg,ResponseTime_s\n']);
    for r = 1:size(trialData, 1)
        % Columns: trialNum, stimLoc, response, angErr, respTime
        fprintf(fid, '%d,%d,%d,%.4f,%.4f\n', ...
            trialData(r,1), trialData(r,2), trialData(r,3), ...
            trialData(r,4), trialData(r,5));
    end
    fclose(fid);
end

% ── Results summary window ────────────────────────────────────────────────
resFig = uifigure('Name', 'Results', ...
    'Position', [80 80 860 560], ...
    'Color',    [0.95 0.97 1.0]);

uipanel(resFig, 'Position', [0 510 860 50], ...
    'BackgroundColor', [0.10 0.48 0.54], 'BorderType', 'none');
uilabel(resFig, 'Text', 'Session Results', ...
    'Position', [0 510 860 50], ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 16, 'FontWeight', 'bold', 'FontColor', [1 1 1]);

if isDiscrete
    statsStr = sprintf( ...
        'Accuracy: %.1f%%    Mean Angular Error: %.1f°    Mean Response Time: %.2f s', ...
        accuracy, meanErr, meanRT);
else
    statsStr = sprintf( ...
        'Mean Angular Error: %.1f°    Mean Response Time: %.2f s', ...
        meanErr, meanRT);
end
uilabel(resFig, 'Text', statsStr, ...
    'Position', [20 468 820 32], ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 11, 'FontColor', [0.15 0.15 0.15]);

% Show heatmap images side by side
errImg = [sessionPath '_heatmap_error.png'];
rtImg  = [sessionPath '_heatmap_RT.png'];
if exist(errImg, 'file'), uiimage(resFig, 'ImageSource', errImg, 'Position', [20  60 400 390]); end
if exist(rtImg,  'file'), uiimage(resFig, 'ImageSource', rtImg,  'Position', [440 60 400 390]); end

uilabel(resFig, ...
    'Text',                sprintf('Results saved to: %s', params.sessionName), ...
    'Position',            [20 20 820 28], ...
    'HorizontalAlignment', 'center', ...
    'FontSize',            9, 'FontColor', [0.5 0.5 0.5]);

end % showResults


% ─────────────────────────────────────────────────────────────────────────
function fig = drawCircularHeatmap(values, isDiscrete, metricLabel, ...
                                    description, CFG, stimLabel, stats)
% Renders a circular heatmap using the conventions defined in the PRD:
%
%   Discrete mode   — 6 solid 60° wedges, each centered on its speaker
%                     angle (0°, 60°, ... 300°), value printed inside.
%   Continuous mode — 36 × 10° wedges, centered on 0°, 10°, ... 350°.
%
%   Both modes: listener head at center (nose → 0°/front), speaker labels
%   and intermediate 30° degree ticks around the outside, green→yellow→red
%   color scale legend at the bottom.
%
%   The stats struct carries .accuracy (NaN for Continuous, omitted from
%   the subtitle line when so), .meanErr, and .meanRT. These are rendered
%   as a third text line below the description subtitle (PRD v1.4 §6.2).

fig = figure('Color', [1 1 1], 'Position', [100 100 600 700], 'Visible', 'off');
ax  = axes(fig, 'Position', [0.05 0.10 0.90 0.78]);
hold(ax, 'on');
axis(ax, 'equal', 'off');

% ── Color scale: green → yellow → red ─────────────────────────────────────
validVals = values(~isnan(values));
vMin = 0; vMax = 1;
if ~isempty(validVals)
    vMin = min(validVals);
    vMax = max(validVals);
    if vMin == vMax, vMax = vMin + 1; end
end

    function c = val2color(v)
        if isnan(v)
            c = [0.85 0.85 0.85]; return;
        end
        u      = max(0, min(1, (v - vMin) / (vMax - vMin)));
        green  = [0.298 0.686 0.314];
        yellow = [0.804 0.863 0.224];
        red    = [0.957 0.263 0.212];
        if u < 0.5
            c = green  + (u / 0.5)       * (yellow - green);
        else
            c = yellow + ((u-0.5) / 0.5) * (red    - yellow);
        end
    end

% ── Wedges ────────────────────────────────────────────────────────────────
R = 1.0;

if isDiscrete
    for s = 1:6
        cDeg = CFG.speakerAngles(s);
        fillWedge(ax, 0, 0, R, cDeg-30, cDeg+30, val2color(values(s)));
        if ~isnan(values(s))
            text(ax, 0.62*sin(cDeg*pi/180), 0.62*cos(cDeg*pi/180), ...
                sprintf('%.1f', values(s)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontSize', 10, 'FontWeight', 'bold', 'Color', [1 1 1]);
        end
    end
else
    for b = 1:36
        cDeg = (b-1) * 10;
        fillWedge(ax, 0, 0, R, cDeg-5, cDeg+5, val2color(values(b)));
    end
end

% Outer ring border
theta = linspace(0, 2*pi, 361);
plot(ax, R*sin(theta), R*cos(theta), 'k-', 'LineWidth', 0.8);

% ── Listener head (top-down schematic) ────────────────────────────────────
ri = 0.32;                                           % clear zone radius
hT = linspace(0, 2*pi, 61);

% Clear inner zone so the head icon sits on a white disc rather than on
% the coloured wedges behind it.
fill(ax, ri*cos(hT), ri*sin(hT), [1 1 1], ...
    'EdgeColor', [0.75 0.75 0.75], 'LineWidth', 0.5);

% Listener head (shared with the Discrete experiment diagram so both
% views have matching orientation cues). Nose points toward 0°.
drawListenerHeadIcon(ax);

% ── Labels and tick marks ─────────────────────────────────────────────────
rLab  = 1.22;
rTkI  = 1.01;
rTkO  = 1.08;

for deg = 0:10:350
    rad       = deg * pi / 180;
    isSpk     = any(deg == CFG.speakerAngles);

    if isSpk
        % Speaker label: bold, number · degree
        spkNum = find(CFG.speakerAngles == deg, 1);
        lx     = rLab * sin(rad);
        ly     = rLab * cos(rad);
        ha     = 'center';
        if sin(rad) >  0.3, ha = 'left';  end
        if sin(rad) < -0.3, ha = 'right'; end
        text(ax, lx, ly, sprintf('%d  ·  %d°', spkNum, deg), ...
            'HorizontalAlignment', ha, 'VerticalAlignment', 'middle', ...
            'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.15 0.15 0.15]);

    elseif mod(deg, 30) == 0
        % Intermediate 30° tick + small label
        plot(ax, [rTkI*sin(rad) rTkO*sin(rad)], ...
                 [rTkI*cos(rad) rTkO*cos(rad)], ...
            '-', 'Color', [0.55 0.55 0.55], 'LineWidth', 0.8);
        lx = 1.16 * sin(rad);
        ly = 1.16 * cos(rad);
        ha = 'center';
        if sin(rad) >  0.3, ha = 'left';  end
        if sin(rad) < -0.3, ha = 'right'; end
        text(ax, lx, ly, sprintf('%d°', deg), ...
            'HorizontalAlignment', ha, 'VerticalAlignment', 'middle', ...
            'FontSize', 7.5, 'Color', [0.50 0.50 0.50]);

    else
        % Minor 10° tick only
        plot(ax, [rTkI*sin(rad) 1.05*sin(rad)], ...
                 [rTkI*cos(rad) 1.05*cos(rad)], ...
            '-', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.5);
    end
end

% ── Color scale legend (gradient bar) ─────────────────────────────────────
nSw = 64;
sX  = linspace(-0.45, 0.45, nSw+1);
y1  = -1.42; y2 = -1.32;
for i = 1:nSw
    u  = (i-1) / (nSw-1);
    fc = val2color(vMin + u*(vMax-vMin));
    fill(ax, [sX(i) sX(i+1) sX(i+1) sX(i)], [y1 y1 y2 y2], ...
        fc, 'EdgeColor', 'none');
end
rectangle('Parent', ax, 'Position', [-0.45 y1 0.90 0.10], ...
    'EdgeColor', [0.65 0.65 0.65], 'LineWidth', 0.6);

text(ax, -0.45, y1-0.06, sprintf('%.1f', vMin), ...
    'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', [0.35 0.35 0.35]);
text(ax,  0.00, y1-0.06, sprintf('%.1f', (vMin+vMax)/2), ...
    'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', [0.35 0.35 0.35]);
text(ax,  0.45, y1-0.06, sprintf('%.1f', vMax), ...
    'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', [0.35 0.35 0.35]);

% ── Title and description subheader ───────────────────────────────────────
modeStr  = 'Discrete Speakers';
if ~isDiscrete, modeStr = 'Continuous Panning'; end

title(ax, sprintf('%s — %s  (%s)', metricLabel, modeStr, stimLabel), ...
    'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.10 0.10 0.10]);

% Stats subtitle line (PRD v1.4 §6.2) — third text line below the
% description subtitle. Smaller and lighter than the description so the
% visual hierarchy is title > description > stats. Continuous mode
% omits accuracy (no "correct" speaker for a panned virtual position).
if isDiscrete && ~isnan(stats.accuracy)
    statsStr = sprintf( ...
        'Accuracy: %.1f%%   Mean Angular Error: %.1f°   Mean Response Time: %.2f s', ...
        stats.accuracy, stats.meanErr, stats.meanRT);
else
    statsStr = sprintf( ...
        'Mean Angular Error: %.1f°   Mean Response Time: %.2f s', ...
        stats.meanErr, stats.meanRT);
end
% MATLAB's subtitle() is anchored to the axes title and accepts cell-array
% input to render multiple lines. We pass {description; statsStr} so the
% stats sit directly below the description, preserving the intended
% visual hierarchy (title > description > stats).
if ~isempty(description)
    subtitle(ax, {description; statsStr}, ...
        'FontSize', 9, 'Color', [0.40 0.40 0.40]);
else
    subtitle(ax, statsStr, ...
        'FontSize', 9, 'Color', [0.45 0.45 0.45]);
end

xlim(ax, [-1.55 1.55]);
ylim(ax, [-1.60 1.55]);

fig.Visible = 'on';
end % drawCircularHeatmap


% ─────────────────────────────────────────────────────────────────────────
function fillWedge(ax, cx, cy, R, a1Deg, a2Deg, faceColor)
% Draws a filled pie-wedge on ax.
% Convention: angles are clock-degrees (0 = top, clockwise positive).
% The wedge vertex is at (cx, cy); the arc is at radius R.

nPts   = max(4, round(abs(a2Deg - a1Deg)));
angles = linspace(a1Deg, a2Deg, nPts) * pi / 180;
px     = [cx,  cx + R*sin(angles),  cx];
py     = [cy,  cy + R*cos(angles),  cy];
fill(ax, px, py, faceColor, 'EdgeColor', [1 1 1], 'LineWidth', 1.0);
end % fillWedge


% ────────────────────────────────────────────────────────────────────────
function drawListenerHeadIcon(ax)
% Draws a top-down schematic of a listener's head centred at (0,0) on ax.
% Used by both the results heatmap and the Discrete-mode experiment
% diagram so the subject sees a consistent orientation reference.
%
% Geometry conventions (axes data units, outer ring at R = 1.0):
%   Head radius           : 0.15
%   Eyes                  : two small dark discs slightly forward of centre
%   Ears                  : two flattened ovals on the sides
%   Nose                  : small triangle pointing UP toward 0° (Speaker 1)
%
% Note: In this figure 0° is the +y direction (top), so "forward" for the
% listener is +y. Eye/ear/nose positions are expressed in that frame.

% Head circle
hT = linspace(0, 2*pi, 61);
hR = 0.15;
fill(ax, hR*cos(hT), hR*sin(hT), [0.92 0.92 0.92], ...
    'EdgeColor', [0.35 0.35 0.35], 'LineWidth', 1.0);

% Eyes (small dark discs, slightly forward of head centre)
eT = linspace(0, 2*pi, 21);
eR = 0.022;
fill(ax, -0.055+eR*cos(eT),  0.065+eR*sin(eT), [0.25 0.25 0.25], 'EdgeColor', 'none');
fill(ax,  0.055+eR*cos(eT),  0.065+eR*sin(eT), [0.25 0.25 0.25], 'EdgeColor', 'none');

% Ears (flattened ovals on left/right)
eaT = linspace(0, 2*pi, 21); eaW = 0.030; eaH = 0.048;
fill(ax, -0.170+eaW*cos(eaT), 0.025+eaH*sin(eaT), [0.92 0.92 0.92], ...
    'EdgeColor', [0.35 0.35 0.35], 'LineWidth', 0.7);
fill(ax,  0.170+eaW*cos(eaT), 0.025+eaH*sin(eaT), [0.92 0.92 0.92], ...
    'EdgeColor', [0.35 0.35 0.35], 'LineWidth', 0.7);

% Nose triangle — points upward toward 0° (Speaker 1 / front)
fill(ax, [-0.03  0.03  0.00 -0.03], [0.115 0.115 0.175 0.115], ...
    [0.35 0.35 0.35], 'EdgeColor', 'none');
end % drawListenerHeadIcon


% ────────────────────────────────────────────────────────────────────────
function btns = buildDiscreteSpeakerDiagram(ax, fig, CFG)
% Builds the Discrete-mode experiment diagram: outer hex circle, six
% sector divider lines, centred listener head icon, and six LARGE
% clickable speaker buttons placed around the outside of the circle.
%
% Returns the 1×6 vector of button handles (so callers can keep them
% alive / inspect them; currently unused downstream but useful for tests).
%
% Geometry:
%   Outer ring radius (axes data units) : R = 1.0
%   Button placement radius             : rBtn = 1.15 (clear of ring)
%   Button size (pixels)                : 70 × 70 (PRD v1.3 §4.3 — the
%                                         buttons are the primary target,
%                                         so noticeably larger than the
%                                         markers on the Continuous ring)
%
% Buttons cannot be children of a uiaxes in MATLAB, so each button is
% parented to the figure and positioned in figure-pixel coordinates
% using a small axes-data → figure-pixel mapper. The caller is expected
% to leave the axes size fixed after this function returns (expFig is
% already set to Resize='off', so this is safe).

hold(ax, 'on');
axis(ax, 'equal');
xlim(ax, [-1.5 1.5]);
ylim(ax, [-1.5 1.5]);

% Outer ring
R     = 1.0;
theta = linspace(0, 2*pi, 361);
plot(ax, R*sin(theta), R*cos(theta), '-', ...
    'Color', [0.5 0.7 0.9], 'LineWidth', 1.5);

% Six sector divider lines (radial), drawn at 30°, 90°, 150°, 210°, 270°,
% 330° — the boundaries BETWEEN speakers. This makes the hex geometry
% visually obvious and matches the sector scheme used by the panning law.
for dividerDeg = 30:60:330
    rad = dividerDeg * pi / 180;
    plot(ax, [0 R*sin(rad)], [0 R*cos(rad)], ...
        '-', 'Color', [0.25 0.35 0.45], 'LineWidth', 0.8);
end

% Listener head at centre
drawListenerHeadIcon(ax);

hold(ax, 'off');

% ── Place six large clickable speaker buttons ───────────────────────────
% Compute the axes' figure-pixel extents once, then map each speaker's
% axes-data coordinate (rBtn*sin(rad), rBtn*cos(rad)) to figure pixels.
axPos   = ax.Position;                   % [x y w h] in figure pixels
xLim    = ax.XLim;  yLim = ax.YLim;
xScale  = axPos(3) / (xLim(2) - xLim(1));
yScale  = axPos(4) / (yLim(2) - yLim(1));
axData2FigPx = @(dx,dy) [ ...
    axPos(1) + (dx - xLim(1)) * xScale, ...
    axPos(2) + (dy - yLim(1)) * yScale ];

rBtn   = 1.15;
btnSz  = 70;      % px, square
btns   = gobjects(1, CFG.numChannels);

for s = 1:CFG.numChannels
    rad     = CFG.speakerAngles(s) * pi / 180;
    centrePx = axData2FigPx(rBtn*sin(rad), rBtn*cos(rad));
    btnPos  = [centrePx(1)-btnSz/2, centrePx(2)-btnSz/2, btnSz, btnSz];

    btns(s) = uibutton(fig, ...
        'Text',            sprintf('%d', s), ...
        'Position',        btnPos, ...
        'FontSize',        24, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.18 0.25 0.32], ...   % dark slate
        'FontColor',       [1 1 1], ...
        'ButtonPushedFcn', makeBtnCallback(fig, s));
end
end % buildDiscreteSpeakerDiagram


% ────────────────────────────────────────────────────────────────────────
function cb = makeBtnCallback(fig, speakerIdx)
% Helper factory that closes over speakerIdx — needed because MATLAB
% anonymous functions in a loop would otherwise all capture the final
% value of the loop variable.
cb = @(~,~) assignResponse(fig, speakerIdx);
end % makeBtnCallback

function assignResponse(fig, val)
if isvalid(fig)
    fig.UserData.response = val;
end
end % assignResponse
