cl;

for iS = 1:6

    filename    = sprintf( 'd:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP/02-ter-p3Classification/LinSvm/subject_S%d/Results.txt', iS );
    temp        = dataset( 'File', filename, 'Delimiter', ',' );
    accDataSi   = temp( strcmp( temp.conditionTest, temp.conditionTrain ), : );
    accDataSi.condition = accDataSi.conditionTrain;
    accDataSi.conditionTrain = [];
    accDataSi.conditionTest = [];
   
    if iS == 1
        accData = accDataSi;
    else
        accData = cat(1, accData, accDataSi);
    end

end

% SST: total sum of squares
accData10Reps = accData( accData.nAverages==10, : );
sub = unique(accData10Reps.subject);
cond = unique(accData10Reps.condition);
gdMean      = mean( accData10Reps.accuracy );
gdVar       = var( accData10Reps.accuracy );
SST         = gdVar * ( size( accData10Reps, 1 ) - 1 );
SST_check   = sum( (accData10Reps.accuracy - gdMean).^2 );

% SSW: within participant sum of squares
meansPerSi  = cell2mat( cellfun(@(x) mean( accData10Reps.accuracy( ismember(accData10Reps.subject, x), : ) ), sub, 'UniformOutput', false ) );
varsPerSi   = cell2mat( cellfun(@(x) var( accData10Reps.accuracy( ismember(accData10Reps.subject, x), : ) ), sub, 'UniformOutput', false ) );
nPerSi      = cell2mat( cellfun(@(x) numel( accData10Reps.accuracy( ismember(accData10Reps.subject, x), : ) ), sub, 'UniformOutput', false ) );
SSW         = sum( varsPerSi .* ( nPerSi-1 ) );
dfW         = (numel(cond)-1)*(numel(sub));
SSW_check = 0;
for iS = 1:numel(sub)
    SSW_check = SSW_check + sum( (accData10Reps.accuracy( ismember(accData10Reps.subject, sub{iS}), : ) - meansPerSi(iS)).^2 );
end

% SSM: model sum of squares
meansPerCond    = cell2mat( cellfun(@(x) mean( accData10Reps.accuracy( ismember(accData10Reps.condition, x), : ) ), cond, 'UniformOutput', false ) );
nPerCond        = cell2mat( cellfun(@(x) numel( accData10Reps.accuracy( ismember(accData10Reps.condition, x), : ) ), cond, 'UniformOutput', false ) );
SSM             = sum( nPerCond.*(meansPerCond-gdMean).^2 );
dfM             = numel(cond) - 1;

% SSR: residual sum of squares
SSR = SSW - SSM;
dfR = dfW - dfM;

MSM = SSM/dfM;
MSR = SSR/dfR;

F = MSM/MSR;







