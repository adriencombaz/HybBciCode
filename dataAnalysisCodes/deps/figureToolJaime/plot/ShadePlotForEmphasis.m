function h=ShadePlotForEmphasis(varargin)
s = parseparameters(varargin{:});
s = ef(s,'Intervals',[]);
s = ef(s,'Color',[0.8 .8 .8]);
s = ef(s,'Alpha',.2);

[m,n] = size(s.Intervals);
for i=1:m
  h(i)=patch([repmat(s.Intervals(i,1),1,2) repmat(s.Intervals(i,2),1,2)], ...
    [get(gca,'YLim') fliplr(get(gca,'YLim'))], ...
    [0 0 0 0],s.Color);
    set(h(i),'FaceAlpha',s.Alpha);
end;
