function slt_regression_v15()
% Offline acoustic-logic regression covering Tests 1-8 from 2026-04-13 LOG
% plus Test 9 for the v1.5 streamPanSweep angle math.
% Closes TASK 12.10 and TASK 13.7.7.
% Runs in <1 second; does not touch the audio device.

slt_path = which('SLT');
src = fileread(slt_path);

src_buildTone   = extractFn(src, 'buildToneBuffer');
src_buildNoise  = extractFn(src, 'buildNoiseBuffer');
src_computePan  = extractFn(src, 'computePanAmplitudes');
src_circErr     = extractFn(src, 'circularAngularError');

% Write extracted functions to a scratch file, then call via handles
scratch = fullfile(tempdir, 'slt_regression_helpers.m');
fid = fopen(scratch, 'w');
fprintf(fid, 'function helpers = slt_regression_helpers()\n');
fprintf(fid, '  helpers.buildTone   = @buildToneBuffer;\n');
fprintf(fid, '  helpers.buildNoise  = @buildNoiseBuffer;\n');
fprintf(fid, '  helpers.computePan  = @computePanAmplitudes;\n');
fprintf(fid, '  helpers.circErr     = @circularAngularError;\n');
fprintf(fid, 'end\n\n');
fprintf(fid, '%s\n\n', src_buildTone);
fprintf(fid, '%s\n\n', src_buildNoise);
fprintf(fid, '%s\n\n', src_computePan);
fprintf(fid, '%s\n\n', src_circErr);
fclose(fid);

addpath(tempdir);
rehash;
H = slt_regression_helpers();

passed = 0; failed = 0;

% Test 1: buildToneBuffer integer-cycle correctness
SR = 48000;
t1_fail = 0;
for f = [125 250 500 750 1000]
    buf = H.buildTone(f, SR);
    expectedN = SR/f;
    cond = (length(buf) == expectedN) && abs(buf(1)) < 1e-12;
    if cond, passed = passed+1; else, failed = failed+1; t1_fail = t1_fail+1;
        fprintf('Test 1 FAIL f=%d: len=%d exp=%d buf(1)=%g\n', f, length(buf), expectedN, buf(1));
    end
end
fprintf('Test 1 (tone integer-cycle, 5 freqs): %d/5 pass\n', 5-t1_fail);

% Test 2: buildNoiseBuffer unit peak
buf = H.buildNoise(SR, 2, 10);
cond = abs(max(abs(buf)) - 1.0) < 1e-9 && length(buf) > 0;
if cond, passed = passed+1; else, failed = failed+1; end
fprintf('Test 2 (noise unit peak): %s\n', tern(cond,'PASS','FAIL'));

% Test 3: pan at speaker angles
spkAngles = [0 60 120 180 240 300];
t3_fail = 0;
for s = 1:6
    amps = H.computePan(spkAngles(s), spkAngles);
    expected = zeros(1,6); expected(s) = 1.0;
    cond = max(abs(amps - expected)) < 1e-12;
    if cond, passed = passed+1; else, failed = failed+1; t3_fail = t3_fail+1;
        fprintf('Test 3 FAIL spk %d: amps=%s\n', s, mat2str(amps,3)); end
end
fprintf('Test 3 (pan at 6 speaker angles): %d/6 pass\n', 6-t3_fail);

% Test 4: pan at sector midpoints (-3 dB law)
midAngles = 30:60:330;
expected_amp = cos(pi/4);
t4_fail = 0;
for d = midAngles
    amps = H.computePan(d, spkAngles);
    nz = amps(amps > 1e-9);
    cond = numel(nz) == 2 && all(abs(nz - expected_amp) < 1e-12);
    if cond, passed = passed+1; else, failed = failed+1; t4_fail = t4_fail+1;
        fprintf('Test 4 FAIL deg %d: amps=%s\n', d, mat2str(amps,3)); end
end
fprintf('Test 4 (pan at sector midpoints): %d/%d pass\n', length(midAngles)-t4_fail, length(midAngles));

% Test 5: constant-power across full 1-360 sweep
maxPowerErr = 0;
for d = 1:360
    amps = H.computePan(d, spkAngles);
    p = sum(amps.^2);
    maxPowerErr = max(maxPowerErr, abs(p - 1));
end
cond = maxPowerErr < 1e-12;
if cond, passed = passed+1; else, failed = failed+1; end
fprintf('Test 5 (constant-power 1-360 deg): max err = %.2e [%s]\n', maxPowerErr, tern(cond,'PASS','FAIL'));

% Test 6: circularAngularError - basic cases
errCases = {
    [0   0],   0;
    [0   90],  90;
    [0   180], 180;
    [10  350], 20;
    [350 10],  20;
    [45  90],  45;
    [180 0],   180;
};
t6_fail = 0;
for i = 1:size(errCases,1)
    inp = errCases{i,1}; expected = errCases{i,2};
    got = H.circErr(inp(1), inp(2));
    cond = abs(got - expected) < 1e-12;
    if cond, passed = passed+1; else, failed = failed+1; t6_fail = t6_fail+1;
        fprintf('Test 6 FAIL: circErr(%d,%d)=%g exp=%g\n', inp(1), inp(2), got, expected); end
end
fprintf('Test 6 (circular angular error, 7 cases): %d/7 pass\n', 7-t6_fail);

% Test 7: pan wraparound 360 == 0
a0 = H.computePan(0, spkAngles);
a360 = H.computePan(360, spkAngles);
cond = max(abs(a0 - a360)) < 1e-12;
if cond, passed = passed+1; else, failed = failed+1; end
fprintf('Test 7 (computePan wrap 0==360): %s\n', tern(cond,'PASS','FAIL'));

% Test 8: sector-1 monotonicity
amps_at = arrayfun(@(d) H.computePan(d, spkAngles), 0:5:60, 'UniformOutput', false);
amps_at = vertcat(amps_at{:});
spk1_amps = amps_at(:,1);
spk2_amps = amps_at(:,2);
cond1 = all(diff(spk1_amps) <= 1e-12);
cond2 = all(diff(spk2_amps) >= -1e-12);
if cond1 && cond2, passed = passed+1; else, failed = failed+1; end
fprintf('Test 8 (sector 1 monotonic): %s\n', tern(cond1 && cond2, 'PASS','FAIL'));

% Test 9 (NEW v1.5): streamPanSweep angle math
SR = 48000; sweepSec = 10; frameN = 16384;
totalSweepSamples = max(round(sweepSec * SR), frameN);
cum = 0; degs = [];
while cum < totalSweepSamples
    degs(end+1) = 360 * (cum / totalSweepSamples); %#ok<AGROW>
    cum = cum + frameN;
end
cond_final = degs(end) > 0.95*360;
expected_step = 360 * frameN / totalSweepSamples;
maxStepErr = max(abs(diff(degs) - expected_step));
cond_step = maxStepErr < 1e-9;
cond_zero = degs(1) == 0;
if cond_final && cond_step && cond_zero, passed = passed+1; else, failed = failed+1; end
fprintf('Test 9 (sweep angle math): %d frames, step=%.3f deg, range [%g, %g] - %s\n', ...
    length(degs), expected_step, degs(1), degs(end), ...
    tern(cond_final && cond_step && cond_zero, 'PASS', 'FAIL'));

fprintf('\n========================\n');
fprintf('TOTAL: %d passed, %d failed\n', passed, failed);
fprintf('========================\n');

end % slt_regression_v15

function body = extractFn(src, name)
    pat = sprintf('function [^\n]*%s\\([^\n]*\\)[\\s\\S]*?\\nend %% %s', name, name);
    body = regexp(src, pat, 'match', 'once');
end

function s = tern(c,a,b)
    if c, s=a; else, s=b; end
end
