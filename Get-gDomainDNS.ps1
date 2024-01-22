function Get-gDomainDNS {

    [CmdletBinding()]

    param()

    $CurrentDomains = @(([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()), ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Children)).Where({ $_ })

    $Forest = $CurrentDomains[0].Forest.Name

    $Results = Foreach ($CurrentDomain in $CurrentDomains) {
       
        $DomainName = $CurrentDomain.Name

        $DomainPDC = $CurrentDomain.PdcRoleOwner.Name
        $DomainDN = $CurrentDomain.GetDirectoryEntry().distinguishedName

        $DomainLDAP = switch ($DomainName) {
    
            $Forest { "LDAP://DC=ForestDNSZones,$DomainDN" }

            default { "LDAP://DC=DomainDNSZones,$DomainDN" }
    
        }

        $DomainADSI = [adsi]$DomainLDAP
        $DomainSearcher = [adsisearcher]::new($DomainADSI)
    
        $DomainSearcher.PageSize = 15000
        $DomainSearcher.SearchRoot = $DomainADSI
        $DomainSearcher.Filter = "(&(objectClass=*)(!(dc=*in-addr*))(!(dc=*arpa,*))(!(dc=*$Forest))(!(dc=*DnsZones))(!(dc=_*))(!dNSTombstoned=TRUE))"
    
        TRY {

            $DomainADSI = [adsi]$DomainLDAP
            $DomainSearcher = [adsisearcher]::new($DomainADSI)
    
            $DomainSearcher.PageSize = 15000
            $DomainSearcher.SearchRoot = $DomainADSI
            $DomainSearcher.Filter = "(&(objectClass=*)(!(dc=*in-addr*))(!(dc=*arpa))(!(dc=*DnsZones))(!(dc=*root-servers))(!(dc=_*))(!(dNSTombstoned=TRUE)))"
     
            $DnsFindAll = $DomainSearcher.FindAll().Where({ $_.properties.dnsrecord -and $_.Path -notmatch "in-addr.arpa|_msdcs" })
    
            $DomainProperties = $DnsFindAll.Properties

        }
        CATCH {
        
            Write-Host "1 $DomainName" -ForegroundColor Red
            Write-Host "1 $DomainLDAP" -ForegroundColor Red
            BREAK
        
        }
        Foreach ($DnsZone in $DnsFindAll) {

            $Tombstoned = $($DnsZone.Properties["dnstombstoned"])
            $DN = $($DnsZone.Properties["distinguishedname"])
            $null = $DN -match '([a-z0-9|-]+\.)*[a-z0-9|-]+\.[a-z]+' # "$(@($CurrentDomains[0].name ))"
            $Domain = switch ( $matches.Values) {
                { @($CurrentDomains.Name) -contains "$_" } { "$_" }
                default { $_ }
            }
            $DnsName = switch ($DnsZone) {

                { $_.Properties["name"] -match 'www' } { "www." + $_.Properties.distinguishedname.split(',')[1].TrimStart('DC=') }

                default { $($_.Properties["name"]).TrimEnd('.') }

            }
            ForEach ($DnsByte in $DnsZone.Properties["dnsrecord"]) {
 
                if ([int]$DnsByte[2] -eq 1 -and $DnsName -notmatch "$(@($CurrentDomains.name -join '|'))") {
 
                    $DnsIP = ("{0}.{1}.{2}.{3}" -f $DnsByte[24], $DnsByte[25], $DnsByte[26], $DnsByte[27]) -as [ipaddress]
                    $Name = ($dn.Split(',')[0..1] -replace 'DC=')[0]
                    $Domain = ($dn.Split(',')[0..1] -replace 'DC=')[1]
                    $FQDN = "$Name.$Domain"
                    switch ($Domain) {

                        { $_ -match "$(@($CurrentDomains.name -join '|'))" -and "$_" -ne $Forest } { $Forest = $matches[0] }
                        default { $Forest = $CurrentDomains[0].Forest.Name }
                        # default { $Forest }

                    }
            
                    if ($Name -match '@' ) {
           
                        $Name = $DN.split(',')[1].split('.').Trim('DC=')[0]
               
                        if (@($DN.split(',')[1].split('.').Trim('DC=')).Count -eq 2) {
                            $Domain = $Name = $DN.split(',')[1].Trim('DC=')
                        }
                        else {
                            $Domain = $Domain -replace "$Name."
                            $FQDN = "$Name.$Domain"
                        }
                    }

                    if ($CurrentDomains.Name -notcontains $FQDN) {
                        [PSCustomObject]@{
 
                            Date    = (Get-Date -Format 'MM-dd-yyyy hh:mm:ss tt')
                            Parent  = $CurrentDomains[0].Forest.Name
                            Domain  = $Domain
                            Name    = $Name
                            # DnsName = $DnsName
                            FQDN    = $FQDN.TrimStart('@.')
                            IP      = $DnsIP.IPAddressToString
                            Network = ($DnsIP.IPAddressToString.Split('.')[0..2] -join '.') + '.0'
                            Created = [datetime]$DnsZone.Properties.whencreated[0].ToString()
                            Changed = [datetime]$DnsZone.Properties.whenchanged[0].ToString()
                            DN      = $Dn

                        }
                    }
 
                }
            }
            
        }

    }

    Write-Output $Results

}
