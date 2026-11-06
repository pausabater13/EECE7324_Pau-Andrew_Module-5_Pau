function errorBounds()
%ERRORBOUNDS Our script (Step 11). Exact (Clopper-Pearson) 95% confidence intervals of the SER
% for the symbol errors we measured over the air (300 symbols per capture), and the bound for 0
% errors. Only base MATLAB (betaincinv), no toolbox needed.

n = 300;
for k = [0 3 23]
    if k == 0
        lo = 0;
    else
        lo = betaincinv(0.025, k, n - k + 1);
    end
    hi = betaincinv(0.975, k + 1, n - k);
    fprintf("%2d errors of %d symbols: SER between %.2f %% and %.2f %% (95%%)\n", k, n, 100*lo, 100*hi);
end
end
