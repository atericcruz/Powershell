#$snn = nmap -v -sn -n 10.111.185.0/24

#$sn = nmap -v -sn 10.111.185.0/24

#$3389 = nmap -v -p 3389 -n 10.111.202.0/24

$Results = Foreach ($Thing in $snn) {

    $MAC = $MacVendor = 'DOWN'

    switch -Regex ($Thing) {

        'Nmap scan report for (?<IP>\d+\.\d+\.\d+\.\d+)\s+\[host (?<UpDown>(\w+))\]' {

            $IP = $Matches["IP"]
            $Computername = try { [System.Net.Dns]::GetHostEntry($IP).hostname }catch { 'No DNS Found' }
            $Computername = $IpIs = $Matches["UpDown"].ToUpper()
            [PSCustomObject]@{
                IP           = $IP
                IpIs         = 'DOWN'
                Computername = $Computername
                Name         = 'DOWN'
                Description  = 'DOWN'
                AdOS         = 'DOWN'
                Latency      = 'DOWN'
                MAC          = 'DOWN'
                Vendor       = 'DOWN'
                DN           = 'DOWN'
            }

        }

        'Nmap scan report for (?<IP>\d+\.\d+\.\d+\.\d{0,3})$' {

            $IP = $Matches["IP"]

        }

        '^Host is up \((?<Latency>(\d+\..*\w)\s)(.*)\)' {

            $Computername = try { [System.Net.Dns]::GetHostEntry($IP).hostname }catch { 'No DNS' }
            $IpIs = 'UP'
            $Latency = $matches["Latency"]
            $AdDN = $ADOS = $adDescription = $adComputerName = "No AD"
  
            try {

                $searcher = [adsisearcher]"(&(objectCategory=computer)(dnshostname=$Computername))"
                $Found = $searcher.FindOne()

                if ($Found -ne $null) {
       
                    $AdName = $Found.Properties["name"][0]
                    $AdDN = $Found.Properties["distinguishedname"][0]
                    $AdDescription = $Found.Properties["description"][0]
                    $AdOS = $Found.Properties["operatingsystem"][0]
                    $Computername = $Found.Properties["dnshostname"][0]
        
                }
                else {
       
                    $adname = $AdDN = $ADOS = $adDescription = "No AD"
            
                }
            }
            catch {

                $AdDN = $adname = $ADOS = $adDescription = "Error querying AD for $Computername"
       
            }
        }

        '^MAC Address: (?<MAC>.*:.*)\s\((?<MacVend>(.*))\)$' {

            $MAC = $Matches["MAC"]
            $MacVendor = $Matches["MacVend"]

            [PSCustomObject]@{
 
                IP           = $IP
                IpIs         = $IpIs
                Computername = $Computername
                Name         = $AdName
                Description  = $adDescription
                AdOS         = $ADOS
                Latency      = $Latency
                MAC          = $MAC
                Vendor       = $MacVendor
                DN           = $AdDN
            }
    
        }

    }

}

Write-Output $Results
