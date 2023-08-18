Function Test-eAzureModule {

    [CmdletBinding()]

    param()

    $Error.Clear()
    
    try {

        $null = Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
        IF (  (Test-eIsAdmin -ErrorAction Stop) -ne $True ) {
            throw "Please Run As Admin"
            break

        }

    }
    catch {

        $Error
        break

    }
        
    if (!(Get-Module -Name PowerShellGet  -ListAvailable | Where-Object { $_.Version -eq '2.2.5' })) {
    
        Write-Host "Installing new PowerShellGet" -ForegroundColor Yellow

        $null = Install-Module -Name PowerShellGet -Force 
        
        Write-Host "Installed new PowerShellGet" -ForegroundColor Green
    
    }
    
    if (Get-Module -Name AzureRM  -ListAvailable) {
    
        Write-Host "Removing old AzureRM Powershell module" -ForegroundColor Yellow

        $null = Uninstall-Module -Name AzureRM -Force

        Write-Host "Removed old AzureRM Powershell module" -ForegroundColor Green
    
    }
    
    if (!(Get-Module -Name Az.* -ListAvailable)) {
    
        Write-Host "Installing AZ Powershell module" -ForegroundColor Yellow

        try {

            Install-Module -Name Az -Repository PSGallery -Force -ErrorAction Stop

        }
        catch {

            Write-Host "ERROR: Installing AZ Powershell module: $($Error.Exception.Message)" -ForegroundColor Red

            if ( ($Error.Exception.Message -match 'AllowCobber') -or ($Error -contains 'AllowClobber')) {

                Write-Host "Installing AZ Powershell module with -AllowClobber" -ForegroundColor 
                
                try {

                    $null = Install-Module -Name Az -Repository PSGallery -Force -AllowClobber -ErrorAction Stop

                }
                catch {

                    return $Error
                    break
                    
                }

            }
            else {

                return $Error

            }

        }

        Write-Host "Installed AZ Powershell module" -ForegroundColor Green
        # $null = Import-Module AZ.* -Force
        return
    
    }
    
    if (!(Get-Module -Name Az.* -ListAvailable)) {
    
        Write-Error "Powershell Azure module AZ is not installed. Please resolve first, then try again"
        return
    
    }

}