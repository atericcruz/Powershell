Function Test-eUCSModules {

    [CmdletBinding()]
       
    param()
           
    Begin { 
   
        if (!(Get-Module -Name Cisco.IMC, Cisco.UCS.Common, Cisco.UCSCentral, Cisco.UCSManager -ListAvailable -ErrorAction SilentlyContinue)) {
           
            Write-Host "$(Get-eDate) INFO - Installing Cisco Powershell modules Cisco.IMC, Cisco.UCS.Common, Cisco.UCSCentral, Cisco.UCSManager as they are missing."  -ForegroundColor Yellow
   
            $Error.Clear()
   
            try {
   
                $null = Install-Module -Name Cisco.IMC, Cisco.UCS.Common, Cisco.UCSCentral, Cisco.UCSManager -Force -AllowClobber -SkipPublisherCheck -Confirm:$false -ErrorAction Stop
   
                Write-Host "$(Get-eDate) SUCCESS - Installed Cisco Powershell modules Cisco.IMC, Cisco.UCS.Common, Cisco.UCSCentral, Cisco.UCSManager"  -ForegroundColor Green
   
                $Success = $True
            }
            catch {
   
                $Error.Clear()
   
                try {
   
                    $null = Install-Module -Name Cisco.IMC, Cisco.UCS.Common, Cisco.UCSCentral, Cisco.UCSManager -Force -AllowClobber -SkipPublisherCheck -Confirm:$false -AcceptLicense -ErrorAction Stop
   
                    $Success = $True
                   
                }
                catch {
   
                    Write-Host "$(Get-eDate) ERROR - Install of Cisco Powershell modules Cisco.IMC, Cisco.UCS.Common, Cisco.UCSCentral, Cisco.UCSManager failed" -ForegroundColor Yellow
   
                    $Success = $False
   
                }
   
            }
   
        }else{

            $Success = $True
        }
   
    }
   
    Process {
           
        if ($Success -eq $True) {
           
            Write-Host "$(Get-eDate) INFO - Importing Cisco Powershell module" 
   
            $null = Import-Module Cisco.IMC, Cisco.UCS.Common, Cisco.UCSCentral, Cisco.UCSManager -Force 
   
            Write-Host "$(Get-eDate) SUCCESS - Imported Cisco Powershell module" 
                   
        }
        else {
            
            $Success = $False
            Write-Host "$(Get-eDate) ERROR - Install and import of Cisco Powershell modules Cisco.IMC, Cisco.UCS.Common, Cisco.UCSCentral, Cisco.UCSManager was not successfull" -ForegroundColor Red
            Write-Host "$("`t"*6)ERROR - TRACE: $($Error[0].ScriptStackTrace)" -ForegroundColor Red
            Write-Host "$("`t"*6)ERROR - MESSAGE: $($Error[0].Exception.Message)" -ForegroundColor Red
            Write-Host "$("`t"*6)ERROR - CategoryInfo: $($Error[0].CategoryInfo)" -ForegroundColor Red
            Write-Host "$("`t"*6)ERROR - FullyQualifiedErrorId: $($Error[0].FullyQualifiedErrorId)" -ForegroundColor Red
            Write-Host "$("`t"*6)ERROR - InvocationInfo: $($Error[0].InvocationInfo)" -ForegroundColor Red
           
        }

        return  $Success
           
    }
           
}