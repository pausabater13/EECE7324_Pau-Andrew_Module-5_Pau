function windowPower()
%WINDOWPOWER Our script (for Step 10). Compares the power of each full 50 us capture with the
% power seen in short windows: 2000 samples (100 ns, the 10 ns/div screen) and 4096 samples
% (204.8 ns, the 4.88 MHz FFT bin size shown by the DSO at 20 GSa/s).

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
for d = ["wired", "wireless"]
    L = dir(fullfile(root, "captures", d, "*.mat"));
    for k = 1:numel(L)
        S = load(fullfile(L(k).folder, L(k).name));
        y = S.Trace_1_VOLT - mean(S.Trace_1_VOLT);
        Pfull = 10*log10(mean(y.^2)/50/1e-3);
        out = "";
        for n = [2000 4096]
            nw = floor(numel(y)/n);
            Y = reshape(y(1:nw*n), n, nw);
            Pw = 10*log10(mean(Y.^2, 1)/50/1e-3);
            out = out + sprintf("  %4d Sa: min %6.1f max %6.1f std %.1f dB", n, min(Pw), max(Pw), std(Pw));
        end
        fprintf("%-22s full %6.1f dBm%s\n", L(k).name, Pfull, out);
    end
end
end
