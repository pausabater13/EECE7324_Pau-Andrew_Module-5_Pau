function runReceiverAll()
%RUNRECEIVERALL Our script (Step 7). Runs receiverSC.m on every capture of Step 6, with the
% matching M and symbol order, and once more with the wrong symbol order as a check, and on
% the M-QAM captures of Step 18.
% It also prints the sample rate of each file, since receiverSC.m assumes 20 GSa/s.

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));

src = fileread("receiverSC.m");
sets = ["wired", "6a"; "wireless", "6b"];
for s = 1:2
    for o = ["gray", "bin"]
        for M = [2 4 8 16 32]
            f = sprintf("captures/%s/%s_%dpsk_%s.mat", sets(s, 1), sets(s, 2), M, o);
            if ~isfile(f), fprintf("%-36s missing\n", f); continue; end
            [ber, ser, fsFile] = runOne(src, M, o, f);
            wrong = "gray"; if o == "gray", wrong = "bin"; end
            berWrong = runOne(src, M, wrong, f);
            fprintf("%-36s fs=%.3g BER=%.2e SER=%.2e | wrong order BER=%.2e\n", f, fsFile, ber, ser, berWrong);
        end
    end
    for M = [4 8 16 32] % M-QAM, Gray (Step 18).
        f = sprintf("captures/%s/%s_%dqam_gray.mat", sets(s, 1), strrep(sets(s, 2), "6", "18"), M);
        [ber, ser, fsFile] = runOne(src, M, "gray", f, "qam");
        fprintf("%-36s fs=%.3g BER=%.2e SER=%.2e\n", f, fsFile, ber, ser);
    end
end
end

function [ber, ser, fsFile] = runOne(src, M, o, f, scheme)
if nargin < 5, scheme = "psk"; end
txt = regexprep(src, 'M = 2;', sprintf('M = %d;', M), 'once');
txt = regexprep(txt, 'modScheme = "psk";', sprintf('modScheme = "%s";', scheme), 'once');
txt = regexprep(txt, 'symOrder = "gray";', sprintf('symOrder = "%s";', o), 'once');
txt = regexprep(txt, 'filename = "[^"]*";', sprintf('filename = "%s";', f), 'once');
[ber, ser, fsFile] = evalRx(txt);
close("all");
end

function [ber, ser, fsFile] = evalRx(txt)
% Runs the receiver in its own workspace (its output is hidden).
evalc(txt);
fsFile = 1 / mean(diff(t));
end
