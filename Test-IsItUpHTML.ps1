Start-Transcript c:\Temp\ISITUP.log
$Excluded = @('COMPUTERNAME')
$SaveToRoot = "\\WEBSERBVERNAME\wwwroot\systems.domain.local"
$DomainDN = ([adsi]'').distinguishedName
$Searcher = [adsisearcher]"LDAP://$DomainDN "
$Searcher.PageSize = 3000
$Searcher.Filter = "(operatingsystem=*Server*)"
      $Properties = 'accountexpires',
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
        'whencreated',
        'whenchanged'
        foreach ($Propertie in $Properties) {

            $null = $Searcher.PropertiesToLoad.Add($Propertie)

        }

$FindAll = $Searcher.FindAll()| Where-Object{ "$($_.properties['description'])" -ne 'Failover cluster virtual network name account' -and $_.properties['name'] -notlike '*00' -and $_.properties['name'] -notmatch 'D2USB01|D1PROOTCA|D1SE04' -and $_.properties['serviceprincipalname'] -NotContains 'mssclustervirtualserver' }
$ADProperties = ($FindAll) 
$Computers = @($ADProperties.name)

$Servers = Foreach($Comp in $FindAll){

$Props = $Comp.Properties| Where-Object{ "$($_['description'])" -ne 'Failover cluster virtual network name account' -and $_['serviceprincipalname'] -NotContains 'mssclustervirtualserver' }
$GetDirectoryEntry = $Comp.GetDirectoryEntry()
$LastLogon = ([datetime]::fromfiletime($GetDirectoryEntry.ConvertLargeIntegerToInt64($GetDirectoryEntry.lastLogonTimestamp[0]))).ToString("MM-dd-yyyy HH:mm:ss")
$LastLogonTimestamp = $LastLogon 
$LastLogonDaysAgo = (New-TimeSpan -Start (get-date $LastLogonTimestamp) -End (Get-Date)).Days

[PSCustomObject]@{
    Name = $Props.name -as [String]
    OperatingSystem = $Props.operatingsystem -as [String]
    OperatingSystemVersion = $Props.operatingsystemversion -as [String]
    LastLogonTimestamp     = $LastLogonTimestamp
    LastLogonDaysAgo       = $LastLogonDaysAgo
    Description = $Props.description -as [String]
    DistinguishedName = $Props.distinguishedname -as [String]
    DNSHostName = ($Props.dnshostname) -as [String]
    InstanceType = $Props.instancetype -as [String]
    IsCriticalSystemObject = $Props.iscriticalsystemobject -as [String]
    Path = $Comp.Path -as [String]
    SAMAccountName = $Props.samaccountname -as [String]
    SAMAccountType = $Props.samaccounttype -as [String]
    ServicePrincipalName = ($Props.serviceprincipalname -join '; ') 
    WhenCreated = $Props.whencreated -as [String]
    WhenChanged = $Props.whenchanged -as [String]
    }
    }

$ScriptBlock = {

    param($Computer,$Excluded)

    function Test-gPort {
    
            [CmdletBinding()]
    
            param(
                $Computername,
                $Port,
                $Timeout = 1000
            )
    
            $Output = ForEach ($P in $Port) {
    
                $TcpClient = [System.Net.Sockets.TcpClient]::new()
                $Result = $TcpClient.ConnectAsync($Computername, $P).Wait($Timeout)
            
                [PSCustomObject]@{
    
                    Destination = $Computername
                    Port        = $P
                    Open        = $Result
                    Source      = $env:COMPUTERNAME
    
                }
           
            }
    
            Write-Output $Output
    
        }#Function Test-gPort

    $gPort = Test-gPort -Computername $Computer.Name -Port 445

    IF ($gPort.Open -ne $True -or @($Excluded) -contains "$($Computer.Name)" ) {

     $DefenderEnabled=$SolarWindsAgent=$ScreenConnect=$UpTime=$LastBootUpTime=$Uptime= 'Unreachable'
    $Online= $False

    if(@($Excluded) -contains "$($Computer.Name)"){

    Remove-Variable Online -EA 0

     $DefenderEnabled=$Online=$SolarWindsAgent=$ScreenConnect=$UpTime=$LastBootUpTime=$Uptime= 'EXCLUDED?'
    
    }

    }else{      

#$DefenderEnabled = (Invoke-command -ScriptBlock { try{ Set-MpPreference -DisableRealtimeMonitoring $true}catch{} } -ComputerName $Computer.Name  -HideComputerName)
$ScreenConnect = Test-Path  "\\$($Computer.Name)\c$\Program Files (x86)\ScreenConnect Client (6e52cd4c464c03bf)\ScreenConnect.ClientService.exe" 
$SolarWindsAgent = Test-Path "\\$($Computer.Name)\c$\Program Files (x86)\SolarWinds\Agent\SolarWinds.Agent.Service.exe"
$win32_operatingsystem =  Get-CimInstance win32_operatingsystem -ComputerName $Computer.Name
$LastBootUpTime = $win32_operatingsystem.LastBootUpTime.ToString('MM-dd-yyyy hh:mm:ss tt')
$UpTimes = (Get-Date) - ([datetime]$LastBootUpTime)
$Uptime = "Days: $($UpTimes.Days), Hours: $($UpTimes.Hours), Minutes: $($UpTimes.Minutes)"
$Online = $True
#.\PsExec.exe "\\$($Computer.Name)" -s winrm.cmd quickconfig -q -accepteula
$null = New-Item -Path "\\WEBSERVERNAME\wwwroot\systems.domain.local\$($Computer.Name)" -ItemType Directory -EA 0  -Force
$null = New-Item -Path "\\$($Computer.Name)\C$\SE\Inventory\History" -ItemType Directory -EA 0  -Force

<##>
$RemoteHistoryFiles = @(Get-ChildItem -Recurse "\\WEBSERVERNAME\wwwroot\systems.domain.local\$($Computer.Name)" -Filter "*.json").Name
$LocalHistoryFiles = @(Get-ChildItem -Recurse "\\$($Computer.Name)\C$\SE\Inventory\History"  -Filter "*.json")
$CopyHistory = @(($LocalHistoryFiles | Where-Object {"$($_.Name)" -notin $RemoteHistoryFiles}).Fullname)

$null = New-Item -Path "\\WEBSERVERNAME\wwwroot\systems.domain.local\$($Computer.Name)" -ItemType Directory -EA 0  -Force
$null = New-Item -Path "\\$($Computer.Name)\C$\SE\Inventory\History" -ItemType Directory -EA 0  -Force

        If ((Get-Item "\\WEBSERVERNAME\wwwroot\systems.domain.local\$($Computer.Name)\index.html").LastWriteTime -lt (Get-Item "\\$($Computer.Name)\C$\Temp\$($Computer.Name).html").LastWriteTime){

            $null = Copy-Item "\\$($Computer.Name)\C$\Temp\$($Computer.Name).html" "\\WEBSERVERNAME\wwwroot\systems.domain.local\$($Computer.Name)\index.html"  -EA 0 -Force

}

if($CopyHistory.Count -ge 1){

            $null = Copy-Item $CopyHistory "\\WEBSERVERNAME\wwwroot\systems.domain.local\$($Computer.Name)" -EA 0 -Recurse -Force

}
 
 }

    $Output = [pscustomobject]@{

        Date = (Get-Date -Format 'MM-dd-yyyy hh:mm:ss tt')
        Compuername = $Computer.Name
        Online      = $Online
        LastBoot    = $LastBootUpTime
        Uptime        = $Uptime
        #DefenderEnabled = $DefenderEnabled
        ScreenConnect  = $ScreenConnect
        SolarWindsAgent = $SolarWindsAgent
        OperatingSystem = $Computer.operatingsystem -as [String]
        OperatingSystemVersion = $Computer.operatingsystemversion -as [String]
        LastLogonTimestamp     = $Computer.LastLogonTimestamp
        LastLogonDaysAgo       = $Computer.LastLogonDaysAgo
        Description = $Computer.description -as [String]
        DistinguishedName = $Computer.distinguishedname -as [String]
        DNSHostName = ($Computer.dnshostname) -as [String]
        InstanceType = $Computer.instancetype -as [String]
        IsCriticalSystemObject = $Computer.iscriticalsystemobject -as [String]
        Path = $Computer.Path -as [String]
        SAMAccountName = $Computer.samaccountname -as [String]
        SAMAccountType = $Computer.samaccounttype -as [String]
        ServicePrincipalName = ($Computer.serviceprincipalname -join '; ') 
        WhenCreated = $Computer.whencreated -as [String]
        WhenChanged = $Computer.whenchanged -as [String]
   
    }

    Write-Output $Output

}
   
#################### Runspaces Section ############################
    
$Output = @()
$Results = @()
$Runspaces = [System.Collections.ArrayList]@()
$SyncHash = [hashtable]::Synchronized(@{})
$Throttle = 100
$MessageInterval = 1
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$RunspacePool = [RunspaceFactory]::CreateRunspacePool($InitialSessionState)
$RunspacePool.SetMinRunspaces(1) | Out-Null
$RunspacePool.SetMaxRunspaces($Throttle) | Out-Null
                   
$RunspacePool.Open()

$Started = Get-Date

 $i = 0
    $ct = $Servers.Count

 $Creating = "$([datetime]::Now.GetDateTimeFormats()[43]) - Creating $($Ct) runspaces to parse records"
        
    Write-Host $Creating -ForegroundColor Yellow
    
    $Failed = @()
    $Output= @()

Foreach ($Computer in $Servers) {
                  
    $PowerShell = [powershell]::Create()
    $null = $PowerShell.AddScript($ScriptBlock)
    $null = $PowerShell.AddArgument($Computer)
    $null = $PowerShell.AddArgument($Excluded)
    # $null = $PowerShell.AddArgument($SyncHash)
    $PowerShell.RunspacePool = $RunspacePool 
            
    [void]$Runspaces.Add( [PSCustomObject]@{ Powershell = $PowerShell; Runspace = $PowerShell.BeginInvoke(); Id = $Computer.name ; Hash = $Hash } )
            
}
clear
        
$StopWatch = [system.diagnostics.stopwatch]::StartNew()
        
Write-Host ("$(Get-Date -Format 'MM-dd-yy HH:mm:ss') - Started RunSpace Jobs: {0}" -f ((@($RunSpaces | Where-Object { $Null -ne $_.RunSpace }).Count))) -ForegroundColor Green  
    
Do {
    
    $Wait = $True
    $More = $False
    
    Foreach ($RunSpace in $RunSpaces) { 
        
        If ($RunSpace.RunSpace.isCompleted) {
                    
            $Returned = $RunSpace.powershell.EndInvoke($RunSpace.RunSpace)
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
        
        Start-Sleep -Milliseconds 1000
        
    }   
        
    $RunSpacesClone = $RunSpaces.clone()
        
    $RunSpacesClone | Where-Object {
        
        $Null -eq $_.RunSpace
        
    } | ForEach-Object {
        
        Write-Host ("$(Get-Date -Format 'MM-dd-yy HH:mm:ss') - Removing {0}" -f $_.ID)  -ForegroundColor Green
        
        $RunSpaces.remove($_)
    }  
        
    if ($stopwatch.Elapsed.Seconds -eq $MessageInterval) {
    
        $Remaining = @($RunSpaces | Where-Object { $Null -ne $_.RunSpace })
        $Counts = $Remaining.Count
    
        if ($Counts -gt 10) {
        
            Write-Host ("$(Get-Date -Format 'MM-dd-yy HH:mm:ss') - Remaining RunSpace Jobs: {0}" -f $Counts)  -ForegroundColor Green   
            
        }
        else {
            
            Write-Host "$(Get-Date -Format 'MM-dd-yy HH:mm:ss') - Remaining RunSpace Jobs: $Counts - $($Remaining.id -join ', ')"  -ForegroundColor Green       
    
        }

        $StopWatch.Restart()
    
    }
        
} while ($More -AND $Wait -eq $True)
    
    $StopWatch.Stop()
    $RunspacePool.close()
    $RunspacePool.Dispose()
    [System.GC]::GetTotalMemory('forcefullcollection') | out-null
    [System.GC]::GetTotalMemory($true) | out-null

$JSON = $Output | ConvertTo-Json -Compress
$JSON | Set-Content "$SaveToRoot\isitup.json"
$Servers|ConvertTo-Json -Compress | Set-Content "$SaveToRoot\servers.json"
$Finished = get-date

stop-transcript
