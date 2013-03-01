function [marker]=getMarker(i)
Markers = ['s' 'd' '+' 'o' '*' '.' 'x'  '^' 'v' '>' '<' 'p' 'h'];
LM = length(Markers);
aux=mod(i-1,LM)+1;
marker = Markers(aux);
