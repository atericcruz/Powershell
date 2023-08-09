Function Install-Nuget {

    [CmdletBinding()]

    Param()

    Begin { 
    
    Start-Transcript C:\Temp\Log.log 
    
    }#Begin

    Process {

        try {

            $Result = Install-PackageProvider Nuget -Scope AllUsers -Force -ErrorAction Stop

            $Result = "Successfully installed Nuget Powershell Package Providor"

        }
        catch {

            $Result = $Error | FL -Force

        }

    }#Process

    End {

        Stop-Transcript 
        Write-Output $Result

    }#End

}
