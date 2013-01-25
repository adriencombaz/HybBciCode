classdef erpDataset < handle
   
    properties
        
        nBdfFile        = 0;
        continousEEG    = [];
        eventSampleInd  = [];
        chanList        = {};
        stimId          = [];
        stimLabel       = {};
        
    end
    
    methods
    
        function obj = erpDataset()
        end
        
        function plotErps( obj )
        end
        
    end
    
end