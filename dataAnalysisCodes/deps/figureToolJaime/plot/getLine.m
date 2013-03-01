function outLine=getLine(i)
TLine={'-' '--' ':' '-.'};
LTL = length(TLine);
aux=mod(i-1,LTL)+1;
outLine = cell2mat(TLine(aux));