<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Get all applications installed, including user install apps (%LOCAL|APPDATA%). Should match exacltly like Programs and features plus any user install apps. 
#>

Function Get-eApplications {

    Function Format-Dates {

        [CmdletBinding()]

        param (

            $Date

        )

        Begin {

            Write-Verbose "Begin"

        }
        Process {

            $Output = switch ( $Date ) {

                { $Date -match '\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2}' } { Get-Date -Date ([datetime]::ParseExact($Date, 'MM/dd/yyyy HH:mm:ss', $Null)) -Format 'MM/dd/yyyy' }

                { $Date -match '(\d{2}/\d{2}/\d{4})([^:]*$)' } { Get-Date -Date ([datetime]::ParseExact($Date , 'MM/dd/yyyy', $Null)) -Format 'MM/dd/yyyy' }

                { $Date -like "*EDT*" } { (Get-Date -Date ([datetime]::ParseExact($Date, 'ddd MMM dd HH:mm:ss \EDT yyyy', $Null)) -Format 'MM/dd/yyyy') }

                { $Date -match "^\d+$" } { Get-Date -Date ([datetime]::ParseExact($Date, 'yyyyMMdd', $Null)) -Format 'MM/dd/yyyy' }

                { [string]::IsNullOrEmpty($Date) } { $Date -replace '\s+', $null; write-host "ldkjfkasdfjmlakdlfadl" } 

                default { $Date }

            }

            Write-Output $Output

        }
        End {}
        
    }

    $Applications_Raw = @() 
    $x32Path = "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $x64Path = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    #New-PSDrive -Name HKCU -PSProvider Registry HKEY_USERS
    Function Test-IsAdmin {

        $IsAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        if ($IsAdmin -eq $false) {
            Write-Error "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' ) - Finding all user applications requires administrative privileges"
            break
        }

    }

    Test-IsAdmin

    $AllProfiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -like "S-1-5-21-*" } # | Select-Object LocalPath, SID, Loaded, Special | Where-Object {$_.SID -like "S-1-5-21-*"}
    $MountedProfiles = $AllProfiles | Where-Object { $_.Loaded -eq $true }
    $UnmountedProfiles = $AllProfiles | Where-Object { $_.Loaded -eq $false }

    #Write-Host "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' ) - Getting installed apps for all users" -ForegroundColor Yellow
    $Applications_Raw += Get-ItemProperty "HKLM:\$x32Path"# | Where-Object{$_.SystemComponent -notmatch '0|1' } #  -and !$_.ReleaseType -and !$_.ParentKeyname -and ($_.UninstallString -or $_.NoRemove)
    $Applications_Raw += Get-ItemProperty "HKLM:\$x64Path"# | Where-Object{$_.SystemComponent -notmatch '0|1' }
    #Write-Host "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' ) - Finished installed apps for all users" -ForegroundColor Green

    ForEach ($MountedProfile in $MountedProfiles) {

        #Write-Host "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' ) - Getting installed apps for: $(($MountedProfile.localpath -split '\\')[-1])" -ForegroundColor Yellow
        try {
            $Applications_Raw += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($MountedProfile.SID)\$x32Path"# | Where-Object{$_.SystemComponent -notmatch '0|1' }
            $Applications_Raw += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($MountedProfile.SID)\$x64Path"# | Where-Object{$_.SystemComponent -notmatch '0|1' }
        }
        catch {}
        #Write-Host "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' ) - Finished getting installed apps for: $(($MountedProfile.localpath -split '\\')[-1])" -ForegroundColor Green
    }

    Foreach ($UnmountedProfile in $UnmountedProfiles ) {

        $NTUSER = "$($UnmountedProfile.LocalPath)\NTUSER.DAT"

        IF ((Test-Path $NTUSER) -eq $True) {

            #Write-Host "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' ) - Mounting and getting applications for NTUser: $NTUSER" -ForegroundColor Yellow

            try { $null = REG LOAD HKU\ATemp $NTUSER | Out-Null }catch {  }

            $Applications_Raw += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$x32Path" # | Where-Object{$_.SystemComponent -notmatch '0|1' }
            $Applications_Raw += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$x64Path" # | Where-Object{$_.SystemComponent -notmatch '0|1' }

            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()

            try { $null = REG UNLOAD HKU\ATemp | Out-Null }catch {}

            #Write-Host "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' ) - Finished unmounting and getting applications for NTUser: $NTUSER" -ForegroundColor Green

        }
    }

    $Apps = @($Applications_Raw  | Where-Object { !$_.SystemComponent -and !$_.ParentKeyName -and $_.Displayname -and $_.UninstallString }) | Select-Object 'DisplayName', 'DisplayVersion', 'Version', 'Comments', 'HelpLink', 'URLInfoAbout', @{n = 'InstallDate'; e = { get-date (format-date $_.installdate) -Format 'MM/dd/yyyy' } }, 'InstallLocation', 'InstallSource', 'ModifyPath', 'Publisher', 'Readme', 'UninstallString', @{N = 'RegistryPath'; e = { ($_.pspath -replace "Microsoft.PowerShell.Core\\Registry::\\|Microsoft.PowerShell.Core\\Registry::") } }

    $AllApplications = ForEach ($App in $Apps) { 

        $registrypath = $App.RegistryPath

        switch ($registrypath) {
            { $registrypath -match "USERS" } { $UserInstall = $True; $UsersInstall = $False; $User = $AllProfiles.Where({ $_.SID -EQ $registrypath.Split('\')[1] }).LocalPath -replace 'c:\\users\\' }
            default { $UserInstall = $False; $UsersInstall = $True; $User = 'AllUsers' }
        }

        $Output = $App | Select-Object *, @{N = 'User'; e = { $User.ToUpper() } }

        Write-Output $Output
    }

    #Write-Host "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt') - $($AllApplications.Count) installed applications found" -ForegroundColor Green
    Write-Output $AllApplications

}