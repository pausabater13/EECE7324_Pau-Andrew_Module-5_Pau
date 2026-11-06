function plotTxQam()
%PLOTTXQAM Our script (Steps 16 and 17). Runs transmitterSC.m with modScheme = "qam" and Gray
% order for M = 4, 8, 16, 32 (which also writes the 4 .WAVEFORM files, moved to qam/), plots the
% generated data constellations with the bits of each point in figures/tx_qam.pdf, and
% prints, for each M, the average power of the constellation, the minimum distance between points
% (QAM and PSK), and how many pairs of neighboring points differ in more than one bit.

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
figOut = fullfile(root, "..", "figures", "tx_qam.pdf");
oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));
if ~isfolder("qam"), mkdir("qam"); end

src = fileread("transmitterSC.m");
Ms = [4 8 16 32];
S = cell(1, numel(Ms));
for k = 1:numel(Ms)
    txt = regexprep(src, 'M = 2;', sprintf('M = %d;', Ms(k)), 'once');
    txt = regexprep(txt, 'modScheme = "psk";', 'modScheme = "qam";', 'once');
    S{k} = runTx(txt);
    close("all");
    wf = sprintf("%dqam_25SR_gray.WAVEFORM", Ms(k));
    movefile(wf, fullfile("qam", wf));
end

f = figure(Visible="off", Units="centimeters", Position=[0 0 28 7.5]);
t = tiledlayout(f, 1, numel(Ms), TileSpacing="compact", Padding="compact");
for k = 1:numel(Ms)
    M = Ms(k);
    ref = qammod((0:M-1).', M, "gray", UnitAveragePower=true); % Point of each integer value.

    % Checks.
    D = abs(ref - ref.');
    D(1:M+1:end) = Inf;
    dmin = min(D(:));
    nb = abs(D - dmin) < 1e-9;                                   % Pairs of neighbors.
    nBits = sum(dec2bin(bitxor((0:M-1).', (0:M-1))) == '1', 2); % Bits that differ, all pairs.
    nBits = reshape(nBits, M, M);
    bad = nnz(triu(nb & nBits > 1));
    fprintf("M=%2d: average power %.2f, dmin QAM %.3f, dmin PSK %.3f, " + ...
        "neighbor pairs %d, of them differing in more than one bit %d\n", M, ...
        mean(abs(ref).^2), dmin, 2*sin(pi/M), nnz(triu(nb)), bad);

    % qammod draws the ideal constellation with the bits of each point.
    qammod(int2bit((0:M-1).', log2(M)), M, "gray", InputType="bit", UnitAveragePower=true, PlotConstellation=true);
    ax = flagTile(t, k, M);
    title(ax, sprintf("%d-QAM, Gray", M));                  % Shorter than the one of qammod.
    plot(ax, real(S{k}), imag(S{k}), ".", MarkerSize=10); % Generated data symbols.
end
exportgraphics(f, figOut, ContentType="vector");
fprintf("Saved %s\n", figOut);
end

function ax = flagTile(t, tile, M)
% Moves the axes of the figure drawn by PlotConstellation into a tile of t.
src = gcf;
ax = copyobj(findobj(src, "Type", "axes"), t);
ax.Layout.Tile = tile;
close(src);
set(findall(ax, "Type", "text"), FontSize=max(5, 9 - log2(M)));
xlabel(ax, "I"); ylabel(ax, "Q");
ax.Title.FontSize = 9;
hold(ax, "on");
end

function s = runTx(txt)
% Runs the transmitter in its own workspace and returns the data symbols.
eval(txt);
s = symbolsData;
end
