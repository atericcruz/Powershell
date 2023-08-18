<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Convert ADSI dates to date

#>

Function Get-eADSIDate {
    
    param($ThisItem)

    $Dated = switch ($ThisItem) {

        { $_ -is [System.MarshalByRefObject] } {

            $Temp = $_

            [Int32]$High = $Temp.GetType().InvokeMember('HighPart', [System.Reflection.BindingFlags]::GetProperty, $Null, $Temp, $Null)
            [Int32]$Low = $Temp.GetType().InvokeMember('LowPart', [System.Reflection.BindingFlags]::GetProperty, $Null, $Temp, $Null)
            Get-Date ([datetime]::FromFileTime([Int64]("0x{0:x8}{1:x8}" -f $High, $Low))) -Format "MM-dd-yyyy hh:mm:ss tt"

        }#

        { $_ -isnot [System.MarshalByRefObject] -and $_ -lt [DateTime]::MaxValue.Ticks } {

            Get-Date ([datetime]::FromFileTime($_)) -Format "MM-dd-yyyy hh:mm:ss tt"

        }#

        { $_ -gt [DateTime]::MaxValue.Ticks -and $_ -isnot [System.MarshalByRefObject] } {

            Get-Date '12/31/1600 7:00:00 PM' -Format "MM-dd-yyyy hh:mm:ss tt"

        }#

    }#switch

    Write-Output $Dated

}#Get-eADSIDate 