function IOaddress = getLPTportIOAddress( desiredLPTport )
    
    switch lower( getHostName() )
        case 'neu-wrk-0158',
            IOaddress = 60416;
        otherwise
            
            if nargin == 0,
                desiredLPTportName = 'LPT1';
            else
                if ischar( desiredLPTport ),
                    desiredLPTportName = upper( desiredLPTport );
                elseif isnumeric( desiredLPTport ) && numel(desiredLPTport)==1 && desiredLPTport>0 && round( desiredLPTport ) == desiredLPTport,
                    desiredLPTportName = sprintf( 'LPT%d', desiredLPTport );
                else
                    error( 'Wrong input parameter!' );
                end
            end
            
            objLocator  = actxserver('WbemScripting.SWbemLocator');             % COM connection
            objService  = objLocator.ConnectServer('.', 'root\cimv2' );            % connet to WMI
            colItems    = objService.ExecQuery('SELECT * FROM Win32_ParallelPort', 'WQL' );
            
            if colItems.Count == 0,
                disp( 'Can''t find parallel port' );
                IOaddress = [];
                return
            end
            
            try
                a = colItems.Item( ['Win32_ParallelPort.DeviceID="' desiredLPTportName '"'] );
            catch %#ok<CTCH>
                error('Cannot find requested LPT port.');
            end
            pportText = a.GetObjectText_;
            
            [PNPDeviceIDs, ~] = regexp( pportText, 'PNPDeviceID = "(.*)";', 'tokens', 'match', 'dotexceptnewline' );
            PNPDeviceID = PNPDeviceIDs{1};
            PNPDeviceID = strrep( PNPDeviceID{1}, '\\', '\' );
            
            regData = typecast( regQuery( 'HKLM', ['SYSTEM\CurrentControlSet\Enum\' PNPDeviceID '\Control'], 'AllocConfig' ), 'uint32' );
            IOaddress = regData(7);
            
            if ~IOaddress,
                regData = typecast( regQuery( 'HKLM', ['SYSTEM\CurrentControlSet\Enum\' PNPDeviceID '\LogConf'], 'BasicConfigVector' ), 'uint32' );
                IOaddress = regData(15);
            end
    end
    
end % of function GETLPTPORTIOADDRESS