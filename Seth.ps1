$Servers = @('Servername1','Servername2')

$ScriptBlock ={

param( $Computer )

$win32_operatingsystem =  Get-CimInstance win32_operatingsystem -ComputerName $Computer
$LastBootUpTime = $win32_operatingsystem.LastBootUpTime.ToString('MM-dd-yyyy hh:mm:ss tt')
$UpTimes = (Get-Date) - ([datetime]$LastBootUpTime)
$Uptime = "Days: $($UpTimes.Days), Hours: $($UpTimes.Hours), Minutes: $($UpTimes.Minutes)"

$Out = [PSCUSTOMOBJECT]@{

Computername = $env:COMPUTERNAME
Uptime = $Uptime

}

return $Out

}#ScriptBlock 


#Runspaces

$Output = @()
$Results = @()
$Runspaces = [System.Collections.ArrayList]@()
$SyncHash = [hashtable]::Synchronized(@{})
#Throttle
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
    # $null = $PowerShell.AddArgument($Excluded)
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

$Output 
$JSON = $Output | ConvertTo-Json -Compress
$JSON | Set-Content "c:\Temp\isitup.json"
$Finished = get-date
