function hostName = getHostName()

    if ispc,
        envVarName = 'COMPUTERNAME';
    else
        envVarName = 'HOSTNAME';
    end

    hostName = lower( strtok( getenv( envVarName ), '.' ) );

end