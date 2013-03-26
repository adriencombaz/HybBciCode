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

scVals = unique(annons);
scVals( scVals == 0 ) = [];

yticks = [ 0 double(scVals)' double(max(annons)) + (ySpacing:ySpacing:nBits*ySpacing) ];
ytickLabel = cell(1, nBits+1+numel(scVals));
ylim = [0 max( annons )+(nBits+1)*ySpacing];

ytickLabel{1} = 'statChan';
for i = 1:numel(scVals)
    plot([x(1) x(end)],[scVals(i) scVals(i)], 'k:')
    ytickLabel{i+1} = num2str(scVals(i));
end
plot(x, annons);

% yticks = ySpacing:ySpacing:nBits*ySpacing;
% ytickLabel = cell(1, nBits);
% ylim = [0 (nBits+1)*ySpacing];


for iBit = 1:nBits
    
    bin = logical( bitand( annons, 2^(iBit-1) ) );
    plot(x, double(bin) + double(max( annons )+iBit*ySpacing));
    
    ytickLabel{iBit+numel(scVals)+1} = sprintf('bit %.2d', iBit-1);
    
end

set(gca, ...
    'Ylim', ylim, ...
    'YTick', yticks, ...
    'YTickLabel', ytickLabel ...
    );


end