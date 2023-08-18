#Add-gDNSRecord -Hostname HOSTNAME -IPAddress '192.168.1.1' -Credential $Credential -CreatePTR $true
#Add-gDNSRecord -Hostname HOSTNAME -IPAddress '192.168.1.1' -Credential $Credential -CreatePTR $false
Function Add-gDNSRecord {

    [CmdletBinding()]

    Param(

        [ValidateNotNullorEmpty()]
        $Hostname,

        $ZoneName = ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name),

        [ValidateNotNullorEmpty()]
        $IPAddress,

        $CreatePTR = $false,

        [PSCredential]$Credential

    )

    Begin {

        $DomainControllers =  @([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().DomainControllers.Name)

        $ScriptBlock = {
            
            [CmdletBinding()]

            Param(

                [ValidateNotNullorEmpty()]
                $Parameters,

                $DomainController,

                [PSCredential]$Credential

            )

            $Output = Invoke-Command -ScriptBlock { 

                param(

                    $Parameters

                )

                $error.Clear()
                try {
       
                    Add-DnsServerResourceRecordA @Parameters

                    $Result = 'Success'

                }
                catch {

                    $id = ($error[0].FullyQualifiedErrorId -split '\s')[1].split(',')[0] -as [int]
                    $Result = ([ComponentModel.Win32Exception]$id | Out-String).Trim() -replace 'Could not create pointer \(PTR\) record', 'A record created but not PTR'
    
                }

                $Output = [PSCustomObject]@{
    
                    DomainController = $env:COMPUTERNAME
                    Zonename         = $Parameters.Zonename
                    Name             = $Parameters.name
                    IP               = $Parameters.IP
                    Result           = $Result
    
                }

                Write-Output $output

            } -ComputerName $DomainController -Credential $Credential -ArgumentList $Parameters | Select * -ExcludeProperty PSComputername, RunspaceID
    
            Write-Output $Output

        }#ScriptBlock

        $Parameters = @{

            Zonename    = $ZoneName
            Name        = $Hostname
            IP          = $IPAddress
            CreatePTR   = $false
            ErrorAction = 'Stop'
    
        }
    
    }#Begin

    Process {
    
        $Runspaces = [System.Collections.ArrayList]@()
        $Output = [System.Collections.ArrayList]@()
        $SyncHash = [hashtable]::Synchronized(@{})
        $Throttle = 10
        $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $RunspacePool = [RunspaceFactory]::CreateRunspacePool($InitialSessionState)
        $RunspacePool.SetMinRunspaces(1) | Out-Null
        $RunspacePool.SetMaxRunspaces($Throttle) | Out-Null
       
        $RunspacePool.Open()

        $Parameters = @{

            Zonename    = $ZoneName
            Name        = $Hostname
            IP          = $IPAddress
            CreatePTR   = $CreatePTR
            ErrorAction = 'Stop'
    
        }

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
            $null = $PowerShell.AddArgument($Parameters)
            $null = $PowerShell.AddArgument($DomainController)
            $null = $PowerShell.AddArgument($Credential)
            # $null = $PowerShell.AddArgument($SyncHash)
            $PowerShell.RunspacePool = $RunspacePool 
    
            [void]$Runspaces.Add( [PSCustomObject]@{ Powershell = $PowerShell; Runspace = $PowerShell.BeginInvoke(); Id = $DomainController ; Hash = $SyncHash } )
    
        }
        
        Do {
    
            $Wait = $True
            $More = $False

            Foreach ($RunSpace in $RunSpaces) { 
        
                If ($RunSpace.RunSpace.isCompleted) {
                    
                    $result = $RunSpace.powershell.EndInvoke($RunSpace.RunSpace)
                    $null = $Output.Add($result)
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
        
                Write-Verbose "Finished: $($_.ID)" 
        
                $RunSpaces.remove($_)
            }  
        
            Write-Verbose ("Remaining RunSpace Jobs: {0}" -f ((@($RunSpaces | Where-Object { $Null -ne $_.RunSpace }).Count)))      
        
        } while ($More -AND $Wait -eq $True)

        Write-Output $Output

    }#Process

}