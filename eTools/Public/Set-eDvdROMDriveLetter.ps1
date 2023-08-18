<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Change DVD drive letter to Z:
#>
Function Set-eDvdROMDriveLetter {

    [CmdletBinding()]
    
    param(

        [char]$ChangeDVDDriveLetter = 'D',

        [char]$NewDVDDriveLetter = 'Z'

    )
    
    Begin {
    
        $SetDriveLetter = @{

            DriveLetter = "$($NewDVDDriveLetter):"

        }
    
    }

    Process {
    
        $Error.Clear()

        try {

            $DVDDrive = Get-WmiObject -Class Win32_volume -Filter 'DriveType=5' | Where-Object { $_.Driveletter -eq "$($ChangeDVDDriveLetter):" }

            if ($null -ne $DVDDrive) {

                $ChangeDriveLetter = Set-WmiInstance -InputObject $DVDDrive -Arguments $SetDriveLetter

                $DVDLetter = $ChangeDriveLetter.DriveLetter

                if ( $DVDLetter -eq "$($NewDVDDriveLetter):") {

                    $Success = $True
                    $Changed = "Changed $($ChangeDVDDriveLetter): to $($NewDVDDriveLetter):"

                }
                else {

                    $Success = $False

                    throw "Drive letter was not changed from $($ChangeDVDDriveLetter): to $($NewDVDDriveLetter):"

                }

            }
            else {

                $Changed = "DVD-ROM drive letter $($ChangeDVDDriveLetter): was not found"
                $Success = $True

            }
    
        }
        catch {
    
            If ($Error -like "*Drive letter was not changed *") {
    
                $Message = $Error.FullyQualifiedErrorId
                $Changed = $Message
    
            }
            ELSE {
    
                $Message = $Error.Exception.Message
                $Changed = 'Error occurred'
    
            }
            
            $Success = $False
            $ErrorException = $Error.Exception
            $ErrorMessage = $Message
            $ErrorDetails = $Error
    
        }
    
        $Output = [PSCustomObject]@{
            
            Date               = Get-Date -Format 'MM-dd-yyyy HH:mm:ss'
            Computername       = $env:COMPUTERNAME
            ChangedDriveLetter = $Changed
            Success            = $Success
            Error              = $ErrorDetails
            ErrorMessage       = $ErrorMessage
            ErrorException     = $ErrorException
    
        }
    
        Write-Output $Output
    
    }#Process
    
}