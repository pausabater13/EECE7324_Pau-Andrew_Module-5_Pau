function bits = symbolDemapping(symbols, M, modScheme, symOrder)
    %SYMBOLDEMAPPING Demodulates the symbols to bits (ML Detection).
    % It finds what of the possible M symbols has the minimum distance to the received symbol,
    % and obtains the corresponding bits (with gray coding).
    %
    % Input:
    %   symbols      Complex value symbols.
    %   M            Modulation order.
    %   modScheme    "psk" or "qam".
    %   symOrder     "gray" (default) or "bin".
    %
    % Output:
    %   bits         Data bits vector.

    if nargin < 4
        symOrder = "gray";
    end

    if strcmp(modScheme, "psk")
        bits = pskdemod(symbols, M, 0, symOrder, OutputType="bit");
    elseif strcmp(modScheme, "qam")
        % QAM decisions depend on the amplitude, so we first give the received symbols unit average
        % power, like the constellation (one real factor; no equalization until Module 6).
        symbols = symbols / sqrt(mean(abs(symbols).^2));
        bits = qamdemod(symbols, M, symOrder, OutputType="bit", UnitAveragePower=true);
    else
        error("Choose a valid modulation scheme.");
    end
end
