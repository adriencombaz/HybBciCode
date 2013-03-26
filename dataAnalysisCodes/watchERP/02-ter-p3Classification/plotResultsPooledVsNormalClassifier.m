function plotResultsPooledVsNormalClassifier

%     fileList = ls('Results*.txt');
%
%     for iF = 1:size(fileList, 1)
%
%         showPlotResults(fileList(iF,:));
%
%     end

%     showPlotResults('resultsSPMD.mat');
iS = 1;
showPlotResults(iS);

end

function showPlotResults(iSList)

LW = 2;
MS = 6;
FS = 9;
fWidth = 25;
fHeight = 16;
cmap = colormap; close(gcf);
nCmap = size(cmap, 1);

lineStyles  = {'--', ':', '-.', '-.', '--'};
markers     = {'o', 's', '^', 'd', 'v'};

figure('Units', 'centimeters', 'Position', [1 1 fWidth fHeight]);

for iS = 1:numel(iSList)
    
    datafile1 = fullfile( sprintf('d:\\KULeuven\\PhD\\Work\\Hybrid-BCI\\HybBciProcessedData\\watch-ERP\\02-ter-p3Classification\\LinSvm\\subject_S%d\\', iSList(iS)), 'Results.txt' );
    datafile2 = fullfile( sprintf('d:\\KULeuven\\PhD\\Work\\Hybrid-BCI\\HybBciProcessedData\\watch-ERP\\02-ter-p3Classification\\LinSvmPooled\\subject_S%d\\', iSList(iS)), 'Results.txt' );
    
    results1 = dataset('File', datafile1, 'Delimiter' ,',');
    results1 = results1( cellfun(@isequal, results1.conditionTrain, results1.conditionTest), : );
    results1.condition  = results1.conditionTrain;
    results1.conditionTrain = [];
    results1.conditionTest = [];
    results1( ismember( results1.condition, 'oddball' ), : ) = [];
    results2 = dataset('File', datafile2, 'Delimiter' ,',');
    results2.condition  = results2.conditionTest;
    results2.conditionTest = [];
    results2( ismember( results2.condition, 'oddball' ), : ) = [];
    
    if size(results1, 1) ~= size(results2, 1)
        error('different amount of data in each file');
    end
    if ~isequal( unique(results1.condition), unique(results2.condition) )
        error('different conditions in both files');
    end
    
    subs = unique(results1.subject);
    %     nSub = numel(subs);
    conds = unique(results1.condition);
    nCond = numel(conds);
    legendStr   = cell(2*nCond, 1);
    colorList = zeros(nCond, 3);
    for i = 1:nCond
        colorList(i, :) = cmap( round((i-1)*(nCmap-1)/(nCond-1)+1) , : );
    end
    
    %% Per subject
    if numel(iSList) > 1
        subplot(2, ceil(numel(iSList)/2), iS);%, 'YGrid', 'on')
    end
    hold on
    for iC = 1:nCond
        
        data = results1( ismember( results1.subject, subs{iS} ) & ismember( results1.condition, conds{iC} ), : );
        [x IX] = sort( data.nAverages, 'ascend' );
        y = data.accuracy;
        y = y(IX);
        %             plot(x, y, '-+', 'color', colors{iC} )
        plot(x, y ...
            , 'LineStyle', lineStyles{1} ...
            , 'Color', colorList(iC, :) ...
            , 'LineWidth', LW ...
            , 'Marker', markers{1} ...
            , 'MarkerFaceColor', colorList(iC, :) ...
            , 'MarkerEdgeColor', colorList(iC, :) ...
            , 'MarkerSize', MS ...
            );
        legendStr{ (iC-1)*2+1 } = [ conds{iC} '-normal' ];
        
        data = results2( ismember( results2.subject, subs{iS} ) & ismember( results2.condition, conds{iC} ), : );
        [x IX] = sort( data.nAverages, 'ascend' );
        y = data.accuracy;
        y = y(IX);
        %             plot(x, y, '-+', 'color', colors{iC} )
        plot(x, y ...
            , 'LineStyle', lineStyles{2} ...
            , 'Color', colorList(iC, :) ...
            , 'LineWidth', LW ...
            , 'Marker', markers{2} ...
            , 'MarkerFaceColor', colorList(iC, :) ...
            , 'MarkerEdgeColor', colorList(iC, :) ...
            , 'MarkerSize', MS ...
            );
        legendStr{ (iC-1)*2+2 } = [ conds{iC} '-pooled' ];
        
    end
    ylim([0 105])
    grid on
    title( sprintf('subject %s', subs{iS}) );
    xlabel('number of repetitions');
    if iS == 1
        ylabel('accuracy (%)');
    end
    legend(legendStr,'Location', 'best');
    
end

h = ImageSetup;
h.I_Width       = fWidth; % cm
h.I_High        = fHeight; % cm
h.I_DPI         = 300;
h.I_KeepColor   = 1;
h.I_Box         = 'off';
h.I_Grid        = 'on';
h.I_FontSize    = FS;
h.I_LineWidth   = LW;
h.I_AlignAxesTexts = 0;
h.I_TitleInAxis = 0;

h.prepareAllFigures;

% set(findobj('parent', gcf, 'tag', 'legend'), 'Box', 'off');
set(findobj(gcf,'Type','uicontrol'),'Visible','off');

s.Format = 'tiff';
s.Resolution = h.I_DPI;
hgexport(gcf,fullfile(cd, [name '.tif']),s);

close(gcf);

% % % % % %% mean all subjects
% % % % % figure('Name', ['mean_' textfile], 'Units', 'centimeters', 'Position', [1 1 fWidth fHeight]);
% % % % % hold on
% % % % % for iC = 1:nCond
% % % % %
% % % % %     data = results( ismember( results.condition, conds{iC} ), : );
% % % % %     x = sort( unique( data.nAverages ), 'ascend' );
% % % % %     y  = zeros( size(x) );
% % % % %     for i = 1:numel(x)
% % % % %         y(i) = mean( data.accuracy( ismember(data.nAverages, x(i)) ) );
% % % % %     end
% % % % %     plot(x, y ...
% % % % %         , 'LineStyle', lineStyles{iC} ...
% % % % %         , 'Color', colorList(iC, :) ...
% % % % %         , 'LineWidth', LW ...
% % % % %         , 'Marker', markers{iC} ...
% % % % %         , 'MarkerFaceColor', colorList(iC, :) ...
% % % % %         , 'MarkerEdgeColor', colorList(iC, :) ...
% % % % %         , 'MarkerSize', MS ...
% % % % %         );
% % % % % end
% % % % % ylim([0 105])
% % % % % grid on
% % % % % xlabel('number of repetitions');
% % % % % if iS == 1
% % % % %     ylabel('accuracy (%)');
% % % % % end
% % % % % legend(conds,'Location', 'best');
% % % % %
% % % % %
% % % % % h = ImageSetup;
% % % % % h.I_Width       = fWidth; % cm
% % % % % h.I_High        = fHeight; % cm
% % % % % h.I_DPI         = 300;
% % % % % h.I_KeepColor   = 1;
% % % % % h.I_Box         = 'off';
% % % % % h.I_Grid        = 'on';
% % % % % h.I_FontSize    = FS;
% % % % % h.I_LineWidth   = LW;
% % % % % h.I_AlignAxesTexts = 0;
% % % % % h.I_TitleInAxis = 0;
% % % % %
% % % % % h.prepareAllFigures;
% % % % %
% % % % % % set(findobj('parent', gcf, 'tag', 'legend'), 'Box', 'off');
% % % % % set(findobj(gcf,'Type','uicontrol'),'Visible','off');
% % % % %
% % % % % s.Format = 'tiff';
% % % % % s.Resolution = h.I_DPI;
% % % % % hgexport(gcf,fullfile(cd, [name '_grandMean.tif']),s);
% % % % %
% % % % % close(gcf);

end
