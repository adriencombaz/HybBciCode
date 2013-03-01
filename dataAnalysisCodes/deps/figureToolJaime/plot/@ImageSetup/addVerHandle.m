function obj = addVerHandle(obj,newFigHandle)
obj.checkFigHandles;
obj.verAddedHandles = [obj.verAddedHandles newFigHandle];
obj.verAddedHandles = obj.unique1(obj.verAddedHandles);
obj.add2VerSubplot;