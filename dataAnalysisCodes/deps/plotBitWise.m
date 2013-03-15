function plotBitWise( annons )

nBits = ceil( log2( max( annons ) ) );

if nBits < 32,
    annons = uint32( annons );
elseif nBits < 64,
    annons = uint64( annons );
else
    error(' nBits >= 64 !!');
end

figure,
hold on
ySpacing  = 2;
x = 1:numel(annons);
yticks = ySpacing:ySpacing:nBits*ySpacing;
ytickLabel = cell(1, nBits);
ylim = [0 (nBits+1)*ySpacing];

for iBit = 1:nBits
    
    bin = logical( bitand( annons, 2^(iBit-1) ) );
    plot(x, bin + iBit*ySpacing);
    
    ytickLabel{iBit} = sprintf('bit %.2d', iBit-1);
    
end

set(gca, ...
    'Ylim', ylim, ...
    'YTick', yticks, ...
    'YTickLabel', ytickLabel ...
    );


end