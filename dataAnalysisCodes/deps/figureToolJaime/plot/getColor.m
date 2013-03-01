function [outcolor]=getColor(i)
Colors = ['k','r','b','m'];
LC = length(Colors);
aux=mod(i-1,LC)+1;
outcolor = [Colors(aux)];