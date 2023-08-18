<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Enable Secure Hashes
Current: 

    'SHA',
    'SHA256',
    'SHA384',
    'SHA512'

#>

Function Enable-gSecureHashes { 

    [CmdletBinding()]
    
    param(

        $SecureHashes = @(

            'SHA',
            'SHA256',
            'SHA384',
            'SHA512'
    
        )
    
    )

    $CiphersKeyPath = 'SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes'
    
    if (!(Test-Path "HKLM:\$CiphersKeyPath" -ErrorAction SilentlyContinue)) {

        $null = New-Item "HKLM:\$CiphersKeyPath" -Force

    }

    $Date = Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' 

    $Result = [ordered]@{

        Date         = $Date
        Computername = $env:COMPUTERNAME

    }

    $null = New-Item 'HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes' -Force
    $null = New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\MD5' -Force
    $null = New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\MD5' -name Enabled -value 0 -PropertyType 'DWord' -Force

    Foreach ($SecureHash in $SecureHashes) {

        try {

            $Cipher = "$CiphersKeyPath\$($SecureHash)"

            if ((Get-ItemProperty "$Cipher" -Name Enabled -ErrorAction SilentlyContinue).Enabled -ne 0) {

                $Key = (Get-Item HKLM:\).OpenSubKey($CiphersKeyPath, $true).CreateSubKey($SecureHash)
                $Key.SetValue('Enabled', 0, 'DWord')
                $Key.close()
            
            }

            $Hash = 'Enabled'

        }
        catch {

            $Hash = "$($Error.Exception.Message)"

        }

        $null = $Result.Add("$InSecureCipher", "$Hash") 

    }

    $Output = [PSCustomObject]$Result

    Write-Output $Output
        
}