<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Disable SSL 3.0
#>
Function Disable-eSSLv3 {

    [CmdletBinding()]
    
    param()
    
    try {

        $null = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' -Force
        $null = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' -name Enabled -value 0 -PropertyType 'DWord' -Force
        $null = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force
        $null = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client' -Force
        $null = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client' -name Enabled -value 0 -PropertyType 'DWord' -Force
        $null = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client' -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force
        
        $SSLv3Disabled = $True
        
    }
    catch {
        
        $SSLv3Disabled = $False
        
    }
        
    $Output = [PSCustomObject]@{
        
        Computername  = $env:COMPUTERNAME
        SSLv3Disabled = $SSLv3Disabled
        
    }
        
    Write-Output $Output
    
}