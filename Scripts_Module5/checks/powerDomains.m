function powerDomains()
%POWERDOMAINS Our script (Step 10). For the wired and wireless 16-PSK Gray captures, computes the
% received power at three points of the receiver, and the SNR where we can:
%   1. Passband, before demodulation: spectrum of the DSO trace summed over the signal band
%      (as in pskTable.m), with the noise floor 100-400 MHz from the carrier.
%   2. Baseband, after iqDemodulation.m: mean(|r|^2)/(2*50), since |r| is the passband amplitude.
%      The noise cannot be separated here without a capture with the SG off, which we did not take.
%   3. Symbol level, after correlationReceiver.m: Es = mean(|s|^2)/Fs (the 1/sqrt(Fs) factor of
%      Step 8, squared) and P = Es*Rs/(2*50); the SNR is Es/N0 = 1/EVM^2, which counts everything
%      that moves the symbols, not only the noise. It also gives the 16-PSK SER expected in AWGN
%      with each Es/N0, to compare with the measured one.

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));
addpath("functions");

src = fileread("receiverSC.m");
src = regexprep(src, 'M = 2;', 'M = 16;', 'once');
fc = 2.4e9; Rs = 25e6; B = 1.75 * Rs; R = 50;
files = ["captures/wired/6a_16psk_gray.mat", "captures/wireless/6b_16psk_gray.mat"];
for f = files
    S = load(f);
    y = S.Trace_1_VOLT - mean(S.Trace_1_VOLT);
    Fs = 1 / mean(diff(S.Time_s));

    % 1. Passband, before demodulation.
    [p, fr] = pwelch(y, hann(65536), [], 65536, Fs);
    df = fr(2) - fr(1); d = abs(fr - fc);
    Pband = sum(p(d <= B/2)) * df;
    N0 = median(p(d >= 100e6 & d <= 400e6));
    snr1 = (Pband - N0*B) / (N0*B);

    % 2. Baseband, after IQ demodulation (whole capture).
    r = iqDemodulation(y, fc, Fs, Rs);
    Pbb = mean(abs(r).^2) / (2*R);

    % 3. Symbol level, after the correlation receiver.
    txt = regexprep(src, 'filename = "[^"]*";', sprintf('filename = "%s";', f), 'once');
    [s, x] = evalRx(txt);
    Es = mean(abs(s).^2) / Fs;
    Psym = Es * Rs / (2*R);
    sn = s * sqrt(mean(abs(x).^2) / mean(abs(s).^2));
    evm = sqrt(mean(abs(sn - x).^2) / mean(abs(x).^2));

    fprintf("%s\n", f);
    fprintf("  1. passband:  P = %.1f dBm, SNR = %.1f dB (Es/N0 = SNR + 2.4 dB = %.1f dB)\n", ...
        10*log10(Pband/R/1e-3), 10*log10(snr1), 10*log10(snr1*B/Rs));
    fprintf("  2. baseband:  P = %.1f dBm\n", 10*log10(Pbb/1e-3));
    fprintf("  3. symbols:   P = %.1f dBm, Es/N0 = 1/EVM^2 = %.1f dB (EVM %.1f %%)\n", ...
        10*log10(Psym/1e-3), 10*log10(1/evm^2), 100*evm);
    serTh = @(EsN0) 2*0.5*erfc(sqrt(2*EsN0)*sin(pi/16)/sqrt(2));   % 16-PSK in AWGN: 2Q(sqrt(2Es/N0) sin(pi/M)).
    fprintf("  16-PSK SER expected in AWGN: %.2g with the Es/N0 of 1, %.2g with the one of 3; measured %.3f\n", ...
        serTh(snr1*B/Rs), serTh(1/evm^2), mean(pskdemod(s, 16, 0, "gray") ~= pskdemod(x, 16, 0, "gray")));
end
end

function [s, x] = evalRx(txt)
% Runs the receiver in its own workspace (its output is hidden).
evalc(txt);
s = symbolsDataReceived;
x = symbolsData;
end
