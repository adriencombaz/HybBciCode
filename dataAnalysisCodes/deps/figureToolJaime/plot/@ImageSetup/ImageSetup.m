%example
%h = ImageSetup; 
%h.I_FontSize = 14; 
%h.I_FontName = 'Arial'; 
%h.I_Width = 8;
%h.I_High= 8;
%h.I_TitleInAxis = 1;
%h.I_Space = [0.01,0.01];
%h.I_Ylim = [-200,200];
%h.I_Grid = 'off'; 
%h.I_KeepColor = 0; 
%h.prepareAllFigures
classdef ImageSetup < hgsetget
   properties 
      I_Width;
      I_High;
      I_Unit;
      I_DPI;
      I_FontSize;
      I_FontName;
      I_Legend;
      I_LegendLocation;
      I_Xlabel;
      I_Ylabel;
      I_Title;
      I_Box;
      I_Grid;
      I_Handles;
      I_Space;
      I_AutoYlim;
      I_Ylim;
      I_AutoXlim;
      I_Xlim;
      I_KeepColor;
      I_LineWidth;
      I_TitleInAxis;
      I_AlignAxesTexts;
      I_LegendBox;
      I_Matrix;
      ResetLineWidth;
      OptimizeSpace;
   end 
   properties (GetAccess = private)
       verAddedHandles;
       horAddedHandles;
       arrayAddedHandles;
       updateContainerFigure;
       hOutFig;
   end
   methods 
      function obj = ImageSetup()
          obj.I_Width = 17.8;% Hearing research 17.8 double column and 8.4single column
          obj.I_High = 16;
          obj.I_Unit='centimeters';
          obj.I_DPI=300;
          obj.I_FontSize = 8;
          obj.I_FontName = 'Arial';
          obj.I_Legend = 'on';
          obj.I_LegendLocation = '';
          obj.I_Xlabel = 'on';
          obj.I_Ylabel = 'on';
          obj.I_Title = 'on';
          obj.I_Box = 'on';
          obj.I_Grid = 'on';
          obj.hOutFig = -1;
          obj.I_Space = [0.015 0.015];
          obj.I_AutoYlim = false;
          obj.I_Ylim = [-inf inf];
          obj.I_AutoXlim = false;
          obj.I_Xlim = [-inf inf] ;
          obj.I_TitleInAxis = true;
          obj.I_KeepColor = false;
          obj.I_LineWidth = 1;
          obj.I_AlignAxesTexts = true;
          obj.I_LegendBox = true;
          obj.I_Matrix = [4,4];
          obj.ResetLineWidth = false;
          obj.updateContainerFigure = true;
          obj.OptimizeSpace = true;
      end
      function obj = set.I_High(obj,high)
         if isfloat(high)
            obj.I_High = high;
         else
            error('high must be float')
         end
      end
      function obj = set.I_Width(obj,width)
         if isfloat(width)
            obj.I_Width = width;
         else
            error('width must be float')
         end
      end
      function obj = set.I_Unit(obj,unit)
         if isstr(unit)
            obj.I_Unit = unit;
         else
            error('unit must be string')
         end
      end
      function obj = set.I_DPI(obj,dpi)
         if isfloat(dpi)
            obj.I_DPI = dpi;
         else
            error('dpi must be float')
         end
      end
      function obj = set.I_FontSize(obj,fontsize)
         if isfloat(fontsize)
            obj.I_FontSize = fontsize;
         else
            error('fontsize must be float')
         end
      end
      function obj = set.I_FontName(obj,fontName)
         if isstr(fontName)
            obj.I_FontName = fontName;
         else
            error('fontName must be string')
         end
      end
      
      function obj = set.I_Legend(obj,onoff)
         if isstr(onoff)
            obj.I_Legend = onoff;
         else
            error('onoff must be string')
         end
      end
     
      function obj = set.I_LegendLocation(obj,location)
         if isstr(location)
            obj.I_LegendLocation = location;
         else
            error('location must be string')
         end
      end
      function obj = set.I_Xlabel(obj,onoff)
         if isstr(onoff)
            obj.I_Xlabel = onoff;
         else
            error('onoff must be string')
         end
      end
      function obj = set.I_Ylabel(obj,onoff)
         if isstr(onoff)
            obj.I_Ylabel = onoff;
         else
            error('onoff must be string')
         end
      end
      function obj = set.I_Title(obj,onoff)
         if isstr(onoff)
            obj.I_Title = onoff;
         else
            error('onoff must be string')
         end
      end
      function obj = set.I_Box(obj,onoff)
         if isstr(onoff)
            obj.I_Box = onoff;
         else
            error('onoff must be string')
         end
      end
      function obj = set.I_Grid(obj,onoff)
         if isstr(onoff)
            obj.I_Grid = onoff;
         else
            error('onoff must be string')
         end
      end
      function obj = set.I_Space(obj,space)
         if isvector(space)
            obj.I_Space = space;
            obj.updateContainerFigure = true;
         else
            error('width must be vector')
         end
      end
      function obj = set.I_AutoYlim(obj,auto)
         if islogical(auto)
            obj.I_AutoYlim = auto;
         else
            error('width must be logical')
         end
      end
      function obj = set.I_Ylim(obj,lim)
         if isvector(lim)
            obj.I_Ylim = lim;
            obj.updateContainerFigure = true;
         else
            error('width must be vector')
         end
      end
      function obj = set.I_AutoXlim(obj,auto)
         if islogical(auto)
            obj.I_AutoXlim = auto;
         else
            error('width must be logical')
         end
      end
      function obj = set.I_Xlim(obj,lim)
         if isvector(lim)
            obj.I_Xlim = lim;
            obj.updateContainerFigure = true;
         else
            error('width must be a vector')
         end
      end
   end
end