function evmTable()
%EVMTABLE Our script (Step 14). Runs receiverSC.m on the Gray captures of Step 6 and computes the
% RMS EVM of the received data symbols against the transmitted ones, normalized by the average
% power of the transmitted symbols (as comm.EVM does by default). The received symbols are first
% multiplied by one real factor, so that they have the same average power as the transmitted ones.
% It checks the result against comm.EVM and writes the table rows to report/tables/evm.tex.

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));

src = fileread("receiverSC.m");
sets = ["wired", "6a"; "wireless", "6b"];
Ms = [2 4 8 16 32];
E = zeros(numel(Ms), 2);
for s = 1:2
    for k = 1:numel(Ms)
        f = sprintf("captures/%s/%s_%dpsk_gray.mat", sets(s, 1), sets(s, 2), Ms(k));
        [y, x] = runRx(src, Ms(k), "gray", f);
        y = y * sqrt(mean(abs(x).^2) / mean(abs(y).^2));   % Same average power as x.
        E(k, s) = 100 * sqrt(mean(abs(y - x).^2) / mean(abs(x).^2));
        evmObj = comm.EVM;                                  % MathWorks, for comparison.
        fprintf("%-8s M=%2d: EVM %.2f %% (comm.EVM %.2f %%), %.1f dB\n", sets(s, 1), Ms(k), ...
            E(k, s), evmObj(x, y), 20*log10(E(k, s)/100));
    end
end

fid = fopen(fullfile(root, "..", "report", "tables", "evm.tex"), "w");
closefile = onCleanup(@() fclose(fid));
for k = 1:numel(Ms)
    fprintf(fid, "%d & %.1f & $%.1f$ & %.1f & $%.1f$ \\\\\n", Ms(k), E(k, 1), 20*log10(E(k, 1)/100), ...
        E(k, 2), 20*log10(E(k, 2)/100));
end
fprintf(fid, "\\hline%%");
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
