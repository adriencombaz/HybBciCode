function theStruct = readXMLfile( filename )
    theStruct = xml2mat( filename );
end % of READXMLFILE private method
%-----------------------------------------------
function y = consolidate( x )
%CONSOLIDATE field names in nested cell arrays produced by xml2mat of mbmling results
%
%Syntax: y=consolidate(x)
%
%Description:
% the nested cell arrays produced by XML2CELL emcapsulate the individual
% data structures. CONSOLIDATE will remove the cell encapsulation,
% returning the nested structure. CONSOLIDATEALL will apply CONSOLIDATE to
% all the cells in the array.
%
% See also CONSOLIDATEALL
%
% Jonas Almeida, almeidaj@musc.edu, 20 May 2003, MAT4NAT Tbox
    
    if strcmp(class(x),'cell')
        if strcmp(class(x{1}),'struct')
            n=length(x);
            for i=1:n
                f(i)=fieldnames(x{i});
                I=strmatch(f(i),f(1:i-1));
                if ~isempty(I);
                    j=I(1);
                    %eval(['y.',f{j},'=consolidate(x{i}.',f{j},');'])
                    if isfield(x{i},f{j})
                        eval(['y.',f{j},'{end+1}=consolidate(x{i}.',f{j},');'])
                        %warning(['field does not exist: ',f{j}])
                    end
                else
                    j=i;
                    %eval(['y.',f{j},'=consolidate(x{i}.',f{j},');'])
                    eval(['y.',f{j},'{1}=consolidate(x{i}.',f{j},');'])
                end
            end
        else
            y=x;
        end
    else
        y=x;
    end
end % of CONSOLIDATE function
%-----------------------------------------------
function y = consolidateall(x)
% CONSOLIDATEALL applies consolidate to all the cells of a nested cell arrays
%
% Syntax: function y=consolidateall(x)
%
% Description:
% See description of CONSOLIDATE for details. By removing cell
% encapsulation of all the cells in the cell array, CONSOLIDATEALL will
% produce a dimensional structure. Therefore this fucntion will convert the
% product of XML2CELL into the output of XML2STRUCT
%
% See also: CONSOLIDATE, XML2STRUCT
%
% Jonas Almeida, almeidaj@musc.edu, 30 June 2003, MAT4NAT Tbox
    
    z=consolidate(x);
    if strcmp(class(z),'struct')
        f=fieldnames(z);
        for i=1:length(f)
            %disp(['(...).',f{i}])
            eval(['k=z.',f{i},';'])
            for j=1:length(k)
                eval(['y(',num2str(j),').',f{i},'=consolidateall(k{',num2str(j),'});'])
            end
        end
    else
        y=z;
    end
end % of CONSOLIDATEALL function
%-----------------------------------------------
function y = file2str( x )
%FILE2STR reads textfile intoa single long string
%
% Syntax: y=file2str(x)
%
% Description
%   x is a filename
%   y is the long string with all contents
%
% Jonas Almeida, almeidaj@musc.edu, 30 June 2003, MAT4NAT Tbox
    
    fid=fopen(x,'r');
    i=1;
    while ~feof(fid)
        y{i}=fgetl(fid);
        i=i+1;
    end
    fclose(fid);
    y=strcat(y{:});

end % of FILE2STR function
%-----------------------------------------------
function [MAT,VARNAME,tag_contents] = xml2mat( XML )
%XML2MAT converts XML string into matlab structure variable
%Syntax: [MAT,VARNAME,tag_contents]=xml2mat(XML)
%Description
% XML is an XML formated string using rules compliant with
%     the proceedure implemented in MAT2XML.
%     It can also be a file name with MbML text.
% VARNAME is the variable name.
%     If recovering the MAT variable with the original name is desired than
%     the followinf line will do the trick:
%
%          [MAT,VARNAME]=xml2mat(XML);eval([VARNAME,'=MAT'])
%
% See Also: mat2xml
% Jonas Almeida, 20 Aug 2002, XML4MAT Tbox
    
    if strncmp(XML,'%60;',4)  % XML provided as encoded XML string
        XML=spcharout(XML);
    end
    
    % is this a xml string or xml filename ?
    if XML(1)~='<'
        XML=strrep(file2str(XML),'''','''''');
        % Remove non-content lines if they exist
        XML=regexprep(XML,'<[?!].*?>','');
    end
    
    %Analise XML line
    tag_ini=find(XML=='<');
    tag_end=find(XML=='>');
    n=length(tag_ini); % number of enclosed tag structures
    
    % extract tag_names properties and contents
    if n>0
        for i=1:n
            tag_close(i)=(XML(tag_ini(i)+1)=='/'); % 1 for closing contents and 0 for opening
            tag_contents{i,1}=XML(tag_ini(i)+1+tag_close(i):tag_end(i)-1);  % first column contains names
        end
        tag_path=[0]; % first name is root name
        to_do=zeros(n,1); % 1 needs doing
        to_do(1)=1;
        tag_open=~tag_close;
        i=1;tag_contents{i,2}=xml2whos(tag_contents{i,1});tag_contents{i,2}.fields=[];tag_contents{i,3}=tag_path;tag_path=[tag_path,i];
        for i=2:n
            tag_contents{i,2}=xml2whos(tag_contents{i,1});tag_contents{i,2}.fields=[]; % second column contains WHO properties
            if tag_open(i)
                tag_contents{i,3}=tag_path;  % third column contains structre path
                tag_path=[tag_path,i];
                to_do(i)=1; % do this one
                to_do(tag_contents{i,3}+(tag_contents{i,3}==0))=0; % do host later
                tag_contents{tag_path(end-1),2}.fields=[tag_contents{tag_path(end-1),2}.fields,i];
            else
                tag_path(end)=[]; % move back one level
            end
        end
        
        % RECOVER DATA
        todo_list=find(to_do==1)';do_i=1;
        while do_i<=length(todo_list);
            i=todo_list(do_i);
            % for each case extract value
            tag_contents{i,4}=XML(tag_end(i)+1:tag_ini(i+1)-1);  % 4th column contains value as string
            w=tag_contents{i,2};
            % recover number format if appropriated
            if ~isfield(w,'class')
                w.class='char';
                tag_contents{i,4}=spcharout(tag_contents{i,4});
                w.size=size(tag_contents{i,4}); %correct size tag as well
                %tag_contents{i,2}=w;
            elseif strcmp(w.class,'char')
                tag_contents{i,4}=spcharout(tag_contents{i,4});
                w.size=size(tag_contents{i,4}); %correct size tag as well
                %tag_contents{i,2}=w;
            elseif strcmp(w.class,'struct')&(~isfield(w,'size'))
                n_fields=length(w.fields);
                for i=1:n_fields
                    field_names{i}=tag_contents{w.fields(i),2}.name;
                end
                unique_names=unique(field_names);
                n_unique=length(unique_names);
                n_certo=(n_fields/n_unique);
                w.size=[1 n_certo];
            else % it is a numeric type, say "double" or "single"
                tag_contents{i,4}=str2num(tag_contents{i,4});
                if ~isfield(w,'size');
                    w.size=size(tag_contents{i,4});
                end
            end
            tag_contents{i,2}=w;
            if (length(w.size>2)||(w.size(1)>1))
                iis='i1';for ii=2:length(w.size);iis=[iis,',i',num2str(ii)];end
                nn=prod(w.size); %number of elements
                eval( ['[', iis, '] = ind2sub(w.size,[1:nn]);'] ); % generation of indexes
%                             evalin('caller', ['[', iis, '] = ind2sub(w.size,[1:nn]);'] ); % generation of indexes
                iis='i1(ind)';for ii=2:length(w.size);iis=[iis,',i',num2str(ii),'(ind)'];end % indexes of indexes
                for ind=1:nn
                    eval(['valor(',iis,')=tag_contents{i,4}(ind);'])
                end
                if exist( 'valor' )==1,
                    tag_contents{i,4} = valor;
                    clear valor;
                end
            end
            do_i=do_i+1;
        end
        
        % RECOVER STRUCTURE
        j=1;tags=find(tag_open);
        eval_i={'MAT'};to_eval={};
        while j<=length(tags)
            i=tags(j);
            [to_eval,eval_i,j]=tag2eval(tag_contents,to_eval,eval_i,j,tags);
            %w=tag_contents{i,2}
            j=j+1;
        end
        
        for i=1:length(to_eval)
            %disp(to_eval{i})
            eval(to_eval{i})
        end
        
        %MAT.tag_contents=tag_contents;
        VARNAME=tag_contents{1,2}.name;
    else
        MAT=XML;
        VARNAME=[];
        tag_contents=[];
    end

end % of XML2MAT function
%-----------------------------------------------
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
    
end % of MAT2XMLF function 
%-----------------------------------------------
function yml = mbmling( xml, plt )
%MBMLING_CELL converts any XML into MbML (Matlab Markup Language) compliant string
%
%Syntax: yml=mbmling(xml,plt)
%
%Description:
%   Converts any XML syntax into Matlab Markup Language (MbML)
%
% Jonas Almeida, almeidaj@musc.edu, 18 May 2002, MAT4NAT Tbox
    
    if nargin<2;plt=0;end
    if plt==1;disp('MbMLing progress report');disp('---------BEGIN----(9 steps)----------');end
    
    % Remove non-content lines if they exist
    if plt==1;disp('1. Removing non-content lines if they exist');end
    xml=regexprep(xml,'<[?!].*?>','');
    % Remove empty spaces between tags
    if plt==1;disp('2. Removing empty spaces between tags');end
    %xml=regexprep(xml,'>[ ]+?<','><');
    xml=strrep(xml,char([13,10]),' '); %replace chariage returns by spaces
    n=length(xml)+1;
    while n>length(xml)
        n=length(xml);
        xml=strrep(xml,'> ','>');
    end
    % Replace symbols that may conflict with matlab variable naming by underscore characters
    if plt==1;disp('3. Replacing symbols that may conflict with matlab variable naming by underscore characters');end
    xml=regexprep(xml,'<[\/]{0,1}(\w*)[^\w\/> ]+(.*?)([ >])','<$1_$2$3','tokenize');
    % Replace one-tag format by open / close tagging
    if plt==1;disp('4. Replace one-tag format by open / close tagging');end
    xml_=regexprep(xml,'<(\w+)([^>]*?)/>','<$1$2></$1>','tokenize');
    % Turn attributes into contents
    if plt==1;disp('5. Turn attributes into contents');end
    xml=regexprep(xml_,'<([^>]+) +(\w+)="(.*?)" *>','<$1><$2>$3</$2>','tokenize');
    while ~strcmp(xml,xml_)
        %disp('...')
        xml_=xml;xml=regexprep(xml_,'<([^>]+) +(\w+)="(.*?)" *>','<$1><$2>$3</$2>','tokenize');
    end
    % remove leftover spaces in tag names
    if plt==1;disp('6. Removing leftover spaces in tag names');end
    xml=regexprep(xml,'(<\w+) +>','$1>','tokenize');
    % Tag untagged contents
    if plt==1;disp('7. Tagging untagged contents');end
    yml=regexprep(xml,'(</\w+>)([^<>]+)</(\w+)','$1<$3>$2</$3></$3','tokenize');
    % Tag cell structures
    if plt==1;disp('8. Tag cell structures');end
    yml=regexprep(yml,'<(\w+)>','<$1 class="cell"><cell>','tokenize');
    yml=regexprep(yml,'<(/\w+)>','</""""><$1>','tokenize');
    yml=regexprep(yml,'<(/\w+)>(<\w+ )','<$1></""""><cell>$2','tokenize');
    % Remove cell tag arround content values
    if plt==1;disp('9. Remove cell tag arround content values');end
    yml=regexprep(yml,'class="cell"><cell>([^<]*)</"""">','class="char">$1','tokenize');
    yml=strrep(yml,'</"""">','</cell>');
    if plt==1;disp('------------END----------------------');end
end % of SIMPLIFY_MBML function
%-----------------------------------------------
function theStruct = parseXML(filename)
% PARSEXML Convert XML file to a MATLAB structure.
    try
        tree = xmlread(filename);
    catch
        error('Failed to read XML file %s.',filename);
    end
    
    % Recurse over child nodes. This could run into problems
    % with very deeply nested trees.
    try
        theStruct = parseChildNodes(tree);
    catch ME,
        error('Unable to parse XML file %s.',filename);
    end
end % of PARSEXML function
% ----- Subfunction PARSECHILDNODES -----
function children = parseChildNodes(theNode)
% Recurse over node children.
    children = [];
    if theNode.hasChildNodes
        childNodes = theNode.getChildNodes;
        numChildNodes = childNodes.getLength;
        allocCell = cell(1, numChildNodes);
        
        children = struct(             ...
            'Name', allocCell, 'Attributes', allocCell,    ...
            'Data', allocCell, 'Children', allocCell);
        
        for count = 1:numChildNodes
            theChild = childNodes.item(count-1);
            children(count) = makeStructFromNode(theChild);
        end
    end
end
% ----- Subfunction MAKESTRUCTFROMNODE -----
function nodeStruct = makeStructFromNode(theNode)
% Create structure of node info.
    
    nodeStruct = struct(                        ...
        'Name', char(theNode.getNodeName),       ...
        'Attributes', parseAttributes(theNode),  ...
        'Data', '',                              ...
        'Children', parseChildNodes(theNode));
    
    if any(strcmp(methods(theNode), 'getData'))
        nodeStruct.Data = char(theNode.getData);
    else
        nodeStruct.Data = '';
    end
end
% ----- Subfunction PARSEATTRIBUTES -----
function attributes = parseAttributes(theNode)
    % Create attributes structure.
    
    attributes = [];
    if theNode.hasAttributes
        theAttributes = theNode.getAttributes;
        numAttributes = theAttributes.getLength;
        allocCell = cell(1, numAttributes);
        attributes = struct('Name', allocCell, 'Value', ...
            allocCell);
        
        for count = 1:numAttributes
            attrib = theAttributes.item(count-1);
            attributes(count).Name = char(attrib.getName);
            attributes(count).Value = char(attrib.getValue);
        end
    end
end % of PARSEATTRIBUTES function
%-----------------------------------------------
function yml = simplify_mbml( xml )
%SIMPLIFY_MBML simplifies the MbML representation by removing attributes with default values
%Syntax: yml=simplify_mbml(xml)
%Description:
%   - Input arguments -
%     xml is a MbML XML statement (string)
%   - Output arguments -
%     yml is the simplified version (string)
%
%Jonas Almeida, almeidaj@musc.edu,29 Oct 2002

%1. remove size for char and double when they are null, elements or
%horizontal vectors
    
    yml=regexprep(xml,' class=(("double")|("char")|("struct")|("cell")) size="[01] \d*"',' class=$1','tokenize');
    yml=regexprep(yml,' class="char">','>');

end % of SIMPLIFY_MBML function
%-----------------------------------------------
function y = spcharin(x)
    %SPCHARIN replaces special characters by their codes
    %
    % Syntax y=spcharin(x)
    %
    % Description
    %   x is a character or 2D cell array of characters
    %   y is the corresponding version with reserved (special) characters
    %   replaced by '%ascii;' codes
    %
    % See also: SPCHAROUT
    %
    % Jonas Almeida, almeidaj@musc.edu, 8 Oct 2002, MAT4NAT Tbox
    
    if iscell(x)
        [n,m]=size(x);
        for i=1:n
            for j=1:m
                y(i,j)={spcharin(x{i,j})};
            end
        end
    elseif ischar(x)
        x=['AAA',x,'AAA'];% add polyA header and tail
        % replace delimiters first (% and ;)
        x=strrep(x,';','*59;');
        x=strrep(x,'#','#35;');
        x=strrep(x,'*59;','#59;');
        ascii=x*1;% Find special characters
        sp=find(~(((x>47)&(x<58))|((x>96)&(x<123))|((x>64)&(x<91))|(x==59)|(x==35)));
        % Replace them by ascii code delimited by % and ;
        for i=length(sp):-1:1
            x=[x(1:(sp(i)-1)),'#',num2str(ascii(sp(i))),';',x((sp(i)+1):end)];
        end
        y=x(4:end-3); % note plyA head and tail are removed
        %y=x;
    else
        w=whos('x')
        error(['string expected, ',w.class',' found instead'])
    end
end % of SPCHARIN function
%-----------------------------------------------
function y = spcharout(x)
%SPCHAROUT replaces special character codes by their values
%
%Syntax y=spcharout(x)
%
%Description
%   x is a character or 2D cell array of characters
%   y is the corresponding version with special character codes
%     '%ascii;' replaced by their values
%
%See also: spcharin
%
% Jonas Almeida, almeidaj@musc.edu 8 Oct 2002, MAT4NAT Tbox
    
    if iscell(x)
        [n,m]=size(x);
        for i=1:n
            for j=1:m
                y(i,j)={spcharout(x{i,j})};
            end
        end
    elseif ischar(x)
        y=eval(['[''',regexprep(x,'\#(\d+);',''',char($1),'''),''']']);
    else
        w=whos('x')
        error(['string expected, ',w.class',' found instead'])
    end
end % of SPCHAROUT function
%-----------------------------------------------
function [to_eval,eval_i,j]=tag2eval(tag_contents,to_eval,eval_i,j,tags)
    %TAG2EVAL Extacts statements for evaluation by XML2MAT
    %
    %Syntax: [to_eval,eval_i,j]=tag2eval(tag_contents,to_eval,j)
    %
    %Description:
    % Autorecursive function that parses tag_contents structure
    % generated within XML2MAT (see %RECOVER STRUCTURE while loop)
    %
    % See Also: xml2whos
    %
    % Jonas Almeida, almeidaj@musc.edu 20 Aug 2002, XML4MAT Tbox
    
    i=tags(j);
    w=tag_contents{i,2};%disp(i)
    if ~isfield(w,'class');w.class='struct';w.size=[1 1];tag_contents{i,2}=w;end
    if strcmp(w.class,'struct')
        if ~isfield(w,'size')
            n_fields=length(w.fields);
            for f_i=1:n_fields
                field_names{f_i}=tag_contents{w.fields(f_i),2}.name;
            end
            unique_names=unique(field_names);
            n_unique=length(unique_names);
            n_certo=(n_fields/n_unique);
            w.size=[1 n_certo];
        end
        nn=prod(w.size); %number of elements
        nf=length(w.fields); %number of fields per element
        iis='i1';for ii=2:length(w.size);iis=[iis,',i',num2str(ii)];end %indexes
        eval(['[',iis,']=ind2sub(w.size,[1:nn]);']); % assigning values to indexes
        iis='i1(ind)';for ii=2:length(w.size);iis=[iis,',i',num2str(ii),'(ind)'];end % indexes of indexes
        %disp(iis)
        for ind=1:nn
            for ind_f=1:(nf/nn)
                %disp(['ind=',num2str(ind),' nf=',num2str(nf)])
                j=j+1;%disp(['j=',num2str(j)])
                i=tags(j);
                field_name=tag_contents{w.fields(ind_f),2}.name;iis_val=num2str(eval(['[',iis,']']));
                iis_val(findstr(iis_val,'  '))=[];iis_val(isspace(iis_val))=',';
                eval_i{length(eval_i)+1}=['(',iis_val,').',field_name];
                [to_eval,eval_i,j]=tag2eval(tag_contents,to_eval,eval_i,j,tags);
                %eval_i_str='';for eval_i_j=1:length(eval_i);eval_i_str=[eval_i_str,eval_i{eval_i_j}];end;eval_i_str=[eval_i_str,'=tag_contents{',num2str(i),',4};'];disp(eval_i_str)
                %to_eval{length(to_eval)+1}=eval_i_str;
                eval_i(end)=[];
            end
        end
    elseif strcmp(w.class,'cell')
        if ~isfield(w,'size')
            w.size=[1,length(w.fields)];
        end
        nn=prod(w.size); %number of elements
        nf=length(w.fields); %number of fields per element
        iis='i1';for ii=2:length(w.size);iis=[iis,',i',num2str(ii)];end %indexes
        eval(['[',iis,']=ind2sub(w.size,[1:nn]);']); % assigning values to indexes
        iis='i1(ind)';for ii=2:length(w.size);iis=[iis,',i',num2str(ii),'(ind)'];end % indexes of indexes
        %disp(iis)
        for ind=1:nn
            for ind_f=1:(nf/nn)
                %disp(['ind=',num2str(ind),' nf=',num2str(nf)])
                j=j+1;%disp(['j=',num2str(j)])
                i=tags(j);
                %disp(iis)
                
                field_name=tag_contents{w.fields(ind_f),2}.name;iis_val=num2str(eval(['[',iis,']']));
                iis_val(findstr(iis_val,'  '))=[];iis_val(isspace(iis_val))=',';
                eval_i{length(eval_i)+1}=['{',iis_val,'}'];
                [to_eval,eval_i,j]=tag2eval(tag_contents,to_eval,eval_i,j,tags);
                %eval_i_str='';for eval_i_j=1:length(eval_i);eval_i_str=[eval_i_str,eval_i{eval_i_j}];end;eval_i_str=[eval_i_str,'=tag_contents{',num2str(i),',4};'];disp(eval_i_str)
                %to_eval{length(to_eval)+1}=eval_i_str;
                eval_i(end)=[];
            end
        end
    elseif strcmp(w.class,'cellstruct')
        %disp(w)
        eval_i{end+1}={};
        for i=1:length(w.fields)
            ww=tag_contents{w.fields(i),2};
            field_exist{i}=ww.name;
            n=sum(strcmp(ww.name,field_exist));
            %disp(['field [',ww.name,'] ',num2str(n)]);
            %eval_i{length(eval_i)+(i==1)}=['.',ww.name,'{',num2str(n),'}'];
            eval_i{length(eval_i)}=['.',ww.name,'{',num2str(n),'}'];
            j=j+1;
            [to_eval,eval_i,j]=tag2eval(tag_contents,to_eval,eval_i,j,tags);
            %if ((i>1)&(n==1));to_eval(end)=[];end
            %disp([eval_i,'.',ww.name])
            %disp(BM_tag2eval(
        end
        eval_i(end)=[];
        clear field_exist;
    else % str or double
        %disp('not struct')
        eval_i_str='';for eval_i_j=1:length(eval_i);eval_i_str=[eval_i_str,eval_i{eval_i_j}];end;eval_i_str=[eval_i_str,'=tag_contents{',num2str(i),',4};'];%disp(eval_i_str)
        to_eval{length(to_eval)+1}=eval_i_str;
    end
    %j=j+1;
end % of TAG2EVAL function
%-----------------------------------------------
function [y,varname] = xml2cell( filename_or_xml_string )
%XML2CELL reads non-MbML compliant xmlfile into matlab nested cell arrays
%
% Syntax [y,varname]=xmlfile2cell(filename_or_xml_string)
%
% Description:
%   1. Convert any non-MbML xml into MbML compliant string
%   2. Stores individual structures as nested cell arrays
%
% If it cannot be garanteed that non-MbML compliant XML has an
% internal referential consistency for convenient conversion to structures,
% this function builds the m-variable object model (MOM) as nested
% cell arrays. This approach ignores the possible dimensionality of the
% object and stores each entry, in a single cell, nested at the
% appropriate level.
%
% Note 1 : if your XML string is MbML compliant use XML2MAT instead
% Note 2 : if your XML structure has consistent dimensionality use XML2STRUCT instead
%
% See also: XML2STRUCT, XML2MAT
%
% Jonas Almeida, almeidaj@musc.edu, 19 May 2003, MAT4NAT Tbox

% is this a xml string or xml filename ?
    if filename_or_xml_string(1)=='<'
        y=filename_or_xml_string;
    else
        y=strrep(file2str(filename_or_xml_string),'''','''''');
    end
    
    % convert first to MbML compliant string and then onto an m-variable
    [y,varname]=xml2mat(mbmling(y,1));
    
end % of XML2CELL function
%-----------------------------------------------
function [y,varname] = xml2struct(filename_or_xml_string)
%XML2STRUCT reads non-MbML compliant xmlfile into matlab structure
%
% Syntax: [y,varname]=xml2struct(filename_or_xml_string)
%
% Description:
%   1. Convert any non-MbML xml into MbML compliant string
%   2. Stores consecutive structures in the a dimensional strucure
%
% If the non-MbML compliant XML has a consistent internal reference structure
% (those that were derived from explicit data models often do)
% this conversion will produce the best results, by building
%
% Note: if your XML string is MbML compliant use XML2MAT instead
%
% See also: XML2STRUCT
%
% Jonas Almeida, almeidaj@musc.edu, 19 May 2003, MAT4NAT Tbox
    
    [y,varname]=xml2cell(filename_or_xml_string);
    y = consolidateall( y );

end % of XML2STRUCT function
%-----------------------------------------------
function w = xml2whos(w_xml)
%XML2WHOS identifies WHOS-type structured variable from xml descriptor
%
%Syntax: w=xml2whos(w_xml)
%
%Description
% w is a structured variable with the information that would have benn
%   returned by a WHOS command of the structured variable
% w_xml is the corresponding xml descriptor, e.g. '<name class size>'
%
% See Also: xml2mat, whos
%
% Jonas Almeida, almeidaj@mussc.edu, 20 Aug 2002, XML4MAT Tbox
    
    w_xml=[w_xml,' '];
    % extract name
    i=1;while ~isspace(w_xml(i));i=i+1;end;w.name=w_xml(1:i-1);
    % extract properties
    i=i+1;i_1=i;is_value=0;
    while i<length(w_xml)
        while ((~isspace(w_xml(i)))|is_value);i=i+1;if w_xml(i)=='"';is_value=~is_value;end;end;i_end=i-1;descrp=w_xml(i_1:i_end); % extract description
        j=1;while descrp(j)~='=';j=j+1;end;propt=descrp(1:j-1); %extract property name
        j=j+1;if descrp(j)~='"';error(['XML error 03: property value is not delimited by " " :',w_xml]);end;j=j+1;
        j_1=j;while descrp(j)~='"';j=j+1;end;j_end=j-1;propt_value=descrp(j_1:j_end); %extract property value
        %disp(['descriptor: ',descrp]);disp(['name: ',propt]);disp(['value: ',propt_value])
        eval(['w.',propt,'=''',propt_value,''';'])
        i=i+1;i_1=i;
    end
    
    if isfield(w,'size');w.size=str2num(w.size);end
end % of XML2WHOS function