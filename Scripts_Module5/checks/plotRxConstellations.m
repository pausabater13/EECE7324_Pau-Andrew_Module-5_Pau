function plotRxConstellations()
%PLOTRXCONSTELLATIONS Our script (Step 12). Runs receiverSC.m on the Gray captures of Step 6,
% plots the received data constellations (wired and wireless) with the ideal points, and prints,
% for each capture, the phase estimated from the header, the residual phase drift along the
% data, and how much the received symbols spread along the circle (phase) and across it
% (amplitude). The received symbols are only divided by their mean amplitude, a single real
% factor for each capture, so that they can be drawn on top of the ideal points.

root = fullfile(fileparts(mfilename("fullpath")), "..");   % Scripts_Module5
oldDir = cd(root);
cleanup = onCleanup(@() cd(oldDir));

src = fileread("receiverSC.m");
Ms = [2 4 8 16 32];
sets = ["wired", "6a"; "wireless", "6b"];
for s = 1:2
    % Run the receiver first: it closes all figures when it starts.
    Y = cell(1, numel(Ms)); X = Y; PHI = zeros(1, numel(Ms));
    for k = 1:numel(Ms)
        file = sprintf("captures/%s/%s_%dpsk_gray.mat", sets(s, 1), sets(s, 2), Ms(k));
        [Y{k}, X{k}, PHI(k)] = runRx(src, Ms(k), "gray", file);
    end

    f0 = figure(Visible="off", Units="centimeters", Position=[0 0 30 6.5]);
    t = tiledlayout(f0, 1, numel(Ms), TileSpacing="compact", Padding="compact");
    for k = 1:numel(Ms)
        M = Ms(k); x = X{k}; phi = PHI(k);
        y = Y{k} / mean(abs(Y{k}));                % One real factor for the whole capture.
        e = (y - x) .* conj(x);                    % Error, rotated so that x is at 0 degrees.
        tang = rad2deg(std(angle(y .* conj(x))));  % Spread along the circle [deg].
        rad = std(real(e));                        % Spread across the circle.
        drift = polyfit((1:numel(y)).', unwrap(angle(y .* conj(x))), 1);
        fprintf("%-8s M=%2d: header phase %6.1f deg, drift %+.4f deg/symbol, " + ...
            "spread along %.2f deg (%.0f%% of half sector), across %.3f\n", sets(s, 1), M, ...
            rad2deg(phi), rad2deg(drift(1)), tang, 100 * tang / (180/M), rad);

        ax = nexttile(t);
        plot(ax, real(y), imag(y), ".", MarkerSize=5); hold(ax, "on");
        ref = pskmod((0:M-1).', M, 0, "gray");
        plot(ax, real(ref), imag(ref), "r+", MarkerSize=8, LineWidth=1);
        axis(ax, "equal"); grid(ax, "on"); xlim(ax, [-1.4 1.4]); ylim(ax, [-1.4 1.4]);
        title(ax, sprintf("%d-PSK", M)); xlabel(ax, "I"); ylabel(ax, "Q");
    end
    out = fullfile(root, "..", "figures", "rx_psk_" + sets(s, 1) + ".pdf");
    exportgraphics(f0, out, ContentType="vector");
    fprintf("Saved %s\n", out);
end
end

function [y, x, phi] = runRx(src, M, o, f)
txt = regexprep(src, 'M = 2;', sprintf('M = %d;', M), 'once');
txt = regexprep(txt, 'symOrder = "gray";', sprintf('symOrder = "%s";', o), 'once');
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
