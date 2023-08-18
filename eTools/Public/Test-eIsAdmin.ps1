<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Test if currently running as Administrator
#>

Function Test-eIsAdmin {

    [CmdletBinding()]
    
    param()

    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($IsAdmin -eq $false) {

        Write-Error "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' ) - Requires administrative privileges"
        
    }
    else {

        return $IsAdmin

    }
    
}