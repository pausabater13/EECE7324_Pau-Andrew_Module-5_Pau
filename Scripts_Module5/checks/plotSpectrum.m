function plotSpectrum()
%PLOTSPECTRUM Our script (Step 10). Plots the PSD of the wired and wireless 16-PSK Gray captures
% around the carrier, with the signal band and the band used for the noise floor, and saves it to
% report/figures/psd_16psk_gray.pdf.

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
files = ["captures/wired/6a_16psk_gray.mat", "captures/wireless/6b_16psk_gray.mat"];
names = ["Wired", "Wireless"];
fc = 2.4e9; B = 43.75e6;

f0 = figure(Visible="off", Units="centimeters", Position=[0 0 24 9]);
ax = axes(f0); hold(ax, "on");
for k = 1:2
    S = load(fullfile(root, files(k)));
    y = S.Trace_1_VOLT - mean(S.Trace_1_VOLT);
    fs = 1 / mean(diff(S.Time_s));
    [p, f] = pwelch(y, hann(65536), [], 65536, fs);
    m = abs(f - fc) <= 450e6;
    plot(ax, (f(m) - fc)/1e6, 10*log10(p(m)/50/1e-3) + 60, DisplayName=names(k)); % dBm/MHz
end
yl = ylim(ax);
patch(ax, [-B B B -B]/2e6, yl([1 1 2 2]), "g", FaceAlpha=0.1, EdgeColor="none", DisplayName="Signal band");
for side = [-1 1]
    patch(ax, side*[100 400 400 100], yl([1 1 2 2]), "k", FaceAlpha=0.06, EdgeColor="none", ...
        HandleVisibility=ternary(side == 1, "on", "off"), DisplayName="Noise floor band");
end
xlabel(ax, "f - 2.4 GHz (MHz)"); ylabel(ax, "PSD (dBm/MHz)");
legend(ax, Location="northeast"); grid(ax, "on"); xlim(ax, [-450 450]); ylim(ax, yl);
out = fullfile(root, "..", "report", "figures", "psd_16psk_gray.pdf");
exportgraphics(f0, out, ContentType="vector");
fprintf("Saved %s\n", out);
end

function v = ternary(c, a, b)
if c, v = a; else, v = b; end
end
