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
        ax = nexttile(t);
        plot(ax, real(S{o, k}), imag(S{o, k}), ".", MarkerSize=12); hold(ax, "on");
        ref = pskmod((0:M-1).', M, 0, orders(o)); % Point of each integer value.
        fs = max(5, 9 - log2(M));
        for m = 0:M-1
            p = ref(m+1) * 1.25;
            text(ax, real(p), imag(p), dec2bin(m, log2(M)), FontSize=fs, HorizontalAlignment="center");
        end
        axis(ax, "equal"); grid(ax, "on"); xlim(ax, [-1.5 1.5]); ylim(ax, [-1.5 1.5]);
        title(ax, sprintf("%d-PSK, %s", M, orders(o)));
        xlabel(ax, "I"); ylabel(ax, "Q");
    end
end
exportgraphics(f, figOut, ContentType="vector");
fprintf("Saved %s\n", figOut);
end

function s = runTx(txt)
% Runs the transmitter in its own workspace and returns the data symbols.
eval(txt);
s = symbolsData;
end
