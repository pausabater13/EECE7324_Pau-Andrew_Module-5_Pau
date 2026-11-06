function plotDistance()
%PLOTDISTANCE Our script (Step 12). Runs receiverSC.m on the captures without Gray coding at
% 10 cm, 1.1 m, 1.5 m and 2 m (2-PSK in the first row, 4-PSK in the second; there is no 4-PSK
% capture at 2 m), prints the peak-to-peak voltage, BER, SER, EVM and header phase of each one,
% and plots the received constellations in figures/rx_2psk_distance.pdf. The received symbols are
% only divided by their mean amplitude (one real factor per capture).

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));

names = ["10 cm", "1.1 m", "1.5 m", "2 m"];
Ms = [2 4];
files = ["captures/wireless_10cm/6b_2psk_bin.mat", "captures/wireless/6b_2psk_bin.mat", ...
         "captures/wireless_1p5m/6b_2psk_bin_1p5m.mat", "captures/wireless_2m/6b_2psk_bin_2m.mat";
         "captures/wireless_10cm/6b_4psk_bin.mat", "captures/wireless/6b_4psk_bin.mat", ...
         "captures/wireless_1p5m/6b_4psk_bin_1p5m.mat", ""];
src = fileread("receiverSC.m");
src = regexprep(src, 'symOrder = "gray";', 'symOrder = "bin";', 'once');

% Run the receiver first: it closes all figures when it starts.
Y = cell(size(files));
for r = 1:numel(Ms)
    for k = 1:numel(names)
        if files(r, k) == "", continue; end
        S = load(files(r, k));
        v = S.Trace_1_VOLT;
        txt = regexprep(src, 'M = 2;', sprintf('M = %d;', Ms(r)), 'once');
        txt = regexprep(txt, 'filename = "[^"]*";', sprintf('filename = "%s";', files(r, k)), 'once');
        [y, x, ber, ser, out] = evalRx(txt);
        close("all");
        yn = y * sqrt(mean(abs(x).^2) / mean(abs(y).^2));
        evm = 100 * sqrt(mean(abs(yn - x).^2) / mean(abs(x).^2));
        ph = regexp(out, 'Phase estimate = ([-\d.]+)', 'tokens', 'once');
        fprintf("%d-PSK %-6s Vpp %.1f mV, BER %.2e, SER %.2e, EVM %.1f %%, header phase %s deg\n", ...
            Ms(r), names(k), 1e3*(max(v) - min(v)), ber, ser, evm, ph{1});
        Y{r, k} = y / mean(abs(y));
    end
end

f = figure(Visible="off", Units="centimeters", Position=[0 0 30 15]);
t = tiledlayout(f, numel(Ms), numel(names), TileSpacing="compact", Padding="compact");
for r = 1:numel(Ms)
    ref = pskmod((0:Ms(r)-1).', Ms(r));
    for k = 1:numel(names)
        ax = nexttile(t);
        if isempty(Y{r, k})
            axis(ax, "off");
            text(ax, 0.5, 0.5, "no capture", HorizontalAlignment="center", Units="normalized");
            continue
        end
        plot(ax, real(Y{r, k}), imag(Y{r, k}), ".", MarkerSize=6); hold(ax, "on");
        plot(ax, real(ref), imag(ref), "r+", MarkerSize=10, LineWidth=1.2);
        axis(ax, "equal"); grid(ax, "on"); xlim(ax, [-1.6 1.6]); ylim(ax, [-1.6 1.6]);
        title(ax, sprintf("%d-PSK, %s", Ms(r), names(k))); xlabel(ax, "I"); ylabel(ax, "Q");
    end
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
