<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Create D:\wwwroot\Main and D:\LogFiles folders
#>
Function Set-IISMainLogFilesFolders {

    [CmdletBinding()]
    
    param(

        [char]$DriveLetter = 'D',
    
        $MainFolder = "$($DriveLetter):\wwwroot\MAIN",

        $LogsFolder = "$($DriveLetter):\LogFiles",

        [switch]$ChangeDVDLetter

    )
    
    Begin {
    
        $Directories = @($MainFolder, $LogsFolder)

        $Drive = "$($DriveLetter):"

    }
    
    Process {
    
        $null = Set-eDvdROMDriveLetter

        $Error.Clear()

        try {

            $DriveAvailable = (! ( (Get-CimInstance Win32_CDRomDrive).Drive -eq $Drive ) )

            if ( ( $ChangeDVDLetter ) -and ( $DriveAvailable -eq $False ) ) {

                $ChangeDVDLetter = Change-DvdROMDriveLetter

            }
            elseif ( $DriveAvailable -eq $False ) {

                $ErrorMessage = "$DriveLetter is in use by CD-ROM Drive"

                throw "$DriveLetter is in use by CD-ROM Drive"

            }

            if ( ( Test-Path -Path $Drive ) -eq $True ) {

                $Directories | ForEach-Object {

                    If (! ( Test-Path -Path $_ ) ) {

                        $null = New-Item -Path $_ -ItemType Directory -Force 

                    }

                }

                $LogFileDir = 'Created'
                $Main = 'Created'
                $Success = $True
                $ErrorException = ''
                $ErrorMessage = ''
                $ErrorDetails = ''

            }
            else {

                $LogFileDir = 'No D:\ drive found'
                $Main = 'No D:\ drive found'
                $Success = $False
                $ErrorException = 'No D:\ drive found'
                $ErrorMessage = 'No D:\ drive found'
                $ErrorDetails = 'No D:\ drive found'
            }
    
        }
        catch {
    
            If ( $Error -like "*in use by CD-ROM Drive" ) {
    
                $Message = $Error.FullyQualifiedErrorId
    
            }
            ELSE {
    
                $Message = $Error.Exception.Message
    
            }

            $LogFileDir = "$(Test-Path D:\LogFiles)"
            $Main = "$(Test-Path D:\wwwroot\MAIN)"
            $Success = $False
            $ErrorException = $Error.Exception
            $ErrorMessage = $Message
            $ErrorDetails = $Error
    
        }
    
        $Output = [PSCustomObject]@{
            
            Date           = Get-Date -Format 'MM-dd-yyyy HH:mm:ss'
            Computername   = $env:COMPUTERNAME
            MainFolder     = $Main
            LogsFolder     = $LogFileDir
            Success        = $Success
            Error          = $ErrorDetails
            ErrorMessage   = $ErrorMessage
            ErrorException = $ErrorException
    
        }
    
        Write-Output $Output
    
    }#Process
    
}