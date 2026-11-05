function paprTable()
%PAPRTABLE Our script (Step 23). For M-QAM with M = 4, 8, 16, 32, computes the PAPR (peak power over
% average power, in dB) of the ideal constellation (all M points), of the 300 transmitted data
% symbols, and of the received data symbols of the wired and wireless captures of Step 18
% (output of receiverSC.m). Writes the table rows to report/tables/papr.tex.

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));

src = fileread("receiverSC.m");
papr = @(x) 10*log10(max(abs(x).^2) / mean(abs(x).^2));
Ms = [4 8 16 32];
P = zeros(numel(Ms), 4);
for k = 1:numel(Ms)
    M = Ms(k);
    [yw, x] = runRx(src, M, sprintf("captures/wired/18a_%dqam_gray.mat", M));
    yl = runRx(src, M, sprintf("captures/wireless/18b_%dqam_gray.mat", M));
    P(k, :) = [papr(qammod((0:M-1).', M)), papr(x), papr(yw), papr(yl)];
    fprintf("%2d-QAM: ideal %.2f dB, transmitted %.2f dB, received wired %.2f dB, wireless %.2f dB\n", M, P(k, :));
end

fid = fopen(fullfile(root, "..", "report", "tables", "papr.tex"), "w");
closefile = onCleanup(@() fclose(fid));
for k = 1:numel(Ms)
    fprintf(fid, "%d & %.2f & %.2f & %.2f & %.2f \\\\\n", Ms(k), P(k, :));
end
fprintf(fid, "\\hline%%");
end

function [y, x] = runRx(src, M, f)
txt = regexprep(src, 'M = 2;', sprintf('M = %d;', M), 'once');
txt = regexprep(txt, 'modScheme = "psk";', 'modScheme = "qam";', 'once');
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
