function plotTxConstellations()
%PLOTTXCONSTELLATIONS Our script (Step 5). Runs transmitterSC.m for M = 2, 4, 8, 16, 32
% with Gray and binary order (which also writes the 10 .WAVEFORM files, moved to gray/ and
% bin/), and plots the
% generated data constellations with the bits of each point in figures/tx_psk.pdf.

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
figOut = fullfile(root, "..", "figures", "tx_psk.pdf");

oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));

src = fileread("transmitterSC.m");
Ms = [2 4 8 16 32];
orders = ["gray", "bin"];
S = cell(2, numel(Ms));
for o = 1:2
    for k = 1:numel(Ms)
        txt = regexprep(src, 'M = 2;', sprintf('M = %d;', Ms(k)), 'once');
        txt = regexprep(txt, 'symOrder = "gray";', sprintf('symOrder = "%s";', orders(o)), 'once');
        S{o, k} = runTx(txt);
        close("all");
        % transmitterSC.m writes the file here; keep it in the gray/ or bin/ folder.
        wf = sprintf("%dpsk_25SR_%s.WAVEFORM", Ms(k), orders(o));
        movefile(wf, fullfile(orders(o), wf));
    end
end

f = figure(Visible="off", Units="centimeters", Position=[0 0 30 13]);
t = tiledlayout(f, 2, numel(Ms), TileSpacing="compact", Padding="compact");
for o = 1:2
    for k = 1:numel(Ms)
        M = Ms(k);
        % pskmod draws the ideal constellation with the bits of each point.
        pskmod(int2bit((0:M-1).', log2(M)), M, 0, orders(o), InputType="bit", PlotConstellation=true);
        ax = flagTile(t, (o - 1)*numel(Ms) + k, M);
        plot(ax, real(S{o, k}), imag(S{o, k}), ".", MarkerSize=10); % Generated data symbols.
    end
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
