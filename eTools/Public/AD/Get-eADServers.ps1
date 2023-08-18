Function Get-eADServers {

    [CmdletBinding()]

    param(
          
        [string[]]$Computername = '*',
        [switch]$Disabled,
        [switch]$Enabled,
        [switch]$CheckOnline

    )

    $ObjectFilter = "(objectclass=computer)"
    $ServerFilter = "(operatingsystem=*Server*)"
    $NameFilter = "(name=$Computername)"
    $DisabledFilter = "(userAccountControl:1.2.840.113556.1.4.803:=2)"
    $EnabledFilter = "(!(userAccountControl:1.2.840.113556.1.4.803:=2))"

    $Filter = $ServerFilter

    switch ($PSBoundParameters.Keys) {

        Disabled { $Filter = $Filter + $DisabledFilter; $IsEnabled = $False }
        Enabled { $Filter = $Filter + $EnabledFilter; $IsEnabled = $True }
        { $Computername -ne '*' } { $Filter = $ObjectFilter }
        <#       {$_ -eq 'Enabled' -and $Computername -ne '*' } { $Filter = $NameFilter + $EnabledFilter }
        {$_ -eq 'Disabled' -and $Computername -ne '*' } { $Filter = $NameFilter + $DisabledFilter } #>
       
    }

    $ADProperties = Foreach ($Computer in $Computername) {

        $DomainName = "$([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name)"
        $DomainDN = ([adsi]'').distinguishedName
        $Searcher = [adsisearcher]"LDAP://$DomainDN "
        $Searcher.PageSize = 3000
        $Searcher.Filter = "(&$Filter(name=$Computer))"

        'accountexpires',
        'cn',
        'description',
        'displayname',
        'distinguishedname',
        'dnshostname',
        'guid',
        'instancetype',
        'iscriticalsystemobject',
        'lastlogontimestamp',
        'memberof',
        'name',
        'operatingsystem',
        'operatingsystemversion',
        'path',
        'pwdlastset',
        'samaccountname',
        'samaccounttype',
        'serviceprincipalname',
        'useraccountcontrol',
        'whencreated',
        'whenchanged',
        'msLAPS-PasswordExpirationTime'	| ForEach-Object {

            $null = $Searcher.PropertiesToLoad.Add($_)
        
        }

        $FindAll = ($Searcher.FindAll()) | Where-Object { "$($_.Properties.description)" -ne 'Failover cluster virtual network name account' -and $_.Properties.serviceprincipalname -NotContains 'mssclustervirtualserver' }
        $FindAll.Properties

    }

    $ComputerNames = @($ADProperties.name)

    $ScriptBlock = {

        param($Properties)

        $IsEnabled = switch ($($Properties.useraccountcontrol)) {

            4096 { $True }
            532480 { $True }
            4098 { $False }
            2 { $False }
            default { $False }

        }

        $DomainName = "$([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name)"
        $Name = $Properties.name
        $Dn = $Properties.distinguishedname
        $AdsPath = $Properties.adspath
        $DNS_IPs = try { ([System.Net.Dns]::GetHostAddresses($Name).IPAddressToString | Sort-Object -Property { $_ -as [ipaddress] } -Descending -Unique) -join ';' }catch {}#((Resolve-DnsName -Name $Name -Type A -NoHostsFile -ErrorAction SilentlyContinue).IPAddress | Sort-Object -Property { $_ -as [ipaddress] } -Descending -Unique) -join ','
        $OS = $Properties.operatingsystem
        $Bornon = $Properties.whencreated.ToShortDateString()
        $Description = $Properties.description
        $LastLogon = ([datetime]::FromFileTime("$($Properties.lastlogontimestamp)")).GetDateTimeFormats()[43] #[datetime]::FromFileTime([int64]($Properties).lastlogontimestamp[0].ToString()).ToString('MM/dd/yyyy HH:mm:ss')
        $DaysAgo = New-TimeSpan -Start $LastLogon -End (Get-Date)
        $SPNs = $Properties.serviceprincipalname -join ';'
        $SQLVNO = $SPNs -match "MSClusterVirtualServer"
        $OSVersion = "$($Properties.operatingsystemversion)"
        $CriticalSystemObject = "$($Properties.iscriticalsystemobject)"
        $Stale = ([int]($DaysAgo.Days) -ge 91)
        $Online = $null
        $LAPS = [datetime]::FromFileTime($Properties.'mslaps-passwordexpirationtime'[0]).GetDateTimeFormats()[43]
        $TcpClient = ([System.Net.Sockets.TcpClient]::new())
        $Online = ($TcpClient.ConnectAsync("$Name", "445").Wait("1000") )

        $Coast = switch ("$Dn") {

            { $_ -match "OU=West,|OU=X2,|CN=X2" } { 'West' }
            { $_ -match "OU=East,|OU=X1,|OU=X3,|CN=X1|CN=X3" } { 'East' }
            { $_ -match "^CN=AZ" } { 'Azure' }
    
        }

        $Output = [PSCustomObject]@{

            Date                 = (Get-Date).ToShortDateString()
            Domain               = "$DomainName"
            Computername         = "$Name"
            Online               = $Online
            BornOn               = $Bornon
            Enabled              = $IsEnabled
            LastLogon            = $LastLogon
            LastLogonDays        = $DaysAgo.Days
            Stale                = $Stale
            Description          = "$Description"
            OS                   = "$OS"
            IP                   = "$DNS_IPs"
            Coast                = "$Coast"
            LAPS                 = $LAPS
            CriticalSystemObject = $CriticalSystemObject
            OU                   = "$Dn"
           
        }

        $Output

    }#ScriptBlock

    $Runspaces = [System.Collections.ArrayList]@()
    $Outputs = [System.Collections.ArrayList]@()
    $Output = @()
    $Throttle = 75
    $MessageInterval = 10
    $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $RunspacePool = [RunspaceFactory]::CreateRunspacePool($InitialSessionState)
    $RunspacePool.SetMinRunspaces(1) | Out-Null
    $RunspacePool.SetMaxRunspaces($Throttle) | Out-Null
    $RunspacePool.Open()

    $i = 0
    $ct = $ADProperties.Count

    $Creating = "$([datetime]::Now.GetDateTimeFormats()[43]) - Creating $($Ct) runspaces to parse records"

    Write-Host $Creating -ForegroundColor Yellow

    $Output = Foreach ($Propterties in $ADProperties) {

        $PowerShell = [powershell]::Create()
        $null = $PowerShell.AddScript($ScriptBlock)
        $null = $PowerShell.AddArgument($Propterties)
            
        [void]$Runspaces.Add( [PSCustomObject]@{ Powershell = $PowerShell; Runspace = $PowerShell.BeginInvoke(); Id = "$($Propterties.name)" } )

    }

    $Started = $(Get-Date -Format 'MM-dd-yy HH:mm:ss')
    Write-Host ("$Started - Started RunSpace Jobs: {0}" -f ((@($RunSpaces | Where-Object { $Null -ne $_.RunSpace }).Count))) -ForegroundColor Green  

    Do {

        $StopWatch = [system.diagnostics.stopwatch]::StartNew()

        $Wait = $True
        $More = $False

        Foreach ($RunSpace in $RunSpaces) { 

            If ($RunSpace.RunSpace.isCompleted) {
            
                $Returned = $RunSpace.powershell.EndInvoke($RunSpace.RunSpace)
                $null = $Outputs.Add($Returned)
                $null = $Output += $Returned
                $RunSpace.powershell.dispose()
                $RunSpace.RunSpace = $null
                $RunSpace.powershell = $null                 
            }

            ElseIf ( $null -ne $RunSpace.RunSpace ) {

                $More = $true

            }

        }

        If ($More -AND $Wait -eq $True) {

            Start-Sleep -Milliseconds 500

        }   

        $RunSpacesClone = $RunSpaces.clone()

        $RunSpacesClone | Where-Object { $Null -eq $_.RunSpace } | ForEach-Object {

            Write-Verbose ("$(Get-Date -Format 'MM-dd-yy HH:mm:ss') - Removing {0}" -f $_.ID)

            $RunSpaces.remove($_)

        }  

        $Remaining = @($RunSpaces | Where-Object { $Null -ne $_.RunSpace })
        $Counts = $Remaining.Count
        $Seconds = ($StopWatch.Elapsed.Seconds)

        switch ("$Seconds") {

            { (("$_" % 30 -eq 0) -eq $True) -and ($Counts -le 10) -eq $Counts -gt 0 } {

                Write-Host "$(Get-Date -Format 'MM-dd-yy HH:mm:ss') - Remaining RunSpace Jobs: $Counts - $($Remaining.id -join ', ')"  -ForegroundColor Green
                    
            } 

        }

        Start-Sleep -Milliseconds 250

    } while ($More -AND $Wait -eq $True)

    $StopWatch.Reset()

    $RunspacePool.close()
    $RunspacePool.Dispose()
    [System.GC]::GetTotalMemory('forcefullcollection') | out-null
    [System.GC]::GetTotalMemory($true) | out-null

    Write-Host "$(Get-Date -Format 'MM-dd-yy HH:mm:ss') - Finished" -ForegroundColor Green  

    $Output = $Output | Sort-Object ComputerName

    Write-Output  $Output 

}