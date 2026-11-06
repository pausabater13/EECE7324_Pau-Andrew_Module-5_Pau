function plotDistance()
%PLOTDISTANCE Our script (Step 12). Runs receiverSC.m on the 2-PSK captures without Gray coding at
% 10 cm, 1.1 m and 2 m, prints the peak-to-peak voltage, BER, SER, EVM and header phase of each one,
% and plots the three received constellations in figures/rx_2psk_distance.pdf. The received symbols
% are only divided by their mean amplitude (one real factor per capture).

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));

files = ["captures/wireless_10cm/6b_2psk_bin.mat", "captures/wireless/6b_2psk_bin.mat", ...
    "captures/wireless_2m/6b_2psk_bin_2m.mat"];
names = ["10 cm", "1.1 m", "2 m"];
src = fileread("receiverSC.m");
src = regexprep(src, 'symOrder = "gray";', 'symOrder = "bin";', 'once');   % M = 2 already.

% Run the receiver first: it closes all figures when it starts.
Y = cell(1, numel(files));
for k = 1:numel(files)
    S = load(files(k));
    v = S.Trace_1_VOLT;
    txt = regexprep(src, 'filename = "[^"]*";', sprintf('filename = "%s";', files(k)), 'once');
    [y, x, ber, ser, out] = evalRx(txt);
    close("all");
    yn = y * sqrt(mean(abs(x).^2) / mean(abs(y).^2));
    evm = 100 * sqrt(mean(abs(yn - x).^2) / mean(abs(x).^2));
    ph = regexp(out, 'Phase estimate = ([-\d.]+)', 'tokens', 'once');
    fprintf("%-6s Vpp %.1f mV, BER %.2e, SER %.2e, EVM %.1f %%, header phase %s deg\n", ...
        names(k), 1e3*(max(v) - min(v)), ber, ser, evm, ph{1});
    Y{k} = y / mean(abs(y));
end

f = figure(Visible="off", Units="centimeters", Position=[0 0 27 8]);
t = tiledlayout(f, 1, numel(files), TileSpacing="compact", Padding="compact");
for k = 1:numel(files)
    ax = nexttile(t);
    plot(ax, real(Y{k}), imag(Y{k}), ".", MarkerSize=6); hold(ax, "on");
    plot(ax, [-1 1], [0 0], "r+", MarkerSize=10, LineWidth=1.2);
    xline(ax, 0, "k--");
    axis(ax, "equal"); grid(ax, "on"); xlim(ax, [-1.6 1.6]); ylim(ax, [-1.6 1.6]);
    title(ax, "2-PSK, " + names(k)); xlabel(ax, "I"); ylabel(ax, "Q");
end
out = fullfile(root, "..", "figures", "rx_2psk_distance.pdf");
exportgraphics(f, out, ContentType="vector");
fprintf("Saved %s\n", out);
end

function [y, x, ber, ser, out] = evalRx(txt)
% Runs the receiver in its own workspace (its output is kept in out).
out = evalc(txt);
y = symbolsDataReceived;
x = symbolsData;
end
