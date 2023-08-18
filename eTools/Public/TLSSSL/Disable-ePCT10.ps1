<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Disable PCT 1.0
#>
Function Disable-ePCT10 {

    [CmdletBinding()]
    
    param()
    
    try {

        $null = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Server' -Force
        $null = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Server' -name Enabled -value 0 -PropertyType 'DWord' -Force
        $null = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Server' -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force
        $null = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Client' -Force
        $null = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Client' -name Enabled -value 0 -PropertyType 'DWord' -Force
        $null = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Client' -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force
        
        $PCTv1Disabled = $True
        
    }
    catch {
        
        $PCTv1Disabled = $False
        
    }
        
    $Output = [PSCustomObject]@{
        
        Computername  = $env:COMPUTERNAME
        PCTv1Disabled = $PCTv1Disabled
        
    }
        
    Write-Output $Output
    
}