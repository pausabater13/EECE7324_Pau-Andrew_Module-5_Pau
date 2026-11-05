function findDips(filename)
%FINDDIPS Our script (for Step 10). Finds the low-power dips of a DSO capture (more than 15 dB
% below the maximum, in windows of 400 samples = 20 ns) and prints where they are.
% Example: findDips("captures/wired/6a_16psk_gray.mat") from Scripts_Module5.

if nargin < 1
    root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
    filename = fullfile(root, "captures", "wired", "6a_16psk_gray.mat");
end
S = load(filename);
y = S.Trace_1_VOLT - mean(S.Trace_1_VOLT);
fs = 1 / mean(diff(S.Time_s));

n = 400;
nw = floor(numel(y)/n);
P = 10*log10(mean(reshape(y(1:nw*n), n, nw).^2, 1)/50/1e-3);
low = P < max(P) - 15;
d = diff([0 low 0]);
s = find(d == 1); e = find(d == -1) - 1;

fprintf("%d dips\n", numel(s));
for k = 1:numel(s)
    fprintf("  start %.3f us, length %.0f ns\n", (s(k)-1)*n/fs*1e6, (e(k)-s(k)+1)*n/fs*1e9);
end
end
