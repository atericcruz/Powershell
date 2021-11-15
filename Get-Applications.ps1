Get-Applications {

  [CmdletBinding()]

  param()

  Process {

    $Applications_Raw = @()
    $x32Path = "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $x64Path = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

    $AllProfiles = Get-CimInstance Win32_UserProfile | Where { $_.SID -like "S-1-5-21-*" } 
    $Loaded = $AllProfiles | Where { $_.Loaded -eq $true }
    $NotLoaded = $AllProfiles | Where { $_.Loaded -eq $false }

    $Applications_Raw += Get-ItemProperty "HKLM:\$x32Path"
    $Applications_Raw += Get-ItemProperty "HKLM:\$x64Path"

    ForEach ($Load in $Loaded) {

      $Username = "$(($Load.localpath -split '\\')[-1])"

      $Applications_Raw += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($Load.SID)\$x32Path" | Select *, @{n = 'Username'; e = { $Username } }
      $Applications_Raw += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($Load.SID)\$x64Path" | Select *, @{n = 'Username'; e = { $Username } }

    }
      
    Foreach ($NotLoad in $NotLoaded ) {

      $NTUSER = "$($NotLoad.LocalPath)\NTUSER.DAT"
      $Username = "$(($NTUSER.localpath -split '\\')[-1])"


      REG LOAD HKU\ATemp $NTUSER

      $Applications_Raw += Get-ItemProperty -Path "Registry::\HKEY_USERS\ATemp\$x32Path" | Select *, @{n = 'Username'; e = { $Username } }
      $Applications_Raw += Get-ItemProperty -Path "Registry::\HKEY_USERS\ATemp\$x64Path" | Select *, @{n = 'Username'; e = { $Username } }

      [GC]::Collect()
      [GC]::WaitForPendingFinalizers()
            
      REG UNLOAD HKU\ATemp

    }

    $Output = @($Applications_Raw | where { !$_.SystemComponent -and !$_.ParentKeyName -and $_.Displayname -and $_.UninstallString }).ForEach({
      
        $Architecture = switch (($_.pspath)) { { $_ -match 'WOW6432Node' } { 'x86' } default { 'x64' } }
        #try{ $Comments = $_.Comments }catch{ $Comments = '' }
        try { $ConfigFileLocation = $_.ConfigFileLocation }catch { $ConfigFileLocation = '' }
        try { $Contact = $_.Contact }catch { $Contact = '' }
        try { $DisplayIcon = $_.DisplayIcon }catch { $DisplayIcon = '' }
        try { $DisplayName = $_.DisplayName }catch { $DisplayName = '' }
        try { $DisplayVersion = $_.DisplayVersion }catch { $DisplayVersion = '' }
        try { $EstimatedSize = [int]([math]::Round($_.EstimatedSize / 1KB, 0) ) }catch { $EstimatedSize = '' }
        try { $ExecutableLocation = $_.ExecutableLocation }catch { $ExecutableLocation = '' }
        try { $ExecutableServiceLocation = $_.ExecutableServiceLocation }catch { $ExecutableServiceLocation = '' }
        try { $HelpLink = $_.HelpLink }catch { $HelpLink = '' }
        try { $HelpTelephone = $_.HelpTelephone }catch { $HelpTelephone = '' }
        try { $InstallDate = ([datetime]::ParseExact( $_.InstallDate, 'yyyyMMdd', $null).Tostring('MM-dd-yyyy')) }catch { try { $InstallDate = ([datetime]::ParseExact( $_.InstallDate, 'MM/dd/yyyy', $null).Tostring('MM-dd-yyyy')) }catch { $InstallDate = '' } }
        try { $Installed = $_.Installed }catch { $Installed = '' }
        try { $InstallLocation = $_.InstallLocation }catch { $InstallLocation = '' }
        try { $InstallSource = $_.InstallSource }catch { $InstallSource = '' }
        #try{ $Language = $_.Language }catch{ $Language = '' }
        #try{ $LogFile = $_.LogFile }catch{ $LogFile = '' }
        #try{ $MajorVersion = $_.MajorVersion }catch{ $MajorVersion = '' }
        #try{ $MinorVersion = $_.MinorVersion }catch{ $MinorVersion = '' }
        try { $ModifyPath = $_.ModifyPath }catch { $ModifyPath = '' }
        try { $ModifyPath_Hidden = $_.ModifyPath_Hidden }catch { $ModifyPath_Hidden = '' }
        #try{ $NoElevateOnModify = $_.NoElevateOnModify }catch{ $NoElevateOnModify = '' }
        try { $NoModify = $_.NoModify }catch { $NoModify = '' }
        try { $NoRemove = $_.NoRemove }catch { $NoRemove = '' }
        #try{ $NoRepair = $_.NoRepair }catch{ $NoRepair = '' }
        try { $ParentDisplayName = $_.ParentDisplayName }catch { $ParentDisplayName = '' }
        try { $ParentKeyName = $_.ParentKeyName }catch { $ParentKeyName = '' }
        #try{ $PSChildName = $_.PSChildName }catch{ $PSChildName = '' }
        #try{ $PSParentPath = $_.PSParentPath }catch{ $PSParentPath = '' }
        #try{ $PSPath = $_.PSPath }catch{ $PSPath = '' }
        #try{ $PSProvider = $_.PSProvider }catch{ $PSProvider = '' }
        try { $Publisher = $_.Publisher }catch { $Publisher = '' }
        try { $QuietUninstallString = $_.QuietUninstallString }catch { $QuietUninstallString = '' }
        try { $Readme = $_.Readme }catch { $Readme = '' }
        try { $ReleaseType = $_.ReleaseType }catch { $ReleaseType = '' }
        try { $RepairPath = $_.RepairPath }catch { $RepairPath = '' }
        try { $SystemComponent = $_.SystemComponent }catch { $SystemComponent = '' }
        try { $UninstallPath = $_.UninstallPath }catch { $UninstallPath = '' }
        try { $UninstallString = $_.UninstallString -replace '/I|/X', '/X ' }catch { $UninstallString = '' }
        try { $UninstallString_Hidden = $_.UninstallString_Hidden }catch { $UninstallString_Hidden = '' }
        try { $UpdaterInstallationPath = $_.UpdaterInstallationPath }catch { $UpdaterInstallationPath = '' }
        try { $UpdaterServiceInstallationPath = $_.UpdaterServiceInstallationPath }catch { $UpdaterServiceInstallationPath = '' }
        try { $URLInfoAbout = $_.URLInfoAbout }catch { $URLInfoAbout = '' }
        try { $URLUpdateInfo = $_.URLUpdateInfo }catch { $URLUpdateInfo = '' }
        try { $Version = $_.Version }catch { $Version = '' }
        #try{ $VersionMajor = $_.VersionMajor }catch{ $VersionMajor = '' }
        #try{ $VersionMinor = $_.VersionMinor }catch{ $VersionMinor = '' }
        try { $WindowsInstaller = $_.WindowsInstaller }catch { $WindowsInstaller = '' }
        $User = $_.Username

        [PSCustomObject]@{

          DisplayName                    = $DisplayName
          Publisher                      = $Publisher 
          DisplayVersion                 = $DisplayVersion 
          DisplayIcon                    = $DisplayIcon
          Size                           = $EstimatedSize
          InstallDate                    = $InstallDate
          InstallLocation                = $InstallLocation 
          InstallSource                  = $InstallSource
          Username                       = $User 
          Architecture                   = $Architecture
          ModifyPath                     = $ModifyPath 
          ModifyPath_Hidden              = $ModifyPath_Hidden 
          Uninstall                      = $UninstallString
          QuietUninstallString           = $QuietUninstallString
          UninstallPath                  = $UninstallPath 
          UpdaterInstallationPath        = $UpdaterInstallationPath 
          UpdaterServiceInstallationPath = $UpdaterServiceInstallationPath  
          Readme                         = $Readme 
          HelpLink                       = $HelpLink 
          HelpTelephone                  = $HelpTelephone 
          RepairPath                     = $RepairPath 
          URLInfoAbout                   = $URLInfoAbout 
          URLUpdateInfo                  = $URLUpdateInfo 
 
        }
      }) | Sort Displayname

    Write-Output $Output

  }

}
