classdef eegDataset2 < handle
   
    properties
        
        sig             = [];
        eventPos        = [];
        eventId         = [];
        chanList        = {};
        nChan           = NaN;
        chanLocs        = [];
        icaWeights      = [];
        icaWinv         = [];
        
        refChanNames    = {'EXG1', 'EXG2'};
        discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};
        eegChanInd      = [];
        extChanInd      = [];
        fs              = NaN;
        locFile         = 'eloc32-biosemi.locs';
        
    end
    
    methods
    
        %% ====================================================================================================================
        %% ====================================================================================================================
        function obj = eegDataset2( sessionDir, bdfFileName )
            
            %%
%             paramFileName   = [bdfFileName(1:19) '.mat'];
%             expParams       = load( fullfile(sessionDir, paramFileName) );
%             expParams.scenario = rmfield(expParams.scenario, 'textures');

            hdr             = sopen( fullfile(sessionDir, bdfFileName) );
            [obj.sig hdr]   = sread(hdr);
            fclose(hdr.FILE.FID);
            statusChannel   = bitand( uint32(hdr.BDF.ANNONS), uint32(255) );
            hdr.BDF         = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
            obj.fs          = hdr.SampleRate;
            
            obj.chanList	= hdr.Label;
            obj.chanList(strcmp(obj.chanList, 'Status')) = [];
            discardChanInd  = cell2mat( cellfun( @(x) find(strcmp(obj.chanList, x)), obj.discardChanNames, 'UniformOutput', false ) );
            obj.chanList(discardChanInd) = [];
            refChanInd      = cell2mat( cellfun( @(x) find(strcmp(obj.chanList, x)), obj.refChanNames, 'UniformOutput', false ) );
            obj.nChan       = numel(obj.chanList);
            
            %%
            
            %% preprocess (discard unused channels, reference)            
            obj.sig(:, discardChanInd)  = [];
            obj.sig = bsxfun( @minus, obj.sig, mean( obj.sig(:,refChanInd) , 2 ) );

            
            %% reorder channels so that it matches the order from the .locs file
            obj.chanLocs    = readlocs(obj.locFile, 'filetype', 'loc');
            nChansToReorder = numel( obj.chanLocs );
            if sum( ismember( obj.chanList(1:nChansToReorder), {obj.chanLocs.labels} ) ) ~= nChansToReorder
                error('the %d first channel labels do not match with the reordered channels list', nChansToReorder)
            end
            
            iCh         = cell2mat(cellfun(@(x) find(strcmp(obj.chanList, x)), {obj.chanLocs.labels}, 'UniformOutput', false));
            obj.sig     = [obj.sig(:,iCh) obj.sig(:, nChansToReorder+1:end)];
            obj.chanList= [{obj.chanLocs.labels}' ; obj.chanList(nChansToReorder+1:end)];
            
            obj.eegChanInd = sort(iCh);
            obj.extChanInd = 1:obj.nChan;
            obj.extChanInd(ismember(obj.extChanInd, obj.eegChanInd)) = [];
            
            %% collect event information
            statusChannel = double(statusChannel);
            obj.eventPos    = find( diff( statusChannel ) ) + 1;
            obj.eventId     = abs( statusChannel( obj.eventPos ) - statusChannel( obj.eventPos - 1) );
            
        end

        %% ====================================================================================================================
        %% ====================================================================================================================
        function butterFilter( obj, lowMargin, highMargin, order )
            
            [a b] = butter(order, [lowMargin highMargin]/(obj.fs/2));
            for i = 1:size(obj.sig, 2)
                obj.sig(:,i) = filtfilt( a, b, obj.sig(:,i) );
            end

        end
        
        %% ====================================================================================================================
        %% ====================================================================================================================
        function zeroMeanSignal( obj )
            
            obj.sig = bsxfun(@minus, obj.sig, mean(obj.sig, 1));
            
        end
        

        
        %% ====================================================================================================================
        %% ====================================================================================================================
        function computeIcaWeight( obj )
            
            obj.icaWeights = jader( obj.sig( :,obj.eegChanInd )' );
            obj.icaWinv = pinv( obj.icaWeights );
            
        end
    
        %% ====================================================================================================================
        %% ====================================================================================================================
        function plotContinuousSignal( obj, varargin )
            
            if ~isempty( varargin ) 
                if strcmp(varargin, 'source')
                    plotEEGChannels( ...
                        obj.sig(:, obj.eegChanInd) * obj.icaWeights', ...
                        'eventLoc', obj.eventPos, ...
                        'eventType', obj.eventId, ...
                        'samplingRate', obj.fs, ...
                        'chanLabels', cellfun(@(x) sprintf('comp%.2d', x), num2cell(1:size( obj.icaWeights, 1)), 'UniformOutput', false) ...
                        )
                end
            else
                plotEEGChannels( ...
                    obj.sig, ...
                    'eventLoc', obj.eventPos, ...
                    'eventType', obj.eventId, ...
                    'samplingRate', obj.fs, ...
                    'chanLabels', obj.chanList ...
                    )
            end
            
        end
        
        %% ====================================================================================================================
        %% ====================================================================================================================
        function topoplotSourceDist( obj )
            
            if isempty( obj.icaWeights )
                error('please compute the ICA weight before trying to see the source signals');
            end
            
            nSource = size( obj.icaWeights, 1);
            nRows = floor( sqrt( nSource ) );
            nCols = ceil( nSource / nRows );
            
            figure;
            for iComp = 1:nSource
                axh = subplot(nRows, nCols, iComp);
                set(axh, 'visible', 'off');
                topoplot( obj.icaWinv(:, iComp), obj.chanLocs );
%                 set(axh, 'CLim', [ min(obj.icaWeights(:)) max(obj.icaWeights(:)) ])
                title( iComp );
            end
%             cbar;          
            
        end
        
    end
    
end