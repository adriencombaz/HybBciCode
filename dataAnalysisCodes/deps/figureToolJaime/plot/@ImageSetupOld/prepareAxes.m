function obj = prepareAxes(obj,hgca);
%% Color of all lines are changed
% hl = findobj(hgca,'Type','line');
% lc = get(hl,{'Color'});
% if ~obj.I_KeepColor
%     for i = 1:length(lc)
%         ncolor = unique(lc{i});
%         if length(ncolor)>1
%             set(hl(i),'Color','k');
%         end
%         
%     end
% end
% set(hl,'lineWidth',obj.I_LineWidth);
% %% Color of all texts propierties are changed
% set(findobj(hgca,'-property','FontUnits'),'FontUnits','points');
% set(findobj(hgca,'-property','FontSize'),'FontSize',obj.I_FontSize);
% set(findobj(hgca,'-property','FontName'),'FontName',obj.I_FontName);


% % set(findobj(hgca,'-property','MarkerFaceColor'),'MarkerFaceColor','k');

% set(hgca,...
%     'fontsize',obj.I_FontSize,...
%     'fontName',obj.I_FontName);

% %% Box of image 
% set(hgca,'box',obj.I_Box);

% %% grid
% set(hgca,'xgrid',obj.I_Grid);
% set(hgca,'ygrid',obj.I_Grid);

% %% Axis
% set(get(hgca,'xlabel'),...
%     'fontName',obj.I_FontName,...
%     'fontsize',obj.I_FontSize,...
%     'visible',obj.I_Xlabel);
% 
% set(get(hgca,'ylabel'),...
%     'fontName',obj.I_FontName,...
%     'fontsize',obj.I_FontSize,...
%     'visible',obj.I_Ylabel);
% %% Texts
% set(findall(hgca,'Type','text'),...
%     'fontName',obj.I_FontName,...
%     'fontsize',obj.I_FontSize);
