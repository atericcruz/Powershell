#Credential = Get-Credential
#Update-gDNSRecord -Hostname testdnsupdate -IPAddress 192.168.1.1 -Verbose -Credential $Credential
Function Update-gDNSRecord {

    [CmdletBinding()]

    Param(

        [ValidateNotNullorEmpty()]
        $Hostname,

        $ZoneName = ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name),

        [ValidateNotNullorEmpty()]
        $IPAddress,

        [PSCredential]$Credential

    )

    Begin {

        $DomainControllers = @([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().DomainControllers.Name)

        $ScriptBlock = {
            
            [CmdletBinding()]

            Param(

                [ValidateNotNullorEmpty()]
                $Hostname,

                $IPAddress,

                $DomainController,
				
                $ZoneName,

                [PSCredential]$Credential

            )

            $Output = Invoke-Command -ScriptBlock { 

                param(

                    $Hostname,
                    $IPAddress,
                    $Zone

                )

                $error.Clear()

                try {

                    $New = Get-DnsServerResourceRecord -Name $Hostname -ZoneName $Zone  # -ComputerName $DC
                    $Old = Get-DnsServerResourceRecord -Name $Hostname -ZoneName $Zone
                    $null = $New.RecordData.IPv4Address = [System.Net.IPAddress]::parse($IPAddress)
                    $Result = Set-DnsServerResourceRecord -NewInputObject $New -OldInputObject $Old -ZoneName $Zone

                    $Result = 'Success'
                    $Success = $True
                }
                catch {
                
                    $id = ($error[0].FullyQualifiedErrorId -split '\s')[1].split(',')[0] -as [int]
                    $Result = $error#([ComponentModel.Win32Exception]$id | Out-String).Trim() -replace 'Could not create pointer \(PTR\) record', 'A record created but not PTR'
                    $Success = $False    
                }
              
                $Output = [PSCustomObject]@{
    
                    DomainController = $env:COMPUTERNAME
                    Zonename         = $Zone
                    Name             = $Hostname
                    IP               = $IPAddress
                    Result           = $Result
                    Success          = $Success

                }

                Write-Output $Output

            } -ComputerName $DomainController -Credential $Credential -ArgumentList $Hostname, $IPAddress, $Zone | Select * -ExcludeProperty PSComputername, RunspaceID
    
            Write-Output   $Output

        }#ScriptBlock

    }#Begin

    Process {

        $Runspaces = [System.Collections.ArrayList]@()
        $SyncHash = [hashtable]::Synchronized(@{})
        $Throttle = 10
        $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $RunspacePool = [RunspaceFactory]::CreateRunspacePool($InitialSessionState)
        $RunspacePool.SetMinRunspaces(1) | Out-Null
        $RunspacePool.SetMaxRunspaces($Throttle) | Out-Null
           
        $RunspacePool.Open()
    
        Foreach ($DomainController in $DomainControllers) {
          
            $PowerShell = [powershell]::Create()
            $null = $PowerShell.AddScript($ScriptBlock)
            $null = $PowerShell.AddArgument($Hostname)
            $null = $PowerShell.AddArgument($IPAddress)
            $null = $PowerShell.AddArgument($DomainController)
            $null = $PowerShell.AddArgument($ZoneName)
            $null = $PowerShell.AddArgument($Credential)
            #  $null = $PowerShell.AddArgument($SyncHash)
            $PowerShell.RunspacePool = $RunspacePool 
    
            [void]$Runspaces.Add( [PSCustomObject]@{ Powershell = $PowerShell; Runspace = $PowerShell.BeginInvoke(); Id = $DomainController ; Hash = $SyncHash } )
    
        }
        
        $Error.Clear()
        $StopWatch = [system.diagnostics.stopwatch]::StartNew()
        $Output = @()

        Do {
    
            $Wait = $True
            $More = $False

            $Output += Foreach ($RunSpace in $RunSpaces) { 
        
                If ($RunSpace.RunSpace.isCompleted) {
                    
                    $RunSpace.powershell.EndInvoke($RunSpace.RunSpace)
                    #  $null = $Output.Add($result)
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
        
                Write-Verbose ("$(Get-Date -Format 'MM-dd-yy HH:mm:ss') - Removing {0}" -f $_.ID)
        
                $RunSpaces.remove($_)
            }  
        
            if ($stopwatch.Elapsed.Seconds -eq $MessageInterval) {

                Write-Verbose ("$(Get-Date -Format 'MM-dd-yy HH:mm:ss') - Remaining RunSpace Jobs: {0}" -f ((@($RunSpaces | Where-Object { $Null -ne $_.RunSpace }).Count)))      

                $StopWatch.Restart()

            }
        
        } while ($More -AND $Wait -eq $True)

        $StopWatch.Stop()

        Write-Output $Output

    }#Process

}