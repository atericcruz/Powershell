<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Enable IIS Central Cert Provider
#>
Function Enable-gIISCentralCertProvider {

    [CmdletBinding()]
    
    param(

        $CertStoreLocation,
        $Username,
        $CertStorPassword,
        $PFXPassword

    )

   $null = Remove-Module WebAdministration -Force -ErrorAction SilentlyContinue
   $null = Import-Module WebAdministration -Force
Write-Verbose "pfx: $PFXPassword"
    try {

        $Enabled = $Installed = 'Unknown'

        if ((Get-WindowsFeature Web-CertProvider -ErrorAction SilentlyContinue ).InstallState -eq 'Available') {

            Write-Verbose "Installing Web-CertProvider"

            $Install = Install-WindowsFeature Web-CertProvider
            $Installed = 'Installed'   

            Write-Verbose "Installed Web-CertProvider"

        }
        else {

            $Installed = 'Installed'
            $Enabled = $True
            
        }

        $Parameters = @{

            CertStoreLocation  = $CertStoreLocation  
            Username           = $Username
            Password           = ( "$CertStorPassword"| ConvertTo-SecureString -AsPlainText -Force)
            PrivateKeyPassword = ( "$PFXPassword"| ConvertTo-SecureString -AsPlainText -Force)
			Verbose            = $True

        }

        $Enable = Enable-IISCentralCertProvider @Parameters

        $Enabled = $True
        $CertStoreConfigd = 'Configured'
		
		    $Output = [PSCustomObject]@{

        Date             = "$(Get-Date -Format 'MM-dd-yy HH:mm:ss')"
        Computername     = $env:COMPUTERNAME
        PFXPath          = $CertStoreLocation
        CertStoreEnabled = $Enabled
        CertStoreInstall = $Installed
        CertStoreConfig  = $CertStoreConfigd

    }

  Write-Output $Output

    }
    catch {

        $CertStoreConfigd = @($Error)
        $Enabled = $Installed = 'ERROR'
		
		Write-Output $Error
        
    }

}