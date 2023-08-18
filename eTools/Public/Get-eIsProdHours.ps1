<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Private function to check if in prod hours
#>

Function Get-eIsProdHours {

    [CmdletBinding()]
       
    param()
       
    $TimeZone = "$([Regex]::Replace([System.TimeZoneInfo]::Local.StandardName, '([A-Z])\w+\s*', '$1'))"
    $DateEST = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now, "Eastern Standard Time")
    $DatePST = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now, "Pacific Standard Time")
    
    $StartEST = Get-Date '07:00'
    $EndEST = Get-Date '19:00'
    $StartPST = $StartEST.AddHours(-3)
    $EndPST = $EndEST.AddHours(-3)

    if (($StartEST.TimeOfDay -le $DateEST.TimeOfDay -and $EndEST.TimeOfDay -ge $DateEST.TimeOfDay) -or (($StartPST.TimeOfDay -le $DateEST.TimeOfDay -and $EndPST.TimeOfDay -ge $DatePST.TimeOfDay))) {

        $InProdEAST = 'LIVE!'

    }
    else {

        $InProdEAST = 'After Hours'

    }
    
    if ($StartPST.TimeOfDay -le $DatePST.TimeOfDay -and $EndPST.TimeOfDay -ge $DatePST.TimeOfDay) {

        $InProdWEST = 'LIVE!'

    }
    else {

        $InProdWEST = 'After Hours'

    }
    
    $Coast = switch(([ADSISEARCHER]::new("name=$($env:Computername)")).FindOne().Path){
        {"$_" -match "OU=East,"}{'East'}
        {"$_" -match "OU=West,"}{'West'}
        }

    $Output = [PSCustomObject]@{

        Date = Get-eDate -WithTimeZone
        Computername = $env:Computername
        Coast = $Coast
        EST = $DateEST
        East = $InProdEAST   
        PST = $DatePST
        West = $InProdWEST
        UTC  = $DateEST.ToUniversalTime()

    }

    Write-Output $Output

}