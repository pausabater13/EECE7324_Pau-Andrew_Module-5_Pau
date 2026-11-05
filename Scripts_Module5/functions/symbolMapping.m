function symbols = symbolMapping(bits, M, modScheme, symOrder)
    %SYMBOLMAPPING Maps the array of bits into complex value symbols.
    %
    % Inputs:
    %   bits         Bits array.
    %   M            Modulation order.
    %   modScheme    "PSK" or "QAM".
    %   symOrder     "gray" (default) or "bin".
    %
    % Outputs:
    %   symbols      Complex value symbols.

    if nargin < 4
        symOrder = "gray";
    end

    if strcmp(modScheme, "psk")
        symbols = pskmod(bits, M, 0, symOrder, InputType="bit");
    elseif strcmp(modScheme, "qam")
        symbols = qammod(bits, M, symOrder, InputType="bit", UnitAveragePower=true); % Average power 1, as pskmod.
    else
        error("Choose a valid modulation scheme.");
    end
end
