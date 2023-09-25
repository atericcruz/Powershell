$Error.Clear(); clear
$PortsList = '21,22,53,67,80,111,123,135,443,445,1031,1433,1434,3389,8080,8443'
$NMAPScans = @(nmap -sV -p $PortsList 10.XXX.XXX.0/24  )
$AllScans = @($NMAPScans -split "`n")
$Output = @()
$i = 0
$AllPorts = @()

$Finished = ForEach ($AllScan in $AllScans) {

    switch -Regex ($AllScan) {

        '^Nmap scan report for (?<IP>\d+.*)$' {

            $IP = $matches["IP"]
            $Computername = try { [System.Net.Dns]::GetHostEntry($IP).hostname }catch { 'No DNS Found' }

            Write-Host "$Computername - $IP" -ForegroundColor Yellow

        }

        '^Nmap scan report for (?<Computername>\w+.*)\s\((?<IP>(.*))\)' {

            $Computername = $matches["Computername"]
            $IP = $matches["IP"]

            Write-Host "$Computername - $IP" -ForegroundColor Green

        }

        'Host is\s(?<UpDown>\w+)\s\((?<Latency>(\d+\..*\w)\s)(.*)\)' {

            $IpIs = $matches["UpDown"].TrimEnd('.').ToUpper()
            $Latency = $matches["Latency"]

            try {

                $searcher = [adsisearcher]"(&(objectCategory=computer)(dnshostname=$Computername))"
                $Found = $searcher.FindOne()

                if ($Found -ne $null) {

                    $AdName = $Found.Properties["name"][0]
                    $AdDN = $Found.Properties["distinguishedname"][0]
                    $AdDescription = $Found.Properties["description"][0]
                    $AdOS = $Found.Properties["operatingsystem"][0]
        
                }
                else {

                    $AdDN = $Computername = $AdName = $ADOS = $adDistinguishedName = $adDescription = $adComputerName = "Not found in AD"
            
                }

            }
            catch {

                $AdDN = $Computername = $AdName = $ADOS = $adDistinguishedName = $adComputerName = "Error querying AD for $Computername"
       
            }

        }

        $Regex_Ports {

            Write-Host "$IP PORTS $_" -ForegroundColor Yellow

            $AllPorts += [PSCustomObject]@{
                IP           = $IP
                IpIs         = $IpIs
                Computername = $Computername
                DN           = $AdDN
                Name         = $AdName
                Description  = $adDescription
                AdOS         = $ADOS
                Latency      = $Latency
                OS           = $null
                Port         = $matches["Port"]
                Protocol     = $matches["Protocol"].ToUpper()
                State        = $matches["State"].ToUpper()
                Service      = $matches["Service"].ToUpper()
                Version      = $matches["Version"]
                Results      = $null
            }
    
        }

        '^MAC Address: (?<MAC>.*:.*)\s\((?<MacVend>(.*))\)$' {

            $MAC = $matches["MAC"]
            $MacVendor = $matches["MacVend"]

        }

        'OS:\s(?<OS>\w+);' {

            $OS = $matches["OS"]

        }

        '^Nmap done:\s(?<Done>\d+\s\w+.*)$' {
 
            Write-Host "Done" -ForegroundColor Green

            $Done = $matches["Done"]
 
            $i++

            $P = Foreach ($AllPort in $AllPorts) {

                $AllPort.'OS' = $OS
                $AllPort.'Results' = $Done

                Write-Output $AllPort

            }

            $P
 
            Write-Host "Finished scanning $i IPs"

            $AllPorts = @()
 
        }

    }#Switch RegEx

}

$Finished | FT
#$Finished | Export-CSV C:\Temp\nmap.csv -NoTypeInformation
