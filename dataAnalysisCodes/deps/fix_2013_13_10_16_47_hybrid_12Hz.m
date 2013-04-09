function newStatChan = fix_2013_13_10_16_47_hybrid_12Hz(varargin)

if isempty( varargin )
    fullfilename = 'd:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\2013-03-13-adrien\2013-03-13-10-16-47-hybrid-12Hz.bdf';
else
    fullfilename = varargin{1};
end

hdr             = sopen( fullfilename );
statusChannel   = bitand( uint32(hdr.BDF.ANNONS), uint32(255) );
% statusChannel   = bitand( uint32(hdr.BDF.ANNONS), uint32(15) );

% plotBitWise( statusChannel );
% set( gcf, 'name', 'original status channel' );


%% fix the experiment start/stop bit (bit 00)
expCh = logical( bitand( statusChannel, uint32(1) ) );
expStart = find( diff( expCh ) == 1, 1, 'first' ) + 1;
expEnd = find( diff( expCh ) == -1, 1, 'last' ) + 1;
newExpCh = expCh;
newExpCh(expStart:expEnd) = uint32(1);



%% fix the ssvep bit (bit 02)
ssvepCh     = logical( bitand( statusChannel, uint32(4) ) );
listUp      = find( diff( ssvepCh ) == 1 ) + 1;
listDown    = find( diff( ssvepCh ) == -1 ) + 1;
listUp( listUp < expStart ) = [];
listUp( listUp > expEnd ) = [];
listDown( listDown < expStart+1 ) = [];
listDown( listDown > expEnd ) = [];


if numel( listUp ) ~= numel( listDown )
    error('there should be as many ups as downs');
end
if find( listDown-listUp ) <= 0
    error('up should be first');
end

p3Chan = logical( bitand( statusChannel, uint32(8) ) );
newSsvepChan = ssvepCh;
for iBlock = 1:numel( listUp )
    if sum( p3Chan( listUp(iBlock):listDown(iBlock) ) ) == 0
        newSsvepChan( listUp(iBlock):listDown(iBlock) ) = uint32(0);
    end
end

newSsvepChan( newExpCh == 0 ) = 0;

%% inject the new values
newStatChan = uint32( zeros( size( statusChannel ) ) );

nBits = ceil( log2( max( double(statusChannel) ) ) );

for iBit = 1:nBits
    
    if iBit == 1     % experiment start/stop bit
        newStatChan = newStatChan + uint32( newExpCh * 2^(iBit-1) );
    elseif iBit == 3 % ssvep bit
        newStatChan = newStatChan + uint32( newSsvepChan * 2^(iBit-1) );
    else
        originalChan = logical( bitand( statusChannel, uint32(2^(iBit-1)) ) );
        newStatChan = newStatChan + uint32( originalChan * 2^(iBit-1) );
    end
    
end
% plotBitWise( newStatChan );
% set( gcf, 'name', 'fixed status channel' );

end
