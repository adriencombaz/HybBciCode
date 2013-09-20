addpath('d:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\deps\');
addpath(genpath('d:\KULeuven\PhD\Matlab\MatlabPath\eeglab10_0_1_0b'));
sessionDir  = 'D:\KULeuven\PhD\Work\Hybrid-BCI\HybBciRecordedData\watchERP\2013-02-26-nikolay\';
filename    = '2013-02-26-11-06-49-hybrid-15Hz.bdf';
erpData     = eegDataset( sessionDir, filename );
erpData.tBeforeOnset = 0.2;
erpData.tAfterOnset = 0.8;
erpData.butterFilter(1, 30, 3);
cuts = erpData.getCuts();

i = 1;

plotEEGChannels( ...
    squeeze(cuts{1}(:,:,i)), ...
    'samplingRate', erpData.fs, ...
    'chanLabels', erpData.chanList ...
    )
