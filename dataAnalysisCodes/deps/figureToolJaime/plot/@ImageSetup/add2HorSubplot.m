function obj = add2HorSubplot(obj);
obj.figs2subplots(obj,'Handles',obj.horAddedHandles,'Direction','horizontal');
obj.prepareFigures('FigHandle',obj.hOutFig);
