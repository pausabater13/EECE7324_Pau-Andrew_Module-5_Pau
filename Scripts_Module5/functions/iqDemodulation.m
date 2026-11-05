function r = iqDemodulation(y, fc, Fs, Rs)
    %IQDEMODULATION Generates the samples of the baseband signal.
    %
    % Input:
    %   y     Samples of the IF signal.
    %   Fc    Normalized carrier frequency (RF or IF).
    %   B     Normalized bandwidth.
    %
    % Output:
    %   r     Complex baseband samples.

    n = (0 : numel(y) - 1).';                            % Sample vector.
    B= 1.75 * Rs / Fs;
    r = lowpass(2 * y .* exp(-1j * 2 * pi * fc * n / Fs), B); % IQ demodulation.
end
