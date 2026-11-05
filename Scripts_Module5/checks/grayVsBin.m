function grayVsBin()
%GRAYVSBIN Our script (Step 13). We measured no errors, so this script adds Gaussian noise to the
% received wireless symbols of the Gray captures, to emulate a lower SNR, and decides each noisy
% symbol. Then it counts the bit errors of the SAME decisions with the two bit mappings (Gray and
% binary), so the SER is the same by construction and only the bits change. For each M, the noise
% is set to the Es/N0 at which the theoretical SER of M-PSK is about 1e-2. The table rows are
% written to tables/gray_vs_bin.tex.

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));

src = fileread("receiverSC.m");
rng(0); % Same noise every time.
nReal = 200; % Noise realizations.
outFile = fullfile(root, "..", "tables", "gray_vs_bin.tex");
fid = fopen(outFile, "w");
closefile = onCleanup(@() fclose(fid));
fprintf(" M  Es/N0[dB]   SER       BER Gray  BER bin   BER/SER Gray  BER/SER bin  1/log2(M)\n");
for M = [4 8 16 32]
    file = sprintf("captures/wireless/6b_%dpsk_gray.mat", M);
    [y, x] = runRx(src, M, "gray", file);
    y = y / mean(abs(y));                        % Unit mean amplitude (one real factor).
    k = posIndex(x, M);                          % Position (0..M-1, counterclockwise) sent.

    gray = posLabels(M, "gray"); bin = posLabels(M, "bin"); % Bits of each position.
    EsN0 = fzero(@(g) 2*qfunc(sqrt(2*10^(g/10)) * sin(pi/M)) - 1e-2, 15);

    nSym = 0; nBit = 0; eSym = 0; eGray = 0; eBin = 0;
    sigma = sqrt(10^(-EsN0/10) / 2);              % Noise std per dimension (unit power symbols).
    for r = 1:nReal
        kHat = posIndex(y + sigma*(randn(size(y)) + 1j*randn(size(y))), M);
        eSym  = eSym + sum(kHat ~= k);
        eGray = eGray + sum(bitCount(bitxor(gray(k+1), gray(kHat+1))));
        eBin  = eBin  + sum(bitCount(bitxor(bin(k+1), bin(kHat+1))));
        nSym = nSym + numel(k); nBit = nBit + numel(k) * log2(M);
    end
    ser = eSym/nSym; bg = eGray/nBit; bb = eBin/nBit;
    fprintf("%2d  %6.1f   %.2e  %.2e  %.2e  %.2f          %.2f         %.2f\n", ...
        M, EsN0, ser, bg, bb, bg/ser, bb/ser, 1/log2(M));
    fprintf(fid, "%d & %.1f & %s & %s & %s & %.2f & %.2f & %.2f \\\\\n", M, EsN0, ...
        num(ser), num(bg), num(bb), bg/ser, bb/ser, 1/log2(M));
end
fprintf(fid, "\\hline%%");
end

function s = num(x)
s = sprintf("$%.1f \\cdot 10^{%d}$", x / 10^floor(log10(x)), floor(log10(x)));
end

function k = posIndex(s, M)
% Closest position on the circle (0..M-1, counterclockwise from 0 degrees).
k = mod(round(angle(s) / (2*pi/M)), M);
end

function lab = posLabels(M, order)
% Integer (bits) carried by each position, for the given symbol order.
ref = pskmod((0:M-1).', M, 0, order);           % Point of each integer value.
lab = zeros(M, 1);
lab(posIndex(ref, M) + 1) = (0:M-1).';
end

function n = bitCount(v)
n = sum(dec2bin(v) == '1', 2);
end

function [y, x] = runRx(src, M, o, f)
txt = regexprep(src, 'M = 2;', sprintf('M = %d;', M), 'once');
txt = regexprep(txt, 'symOrder = "gray";', sprintf('symOrder = "%s";', o), 'once');
txt = regexprep(txt, 'filename = "[^"]*";', sprintf('filename = "%s";', f), 'once');
[y, x] = evalRx(txt);
close("all");
end

function [y, x] = evalRx(txt)
% Runs the receiver in its own workspace (its output is hidden).
evalc(txt);
y = symbolsDataReceived;
x = symbolsData;
end
