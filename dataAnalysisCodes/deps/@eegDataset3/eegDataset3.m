classdef eegDataset3 < handle
    
    properties
        
        sig             = []; % nTimeSteps by nChan double array
        eventPos        = []; % 1-D array, index of each event
        % (points to the corresponding sample of eeg)
        chanList        = {};
        nChan           = NaN;
        chanLocs        = [];
        icaWeights      = [];
        icaWinv         = [];
        keepReject      = []; % 1-D array, for each event keep (=1) or reject (=0)
        
        refChanNames    = {'EXG1', 'EXG2'};
        discardChanNames= {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};
        eegChanInd      = [];
        extChanInd      = [];
        tBeforeOnset    = 0.2; % lower time range in secs
        tAfterOnset     = 0.8; % upper time range in secs
        fs              = NaN;
        locFile         = 'eloc32-biosemi.locs';
        
    end
    
    methods
        
        %% ====================================================================================================================
        %% ====================================================================================================================
        function obj = eegDataset3( sessionDir, bdfFileName, varargin )
            
            %% Parse input parameters
            
            % default values
            onsetEventValue = 4; % DEFAULT VALUE
            
            %
            if ~isempty(varargin)
                nParams = numel(varargin) / 2;
                if round(nParams) ~= nParams, error('eegDataset3:eegDataset3', 'parameters must go by pairs!'); end
                paramNames = varargin(1:2:end);
                if ~iscellstr( paramNames ), error('eegDataset3:eegDataset3', 'the name of the parameters must be specified as a string, before their value'); end
                paramValues = varargin(2:2:end);
                
                %
                if nParams >= 1
                    for iPar = 1:nParams
                        if strcmp( paramNames{iPar}, 'onsetEventValue')
                            onsetEventValue = paramValues{iPar};
                        else
                            error('eegDataset3:eegDataset3', 'parameter %s not recognized', paramNames{iPar});
                        end
                    end
                end
            end
            
            %% Load eeg data
            
            hdr             = sopen( fullfile(sessionDir, bdfFileName) );
            [obj.sig hdr]   = sread(hdr);
            fclose(hdr.FILE.FID);
            statusChannel   = bitand(hdr.BDF.ANNONS, 255);
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
            eventChan       = logical( bitand( statusChannel, onsetEventValue ) );
            obj.eventPos    = find( diff( eventChan ) == 1 ) + 1;
            obj.keepReject = ones( size( obj.eventPos ) );
            
            
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
        function meanCut = getMeanCut( obj, varargin )
            
            [sumCut nCuts] = obj.getSumCut( varargin );
            meanCut = sumCut / nCuts;
            
        end
        
        %% ====================================================================================================================
        %% ====================================================================================================================
        function [sumCut nCuts] = getSumCut( obj, varargin )
            
            %% Parse input parameters
            
            % default values
            source = 0;
            epochInds = 1:numel(obj.eventPos);
            
            %
            if ~isempty(varargin)
                nParams = numel(varargin) / 2;
                if round(nParams) ~= nParams, error('eegDataset3:getSumCut', 'parameters must go by pairs!'); end
                paramNames = varargin(1:2:end);
                if ~iscellstr( paramNames ), error('eegDataset3:getSumCut', 'the name of the parameters must be specified as a string, before their value'); end
                paramValues = varargin(2:2:end);
                
                %
                if nParams >= 1
                    for iPar = 1:nParams
                        if strcmp( paramNames{iPar}, 'source')
                            if ( paramValues{iPar} == 0 || paramValues{iPar} == 1 )
                                source = paramValues{iPar};
                            else
                                error('eegDataset3:getSumCut', '''source'' must be 0 or 1');
                            end
                        elseif strcmp( paramNames{iPar}, 'epochInds')
                            if isnumeric( paramValues{iPar} ) ...
                                    && sum(size( paramValues{iPar} )) == numel( paramValues{iPar} ) + 1 ...
                                    && min( paramValues{iPar} ) >= 1 && max( paramValues{iPar} ) <= numel( obj.eventPos )
                                epochInds = paramValues{iPar};
                            else
                                error('eegDataset3:getSumCut', 'Invalid ''epochInds'' argument');
                            end
                        else
                            error('eegDataset3:getSumCuts', 'parameter %s not recognized', paramNames{iPar});
                        end
                    end
                end
            end
            
            
            %% sum the cuts
            nl      = round( obj.tBeforeOnset*obj.fs );
            nh      = round( obj.tAfterOnset*obj.fs );
            range   = nh+nl+1;
            
            if source
                sumCut = zeros(range, numel(obj.chanLocs));
            else
                sumCut = zeros(range, obj.nChan);
            end
            events = obj.eventPos( epochInds );
            events = events( obj.keepReject(epochInds) == 1 );
            for i = 1:numel(events)
                if source
                    %                     meanCut = meanCut + ( obj.icaWeights * obj.sig( (events(i)-nl) : (events(i)+nh), : )' )';
                    sumCut = sumCut + obj.sig( (events(i)-nl) : (events(i)+nh), obj.eegChanInd ) * obj.icaWeights';
                else
                    sumCut = sumCut + obj.sig( (events(i)-nl) : (events(i)+nh), : );
                end
            end
            nCuts   = numel(events);
            
        end
        
        %% ====================================================================================================================
        %% ====================================================================================================================
        function cuts = getCuts( obj, varargin )
            
            %% Parse input parameters
            
            % default values
            source = 0;
            epochInds = 1:numel(obj.eventPos);
            
            %
            if ~isempty(varargin)
                nParams = numel(varargin) / 2;
                if round(nParams) ~= nParams, error('eegDataset3:getMeanCut', 'parameters must go by pairs!'); end
                paramNames = varargin(1:2:end);
                if ~iscellstr( paramNames ), error('eegDataset3:getMeanCut', 'the name of the parameters must be specified as a string, before their value'); end
                paramValues = varargin(2:2:end);
                
                %
                if nParams >= 1
                    for iPar = 1:nParams
                        if strcmp( paramNames{iPar}, 'source')
                            if ( paramValues{iPar} == 0 || paramValues{iPar} == 1 )
                                source = paramValues{iPar};
                            else
                                error('eegDataset3:getMeanCut', '''source'' must be 0 or 1');
                            end
                        elseif strcmp( paramNames{iPar}, 'epochInds')
                            if isnumeric( paramValues{iPar} ) ...
                                    && sum(size( paramValues{iPar} )) == numel( paramValues{iPar} ) + 1 ...
                                    && min( paramValues{iPar} ) >= 1 && max( paramValues{iPar} ) <= numel( obj.eventPos )
                                epochInds = paramValues{iPar};
                            else
                                error('eegDataset3:getMeanCut', 'Invalid ''epochInds'' argument');
                            end
                        else
                            error('eegDataset3:getMeanCut', 'parameter %s not recognized', paramNames{iPar});
                        end
                    end
                end
            end
            
            
            nl      = round( obj.tBeforeOnset*obj.fs );
            nh      = round( obj.tAfterOnset*obj.fs );
            range   = nh+nl+1;
            
            events = obj.eventPos( epochInds );
            events = events( obj.keepReject(epochInds) == 1 );
            
            if source
                cuts   = zeros( range, numel(obj.chanLocs), numel(events) );
            else
                cuts   = zeros( range, obj.nChan, numel(events) );
            end
            
            for i = 1:numel(events)
                if source
                    cuts(:,:,i) = obj.sig( (events(i)-nl) : (events(i)+nh), obj.eegChanInd ) * obj.icaWeights';
                else
                    cuts(:,:,i) = obj.sig( (events(i)-nl) : (events(i)+nh), : );
                end
            end
            
        end
        
        %% ====================================================================================================================
        %% ====================================================================================================================
        function computeIcaWeight( obj )
            
            obj.icaWeights = jader( obj.sig( :,obj.eegChanInd )' );
            obj.icaWinv = pinv( obj.icaWeights );
            
        end
        
        %% ====================================================================================================================
        %% ====================================================================================================================
        function plotMeanCut( obj, varargin )
            
            if ~isempty( varargin )
                if strcmp(varargin, 'source')
                    meanCut = getMeanCut( obj, 'source' );
                    compLabels = cellfun(@(x) sprintf('comp%.2d', x), num2cell(1:size( obj.icaWeights, 1)), 'UniformOutput', false);
                end
            else
                meanCut = getMeanCut( obj );
                compLabels = obj.chanList;
            end
            
            plotERPsFromCutData2( ...
                meanCut, ...
                'samplingRate', obj.fs, ...
                'chanLabels', compLabels, ...
                'timeBeforeOnset', obj.tBeforeOnset, ...
                'nMaxChanPerAx', 10, ...
                'axisOfEvent', [1 1], ...
                'legendStr',  obj.eventLabel, ...
                'scale', 8, ...
                'title', 'meanERPs' ...
                );
            
            
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
                if ~isempty( find(obj.keepReject==0, 1) )
                    plotEEGChannels( ...
                        obj.sig, ...
                        'eventLoc', obj.eventPos, ...
                        'eventType', obj.eventId, ...
                        'samplingRate', obj.fs, ...
                        'chanLabels', obj.chanList, ...
                        'indEvColorTrace', find(obj.keepReject==0) ...
                        )
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
        
        
        
        %% ====================================================================================================================
        %% ====================================================================================================================
        function markEpochsForRejection( obj, criteria, decision, decisionValue, varargin )
            
            
            %% Parse input parameters
            
            % default values
            epochInds = 1:numel(obj.eventPos);
            
            %
            if ~isempty(varargin)
                nParams = numel(varargin) / 2;
                if round(nParams) ~= nParams, error('eegDataset3:markEpochsForRejection', 'parameters must go by pairs!'); end
                paramNames = varargin(1:2:end);
                if ~iscellstr( paramNames ), error('eegDataset3:markEpochsForRejection', 'the name of the parameters must be specified as a string, before their value'); end
                paramValues = varargin(2:2:end);
                
                %
                if nParams >= 1
                    for iPar = 1:nParams
                        if strcmp( paramNames{iPar}, 'epochInds')
                            if isnumeric( paramValues{iPar} ) ...
                                    && sum(size( paramValues{iPar} )) == numel( paramValues{iPar} ) + 1 ...
                                    && min( paramValues{iPar} ) >= 1 && max( paramValues{iPar} ) <= numel( obj.eventPos )
                                epochInds = paramValues{iPar};
                            else
                                error('eegDataset3:markEpochsForRejection', 'Invalid ''epochInds'' argument');
                            end
                        else
                            error('eegDataset3:markEpochsForRejection', 'parameter %s not recognized', paramNames{iPar});
                        end
                    end
                end
            end
            
            %%
            
            obj.keepReject(epochInds) = 1;
            nl      = round( obj.tBeforeOnset*obj.fs );
            nh      = round( obj.tAfterOnset*obj.fs );
            range   = nh+nl+1;
                        
            % compute criteria values
            values      = zeros( numel(epochInds), 1 );
            events      = obj.eventPos( epochInds );
            
            switch criteria
                case 'minMax'
                    for i = 1:numel( events )
                        cut         = obj.sig( (events(i)-nl) : (events(i)+nh), : );
                        values(i)   = max( max(cut, [], 1) - min(cut, [], 1) );
                    end
                    
                case 'meanDev'
                    meanCut = zeros(range, obj.nChan);
                    for i = 1:numel(events)
                        meanCut = meanCut + obj.sig( (events(i)-nl) : (events(i)+nh), : );
                    end
                    meanCut = meanCut / numel(events);
                    
                    stdCut = zeros(range, obj.nChan);
                    for i = 1:numel(events)
                        stdCut = stdCut + ...
                            ( obj.sig( (events(i)-nl) : (events(i)+nh), : ) - meanCut ) .* ...
                            ( obj.sig( (events(i)-nl) : (events(i)+nh), : ) - meanCut );
                    end
                    stdCut = sqrt( stdCut ./ (numel(events)-1) );
                    
                    for i = 1:numel( events )
                        cut       = obj.sig( (events(i)-nl) : (events(i)+nh), : );
                        temp      = abs(cut - meanCut)./stdCut;
                        values(i) = max( temp(:) );
                    end
                    
                case 'medianDev'
                    
                    fctpath = which('quantile');
                    if isempty( strfind(fctpath, matlabroot) )
                        rmpath(fileparts(fctpath));
                    end
                    medianCut   = zeros(range, obj.nChan);
                    q1Cut       = zeros(range, obj.nChan);
                    q3Cut       = zeros(range, obj.nChan);
                    iqrCut      = zeros(range, obj.nChan);
                    
                    %-%-% this block can be more compact (faster? maybe) 2.63 sec
%                     tic
                    for it = -nl:1:nh
                        temp = zeros(numel(events) , obj.nChan);
                        for iEv = 1:numel(events)
                            temp(iEv, :) = obj.sig( events(iEv)+it, : );
                        end
                        medianCut(it+nl+1, :) = median(temp, 1);
                        iqrCut(it+nl+1, :)    = iqr(temp, 1);
                        q1Cut(it+nl+1, :)     = quantile(temp, .25, 1);
                        q3Cut(it+nl+1, :)     = quantile(temp, .75, 1);
                    end
%                     toc
%                     %-%-% alternative way (more memory demanding) 1.64 secs (not worth spending the memory)
%                     tic
%                     temp = zeros( range, obj.nChan, numel(events));
%                     for iEv = 1:numel(events)
%                         temp(:, :, iEv) = obj.sig( (events(iEv)-nl) : (events(iEv)+nh), : );
%                     end
%                     medianCut2  = median(temp, 3);
%                     iqrCut2     = iqr(temp, 3);
%                     q1Cut2      = quantile(temp, .25, 3);
%                     q3Cut2      = quantile(temp, .75, 3);
%                     toc
%                     -%-%
%                     
%                     -%-% THIS ONE IS TIME CONSUMING !!! (~0.23 secs * numel(events))
%                     tic
%                     for iEv = 1:numel(events)
%                         %                             tic
%                         temp = 0;
%                         for it = -nl:1:nh
%                             for iCh = 1:obj.nChan
%                                 if obj.sig( events(iEv)+it, iCh ) > q3Cut(it+nl+1, iCh)
%                                     temp = max(temp, ( obj.sig( events(iEv)+it, iCh ) - q3Cut(it+nl+1, iCh) ) /  iqrCut(it+nl+1, iCh) );
%                                 elseif obj.sig( events(iEv)+it, iCh ) < q1Cut(it+nl+1, iCh)
%                                     temp = max(temp, ( q1Cut(it+nl+1, iCh) - obj.sig( events(iEv)+it, iCh ) ) /  iqrCut(it+nl+1, iCh) );
%                                 end % otherwise just leave to 0 (wanna keep at least 50% of the data)
%                             end
%                         end
%                         values(iEv) = temp;
%                         %                             toc
%                     end
%                     toc
%                     -%-% ALTERNATIVE: take the distance to the median, instead of the distance to the closest quartile (still dividde it by the IQR)
%                     tic
                    for iEv = 1:numel(events)
                        temp = obj.sig( (events(iEv)-nl) : (events(iEv)+nh), : );
                        temp = (temp - medianCut) ./ iqrCut;
                        values(iEv) = max(temp(:));
                    end
%                     toc
                    
                    addpath(fileparts(fctpath));
                    
                otherwise
                    error('markEpochsForRejection:UnknownParameterName', ...
                        'Unknown parameter name %s.', criteria );
            end
            
            %
            toReject = false( numel(values), 1 );
            
            switch decision
                case 'threshold'
                    toReject( values > decisionValue ) = true;
                    obj.keepReject( epochInds( toReject ) ) = 0;
                    
                    fprintf( 'event %s, %s rejection method, threshold = %g, %d out of %d epochs rejected.\n', ...
                        obj.eventLabel{iEVT}, criteria, decisionValue, sum(toReject), numel(toReject) );
                    
                case 'proportion'
                    
                    if decisionValue >= 1 || decisionValue <= 0
                        error('markEpochsForRejection:WrongParameterValue', ...
                            'Wrong parameter value %s.', decisionValue );
                    end
                    [sortedValues indSorted]    = sort(values, 'descend');
                    nToReject                   = round(decisionValue * numel(values));
                    toReject( indSorted(1:nToReject) )      = true;
                    obj.keepReject( epochInds( toReject ) )   = 0;
                    
                    fprintf( '%s rejection method, %d out of %d epochs rejected, max value kept = %g.\n', ...
                        criteria, nToReject, numel(toReject), sortedValues(nToReject+1) );
                    
                otherwise
                    error('markEpochsForRejection:UnknownParameterName', ...
                        'Unknown parameter name %s.', decision );
            end
            
            
        end % OF MARKEPOCHSFORREJECTION FUNCTION
        
        %% ====================================================================================================================
        %% ====================================================================================================================
        
    end
    
end