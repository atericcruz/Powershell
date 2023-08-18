<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Get My Personal (server) SSL certificates
#>
Function Get-eSslPersonalCerts {

    [CmdletBinding()]
    
    param(
    
        $Thumbprint,
        $Serial
    
    )
    
    if ($Thumbprint) {

        $Roots = @(Get-ChildItem -Path Cert:\LocalMachine\My\$Thumbprint)

    }
    elseif ($Serial) {

        $Roots = @(Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Serial -like "$Serial*" })

    }
    else {
    
        $Roots = @(Get-ChildItem -Path Cert:\LocalMachine\My )
    
    }

    $Output = Foreach ($Cert in $Roots) {
    
        $KeyName = $Cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
        $KeyPath = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\"
        $FullPath = $KeyPath + $KeyName
        $ACL = (Get-Item $FullPath).GetAccessControl('Access')
    
        $Full = (($ACL.Access | Group-Object FileSystemRights | Where-Object { $_.Name -eq 'FullControl' } ).Group.IdentityReference.value -replace 'BUILTIN\\' -replace 'NT AUTHORITY\\' | Sort-Object -Unique ) -join ','
        $Read = (($ACL.Access | Group-Object FileSystemRights | Where-Object { $_.Name -like 'Read*' }).Group.IdentityReference.value -replace 'BUILTIN\\' -replace 'NT AUTHORITY\\' | Sort-Object -Unique ) -join ','
        $ReadWrite = (($ACL.Access | Group-Object FileSystemRights | Where-Object { $_.Name -like 'Write*' }).Group.IdentityReference.value -replace 'BUILTIN\\' -replace 'NT AUTHORITY\\' | Sort-Object -Unique ) -join ','
        $SSLThumbprint = $Cert.Thumbprint
        $Friendly = "$($Cert.FriendlyName)"
        $NotAfter = "$($Cert.NotAfter)"
        $NotBefore = "$($Cert.NotBefore)"
        $Subject = "$($Cert.Subject)"
        $Issuer = "$($Cert.Issuer)"
        $SSLSerial = "$($cert.SerialNumber)"
        $NameList = "$($Cert.DnsNameList -join ',')"
        $Days = "$((New-TimeSpan -Start (Get-Date) -End $NotAfter).Days)"

        if ($Days -like '-*') { 
            
            $Expired = $TRUE 
        
        }
        else { 
            
            $Expired = $FALSE 
        
        }

        [PSCustomObject]@{
    
            Computername = $env:Computername
            Store        = 'LocalMachine\Personal'
            Friendly     = $Friendly
            Expired      = $Expired
            StartDate    = $NotBefore
            Expires      = $NotAfter
            ExpiresDays  = $Days
            DNSNames     = $NameList
            Thumbprint   = $SSLThumbprint
            Serial       = $SSLSerial
            Issuer       = $Issuer
            Subject      = $Subject 
            Full         = $Full
            ReadWrite    = $ReadWrite
            Read         = $Read    
        
        }
    
    }
    
    Write-Output $Output
    
}