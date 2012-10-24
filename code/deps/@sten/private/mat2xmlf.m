function XML = mat2xmlf(MAT, VARNAME)
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
    
    indent = repmat( sprintf('\t'), [1 level] );
    
    if nargin < 2;
        VARNAME = 'ans';
    end % if not provided make it a matlab answer variable
    w = whos('MAT');    
    w.name = VARNAME;
    if w.size(1) > 1,
        size_string = sprintf('%g ', w.size(:)');
        size_string = [' size="' size_string(1:end-1) '"'];
    else
        size_string = '';
    end
    
    XML = sprintf('%s<%s', indent, w.name);
    switch w.class,
        case 'char',
%             XML = sprintf('%s>%s', XML, spcharin(MAT(:)') );
            XML = sprintf('%s>%s', XML, MAT);

        case 'struct',
            XML = sprintf('%s class="struct"%s>\n', XML, size_string);
            level = level + 1;
            names = fieldnames(MAT);
            %struct_fields=[' fields="',names{1}];for j=2:length(names);struct_fields=[struct_fields,' ',names{j}];end;struct_fields=[struct_fields,'">'];XML=[XML(1:(end-1)),struct_fields];
            for i = 1:prod(w.size)
                for j = 1:length(names)
                    XML = [ XML mat2xmlf(eval(['MAT(i).' names{j}]), names{j}) ];
                end
            end
            level = level - 1;
            XML = [ XML indent ];
            
        case 'cell',
            XML = sprintf('%s class="cell"%s>', XML, size_string);
            for i = 1:prod(w.size)
                XML = sprintf( '%s%s', XML, mat2xmlf(MAT{i}, 'cell') );
            end
            
        case {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'},
            XML = sprintf( '%s class="%s"%s>%s', XML, w.class, size_string, num2str(MAT(:)') );
            
        case {'double', 'single'},
%             abs_difference = abs( MAT(:) - round(MAT(:)) );
            
            if isequal(MAT(:), round(MAT(:))), %all( abs_difference < eps ), %(
                val_string = sprintf( '%d ', MAT(:)' );
            else
                val_string = sprintf( '%e ', MAT(:)' );
            end
            XML = sprintf( '%s class="%s"%s>%s', XML, w.class, size_string, val_string(1:end-1) );

        case 'logical',
            XML = sprintf( '%s class="logical">%d', XML, MAT);
%             if MAT,
%                 XML = [XML 'true'];
%             else
%                 XML = [XML 'false'];
%             end
            
        otherwise
            XML = sprintf(' class="%s"%s>', w.class, size_string);
            warning('MAT2XMLF:unsopported_class', 'unsupported class (%s)', w.class);          
            XML = [XML num2str(MAT(:)')];
            
    end % of class switch    

    XML = sprintf('%s</%s>\n', XML, w.name);
    XML = regexprep(XML, '\o{40}{2,}', ' ');

end % of MAT2XMLF function