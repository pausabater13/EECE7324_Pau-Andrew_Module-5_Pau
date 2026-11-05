function compareReceivers(files)
%COMPARERECEIVERS Our script (Steps 25 and 27). Runs receiverSC.m on each capture twice, once with
% correlationReceiver.m (as provided) and once with matchedFilter.m in its place, and compares the
% received data symbols, the BER and the SER, and the time each run takes. Without inputs, it
% uses all the PSK and QAM captures of Steps 6 and 18.

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));

if nargin < 1
    L = [dir("captures/wired/*.mat"); dir("captures/wireless/*.mat")];
    files = string(fullfile(erase({L.folder}, [pwd filesep]), {L.name}));
end

src = fileread("receiverSC.m");
srcMF = strrep(src, "correlationReceiver(", "matchedFilter(");   % Same receiver, other filter.
fprintf("%-36s %10s %10s %10s %8s %8s\n", "capture", "max diff", "max |y|", "BER", "t corr", "t MF");
for f = files(:).'
    tok = regexp(f, "_(\d+)(psk|qam)_(gray|bin)\.mat$", "tokens", "once");
    M = str2double(tok(1));
    [y1, ber1, ser1, t1] = runRx(src, M, tok(2), tok(3), f);
    [y2, ber2, ser2, t2] = runRx(srcMF, M, tok(2), tok(3), f);
    fprintf("%-36s %10.1e %10.3g %10.2e %7.1fs %7.1fs  same BER %d, same SER %d\n", f, ...
        max(abs(y1 - y2)), max(abs(y1)), ber2, t1, t2, ber1 == ber2, ser1 == ser2);
end
end

function [y, ber, ser, t] = runRx(src, M, scheme, o, f)
txt = regexprep(src, 'M = 2;', sprintf('M = %d;', M), 'once');
txt = regexprep(txt, 'modScheme = "psk";', sprintf('modScheme = "%s";', scheme), 'once');
txt = regexprep(txt, 'symOrder = "gray";', sprintf('symOrder = "%s";', o), 'once');
txt = regexprep(txt, 'filename = "[^"]*";', sprintf('filename = "%s";', f), 'once');
tic;
[y, ber, ser] = evalRx(txt);
t = toc;
close("all");
end

function [y, ber, ser] = evalRx(txt)
% Runs the receiver in its own workspace (its output is hidden).
evalc(txt);
y = symbolsDataReceived;
end
