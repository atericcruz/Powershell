Function New-eDNS {

[CmdletBinding()]

    param(
    
        $DNSParameters,
        $DomainControllers = @([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().DomainControllers.Name),
        [PSCredential] $Credential
    
    )
    
    
    $InvokeDNS = Invoke-Command -ScriptBlock {
    
        param($Parameters)
    
          $Error.Clear()
    
        try {
           
            Add-DnsServerResourceRecordA @Parameters

            $Result = 'Success'
    
        }
        catch {
    
            $id = ($Error[0].FullyQualifiedErrorId -split '\s')[1].split(',')[0] -as [int]
            $Result = ([ComponentModel.Win32Exception]$id | Out-String).Trim() -replace 'Could not create pointer \(PTR\) record', 'A record created but not PTR'
        
        }
    
        $Output = [PSCustomObject]@{
        
            DomainController = $env:COMPUTERNAME
            Zonename         = $Parameters.Zonename
            Name             = $Parameters.Name
            IP               = $Parameters.IPv4Address
            Result           = $Result
        
        }
    
        Write-Output $Output
                    
    } -ComputerName $DomainControllers -Credential $Credential -ArgumentList $DNSParameters -ErrorAction Stop -HideComputerName | Select * -ExcludeProperty RunSpaceId

  Write-Output $InvokeDNS
    
}