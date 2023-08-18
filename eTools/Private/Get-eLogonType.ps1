<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Private function for Get-eEventsLogOnOff to translate the logon type from an integer to a string
#>
Function Get-eLogonType {

    [CmdletBinding()]
    
    param(
        $Type
    )
    
    $Output = switch ($Type) {
                            
        0 { "Local System" }
        2 { "Interactive (Local logon)" }
        3 { "Network (Remote logon)" }
        4 { "Batch (Scheduled task)" } 
        5 { "Service (Service account logon)" }
        7 { "Unlock (Screen saver)" }
        8 { "NetworkCleartext (Cleartext network logon)" }
        9 { "NewCredentials (RunAs using alternate credentials)" }
        10 { "RemoteInteractive (RDP\TS\RemoteAssistance)" }
        11 { "CachedInteractive (Local w\cached credentials)" }
        default { 'Unknown' }
    
    }

    Write-Output $Output
    
}#Get-eLogonType