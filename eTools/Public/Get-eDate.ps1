<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Private function to format date to MM-dd-yyyy hh:mm:ss AM/PM
#>
Function Get-eDate {

    [CmdletBinding()]
       
    param(
       
        [switch]$ForWriteHost,

        [switch]$WithTimeZone,

        [switch]$IsProdHours
   
    )
           
    $Date = Get-Date
    $TimeZone = "$([Regex]::Replace([System.TimeZoneInfo]::Local.StandardName, '([A-Z])\w+\s*', '$1'))"

    if ($ForWriteHost) {
           
        $Output = "$($Date.ToString('MM-dd-yyyy hh:mm:ss tt') ) -"
           
    }
    elseif ($WithTimeZone) {

        $Output = "$($Date.ToString('MM-dd-yyyy hh:mm:ss tt')) $TimeZone"

    }
    else {
           
        $Output = "$($Date.ToString('MM-dd-yyyy hh:mm:ss tt'))"
           
    }
   
    Write-Output $Output
   
}