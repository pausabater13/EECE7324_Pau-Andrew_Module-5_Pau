function pskTable()
%PSKTABLE Our script (Steps 10 and 21). For every capture of Steps 6 and 18, estimates the SNR from
% the spectrum, converts it to Eb/N0, runs receiverSC.m to get the SER and BER, and writes the
% tables to report/tables/psk_gray.tex, psk_bin.tex (Step 10) and qam_gray.tex (Step 21).
%
% SNR: Welch PSD of the whole capture. The power in the signal band B = (1+beta)*Rs = 43.75 MHz
% around fc is P_S + P_N. The noise PSD N0 is the median of the PSD between 100 and 400 MHz from
% the carrier, where there is only the noise floor of the DSO (the median ignores the narrow
% spurs and interferers there). Then P_N = N0*B, P_S = P_band - P_N and SNR = P_S/P_N.
% Eb/N0 = SNR * B / (Rs*log2(M)).

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));

Rs = 25e6; fc = 2.4e9; B = 1.75 * Rs;
Ms = [2 4 8 16 32];
sets = ["wired", "6a"; "wireless", "6b"];
src = fileread("receiverSC.m");
outDir = fullfile(root, "..", "report", "tables");
if ~isfolder(outDir), mkdir(outDir); end

for o = ["gray", "bin"]
    R = zeros(numel(Ms), 8); % SNR w, SNR wl, EbN0 w, EbN0 wl, SER w, SER wl, BER w, BER wl
    for k = 1:numel(Ms)
        M = Ms(k);
        for s = 1:2
            f = sprintf("captures/%s/%s_%dpsk_%s.mat", sets(s, 1), sets(s, 2), M, o);
            snr = estimateSNR(f, fc, B);
            [ber, ser] = runRx(src, M, o, f);
            R(k, s)     = 10*log10(snr);
            R(k, 2 + s) = 10*log10(snr * B / (Rs * log2(M)));
            R(k, 4 + s) = ser;
            R(k, 6 + s) = ber;
        end
        fprintf("%-4s M=%2d: SNR %5.1f / %5.1f dB, Eb/N0 %5.1f / %5.1f dB, SER %g / %g, BER %g / %g\n", o, M, R(k, :));
    end
    writeTable(fullfile(outDir, "psk_" + o + ".tex"), Ms, R);
end

% M-QAM with Gray coding (Step 21).
MsQ = [4 8 16 32];
R = zeros(numel(MsQ), 8);
for k = 1:numel(MsQ)
    M = MsQ(k);
    for s = 1:2
        f = sprintf("captures/%s/%s_%dqam_gray.mat", sets(s, 1), strrep(sets(s, 2), "6", "18"), M);
        snr = estimateSNR(f, fc, B);
        [ber, ser] = runRx(src, M, "gray", f, "qam");
        R(k, s)     = 10*log10(snr);
        R(k, 2 + s) = 10*log10(snr * B / (Rs * log2(M)));
        R(k, 4 + s) = ser;
        R(k, 6 + s) = ber;
    end
    fprintf("qam  M=%2d: SNR %5.1f / %5.1f dB, Eb/N0 %5.1f / %5.1f dB, SER %g / %g, BER %g / %g\n", M, R(k, :));
end
writeTable(fullfile(outDir, "qam_gray.tex"), MsQ, R);
end

function snr = estimateSNR(f, fc, B)
S = load(f);
y = S.Trace_1_VOLT - mean(S.Trace_1_VOLT);
fs = 1 / mean(diff(S.Time_s));
[p, fr] = pwelch(y, hann(65536), [], 65536, fs); % One-sided PSD [V^2/Hz].
df = fr(2) - fr(1);
d = abs(fr - fc);
Pband = sum(p(d <= B/2)) * df;           % P_S + P_N.
N0 = median(p(d >= 100e6 & d <= 400e6));  % Noise floor [V^2/Hz].
PN = N0 * B;
snr = (Pband - PN) / PN;                 % 50 ohm cancels in the ratio.
end

function [ber, ser] = runRx(src, M, o, f, scheme)
if nargin < 5, scheme = "psk"; end
txt = regexprep(src, 'M = 2;', sprintf('M = %d;', M), 'once');
txt = regexprep(txt, 'modScheme = "psk";', sprintf('modScheme = "%s";', scheme), 'once');
txt = regexprep(txt, 'symOrder = "gray";', sprintf('symOrder = "%s";', o), 'once');
txt = regexprep(txt, 'filename = "[^"]*";', sprintf('filename = "%s";', f), 'once');
[ber, ser] = evalRx(txt);
close("all");
end

function [ber, ser] = evalRx(txt)
% Runs the receiver in its own workspace (its output is hidden).
evalc(txt);
end

function writeTable(file, Ms, R)
fid = fopen(file, "w");
cleanup = onCleanup(@() fclose(fid));
for k = 1:numel(Ms)
    fprintf(fid, "%d & %.1f & %.1f & %.1f & %.1f & %s & %s & %s & %s \\\\\n", Ms(k), R(k, 1:4), ...
        num(R(k, 5)), num(R(k, 6)), num(R(k, 7)), num(R(k, 8)));
end
fprintf(fid, "\\hline%%"); % Here, since LaTeX does not accept \hline right after \input.
end

function s = num(x)
if x == 0
    s = "0";
else
    s = sprintf("$%.1f \\cdot 10^{%d}$", x / 10^floor(log10(x)), floor(log10(x)));
end
end
