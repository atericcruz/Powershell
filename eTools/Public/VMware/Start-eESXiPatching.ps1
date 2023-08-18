Function Start-gESXiPatching {

    [CmdletBinding()]

    param()

    $null = try { New-Item -Path 'C:\Temp' -ItemType Directory -Force -ErrorAction SilentlyContinue }catch { $Error.Clear() }
    $null = Set-Location 'C:\Temp'
    Start-Transcript C:\Temp\1Log.txt
    $Read_Domain = $env:USERDNSDOMAIN 
    $Read_vCenter = "$(Read-Host "Which vCenter? (IE: d1pvcenter1.geosolinc.net)")".Trim().ToUpper()
    $Depot = 'https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml'

    if (!(Resolve-DnsName $Read_vCenter -ErrorAction SilentlyContinue)) {

        Write-Host "$Read_vCenter not found in DNS. Please verify and try again" -ForegroundColor Red

        $Read_vCenter = "$(Read-Host "Which vCenter?")".Trim()

        if (!(Resolve-DnsName $Read_vCenter -ErrorAction SilentlyContinue)) {

            Write-Warning "Soooooo... $Read_vCenter not found in DNS again. Please re-run after you have verified the vCenter name"
            break

        }

    }

    if ($Credential.Username.length -lt 4) {

        Write-Host "Please enter your $Read_vCenter priv credentials" -ForegroundColor Yellow

        $Credential = Get-Credential -Message "Please enter your $Read_vCenter priv credentials"

        if ($Credential.Username.length -lt 4) {

            Write-Warning "Excuse me $env:USERNAME, but you did not provide your credentials. Please enter you credentials."

            $Credential = Get-Credential -Message "Please enter your $Read_vCenter priv credentials"

            if ($Credential.GetNetworkCredential().Username.length -lt 4) {

                Write-Host "No credentials again $env:USERNAME. Exiting" -ForegroundColor Red

                break

            }

        }

    }

    Write-Host "Connecting to $Read_vCenter as $($Credential.UserName)" -ForegroundColor Yellow
    $Center = Connect-VIServer -Server $Read_vCenter -Credential $Credential -Force
    Write-Host "Connected to $Read_vCenter as $($Credential.UserName)" -ForegroundColor Green

    Write-Host "Getting the datacenter" -ForegroundColor Yellow
    $Datacenter = (Get-Datacenter -Server $Center).Name
    Write-Host "Got the datacenter" -ForegroundColor Green

    Write-Host "Getting VM hosts" -ForegroundColor Yellow
    $VMHosts = Get-VMHost -Server $Center 
    Write-Host "Got VM hosts" -ForegroundColor Green

    Write-Host "Please select the ESXi host to patch" -ForegroundColor Yellow
    $VMHost = $VMHosts | Out-GridView -Title "Please select the ESXi host to patch" -PassThru

    Write-Host "Connecting to EsxCli on $($VMHost.name)" -ForegroundColor Yellow
    $ESXCLi = Get-EsxCli -VMHost (Get-VMHost $VMHost) -V2 -Server $Center
    Write-Host "Connected to EsxCli on $($VMHost.name)" -ForegroundColor Green

    Write-Host "Getting current profile image on $($VMHost.name)" -ForegroundColor Yellow
    $CurrentProfile = $EsxCli.software.profile.get.Invoke()
    Write-Host "Current profile image on $($VMHost.name): $($CurrentProfile.Name)" -ForegroundColor Green
    #$VMHostMain = (Set-VMHost -VMHost $VMHost -State Connected -Server $Center -Confirm:$False)

    Write-Host "Getting list of profile images from VMware repo. This will take 2 or 3 minutes" -ForegroundColor Yellow
    $OnlineProfilesList = @($ESXCLi.software.sources.profile.list.Invoke(@{depot = $Depot })) | where { (get-date $_.CreationTime) -ge ((get-date).AddDays(-120)) -and ($_.Name -like "ESXi-6.7*2022*" -or $_.name -like "ESXi-7*") } | Sort -Property { $_.CreationTime -as [datetime] } -Descending #|where {$_.CreationTime})

    Write-Host "Please select from the list of profile images from VMware repo to install" -ForegroundColor Yellow
    Write-Host "Reminder current profile image on $($VMHost.name): $($CurrentProfile.Name)" -ForegroundColor Yellow
    $InstallProfile = $OnlineProfilesList | Out-GridView -PassThru -Title 'Please select the update:'

    $Install = $ESXCli.software.profile.get.createargs()
    $Install.depot = "https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml"
    $Install.profile = $InstallProfile.Name

    $VMs = @($VMHost | Get-VM)
    $VMCount = $VMs.Count

    if ( $VMCount -ne 0 -or $ESXI.ConnectionState -ne 'Maintenance') {

        Write-Warning "$(Get-Date -Format "MM-dd-yyyy hh:mm:ss tt") - There are $VMCount powered on VMs on $($VMHost.Name)"

        switch ( Read-Host "Proceed with placing $($VMHost.Name) in maintenance mode?[(Y)es/(N)o]") {

            { $_ -like 'Y*' } {
 
                Write-Host "Placing $($VMHost.name) in maintenance mode" -ForegroundColor Yellow
                $MaintModeOn = ($VMHost | Set-VMHost -State Maintenance -Confirm:$False -Server $Center )

                Write-Host "$($VMHost.Name) is in maintenance mode and $OnCount powered on VMs. Proceeding with Update $($InstallProfile.Name)" -ForegroundColor Green

            }

            default {
            
                Write-Host "You chose not to place $($VMHost.Name) in maintenance mode. Exiting..."
                break
            
            }

        }#Switch

    }

    Write-Warning "$(Get-Date -Format "MM-dd-yyyy hh:mm:ss tt") - This update can take 5-10 minutes" 

    $InstallUpdate = ($ESXCli.software.profile.update.Invoke($Install))
    
    If ($InstallUpdate.Message -match 'completed successfully') {
    
        $RefreshESXi = (Get-VMHost -Name $VMHost.Name -Server $VIServer)

        Write-Host "$(Get-Date -Format "MM-dd-yyyy hh:mm:ss tt") - $($VMHost.Name) updated successfully and reboot required is $($InstallUpdate.RebootRequired)" -ForegroundColor Green
        Write-Host "`n`tVIBs Installed:`n`t$($InstallUpdate.VIBsInstalled -join "`n`t")" -ForegroundColor Green
        Write-Host "`n`tVIBs Removed:`n`t$($InstallUpdate.VIBsRemoved -join "`n`t")" -ForegroundColor Green

        if ($VibPath -ne $False) {
  
            Write-Host "Installing $VibName located at $VibPath" -ForegroundColor Yellow
         
            $InstallVib = $ESXCli.software.vib.install.CreateArgs()
            $InstallVib.depot = $VibPath
    
            $InstallingVib = $ESXCli.software.vib.install.Invoke($InstallVib)

            If ($InstallingVib.Message -match 'completed successfully') {
  
                Write-Host "$(Get-Date -Format 'MM-dd-yyyy HH:mm:ss') - Installed $($InstallingVib.VIBsInstalled) and removed $($InstallingVib.VIBsRemoved).`n" -ForegroundColor Green
  
            }
            else {
  
                Write-Host "$(Get-Date -Format 'MM-dd-yyyy HH:mm:ss') - Not sure if $VibName installed. Install returned`n" -ForegroundColor Green
                Write-Output $InstallVib
                Write-Host "`n"
  
            }
  
        }#VibPath -ne $False

        Write-Host "$(Get-Date -Format 'MM-dd-yyyy HH:mm:ss') - Reboot required $( $InstallingVib.RebootRequired) $VibName" -ForegroundColor Green
        Write-Host "Rebooting $($VMHost.Name)"
        $RebootESXi = ($RefreshESXi | Restart-VMHost -Confirm:$false -Force )

    }
    else {
    
        Write-Error "Something failed. Please review manually.`n$($InstallUpdate.Message)"
        break

    }

    $Continue = $True

    while ($Continue -eq $true ) {

        Write-Host "$(Get-Date -Format 'MM-dd-yyyy HH:mm:ss') - Waiting for $($VMHost.Name) to Power Off" -ForegroundColor Yellow

        sleep -Seconds 15
        $RefreshESXi2 = (Get-VMHost -Name $VMHost -Server $Center)
        $Continue = ($RefreshESXi2).PowerState -EQ 'PoweredOn'
 
    }

    Write-Host "$(Get-Date -Format 'MM-dd-yyyy HH:mm:ss') - $($VMHost.Name) to Powered off" -ForegroundColor Green

    $Continue = $true

    while ($Continue -eq $true ) {

        Write-Host "$(Get-Date -Format 'MM-dd-yyyy HH:mm:ss') - Waiting for $($VMHost.Name) to Power On" -ForegroundColor Yellow

        sleep -Seconds 15
        $RefreshESXi2 = (Get-VMHost -Name $VMHost -Server $VIServer)
        $Continue = ($RefreshESXi).PowerState -EQ 'PoweredOff'

    }

    while (  (Get-VMHost -Name $VMHost -Server $Center).ExtensionData.Runtime.ConnectionState -ne 'Connected') {
        Write-Host "$(Get-Date -Format 'MM-dd-yyyy HH:mm:ss') - Waiting for $($VMHost.Name) to connect to $Center" -ForegroundColor Yellow

        sleep -Seconds 15

    }

    Write-Host "$(Get-Date -Format 'MM-dd-yyyy HH:mm:ss') - $($RefreshESXi.name) connected to $Center" -ForegroundColor Green

    switch (Read-Host "Remove $($VMHost.Name) from maintenance mode? [Yes/No]") {

        { $_ -match "Y" } {

            Write-Host "Removing $($VMHost.Name) from maintenance mode" -ForegroundColor Yellow
            $MaintModeOff = ($VMHost | Set-VMHost -State Connected -Confirm:$False -Server $Center )
            Write-Host "Removed $($VMHost.Name) from maintenance mode" -ForegroundColor Green

        }

        default { Write-Warning "Leaving $($VMHost.Name) in maintenance mode" }

    }

    Write-Host "*************        All done. I said good day $env:USERNAME        **************" -ForegroundColor Green
    Stop-Transcript

}