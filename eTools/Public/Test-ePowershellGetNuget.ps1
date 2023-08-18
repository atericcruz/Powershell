<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Sets PSGallery as Trusted, checks that PowershellGet is updated to at least 2.2.5 and installs Nuget as required for many Powershell modules (Nimble,Pure,VMware,etc). 
#>
Function Test-ePowershellGetNuget {

    [CmdletBinding()]
    
    param()
    
    if ((Get-Module -Name PowershellGet -ListAvailable).Version -notcontains '2.2.5' ) {

        Write-Host "Updating PowershellGet and Nuget" -ForegroundColor Yellow
    
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
        Install-PackageProvider Nuget -Force
        Install-Module -Name PowerShellGet -RequiredVersion 2.2.5 -Force -AllowClobber
        Update-Module -Name PowerShellGet -Force -RequiredVersion 2.2.5
        Import-Module PowerShellGet -RequiredVersion 2.2.5

        Write-Host "Updated PowershellGet and Nuget.`nSometimes a new powershell session may need to be launched" -ForegroundColor Green

    }
    else {

        Write-Host "PowershellGet and Nuget are upto date" -ForegroundColor Green
        
    }

}