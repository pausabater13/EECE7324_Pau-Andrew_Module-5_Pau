function demodNearest()
%DEMODNEAREST Our script (Step 9). Checks that pskdemod() returns the constellation point that
% is closest to each received symbol (minimum distance), for both symbol orders, and that the
% amplitude of the received symbols does not change the decision.

rng(0); % Same random symbols every time.
for M = [2 4 8 16 32]
    for o = ["gray", "bin"]
        ref = pskmod((0:M-1).', M, 0, o);                    % Point of each integer value.
        y = 3 * (randn(1e4, 1) + 1j*randn(1e4, 1));            % Random received symbols.
        [~, k] = min(abs(y - ref.'), [], 2);                   % Closest point.
        zNearest = k - 1;
        z = pskdemod(y, M, 0, o);
        zScaled = pskdemod(0.01 * y, M, 0, o);                 % Same symbols, 100 times smaller.
        fprintf("M=%2d %-4s: same as closest point %d, same after scaling %d\n", ...
            M, o, isequal(z, zNearest), isequal(z, zScaled));
    end
end
end
