function obj = addHandle2Array(obj,newFigHandle)
obj.checkFigHandles;
obj.arrayAddedHandles = [obj.arrayAddedHandles newFigHandle];
obj.arrayAddedHandles = obj.unique1(obj.arrayAddedHandles);
obj.add2ArraySubplot;