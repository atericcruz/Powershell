<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Gets Logon/Logoff from the events log
#>
Function Get-eEventsLogOnOff {

    [CmdletBinding()]
    
    param(

        $StartTimeHoursAgo = 1,
        $EndTimeHoursAgo
        
    )
    
    try {
        
        $StartTime = (Get-Date).AddHours(-$StartTimeHoursAgo)

        $Filter = @{

            LogName   = 'Security'
            ID        = 4624, 4625, 4634
            StartTime = $StartTime

        }
		
        if ($EndTimeHoursAgo) {
			
            $EndTime = (Get-Date).AddHours(-$EndTimeHoursAgo)
            $null = $Filter.Add('EndTime', $EndTime)
			
        }
        
        $Logs = Get-WinEvent  -FilterHashtable $Filter -ErrorAction Stop

        $Output = Foreach ($Log in $Logs) {
  
            Remove-Variable Action, Computername, EventId, Level, LogonType, Message, SourceIP, TargetDomain, TargetUser, TimeCreated, UserDomain, UserName, UserSID, Workstation  -EA 0
        
            $LogXML = [xml]$Log.ToXml()
            $LogData = $LogXML.Event.EventData.Data
            $Computername = $Log.MachineName
            $EventId = "$($Log.ID)"
            $EventId = $LogXML.Event.System.EventID
            $Action = $Log.TaskDisplayName
            $Level = $Log.OpcodeDisplayName
            $UserSID = $LogData[0].'#text'
            $UserName = $LogData[1].'#text'
            $UserDomain = $LogData[2].'#text'
            $TimeCreated = $Log.TimeCreated.ToString('MM-dd-yyyy hh:mm:ss tt')

            switch ($EventId) {
              
                4624 {
                    
                    $LogonType = "$(Get-eLogonType -Type $LogData[8].'#text')"
                    $TargetUser = $LogData[5].'#text'
                    $TargetDomain = $LogData[6].'#text'
                    $Message = 'An account was successfully logged on'
                    $IPAddress = $LogData[18].'#text'
                    $Workstation = $LogData[11].'#text'
                    
                }
                4625 {
                   
                    $LogonType = "$(Get-eLogonType -Type $LogData[10].'#text')"
                    $TargetUser = $LogData[5].'#text'
                    $TargetDomain = $LogData[6].'#text'
                    $Message = 'An account failed to log on'
                    $IPAddress = $LogData[-2].'#text'
                    $Workstation = $LogData[-8].'#text'

                }
                4634 {
                   
                    $LogonType = "$(Get-eLogonType -Type $LogData[4].'#text')"
                    $TargetUser = $null
                    $TargetDomain = $null
                    $Message = 'An account was logged off'
                    $IPAddress = $null
                    $Workstation = $null

                }
              
            }
            
            [pscustomobject]@{
                
                TimeCreated  = $TimeCreated
                Computername = $Computername
                EventId      = $EventId
                Level        = $Level
                Action       = $Action
                Message      = $Message
                UserSID      = $UserSID
                UserName     = $UserName
                UserDomain   = $UserDomain
                TargetUser   = $TargetUser
                TargetDomain = $TargetDomain
                LogonType    = $LogonType
                Workstation  = $Workstation
                SourceIP     = $IPAddress
                      
            }
      
        }

    }
    catch {
    
        $Action = $EventId = $Level = $LogonType = $Message = $IPAddress = $TargetDomain = $TargetUser = $TimeCreated = $UserDomain = $UserName = $UserSID = $Workstation = 'ERROR'
        
        $EventId = "$($Error.Exception.Message)"
       
        $Output = [pscustomobject]@{

            TimeCreated  = $TimeCreated
            Computername = $env:Computername
            EventId      = $EventId
            Level        = $Error
            Action       = $Action
            Message      = $Message
            UserSID      = $UserSID
            UserName     = $UserName
            UserDomain   = $UserDomain
            TargetUser   = $TargetUser
            TargetDomain = $TargetDomain
            LogonType    = $LogonType
            Workstation  = $Workstation
            SourceIP     = $IPAddress
            
        }

    }
    
    Write-Output $Output
    
}