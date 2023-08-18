function Get-eDNS {

    [CmdletBinding()]
    
    param(
    
        [string]$HostnameOrIPAddress
     
    )
    
    Process {
    
        $Error.Clear()
        $NoPTR = 'No PTR record'
        $NoDNS = "No DNS Entry"
        $NOA = 'No A record'
        $SendPing = [System.Net.NetworkInformation.Ping]::new()
    
        try {
    
            $Ping = $SendPing.Send($HostnameOrIPAddress).Status
    
        }
        catch {
    
            $Ping = 'Error'
    
        }
    
        switch ($HostnameOrIPAddress) {
    
            { $_ -as [IPADDRESS] -as [Bool] -eq $True } {
    
                $Query = Resolve-DnsName $HostnameOrIPAddress -DnsOnly -ErrorAction SilentlyContinue
    
                if ($Query.Name -eq $null) {
    
                    $Resolved = $False
                    $Note = $NoDNS
                    $Name = $Note
                    $IP = $Note
                    $PTR = $Note
                    $Domain = $Note
                    $NameHost = $Note
    
                }
                else {
     
                    $AQuery = $Query.Server  | % {
     
                        Resolve-DnsName $_ -Type A -ErrorAction SilentlyContinue
     
                    }
    
                    If ($AQuery.Name -eq $null) {
     
                        $AQuery = @{
     
                            Name      = $NOA
                            IPAddress = $NOA
     
                        }
     
                    }
    
                    $Name = ($AQuery.Name | Sort -Unique) -join ', '
                    $IP = ($AQuery.IPAddress | Sort -Unique) -join ', '
                    $PTR = ($Query.Name | Sort -Unique) -join ', '
                    $PTRNameHost = ($Query.NameHost | Sort -Unique) -join ', '
                    $TTL = ($Query.TTL | Sort -Unique) -join ', '
                    $Domain = $Query.Server.Split('.')[-2..-1] -join '.' | Sort -Unique
     
                    $Resolved = $True
                    $Note = "DNS found"
    
                }
     
            }#Is IP
    
            { $_ -as [IPADDRESS] -as [Bool] -eq $False } { 
    
                $Query = Resolve-DnsName $HostnameOrIPAddress -ErrorAction SilentlyContinue 
    
                if ($Query.Name -eq $null) {
    
                    $Resolved = $False
                    $Note = $NoDNS
                    $Name = $Note
                    $IP = $Note
                    $PTR = $Note
                    $PTRNameHost = $Note
                    $Domain = $Note
    
                }
                else {
    
                    $Resolved = $True
    
                    $PTRQuery = $Query.IPAddress | % {
    
                        $I = $_
    
                        Resolve-DnsName $I -Type PTR -DnsOnly -ErrorAction SilentlyContinue
    
                    }
    
                    If ($PTRQuery.Name -eq $null) {
                        
                        $PTRQuery = @{
    
                            Name     = $NoPTR
                            NameHost = $NoPTR
                            Domain   = $NoPTR
    
                        }
    
                    }
    
                    $Name = ($Query.Name | Sort -Unique) -join ', '
                    $IP = ($Query.IPAddress  | Sort -Unique) -join ', '
                    $PTR = ($PTRQuery.Name | Sort -Unique) -join ', '
                    $PTRNameHost = ($PTRQuery.NameHost | Sort -Unique) -join ', ' 
                    $TTL = ($Query.TTL | Sort -Unique) -join ', '
                    $Domain = $Query.Name.Split('.')[-2..-1] -join '.' | Sort -Unique
    
                }
    
            }#Is NOT IP
    
        }
    
        $Output = [PSCustomObject]@{
    
            Searched     = $HostnameOrIPAddress.ToUpper()
            PingSearched = $Ping
            Domain       = $Domain.ToUpper()
            DNSName      = $Name.ToUpper()
            DNSIP        = $IP
            PTR          = $PTR.ToUpper()
            PTRNameHost  = $PTRNameHost.ToUpper()
            Resolved     = $Resolved
    
        }
    
        Write-Output $Output
    
    }#Process   
    
}