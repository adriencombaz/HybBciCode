function a = unique1(obj,a)
cont=1;
while cont<length(a)
    b = find(a==a(cont));
    if (length(b)>1) 
        a(b(2:end))=[];
    end
    cont = cont+1;
end
