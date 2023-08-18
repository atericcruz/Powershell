<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Enable TLS 1.2 for .NET 3.5 and .NET 4.x

#>

Function Enable-gTLS12ForNET { 

    [CmdletBinding()]
    
    param()

    Begin {

        $Date = Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' 

    }
    Process {

        try {

            $null = New-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727" -name 'SystemDefaultTlsVersions' -value 1 -PropertyType 'DWord' -Force
            $null = New-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727" -name 'SchUseStrongCrypto' -value 1 -PropertyType 'DWord' -Force
            $null = New-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -name 'SystemDefaultTlsVersions' -value 1 -PropertyType 'DWord' -Force
            $null = New-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -name 'SchUseStrongCrypto' -value 1 -PropertyType 'DWord' -Force
      
            if (Test-Path 'HKLM:\SOFTWARE\Wow6432Node') {
      
                $null = New-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727" -name 'SystemDefaultTlsVersions' -value 1 -PropertyType 'DWord' -Force
                $null = New-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727" -name 'SchUseStrongCrypto' -value 1 -PropertyType 'DWord' -Force
                $null = New-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319" -name 'SystemDefaultTlsVersions' -value 1 -PropertyType 'DWord' -Force
                $null = New-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319" -name 'SchUseStrongCrypto' -value 1 -PropertyType 'DWord' -Force
      
            }

            $TLSForNET = 'Enabled'
               
        }
        catch {
                
            $TLSForNET = "$($Error.Exception.Message)"

        }

        $Output = [PSCustomObject]@{

            Date         = $Date
            Computername = $env:COMPUTERNAME
            TLSForNET    = $TLSForNET

        }

        Write-Output $Output

    }

}