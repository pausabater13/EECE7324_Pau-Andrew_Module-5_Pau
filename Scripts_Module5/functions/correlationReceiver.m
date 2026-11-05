function symbols = correlationReceiver(r, sps, nSymbols)
    %CORRELATIONRECEIVER Does the correlation, i.e. inner product of the received signal with the pulse shape.
    %
    % Input:
    %   r           [samples] Received signal.
    %   sps         [Sa/symbol] Number of samples per symbol.
    %   nSymbols    Number of symbols.
    %
    % Output:
    %   symbols     [symbols] Complex value received symbols.

    pulse = rcosdesign(0.75, 10, sps); % [samples] Design a square root raised cosine filter.

    nPulseSamples = numel(pulse);  % Number of samples per pulse.

    symbols = zeros(nSymbols, 1);
    for iSymbol = 1 : nSymbols
        ySymbol = r((1 : nPulseSamples) + (iSymbol - 1) * sps);

        symbols(iSymbol) = pulse * ySymbol; % Correlator receiver.
    end
end
