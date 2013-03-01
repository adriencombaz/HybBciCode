function layoutplot(H, varargin)

params = varargin_to_struct(varargin{:});
params = ef(params, 'Width', 17.4);
params = ef(params, 'High', 8.4);
params = ef(params, 'FontSize', 10);
params = ef(params, 'FontName', 'Courier');
params = ef(params, 'Left', []);

reqwidth = params.Width;
reqhigh = params.High;
font = params.FontSize;
fontName = params.FontStyle;


allText   = findall(H, 'type', 'text');
allAxes   = findall(H, 'type', 'axes');
allFont   = [allText; allAxes];
set(allFont, 'FontUnits', 'points');
set(allFont, 'FontSize', font);
set(allFont, 'FontName', fontName);


%ax = axes('Position', [0 0 1 1])
%xlim([0 1])
%ylim([0 1])

handles = get_axes_or_legend_handles(H, 'axes');

for l = 1:2
    lims = nan(1, 4);
    for k = 1:length(handles)
        h = handles(k);
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
    if ~isempty(params.Left)
        if l == 1
            lims(1) = params.Left;
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
    for k = 1:length(handles)
        h = handles(k);
        pos = get(h, 'Position');
        pos(3) = pos(3) / width;
        pos(4) = pos(4) / height;
        pos(1) = (pos(1) - lims(1)) / width;
        pos(2) = (pos(2) - lims(2)) / height;
        set(h, 'Position', pos)
    end
    set(H, 'Units', 'centimeters');
    fpos = get(H, 'Position');
    fpos(3:4) = [reqwidth reqhigh];
    set(H, 'Position', fpos);
    set(H, 'Units', 'pixels');
end

set(H, 'PaperUnits', 'centimeters')
set(H, 'PaperSize', [reqwidth reqhigh])
set(H, 'PaperUnits', 'normalized')
set(H, 'PaperPosition', [0 0 1 1])
set(H, 'PaperUnits', 'inches')

function handles = get_axes_or_legend_handles(parentHandle, type)

% First get all axes handles, this includes the legends
allAxes = transpose(findobj(parentHandle, 'Type', 'axes'));
allLegends = [];
for h = allAxes
    allLegends = [allLegends legend(h)]; %#ok<AGROW>
end
if strcmp(type, 'axes')
    handles = setdiff(allAxes, allLegends);
elseif strcmp(type, 'legends')
    handles = allLegends;
else
    handles = [];
end
