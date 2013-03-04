function plotResults
    
%     fileList = ls('Results*.txt');
%     
%     for iF = 1:size(fileList, 1)
%         
%         showPlotResults(fileList(iF,:));
%         
%     end
    
    showPlotResults('resultsSPMD.mat');
    
end

function showPlotResults(textfile)
    
    [dum1, name, ext] = fileparts(textfile);
    
    switch ext
        case '.txt'
            results = dataset('File', textfile, 'Delimiter' ,',');
        case '.mat'
            load(textfile);
            results = eval(name);
        otherwise
            error('file extension not expected');
    end
    
    subs = unique(results.subject);
    nSub = numel(subs);
    conds = unique(results.condition);
    nCond = numel(conds);
    LW = 2;
    MS = 6;
    FS = 9;
    fWidth = 25;
    fHeight = 8;
    cmap = colormap; close(gcf);
    nCmap = size(cmap, 1);
    colorList = zeros(nCond, 3);
    for i = 1:nCond
        colorList(i, :) = cmap( round((i-1)*(nCmap-1)/(nCond-1)+1) , : );
    end


    lineStyles = {'--', ':', '-.', '-.', '--'};
    markers = {'o', 's', '^', 'd', 'v'};
    figure('Name', textfile, 'Units', 'centimeters', 'Position', [1 1 fWidth fHeight]);
    for iS = 1:nSub
        subplot(1, nSub, iS);%, 'YGrid', 'on')
        hold on
        for iC = 1:nCond
            
            data = results( ismember( results.subject, subs{iS} ) & ismember( results.condition, conds{iC} ), : );
            [x IX] = sort( data.nAverages, 'ascend' );
            y = data.accuracy;
            y = y(IX);
%             plot(x, y, '-+', 'color', colors{iC} )
            plot(x, y ...
                , 'LineStyle', lineStyles{iC} ...
                , 'Color', colorList(iC, :) ...
                , 'LineWidth', LW ...
                , 'Marker', markers{iC} ...
                , 'MarkerFaceColor', colorList(iC, :) ...
                , 'MarkerEdgeColor', colorList(iC, :) ...
                , 'MarkerSize', MS ...
                );
        end
        ylim([0 105])
        grid on
        title( sprintf('subject %s', subs{iS}) );
        xlabel('number of repetitions');
        if iS == 1
            ylabel('accuracy (%)');
        end
    end
    legend(conds,'Location', 'best');
   
    
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
    hgexport(gcf,fullfile(cd, [textfile(1:end-4) '.tif']),s);
    
    close(gcf);
end
    