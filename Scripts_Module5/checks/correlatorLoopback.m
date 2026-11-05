function correlatorLoopback()
%CORRELATORLOOPBACK Our script (Step 8). Checks the pulse of correlationReceiver.m and passes
% 300 random 16-PSK symbols through the pulse shaping and correlationReceiver.m with no
% channel, to compare the output with the transmitted symbols. It also checks that the pulse is
% symmetric, so the matched filter (the time-reversed pulse) is the pulse itself (Step 26).

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
addpath(fullfile(root, "functions"));

sps = 800; % [Sa/symbol] At the DSO sample rate.
p = rcosdesign(0.75, 10, sps);
fprintf("Pulse: %dx%d, energy %.6f, real %d\n", size(p, 1), size(p, 2), sum(p.^2), isreal(p));
fprintf("Pulse symmetry (Step 26): max |p - fliplr(p)| = %.1e at sps = %d, %.1e at sps = 3 (transmitter)\n", ...
    max(abs(p - fliplr(p))), sps, max(abs(rcosdesign(0.75, 10, 3) - fliplr(rcosdesign(0.75, 10, 3)))));

rng(0); % Same random symbols every time.
s = pskmod(randi([0 15], 300, 1), 16, 0, "gray");
x = pulseShaping(s, sps);
y = correlationReceiver(x, sps, numel(s));
fprintf("Max |received - transmitted| = %.2e\n", max(abs(y - s)));
end
