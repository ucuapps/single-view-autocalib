function [dr,G] = keep_only_valid(dr,G)
validG = ~isnan(G);
dr = dr(validG);
G = G(validG);