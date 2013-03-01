function obj = addHorHandle(obj,newFigHandle)
obj.checkFigHandles;
obj.horAddedHandles = [obj.horAddedHandles newFigHandle];
obj.horAddedHandles = obj.unique1(obj.horAddedHandles);
obj.add2HorSubplot;