h = ImageSetup;
h.I_Width       = fWidth; % cm
h.I_High        = fHeight; % cm
h.I_KeepColor   = 1;
h.I_Box         = 'off';
h.I_FontSize    = FS;
h.I_LineWidth   = LW;
h.I_AlignAxesTexts = 0;
h.I_TitleInAxis = 1;
h.OptimizeSpace = 0;

h.prepareAllFigures;

legObj = findobj('parent', gcf, 'tag', 'legend');
legUnits = get(legObj, 'Units');
set(legObj, 'Units', 'centimeters');
legPos = get(legObj, 'Position');
legPosNew = legPos;
legPosNew(1) = fWidth - legPos(3) - 1;
legPosNew(2) = fHeight - legPos(4) - 1;
set(legObj, 'Position', legPosNew);
set(legObj, 'Units', legUnits);


set(findobj(gcf,'Type','uicontrol'),'Visible','off');

s.Format = 'tiff';
s.Resolution = h.I_DPI;
hgexport(gcf, figName, s);

close(gcf);


