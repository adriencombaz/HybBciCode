function obj = printNow(obj,hgcf);
filename=get(hgcf,'name');
[FileName,PathName,FilterIndex] = uiputfile({...
    '*.fig;*.eps;*.tiff;*.pdf','Figure Files (*.fig,*.eps,*.tiff,*.pdf)';...
    '*.fig','Figures (*.fig)';...
    '*.eps','EPS(*.eps)';...
    '*.tiff','TIFF(*.tiff)';...
    '*.pdf','PDF(*.pdf)'...
    },'save figure',filename);    
if isequal(FileName,0) || isequal(PathName,0)
    return;
end

set(findobj(hgcf,'Type','uicontrol'),'Visible','off');
[texts]=regexpi(FileName,'\.','split');
saveas(hgcf,fullfile(PathName,cell2mat(texts(1))),'fig'); 
% saveas(hgcf,[fullfile(PathName,cell2mat(texts(1))) '.eps'],'psc2'); 
% print(hgcf,'-dmeta','-deps2',[fullfile(PathName,cell2mat(texts(1))) '.eps']);
% print_eps([fullfile(PathName,cell2mat(texts(1))) '.eps']);

s.Format = 'eps';
s.Preview = 'tiff';
hgexport(hgcf,[fullfile(PathName,cell2mat(texts(1))) '.eps'],s);

s.Format = 'tiff';
s.Resolution = obj.I_DPI;
hgexport(hgcf,[fullfile(PathName,cell2mat(texts(1))) '.tiff'],s);

if ~isunix
    s.Format = 'pdf';
    s.Resolution = obj.I_DPI;
    hgexport(hgcf,[fullfile(PathName,cell2mat(texts(1))) '.pdf'],s);
else
  [status, result] = system(['epstopdf ''',[fullfile(PathName,cell2mat(texts(1))) '.eps''']]);
end
set(findobj(hgcf,'Type','uicontrol'),'Visible','on');
