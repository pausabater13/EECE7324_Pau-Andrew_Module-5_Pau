function capturePower()
%CAPTUREPOWER Our script (Step 6). For every DSO capture in captures/wired and
% captures/wireless, prints the number of samples, the sample rate, the duration, the
% peak-to-peak voltage and the power in the signal band (43.75 MHz around 2.4 GHz, 50 ohm).
% It also estimates the vertical scale of the DSO from the quantization step of the samples: the
% step is proportional to V/div, and the PSK captures, at a known 500 and 14 mV/div, give the
% factor. The number of samples at the maximum and minimum levels shows if the signal clipped.

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
k500 = lsb(fullfile(root, "captures", "wired", "6a_16psk_gray.mat")) / 0.5; % Step per V/div.
for d = ["wired", "wireless"]
    L = dir(fullfile(root, "captures", d, "*.mat"));
    for k = 1:numel(L)
        S = load(fullfile(L(k).folder, L(k).name));
        t = S.Time_s; y = S.Trace_1_VOLT;
        fs = 1 / mean(diff(t));
        [p, f] = pwelch(y - mean(y), hann(65536), [], 65536, fs);
        band = abs(f - 2.4e9) <= 43.75e6/2;
        Pband = sum(p(band)) * (f(2) - f(1)) / 50; % One-sided PSD in V^2/Hz -> W.
        vdiv = lsb(fullfile(L(k).folder, L(k).name)) / k500;
        fprintf("%-10s %-20s N=%d fs=%.3g dur=%.2f us Vpp=%.1f mV Pband=%.1f dBm, " + ...
            "about %.0f mV/div, samples at max/min %d/%d\n", d, L(k).name, numel(y), fs, ...
            (t(end) - t(1))*1e6, (max(y) - min(y))*1e3, 10*log10(Pband/1e-3), vdiv*1e3, ...
            sum(y == max(y)), sum(y == min(y)));
    end
end
end

function q = lsb(file)
% Quantization step of a capture [V].
S = load(file);
d = diff(unique(S.Trace_1_VOLT));
q = median(d(d > 0));
end
