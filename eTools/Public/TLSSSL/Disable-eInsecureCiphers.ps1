<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Disabled insecure ciphers
Current: 

        'DES 56/56',
        'NULL',
        'RC2 128/128',
        'RC2 40/128',
        'RC2 56/128',
        'RC4 40/128',
        'RC4 56/128',
        'RC4 64/128',
        'RC4 128/128',
        'Triple DES 168'

#>

Function Disable-eInSecureCiphers { 

    [CmdletBinding()]
    
    param( 

        $InsecureCiphers = @(

            'DES 56/56',
            'NULL',
            'RC2 128/128',
            'RC2 40/128',
            'RC2 56/128',
            'RC4 40/128',
            'RC4 56/128',
            'RC4 64/128',
            'RC4 128/128',
            'Triple DES 168'
        
        )
        
    )

    $CiphersKeyPath = 'SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers'
    
    if (!(Test-Path "HKLM:\$CiphersKeyPath" -ErrorAction SilentlyContinue)) {

        $null = New-Item "HKLM:\$CiphersKeyPath" -Force

    }
     
    $Date = Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' 

    $Result = [ordered]@{

        Date         = $Date
        Computername = $env:COMPUTERNAME

    }

    Foreach ($InSecureCipher in $InSecureCiphers) {

        try {

            $Cipher = "$CiphersKeyPath\$($InSecureCipher)"

            if ((Get-ItemProperty "$Cipher" -Name Enabled -ErrorAction SilentlyContinue).Enabled -ne 0) {

                $Key = (Get-Item HKLM:\).OpenSubKey($CiphersKeyPath, $true).CreateSubKey($InSecureCipher)
                $Key.SetValue('Enabled', 0, 'DWord')
                $Key.close()
            
            }

            $Disabled = 'Disabled'

        }
        catch {

            $Disabled = "$($Error.Exception.Message)"

        }

        $null = $Result.Add("$InSecureCipher", "$Disabled") 

    }

    $Output = [PSCustomObject]$Result

    Write-Output $Output
        
}