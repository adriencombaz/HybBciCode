function obj = prepareFigures(obj,varargin);
s = parseparameters(varargin{:});
s = ef(s,'FigHandle',[]);
hgcf = s.FigHandle;
%% first it is prapared the output image
% set(hgcf, 'PaperUnit', obj.I_Unit);
% papersize = get(hgcf, 'PaperSize');
% left = (papersize(1)- obj.I_Width)/4;
% bottom = (papersize(2)- obj.I_High)/4;
% myfiguresize = [left, bottom, obj.I_Width, obj.I_High];
% set(hgcf, 'PaperPosition', myfiguresize);
% set(hgcf,'units',obj.I_Unit,'position',myfiguresize);


allText   = findall(hgcf, 'type', 'text');
allAxes   = findall(hgcf, 'type', 'axes');
allFont   = [allText; allAxes];
set(allFont, 'FontUnits', 'points');
set(allFont, 'FontSize', obj.I_FontSize);
set(allFont, 'FontName', obj.I_FontName);
%%remove colors from texts
set(allText,'BackgroundColor','none')

%% limits for the axis
haxis = findobj(hgcf,'type','axes','-not','Tag','legend'); %only axes
if obj.I_AutoYlim
    y1=min(cell2mat(get(haxis,'YLim')));
    y2=max(cell2mat(get(haxis,'YLim')));
    obj.I_Ylim= [y1(1) y2(2)];
    set(haxis,'YLim',obj.I_Ylim);
else
    if ~isequal(obj.I_Ylim,[-inf inf])
        set(haxis,'YLim',obj.I_Ylim);
    end;
end

if obj.I_AutoXlim
    x1=min(cell2mat(get(haxis,'XLim')));
    x2=max(cell2mat(get(haxis,'XLim')));
    obj.I_Ylim= [x1(1) x2(2)];
    set(haxis,'XLim',obj.I_Xlim);
else
    if ~isequal(obj.I_Xlim,[-inf inf])
        set(haxis,'XLim',obj.I_Xlim);
    end;
end;
%% position of legends
hlegends = findobj(hgcf,'type','axes','Tag','legend'); %only legends
if ~isequal(obj.I_LegendLocation,'')
    set(hlegends,'Location',obj.I_LegendLocation);
end

%% legend setup
set(hlegends,...
    'visible',obj.I_Legend); 
if obj.I_LegendBox
    set(hlegends,'Box','on')
else
    set(hlegends,'Box','off')
end
%% preparation of axes 
for i=1:length(haxis)
    hl = findobj(haxis(i),'Type','line');
    lc = get(hl,{'Color'});
    hmarker = findobj(hl,'type','line','-and','-not','Marker','none');
    if ~obj.I_KeepColor
        for j = 1:length(lc)
            ncolor = unique(lc{j});
            if length(ncolor)>1
                set(hl(j),'Color','k');
            end
        end
        for j = 1:numel(hmarker)
                %keep only grayscale colors
                if ~isequal(get(hmarker(j),'MarkerFaceColor'),'none') && numel(unique(get(hmarker(j),'MarkerFaceColor'))) > 1
                    set(hmarker(j),'MarkerFaceColor',[0,0,0]);
                end
        end
        colormap('gray');
    end
    if obj.ResetLineWidth
        set(hl,'lineWidth',obj.I_LineWidth);
    end
    %set(hl,'lineStyle','-');
    %% Box of image
    set(haxis(i),'box',obj.I_Box);
    %% grid
    set(haxis(i),'xgrid',obj.I_Grid);
    set(haxis(i),'ygrid',obj.I_Grid);
    
    if obj.I_TitleInAxis
        htitle = get(haxis(i),'title');
        titpos = get(htitle,'position');
        axiLim = get(haxis(i),'Ylim');
        titpos(2) = axiLim(2);
        set(htitle,'position',titpos);
        set(htitle,'VerticalAlignment','top');
    end
end

if obj.OptimizeSpace
    left = [];
    for l = 1:2
        lims = nan(1, 4);
        for k = 1:length(haxis)
            h = haxis(k);
            pos = get(h, 'Position');
            
            %    rectangle('Position', pos)
            
            inset = get(h, 'TightInset');
            
            pos(1:2) = pos(1:2) - inset(1:2);
            pos(3:4) = pos(3:4) + inset(3:4) + inset(1:2);
            
            %    rectangle('Position', pos)
            
            if ~(pos(1) >= lims(1))
                lims(1) = pos(1);
            end
            if ~(pos(2) >= lims(2))
                lims(2) = pos(2);
            end
            if ~(pos(1) + pos(3) <= lims(3))
                lims(3) = pos(1) + pos(3);
            end
            if ~(pos(2) + pos(4) <= lims(4))
                lims(4) = pos(2) + pos(4);
            end
        end
        if ~isempty(left)
            if l == 1
                lims(1) = left;
            else
                lims(1) = 0;
            end
        end
        %rectangle('Position', [lims(1:2) lims(3:4) - lims(1:2)])
        width = lims(3) - lims(1);
        height = lims(4) - lims(2);
        if l == 1
            ar = 4 / 3 * width / height;
        end
        for k = 1:length(haxis)
            h = haxis(k);
            pos = get(h, 'Position');
            pos(3) = pos(3) / width;
            pos(4) = pos(4) / height;
            pos(1) = (pos(1) - lims(1)) / width;
            pos(2) = (pos(2) - lims(2)) / height;
            set(h, 'Position', pos)
        end
    end
end

%% ====================== AREA UNDER CONSTRUCTION =================================

%----------------------------- original code ----------------------------------------
set(hgcf, 'Units', obj.I_Unit);
fpos = get(hgcf, 'Position');
fpos(3:4) = [obj.I_Width obj.I_High];
set(hgcf, 'Position', fpos);
set(hgcf, 'Units', 'pixels');

set(hgcf, 'PaperUnits', obj.I_Unit)
set(hgcf, 'PaperSize', [obj.I_Width obj.I_High])
set(hgcf, 'PaperUnits', 'normalized')
set(hgcf, 'PaperPosition', [0 0 1 1])
set(hgcf, 'PaperUnits', 'inches')
set(hgcf,'color','w');
%----------------------------- new code ----------------------------------------
% originalFigUnits = get(hgcf, 'Units');
% 
% set(hgcf, 'Units', obj.I_Unit);
% fpos = get(hgcf, 'Position');
% fpos(3:4) = [obj.I_Width obj.I_High];
% set(hgcf, 'Position', fpos);
% 
% set(hgcf, 'Units', 'inches');
% sizeInInches = get(hgcf, 'Position');
% set(hgcf, 'Units', 'pixels');
% sizeInPixels = get(hgcf, 'Position');
% sizeInPixels(3:4) = sizeInInches(3:4)*obj.I_DPI;
% set(hgcf, 'Position', sizeInPixels);
% 
% set(hgcf, 'Units', 'inches');
% sizeInInches = get(hgcf, 'Position');
% originalPaperUnit = get(hgcf, 'PaperUnits');
% set(hgcf, 'PaperUnits', 'inches');
% set(hgcf, 'PaperSize', sizeInInches(3:4));
% set(hgcf, 'PaperUnits', 'normalized');
% set(hgcf, 'PaperPosition', [0 0 1 1]);
% set(hgcf, 'PaperUnits', originalPaperUnit);
% set(hgcf, 'Units', originalFigUnits);
% set(hgcf,'color','w');


%% ====================== END OF CONSTRUCTION AREA =================================

%% all texts (not in legend)
% delete(findobj(hgcf,'Tag','toDelete'));%my created texts
htexts = findall(hgcf,'Type','text','-not','String','');
cont=1;
while cont<=length(htexts)
    if length(findobj(get(htexts(cont),'Parent'),'Tag','legend')) >=1
        htexts(cont)=[];
    else
        cont=cont+1;
    end
end
alltexts=get(htexts,'String');
set(htexts,'Visible','on');
%% align lines and texts in axes
for i=1:length(haxis)
    if obj.I_AlignAxesTexts
        x=get(haxis(i),'Xlim');
        %% aling text objects
        halltexts = findobj(haxis(i),'Type','Text');
        htext = [];
        if numel(halltexts) > 0
            for j = 1:numel(halltexts)
                if ~isequal(get(halltexts(j),'UserData'),'keep_pos');
                    htext = [htext, halltexts(j)];
                end
            end
            
            pos = get(htext,'Position');
            if iscell(pos)
                pos = cell2mat(pos);
            end
            extent = get(htext,'Extent');
            if iscell(extent)
                extent = cell2mat(extent);
            end
            
            for j = 1:numel(htext)
                pos(j,1) = x(end)-extent(j,3);
                set(htext(j),'Position',pos(j,:));
            end
        end
        %% aling lines objects
        halllines = findobj(haxis(i),'Type','Line');
        hlines = [];
        htexts = [];
        if numel(halllines ) > 0
            for j = 1:numel(halllines)
                udata  =get(halllines(j),'UserData');
                if isfield(udata,'Align') && isfield(udata,'HText');
                    if udata.Align
                        hlines = [hlines, halllines(j)];
                    end
                end
            end
            if isequal(numel(htext),numel(hlines))
                for j = 1:numel(htext)
                    pos = get(htext(j),'Position');
                    extent = get(htext(j),'Extent');
                    pos(1) = x(end)-extent(3);
                    set(hlines(j),'XData',[pos(1)-diff(x)*0.05,pos(1)])
                    set(hlines(j),'YData',[pos(2),pos(2)]);
                end
            end
        end
    end
end


%% Subplot Buttons
hprint = uicontrol(hgcf,'Style', 'pushbutton', 'String', 'Save',...
    'Position', [0 0 60 20], 'Callback', @printNow1);
% hsubp = uicontrol(hgcf,'Style', 'pushbutton', 'String', 'add2Ver',...
%     'Position', [60 0 60 20], 'Callback',@addVerHandle1);
% hsubp = uicontrol(hgcf,'Style', 'pushbutton', 'String', 'add2Hor',...
%     'Position', [120 0 60 20], 'Callback', @addHorHandle1);
hsubp = uicontrol(hgcf,'Style', 'pushbutton', 'String', 'add2ArrHor',...
    'Position', [60 0 100 20], 'Callback',@addHandletoArrayHor);
hsubp = uicontrol(hgcf,'Style', 'pushbutton', 'String', 'add2ArrVer',...
    'Position', [160 0 100 20], 'Callback', @addHandletoArrayVer);
hsubp = uicontrol(hgcf,'Style', 'pushbutton', 'String', 'Copy2Clipboard',...
    'Position', [260 0 60 20], 'Callback', @copy2clipboard);
%% buttons connections
    function printNow1(hObject,eventdata)
        obj.printNow(hgcf);
    end
    function addVerHandle1(hObject,eventdata)
        if hgcf == obj.hOutFig
            obj.clearHandles;
        end
        obj.addVerHandle(hgcf);
    end
    function addHorHandle1(hObject,eventdata)
        if hgcf == obj.hOutFig
            obj.clearHandles;
        end
        obj.addHorHandle(hgcf);
    end
    function addHandletoArrayHor(hObject,eventdata)
        if hgcf == obj.hOutFig
            obj.clearHandles;
        end
        obj.addHandle2Array(hgcf,'horizontal');
    end
    function addHandletoArrayVer(hObject,eventdata)
        if hgcf == obj.hOutFig
            obj.clearHandles;
        end
        obj.addHandle2Array(hgcf,'vertical');
    end
    function addHandletoArray(hObject,eventdata)
    end
    function copy2clipboard(hObject,eventdata)
        if ~ispc
            return;
        end
        set(findobj(hgcf,'Type','uicontrol'),'Visible','off');
        %print(hgcf,['-r' num2str(obj.I_DPI)], '-dmeta');
        hgexport(hgcf,'-clipboard');
        set(findobj(hgcf,'Type','uicontrol'),'Visible','on');
    end

end