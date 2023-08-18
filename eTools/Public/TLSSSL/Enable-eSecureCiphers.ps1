<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Enable secure ciphers
Current: 

        'AES 128/128',
        'AES 256/256'

#>

Function Enable-gSecureCiphers { 

    [CmdletBinding()]
    
    param(

        $SecureCiphers = @(

            'AES 128/128',
            'AES 256/256'

        )

    )

    Begin {

        $CiphersKeyPath = 'SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers'
    
        $Date = Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' 

        $Result = [ordered]@{

            Date         = $Date
            Computername = $env:COMPUTERNAME

        }

    }
    Process {

        Foreach ($SecureCipher in $SecureCiphers) {

            try {

                $Key = (Get-Item HKLM:\).OpenSubKey($CiphersKeyPath, $true).CreateSubKey($SecureCipher)
                $null = New-ItemProperty -path "HKLM:\$CiphersKeyPath\$SecureCipher" -name 'Enabled' -value '0xffffffff' -PropertyType 'DWord' -Force
                $Key.close()

                $Enabled = 'Enabled'

            }
            catch {
                
                $Enabled = "$($Error.Exception.Message)"

            }
 
            $null = $Result.Add("$SecureCipher", "$Enabled") 

        }

        $Output = [PSCustomObject]$Result
        Write-Output $Output

    }

}