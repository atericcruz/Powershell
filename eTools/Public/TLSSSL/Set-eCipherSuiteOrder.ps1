<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Set Cipher Suite Order
Current: 

    'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
    'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
    'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384',
    'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256',
    'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA',
    'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA',
    'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
    'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
    'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384',
    'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256',
    'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA',
    'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA'

#>

Function Set-eCipherSuiteOrder { 

    [CmdletBinding()]
    
    param(

        $SuitesOrder = @(

            'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
            'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
            'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384',
            'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256',
            'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA',
            'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA',
            'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
            'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
            'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384',
            'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256',
            'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA',
            'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA'

        )

    )

    Begin {

        $CiphersKeyPath = 'SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002'
    
        $SuitesOrderString = [string]::join(',', $SuitesOrder)

        $Date = Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' 

    }
    Process {

        try {

            New-ItemProperty -path $CiphersKeyPath -name 'Functions' -value $SuitesOrderString -PropertyType 'String' -Force | Out-Null

            $Ordered = 'Enabled'

        }
        catch {
                
            $Ordered = "$($Error.Exception.Message)"

        }

        $Output = [PSCustomObject]@{

            Date         = $Date
            Computername = $env:COMPUTERNAME
            SuitesOdered = $Ordered
            SuitesOrder  = $SuitesOrderString

        }

        Write-Output $Output

    }

}