<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Faster alternative to Test-NetConnection as it checks provided port however it also pings on every use. 
Test-NetConnection also does not have a "Timeout" parameter so large sweeps can take longer than necessary waiting for a timeout on a port or ping.
Test-ePort timeout can be set, however the default is 1000ms (1 second)
Test-ePort also has an Async (-Async $True) parameter for testing more than a 100 targets. Even if the Async parameter is not used, but there are more than 100 Computernames, it
will automatically switch to Async
#>
function Test-ePort {
    
    [CmdletBinding()]

    param(
        [string[]]$Computername,
        [int[]]$Port,
        [int]$Timeout = 10000,
        [int]$Throttle = 50,
        [bool]$Async
    )

    if ($Computername.count -le 100 -and $Async -ne $True) {

        $i = 0
        $CT = $Computername.count

        $Output = Foreach ($Computer in $Computername) {

            $i++
            Write-Verbose "Computer $i of $CT"
    
            $h = 0
            $PCT = $Port.count

            ForEach ($P in $Port) {

                $h++
                Write-Verbose "Port $h of $PCT"

                $TcpClient = [System.Net.Sockets.TcpClient]::new()
                $Result = $TcpClient.ConnectAsync($Computer, $P).Wait($Timeout)
    
                [PSCustomObject]@{

                    Destination = $Computer
                    Port        = $P
                    Open        = $Result
                    Source      = $env:COMPUTERNAME

                }
   
            }

        }

    }#Not Async #################

    #################
 
    if ($Async -eq $True -or $Computername.Count -gt 100) {

        $ScriptBlock = {

            param(
                $Comp,
                $PortNum,
                $Timedout
            )

            $TcpClient = [System.Net.Sockets.TcpClient]::new()
            $Result = $TcpClient.ConnectAsync("$Comp", "$PortNum").Wait("$Timedout")
    
            $Output = [PSCustomObject]@{

                Date        = [datetime]::Now.GetDateTimeFormats()[43]
                Destination = $Comp
                Port        = "$PortNum"
                Open        = "$Result"
                Timeout     = "$Timedout"
                Source      = $env:COMPUTERNAME

            }

            Write-Output $Output
             
        }#ScriptBlock

        $Output = @()
        $Runspaces = [System.Collections.ArrayList]@()

        $MessageInterval = 1
        $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $RunspacePool = [RunspaceFactory]::CreateRunspacePool($InitialSessionState)
        $RunspacePool.SetMinRunspaces(1) | Out-Null
        $RunspacePool.SetMaxRunspaces($Throttle) | Out-Null
                   
        $RunspacePool.Open()

        $i = 0
        $ct = $Computername.Count

        $Creating = "$([datetime]::Now.GetDateTimeFormats()[43]) - Creating $($Ct) runspaces to parse records. Throttle $throttle"

        Write-Host $Creating -ForegroundColor Yellow

        $Output = @()

        Foreach ($Computer in $Computername) {
         
            $PowerShell = [powershell]::Create()
            $null = $PowerShell.AddScript($ScriptBlock)
            $null = $PowerShell.AddArgument($Computer)
            $null = $PowerShell.AddArgument($Port)
            $null = $PowerShell.AddArgument($Timeout)
            [void]$Runspaces.Add( [PSCustomObject]@{ Powershell = $PowerShell; Runspace = $PowerShell.BeginInvoke(); Id = $Computer } )
    
        }

        Write-Host ("$(Get-Date -Format 'MM-dd-yy HH:mm:ss') - Started RunSpace Jobs: {0}" -f ((@($RunSpaces | Where-Object { $Null -ne $_.RunSpace }).Count))) -ForegroundColor Green  

        Do {

            $StopWatch = [system.diagnostics.stopwatch]::StartNew()

            $Wait = $True
            $More = $False

            Foreach ($RunSpace in $RunSpaces) { 

                If ($RunSpace.RunSpace.isCompleted) {
            
                    $null = $Output += $RunSpace.powershell.EndInvoke($RunSpace.RunSpace)
                    #$null = $Output += $Returned
                    $RunSpace.powershell.dispose()
                    $RunSpace.RunSpace = $null
                    $RunSpace.powershell = $null                 
                }

                ElseIf ( $null -ne $RunSpace.RunSpace ) {

                    $More = $true

                }

            }

            If ($More -AND $Wait -eq $True) {

                # Start-Sleep -Milliseconds 500

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

    }#if($Async #################

    Write-Output $Output

}#Function Test-ePort