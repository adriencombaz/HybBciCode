function obj = checkFigHandles(obj)
obj.findImageHandles;

cont=1;
while cont <= length(obj.horAddedHandles)
    if (isempty(find(obj.I_Handles == obj.horAddedHandles(cont), 1))) 
        obj.horAddedHandles(cont)=[];
    end
    cont=cont+1;
end
obj.horAddedHandles = obj.unique1(obj.horAddedHandles);

cont=1;
while cont <= length(obj.verAddedHandles)
    if (isempty(find(obj.I_Handles == obj.verAddedHandles(cont), 1)))
        obj.verAddedHandles(cont)=[];
    end
    cont=cont+1;
end
obj.verAddedHandles = obj.unique1(obj.verAddedHandles);

cont=1;
while cont <= length(obj.arrayAddedHandles)
    if (isempty(find(obj.I_Handles == obj.arrayAddedHandles(cont), 1)))
        obj.arrayAddedHandles(cont)=[];
    end
    cont=cont+1;
end
obj.arrayAddedHandles = obj.unique1(obj.arrayAddedHandles);