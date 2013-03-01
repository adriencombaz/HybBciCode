function obj = add2ArraySubplot(obj);
obj.figs2subplotsArray(obj,'Handles',obj.arrayAddedHandles,'Tiling',obj.I_Matrix);
obj.prepareFigures('FigHandle',obj.hOutFig);