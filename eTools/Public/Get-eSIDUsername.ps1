<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Translate a SID id to a Username
#>
Function Get-eSIDUsername {

    [CmdletBinding()]
    
    param(

        [ValidateNotNullorEmpty()]
        $SID
        
    )
    
    try {
    
        $SIDObject = New-Object System.Security.Principal.SecurityIdentifier($SID)
        $NTAccount = $SIDObject.Translate([System.Security.Principal.NTAccount])
        $Username = $NTAccount.Value
    
    }
    catch {
    
        $Username = $Error.Exception.Message
    
    }
    
    Write-Output $Username
    
}
    