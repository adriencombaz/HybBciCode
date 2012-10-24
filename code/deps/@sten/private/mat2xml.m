function XML = mat2xml(MAT, VARNAME)
% MAT2XMLF converts structured variable MAT into properly formatted XML string
%
%Syntax XML = mat2xmlf(MAT, VARNAME)
%
%Description
%  MAT : structured varable
%  VARNAME : variable name (string)
%  XML : xml version of structured variable (string)
%
% See Also: XML2MAT, MAT2XML
%
% Jonas Almeida, almeidaj@musc.edu, 20 Aug 2002, XML4MAT Tbox
%
% modified by Nikolay Chumerin (http://sites.google.com/site/chumerin)
    
    persistent level;
    if isempty(level),
        level = 0;
    end
    tab_char = sprintf('\t');
    
    if nargin<2;
        VARNAME='ans';
    end % if not provided make it a matlab answer variable
    w = whos('MAT');
    w.name = VARNAME;
    
    % XML=['<' w.name ' class="' w.class '" size="'  num2str(w.size) '">'];
    XML = sprintf('%s<%s class="%s" size="%s">', 9*ones(1,level), w.name, w.class, num2str(w.size));
    if strcmp(w.class, 'char')
        XML=[ XML spcharin(MAT(:)') ];
    elseif strcmp(w.class, 'struct')
        level = level + 1;
        XML = sprintf('%s\n', XML);
        names = fieldnames(MAT);
        %struct_fields=[' fields="',names{1}];for j=2:length(names);struct_fields=[struct_fields,' ',names{j}];end;struct_fields=[struct_fields,'">'];XML=[XML(1:(end-1)),struct_fields];
        for i = 1:prod(w.size)
            for j = 1:length(names)
                XML = [ XML mat2xmlf(eval(['MAT(i).' names{j}]), names{j}) ];
            end
        end
        level = level - 1;
        XML = [ XML 9*ones(1,level) ];
    elseif strcmp(w.class, 'cell')
        for i = 1:prod(w.size)
            XML = [ XML mat2xmlf(MAT{i}, 'cell') ];
        end
    else %if strcmp(w.class,'double')|strcmp(w.class,'single')
        XML=[XML num2str(MAT(:)')];
    end
    XML = sprintf('%s</%s>\n', XML, w.name);
    XML = regexprep(XML, '\o{40}{2,}', ' ');
    
end % of function mat2xmlf