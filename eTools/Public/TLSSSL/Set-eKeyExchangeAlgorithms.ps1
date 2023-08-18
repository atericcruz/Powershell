<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Enable TLS 1.2 for .NET 3.5 and .NET 4.x

  'Diffie-Hellman',
  'ECDH',
  'PKCS'

#>

Function Set-eKeyExchangeAlgorithms { 

    [CmdletBinding()]
    
    param(

        $Algorithms = @('Diffie-Hellman', 'ECDH', 'PKCS')

    )

    Begin {

        $KeyPath = 'SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms'
        $Date = Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' 

        $Result = [ordered]@{

            Date         = $Date
            Computername = $env:COMPUTERNAME
    
        }
    
    }
    Process {

        Foreach ($Algorithm in $Algorithms) {

            try {

                $Key = (Get-Item HKLM:\).OpenSubKey($KeyPath, $true).CreateSubKey($Algorithm)
                $null = New-ItemProperty -path "HKLM:\$KeyPath\$Algorithm" -name 'Enabled' -value '0xffffffff' -PropertyType 'DWord' -Force
                $Key.close()
            
                $AlgorithmsSet = 'Enabled'
               
            }
            catch {
                
                $AlgorithmsSet = "$($Error.Exception.Message)"

            }

            $null = $Result.Add("$Algorithm", "$AlgorithmsSet") 

        }
    
        $Output = [PSCustomObject]$Result
    
        Write-Output $Output

    }

}