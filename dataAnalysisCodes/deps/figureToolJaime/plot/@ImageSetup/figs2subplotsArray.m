function obj = figs2subplotsArray(obj,varargin)
s = parseparameters(varargin{2:end});
ensurefields(s,'Handles');
s = setfielddefault(s, 'Direction','vertical');
s = setfielddefault(s, 'Tiling',[]);
% s = setfielddefault(s, 'Arr',{});

% FIGS2SUBLPLOTS Combine axes in many figures into subplots in one figure
%
%   The syntax:
%
%       >> newfig = figs2subplots(handles,tiling,arr);
%   
%   creates a new figure with handle "newfig", in which the axes specified
%   in vector "handles" are reproduced and aggregated as subplots. 
%
%   Vector "handles" is a vector of figure and/or axes handles. If an axes
%   handle is encountered, the corresponding axes is simply reproduced as
%   a subplot in the new figure; if a figure handle is encountered, all its
%   children axes are reproduced as subplots in the figure.
%
%   Vector "tiling" is an optional subplot tiling vector of the form 
%   [M N], where M and N specify the number of rows and columns for the
%   subplot tiling. M and N correspond to the first two arguments of the
%   SUBPLOT command. By default, the tiling is such that all subplots are
%   stacked in a column.
%
%   Cell array "arr" is an optional subplot arrangement cell array. For
%   the k-th axes handle encountered, the subplot command issued is
%   actually:
%
%       subplot(tiling(1),tiling(2),arr{k})
%
%   By default, "arr" is a cell array {1,2,...}, which means that each axes
%   found in the figures is reproduced in a neatly tiled grid.
%
%   Example:
%
%       figs2subplots([a1 a2 a3],[2 2],{[1 3],2,4})
%
%   copies the three axes a1, a2 and a3 as subplots in a new figure with a 
%   2x2 tiling arangement. Axes a1 will be reproduced as a subplot 
%   occupying tiles 1 and 3 (thus covering the left part of the figure), 
%   while axes a2 will be reproduced as a subplot occupying tile 2 (upper
%   right corner) and a3 occupying tile 4 (lower right corner).

%   Original version by Fran�ois Bouffard (fbouffard@gmail.com)
%   Legend copy code by Zoran Pasaric (pasaric@rudjer.irb.hr)

%% Parsing handles vector
av = [];
lh = [];
for k = 1:length(s.Handles)
    if strcmp(get(s.Handles(k),'Type'),'axes')
        av = [av s.Handles(k)];
    elseif strcmp(get(s.Handles(k),'Type'),'figure');
        fc = get(s.Handles(k),'Children');
        for j = numel(fc):-1:1
            if numel(findobj(fc(j),'type','axes','-and','-not','parent',obj.hOutFig,'-and','-not','Tag','legend'))>0
                av = [av fc(j)]; %axes to plot
            elseif numel(findobj(fc(j),'type','axes','-and','-not','parent',obj.hOutFig,'-and','Tag','legend'))>0
                lh = [lh fc(j)];%legend handles of included axes
            end;
        end;
    end;
end;

%% --- find all around axes and legends
hAxes = findobj('type','axes','-and','-not','parent',obj.hOutFig);
hLeg = findobj(hAxes,'Tag','legend','-and','-not','parent',obj.hOutFig); % only legend axes
cud = get(hLeg,'UserData');
if ~iscell(cud)
    ud = {cud};
else
    ud = cud;
end
%% search for legals user data only
userDat={};
legendHandles = [];
for i = 1:length(ud)
    if ~isempty(ud{i}) && ~isempty(ud{i}.PlotHandle) && ~isempty(find(av == ud{i}.PlotHandle))
        userDat = [userDat, ud(i)];
        legendHandles = [legendHandles, hLeg(i)];
    end
end

%% Extract axes handles that own particular legend, and corresponding strings

hLegParAxes=[];
hLegString={};

if numel(userDat)==1 && ~isempty(userDat{1}.PlotHandle)
    hLegParAxes(1) = userDat{1}.PlotHandle;
else
    for i1 = 1:length(userDat)
        if ~isempty(userDat{1}.PlotHandle)
            hLegParAxes = [hLegParAxes,userDat{i1}.PlotHandle];
        end
    end
end

%% Setting the subplots arrangement
Na = length(av);
if isequal(s.Tiling,[])
    if strcmp(s.Direction,'horizontal')
        s.Tiling = [1 Na];
    else
        s.Tiling = [Na 1];
    end
    Ns = Na;
else
    Ns = prod(s.Tiling);
end

% if isequal(s.Arr,{})
%     s.Arr = mat2cell((1:Ns)',ones(1,Ns));
% end;
% 
% if ~iscell(s.Arr)
%     error('Arrangement must be a cell array');
% end;

%% Creating new figure
if ~ishandle(obj.hOutFig) || isequal(obj.hOutFig,gcf)
    obj.hOutFig = figure;
end

%%
hNewFigure = obj.subplot1(s.Tiling(1),s.Tiling(2),'Gap',obj.I_Space);
hNewSubplots = sort(findobj(hNewFigure,'Type','axes'));

fnCols = s.Tiling(2);
fnRows = s.Tiling(1);

%%
hsubaxes = sort(findobj(obj.hOutFig,'Type','axes'));
naxes = min(Ns,Na);
%here we create a matrix to know the handles of the visual matrix used to
%add the axes in vertical direction
for k = 1:fnRows
    spmatrix(k,:) = fnCols*(k-1)+1:fnCols*k;
end
if strcmp(s.Direction,'horizontal')
    orderaxes = 1:numel(spmatrix);
    fnCols = min(Na,s.Tiling(2));
    fnRows= ceil(Na/s.Tiling(2));
else
    orderaxes = reshape(spmatrix,1,[]);
    fnRows = min(Na,s.Tiling(1));
    fnCols = ceil(Na/s.Tiling(1));
end
%%
%% for deleting unnecessary lables and ticks
yTicks = get(av,'YTick');
xTicks = get(av,'XTick');
yLabels = get(av,'YLabel');
xLabels = get(av,'XLabel');

[m,n] = size(spmatrix);
removeYTicks = true;
removeYLabels = true;
for i = 1:m
    colaidx = [];
    for k = 1:n
        colaidx = [colaidx, find(orderaxes == spmatrix(i,k))];
    end
    
    for k = 1:fnCols - 1
        if colaidx(k+1) <= naxes
            if ~isequal(yTicks(colaidx(k)),yTicks(colaidx(k+1)))
                removeYTicks=false;
                %break;
            end
            cLab1 = get(yLabels{colaidx(k)},'String');
            cLab2 = get(yLabels{colaidx(k+1)},'String');
            if ~isequal(cLab1,cLab2)
                removeYLabels = false;
            end
        end
    end
end

yLims = get(av,'YLim');
xLims = get(av,'XLim');
[m,n] = size(spmatrix);
removeYTicks = true;
for i = 1:m
    colaidx = [];
    for k = 1:n
        colaidx = [colaidx, find(orderaxes == spmatrix(i,k))];
    end
    for k = 1:fnCols - 1
        if colaidx(k+1) <= naxes
            if ~isequal(yLims(colaidx(k)),yLims(colaidx(k+1)))
                removeYTicks=false;
                %break;
            end
        end
    end
end


removeXTicks = true;
removeXLabels = true;
for i = 1:n
    rowaidx = [];
    for k = 1:m
        rowaidx = [rowaidx, find(orderaxes == spmatrix(k,i))];
    end
    
    for k = 1:fnRows - 1
        if rowaidx(k+1) <= naxes
            if ~isequal(xTicks(rowaidx(k)),xTicks(rowaidx(k+1)))
                removeXTicks=false;
                %break;
            end
            cLab1 = get(xLabels{rowaidx(k)},'String');
            cLab2 = get(xLabels{rowaidx(k+1)},'String');
            if ~isequal(cLab1,cLab2)
                removeXLabels = false;
            end
        end
    end
end

removeXTicks = true;
for i = 1:n
    rowaidx = [];
    for k = 1:m
        rowaidx = [rowaidx, find(orderaxes == spmatrix(k,i))];
    end
    
    for k = 1:fnRows - 1
        if rowaidx(k+1) <= naxes
            if ~isequal(xLims(rowaidx(k)),xLims(rowaidx(k+1)))
                removeXTicks=false;
                %break;
            end
        end
    end
end

%% Here we deleted the extra axes
for i = naxes+1:numel(hNewSubplots)
    delete(hNewSubplots(orderaxes(i)));
end

%now we put the axes
for k = 1:naxes
    caxeidx = orderaxes(k);
    axes(hsubaxes(caxeidx));
    na(k) = copyobj(av(k),obj.hOutFig);
    set(na(k),'Position',get(hsubaxes(caxeidx),'Position'));
    [m,n] = find(spmatrix == caxeidx);
    if removeXTicks
        if m ~= fnRows
            set(na(k),'XTickLabel',[]);
%             hxlabel = get(na(k),'xlabel');
%             set(hxlabel,'String','');
        end;
    end
    if removeYTicks
        if n > 1 
            set(na(k),'YTickLabel',[]);
%             hylabel = get(na(k),'ylabel');
%             set(hylabel,'String','');
        end
    end
    if removeXLabels
        if m ~= fnRows
            hxlabel = get(na(k),'xlabel');
            set(hxlabel,'String','');
        end;
    end
    if removeYLabels
        if n > 1 
            hylabel = get(na(k),'ylabel');
            set(hylabel,'String','');
        end
    end
end;

for k = 1:naxes
% Produce legend if it exists in original axes
    [ii jj] = ismember(av(k),hLegParAxes);
    if (jj>0)
        hnl = copyobj(legendHandles(jj),get(na(jj),'Parent'));
        oldpos = get(hnl,'position');
        axepos = get(na(jj),'position');
        newpos = [axepos(1),axepos(2),oldpos(3:4)];
        set(hnl,'position',newpos);
        ud = get(hnl,'userdata');
        ud.PlotHandle = na(jj);
        set(hnl,'userdata',ud);
%         set(hnl, 'FontSize', 8)
    end
    caxeidx = orderaxes(k);
    delete(hsubaxes(caxeidx));
end
