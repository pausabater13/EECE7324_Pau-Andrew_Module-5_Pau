function qamPower()
%QAMPOWER Our script (Step 15). Prints the average power of the M-QAM constellation from qammod()
% without and with UnitAveragePower=true, the one of M-PSK, and the average power of the 300 data
% symbols that symbolMapping.m generates from the bits of transmitterSC.m.

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
addpath(fullfile(root, "functions"));
src = fileread(fullfile(root, "transmitterSC.m"));
tok = regexp(src, 'bits = (\[[^\]]*\]\.'')', 'tokens', 'once');
bits = eval(tok{1});                                      % Same bits as transmitterSC.m.

for M = [4 8 16 32]
    pts = qammod((0:M-1).', M);                         % Default constellation.
    ptsUnit = qammod((0:M-1).', M, UnitAveragePower=true);
    psk = pskmod((0:M-1).', M);
    s = symbolMapping(bits(1 : 300*log2(M)), M, "qam");  % Data symbols of the transmitter.
    fprintf("M=%2d: QAM default %.2f, unit %.2f, PSK %.2f, data symbols %.2f\n", M, ...
        mean(abs(pts).^2), mean(abs(ptsUnit).^2), mean(abs(psk).^2), mean(abs(s).^2));
end
end
