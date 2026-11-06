function plotRxQam()
%PLOTRXQAM Our script (Step 20). Runs receiverSC.m on the M-QAM captures of Step 18 and plots the
% received data symbols as they come out of the receiver, without normalizing I or Q. The ideal
% points are drawn scaled by the RMS value of the received symbols, so that they can be compared.
% It prints, for each capture, the header phase, the RMS and largest amplitude of the received
% symbols, and the EVM (after one real factor, as in checks/evmTable.m).

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));

src = fileread("receiverSC.m");
Ms = [4 8 16 32];
sets = ["wired", "18a"; "wireless", "18b"; "wireless_10cm", "18b"]; % 10 cm: earlier captures, for comparison.
for s = 1:size(sets, 1)
    % Run the receiver first: it closes all figures when it starts.
    Y = cell(1, numel(Ms)); X = Y; PHI = zeros(1, numel(Ms));
    for k = 1:numel(Ms)
        f = sprintf("captures/%s/%s_%dqam_gray.mat", sets(s, 1), sets(s, 2), Ms(k));
        [Y{k}, X{k}, PHI(k)] = runRx(src, Ms(k), f);
    end

    f0 = figure(Visible="off", Units="centimeters", Position=[0 0 28 7.5]);
    t = tiledlayout(f0, 1, numel(Ms), TileSpacing="compact", Padding="compact");
    for k = 1:numel(Ms)
        M = Ms(k); y = Y{k}; x = X{k};
        g = sqrt(mean(abs(y).^2));                          % RMS of the received symbols.
        ref = g * qammod((0:M-1).', M, "gray", UnitAveragePower=true);
        yn = y * sqrt(mean(abs(x).^2) / mean(abs(y).^2));
        evm = 100 * sqrt(mean(abs(yn - x).^2) / mean(abs(x).^2));
        fprintf("%-8s %2d-QAM: header phase %5.1f deg, RMS %.3g, largest |I|,|Q| %.3g, EVM %.1f %%\n", ...
            sets(s, 1), M, rad2deg(PHI(k)), g, max(abs([real(y); imag(y)])), evm);

        ax = nexttile(t);
        plot(ax, real(y), imag(y), ".", MarkerSize=5); hold(ax, "on");
        plot(ax, real(ref), imag(ref), "r+", MarkerSize=8, LineWidth=1);
        lim = 1.3 * max(abs([real(ref); imag(ref)]));
        axis(ax, "equal"); grid(ax, "on"); xlim(ax, [-lim lim]); ylim(ax, [-lim lim]);
        title(ax, sprintf("%d-QAM", M)); xlabel(ax, "I"); ylabel(ax, "Q");
    end
    out = fullfile(root, "..", "figures", "rx_qam_" + sets(s, 1) + ".pdf");
    exportgraphics(f0, out, ContentType="vector");
    fprintf("Saved %s\n", out);
end
end

function [y, x, phi] = runRx(src, M, f)
txt = regexprep(src, 'M = 2;', sprintf('M = %d;', M), 'once');
txt = regexprep(txt, 'modScheme = "psk";', 'modScheme = "qam";', 'once');
txt = regexprep(txt, 'filename = "[^"]*";', sprintf('filename = "%s";', f), 'once');
[y, x, phi] = evalRx(txt);
close("all");
end

function [y, x, phi] = evalRx(txt)
% Runs the receiver in its own workspace (its output is hidden).
evalc(txt);
y = symbolsDataReceived;
x = symbolsData;
end
