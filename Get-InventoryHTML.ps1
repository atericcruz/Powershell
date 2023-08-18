<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Inventory Script
#>

$InventoryScript = "\\$env:USERDNSDOMAIN\NETLOGON\Inventory.ps1"
$InventoryScriptHash = (Get-FileHash $InventoryScript).hash
$Inventory = 'C:\Temp\Inventory.ps1'
$InventoryFile = 'C:\Temp\Inventory.ps1'
$HistoryPath = 'C:\SE\Inventory\History'
$History = "$HistoryPath\*_$($ENV:COMPUTERNAME).json"
$MyHash = (Get-FileHash $InventoryFile).hash
$HtmlFile = "C:\Temp\$($ENV:COMPUTERNAME).html"
$SchTask = Get-ScheduledTask -TaskName "Systems Inventory HTML" -EA 0

if ((Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate") -EQ $True) {

    $WindowsUpdate = (Get-ItemProperty –Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" –Name WUServer -ErrorAction SilentlyContinue)
    $WsusServer = $WindowsUpdate.WuServer -replace 'http.*://|:\d\d\d\d'

}
else {

    $WsusServer = 'NONE'

}

$WsusOfflineFolder = "C:\Temp\WSUS Offline Catalog"
$WsusLocalCabPath = "$WsusOfflineFolder\wsusscn2.cab"
$WsusRemoteCabPath = "\\$WsusServer\offlinescan\wsusscn2.cab"

$FixComPlusApps = $False
$GetWsusOfflineScan = $False
$Web = $False
$SQL = $False
$Corporate = $False
$IsSecurity = $False
$Tier = 'UNKNOWN'
$Stack = 'UNKNOWN'
$IsVM = $False
$IsPhysical = $False
$IsWeb = $False
$IsSQL = $False
$Computername = $env:COMPUTERNAME
$IPDns = "$((Resolve-DnsName $Computername -ErrorAction SilentlyContinue ).IP4Address -join ',')"

########################################################################## Prereq Tests ##########################################################################

if ((Get-Item $HistoryPath).GetType().Name -ne 'DirectoryInfo') {

    $null = Remove-Item $HistoryPath -Force -EA 0

}

$null = New-Item -Path "$HistoryPath", 'C:\Temp', "$WsusOfflineFolder"-ItemType Directory -Force -EA 0

If ("$MyHash" -ne "$InventoryScriptHash") {

    $null = Copy-Item "$InventoryScript" "$InventoryFile" -Force -EA 0

}

If ($null -eq $SchTask) {

    $Trigger = New-ScheduledTaskTrigger -At 12:00am -Daily
    $User = "NT AUTHORITY\SYSTEM"
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $InventoryFile
    $Regist = Register-ScheduledTask -TaskName "Systems Inventory HTML" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest –Force
    $Tsk = (Get-ScheduledTask -TaskName "Systems Inventory HTML" -EA 0) 

}

########################################################################## Prereq Tests End ##########################################################################

##########################################################################     Functions    ##########################################################################

$DuhDate = { "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' ) - " }

Function Create-gDatatableHtml {

    [CmdletBinding()]

    param(
        [ValidateNotNullorEmpty()]
        $Data,
        [string]$Title,
        [string]$IDName
    )

    $Html = @()
    $Html += "<div>`n"
    $Html += "<h4>$Title</h4>`n"
    $Html += "<table id=""a$($IDName)tb"" class=""table table-bordered table-striped table-sm"" style=""width:100%"">`n"
    $Html += "`t<thead>`n"
($Data[0]).psobject.Properties.ForEach({ $Html += "`t`t<th>$($_.Name)</th>`n" })
    $Html += "`t</thead>`n"
    $Html += "`t<tbody>`n"
    $Data | Foreach {
        $Html += "`t`t<tr>`n"
($_).psobject.Properties.ForEach({ $Html += "`t`t<td>$($_.value)</td>`n" })
        $Html += "`t`t</tr>`n"
    }
    $Html += "`t</tbody>`n"
    $Html += "</table>`n"
    $Html += "</div>`n"
    $HTML += "<br>"

    Write-Output $Html

}

Function New-HTMLAccordion {

    [CmdletBinding()] 
    param (
        [Parameter(Mandatory = $false)]
        $Table,
        [string]$Tabletitle,
        $Id,
        [bool]$Collapsed = $true

    )

    $accordionclosed = @"
<div class="accordion-item">
    <div class="accordion-header" id="a$($Id  -replace " ")1">
        <h5 class="mb-0">
            <button id="$Id" class="accordion-button collapsed" type="button" data-bs-toggle="collapse"
                data-bs-target="#a$($Id -replace " ")" aria-expanded="false" aria-controls="$($Id -replace " ")">
                $($Tabletitle -replace ':',': ' -replace '-','- ')
            </button>
        </h5>

        <div id="a$($Id  -replace " ")" class="accordion-collapse collapse" aria-labelledby="a$($Id -replace " ")1"
            data-bs-parent="#accordion">
            <div class="accordion-body">
                <div class="table-responsive">
                    $Table
                </div>
            </div>
        </div>
    </div>
</div>
"@
    $accordionclosedORG = @"
<div class="accordion-item">
    <div class="accordion-header" id="a$($Id  -replace " ")1">
        <h5 class="mb-0">
            <button id="$Id" class="accordion-button collapsed" type="button" data-bs-toggle="collapse"
                data-bs-target="#a$($Id -replace " ")" aria-expanded="false" aria-controls="a$($Id -replace " ")">
                $($Tabletitle -replace ':',': ' -replace '-','- ')
            </button>
        </h5>

        <div id="a$($Id  -replace " ")" class="accordion-collapse collapse" aria-labelledby="a$($Id -replace " ")1"
            data-bs-parent="#accordion">
            <div class="accordion-body">
                <div class="table-responsive">
                    <table id="a$($Id  -replace " ")tb" class="table table-bordered table-striped table-sm"
                        style="width:100%" cellspacing="0">$table</table>
                </div>
            </div>
        </div>
    </div>
</div>
"@

    $accordionopen = 
    @"
<div class="accordion-item">
    <div class="accordion-header" id="a$($Id  -replace " ")1">
        <h5 class="mb-0">
            <button id="$Id" class="accordion-button collapsed" type="button" data-bs-toggle="collapse"
                data-bs-target="#a$($Id -replace " ")" aria-expanded="false" aria-controls="a$($Id -replace " ")">
                $Tabletitle
            </button>
        </h5>

        <div id="a$($Id  -replace " ")" class="accordion-collapse show" aria-labelledby="a$($Id -replace " ")1"
            data-bs-parent="#accordion">
            <div class="accordion-body">

                <div class="table-responsive">
                    $Table
                </div>
            </div>
        </div>
    </div>
</div>
"@


    if ($Collapsed -eq $true) {
        $accordionclosed
    }
    else {

        $accordionopen

    }


}

Function Get-gApplications {

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

                { [string]::IsNullOrEmpty($Date) } { $Date -replace '\s+', $null; write-host "$Date" } 

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

    $AllProfiles = Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -like "S-1-5-21-*" } # | Select LocalPath, SID, Loaded, Special | Where-Object {$_.SID -like "S-1-5-21-*"}
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

            $Applications_Raw += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$x32Path"# | Where-Object{$_.SystemComponent -notmatch '0|1' }
            $Applications_Raw += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$x64Path"# | Where-Object{$_.SystemComponent -notmatch '0|1' }

            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()

            try { $null = REG UNLOAD HKU\ATemp | Out-Null }catch {}

            #Write-Host "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' ) - Finished unmounting and getting applications for NTUser: $NTUSER" -ForegroundColor Green

        }
    }

    $Apps = @($Applications_Raw  | Where-Object { !$_.SystemComponent -and !$_.ParentKeyName -and $_.Displayname -and $_.UninstallString }) | Select 'DisplayName', 'DisplayVersion', 'Version', 'Comments', 'HelpLink', 'URLInfoAbout', @{n = 'InstallDate'; e = { get-date (format-dates $_.installdate) -Format 'MM/dd/yyyy' } }, 'InstallLocation', 'InstallSource', 'ModifyPath', 'Publisher', 'Readme', 'UninstallString', @{N = 'RegistryPath'; e = { ($_.pspath -replace "Microsoft.PowerShell.Core\\Registry::\\|Microsoft.PowerShell.Core\\Registry::") } }

    $AllApplications = ForEach ($App in $Apps) { 

        $registrypath = $App.RegistryPath

        switch ($registrypath) {
            { $registrypath -match "USERS" } { $UserInstall = $True; $UsersInstall = $False; $User = $AllProfiles.Where({ $_.SID -EQ $registrypath.Split('\')[1] }).LocalPath -replace 'c:\\users\\' }
            default { $UserInstall = $False; $UsersInstall = $True; $User = 'AllUsers' }
        }

        $Output = $App | Select *, @{N = 'User'; e = { $User.ToUpper() } }

        Write-Output $Output
    }

    #Write-Host "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt') - $($AllApplications.Count) installed applications found" -ForegroundColor Green
    Write-Output $AllApplications

}

##########################################################################  Functions End   ##########################################################################

#########################################################################################################################################################################
########################################################################  GETTING INVENTORY Start  ########################################################################
#########################################################################################################################################################################

##########################################################################   Get AD Info    ##########################################################################

Write-Verbose "Get AD Info"
$DomainDN = ([adsi]'').distinguishedName
$Searcher = [adsisearcher]"LDAP://$DomainDN "
$Searcher.Filter = "(name=$ENV:Computername)"
$ADProperties = $Searcher.FindAll().Properties
$Description = $ADProperties.description
$DistinguishedName = $ADProperties.distinguishedname
$LastLogon = ([datetime]::FromFileTime("$($ADProperties.lastlogontimestamp)")).GetDateTimeFormats()[43]
$LastLogonDaysAgo = (New-TimeSpan -Start $LastLogon -End (get-date)).Days
$LastLogonGt91Days = $LastLogonDaysAgo -gt 90
$ADDNSHostname = $ADProperties.dnshostname
$Domain = $ADProperties.dnshostname -replace "$ENV:COMPUTERNAME."

########################################################################   Get AD Info End  ##########################################################################

########################################################################       WMI Info     ##########################################################################

$win32_computersystem = (Get-CimInstance win32_computersystem)
$win32_processor = (Get-CimInstance win32_processor)
$win32_operatingsystem = (Get-CimInstance win32_operatingsystem)
$Win32_NetworkAdapterConfiguration = Get-CimInstance Win32_NetworkAdapterConfiguration -Property * | Where-Object { "$($_.DefaultIPGateway)".length -gt 1 } 

$Win32_PhysicalMemory = Get-CIMInstance -ClassName Win32_PhysicalMemory | ForEach-Object {

    [PSCustomObject]@{
        Computername  = $ENV:COMPUTERNAME
        Name          = $_.Name
        Description   = $_.Description
        Manufacturer  = $_.Manufacturer
        Model         = $_.Model
        CapacityGB    = [math]::Round($_.Capacity / 1GB)
        Status        = $_.Status
        PartNumber    = $_.PartNumber
        SerialNumber  = $_.SerialNumber
        SKU           = $_.SKU
        Version       = $_.Version
        HotSwappable  = $_.HotSwappable
        FormFactor    = $_.FormFactor
        BankLabel     = $_.BankLabel
        MemoryType    = $_.MemoryType
        PositionInRow = $_.PositionInRow
        Speed         = $_.Speed
        ClockSpeed    = $_.ConfiguredClockSpeed
        Voltage       = $_.ConfiguredVoltage
    }

}

$Memory = [math]::Round($win32_computersystem.TotalPhysicalMemory / 1GB, 0)
$Cores = $win32_computersystem.NumberOfProcessors
$OS = $win32_operatingsystem.Caption
$OSInstallDate = $win32_operatingsystem.InstallDate.ToString('MM-dd-yyyy HH:mm')
$LastBoot = $win32_operatingsystem.LastBootUpTime.ToString('MM-dd-yyyy HH:mm')
$IP = $Win32_NetworkAdapterConfiguration.ipaddress[0]
$Gateway = $Win32_NetworkAdapterConfiguration.DefaultIPGateway -join ', '
$DNS = $Win32_NetworkAdapterConfiguration.DNSServerSearchOrder -join ', '

if ($win32_computersystem.Manufacturer -match 'VMWare|Hyper-v' ) { 

    $IsVm = $true 

}
else { 

    $IsPhysical = $True 

}

$Processor = $win32_processor[0]
$ProcessorName = $Processor.Name
$Sockets = $win32_processor.Count
$CoresPer = $win32_processor.NumberOfCores[0]
$Cores = $Sockets * $CoresPer
$LogicalProcs = $win32_processor.NumberOfLogicalProcessors.Count
$Manufacturer = $win32_computersystem.Manufacturer
$Model = $win32_computersystem.Model
$Cpu = $ProcessorName
$Sockets = $Sockets
$Cores = $Cores
$LogicalCores = $LogicalProcs
$TotalCores = $Cores * $Sockets
$TotalThreads = $LogicalProcs * $Sockets
$TotalCPUs = $win32_computersystem.NumberOfLogicalProcessors
$CpuLoad = (Get-CimInstance win32_processor | Measure-Object loadpercentage -Average | Select-Object -ExpandProperty Average)
$MemoryGB = [math]::Round($win32_operatingsystem.TotalVisibleMemorySize / 1MB)
$FreeMemory = [math]::Round($win32_operatingsystem.FreePhysicalMemory / 1KB)
$FreeMemoryGB = [math]::Round( ($win32_operatingsystem.FreePhysicalMemory / 1MB), 2 )
$FreeMemoryPerc = [math]::Round( ( ($win32_operatingsystem.FreePhysicalMemory / $win32_operatingsystem.TotalVisibleMemorySize) * 100 ) )

########################################################################      WMI Info End      ##########################################################################

########################################################################    Windows Features    ##########################################################################

if ($OS -like '*Server*') {

    $WindowsFeatures = @(Get-WindowsFeature | Where-Object { $_.InstallState -eq 'Installed' }) | Select Displayname, Name, InstallState, Description

}

########################################################################  Windows Features End  ##########################################################################

########################################################################        Services        ##########################################################################

$Service = @(
    
    @{ Name = 'AcceptPause' ; Expression = { ($_.'AcceptPause' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'AcceptStop' ; Expression = { ($_.'AcceptStop' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'Caption' ; Expression = { ($_.'Caption' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'CheckPoint' ; Expression = { ($_.'CheckPoint' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'DelayedAutoStart' ; Expression = { ($_.'DelayedAutoStart' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'Description' ; Expression = { ($_.'Description' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'DesktopInteract' ; Expression = { ($_.'DesktopInteract' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'DisplayName' ; Expression = { ($_.'DisplayName' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'ErrorControl' ; Expression = { ($_.'ErrorControl' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'ExitCode' ; Expression = { ($_.'ExitCode' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'InstallDate' ; Expression = { ($_.'InstallDate' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'Name' ; Expression = { ($_.'Name' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'PathName' ; Expression = { ($_.'PathName' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'ProcessId' ; Expression = { ($_.'ProcessId' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'ServiceSpecificExitCode' ; Expression = { ($_.'ServiceSpecificExitCode' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'ServiceType' ; Expression = { ($_.'ServiceType' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'Started' ; Expression = { ($_.'Started' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'StartMode' ; Expression = { ($_.'StartMode' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'StartName' ; Expression = { ($_.'StartName' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'State' ; Expression = { ($_.'State' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'Status' ; Expression = { ($_.'Status' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'TagId' ; Expression = { ($_.'TagId' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'TotalSessions' ; Expression = { ($_.'TotalSessions' -replace '\s+', ' ' -join ', ' ).Trim() } },
    @{ Name = 'WaitHint' ; Expression = { ($_.'WaitHint' -replace '\s+', ' ' -join ', ' ).Trim() } }
   
)
        
$Query = Get-CIMInstance -ClassName Win32_Service
$Services = $Query | Select-Object $Service 

########################################################################      Services End      ##########################################################################

########################################################################     System Overview    ##########################################################################

$SysInfo = [PSCustomObject]@{

    Computername      = $Computername
    Description       = $Description
    DistinguishedName = "$DistinguishedName"
    Manufacturer      = $Manufacturer
    Model             = $Model
    'CPU%'            = $CpuLoad
    'FreeMem%'        = $FreeMemoryPerc
    FreeMemGB         = $FreeMemoryGB
    LastBoot          = "$LastBoot"
    OS                = $OS
    IP                = $IP
    Gateway           = $Gateway
    DNS               = $DNS
    CPU               = $Cpu
    Sockets           = $Sockets
    Cores             = $Cores
    Memory            = $Memory
    dotNET            = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Version
    #LogicalCores = $LogicalCores
    #TotalCores   = $TotalCores
    #TotalThreads = $TotalThreads
    #TotalCPUs    = $TotalCPUs
    IsVM              = $IsVm
    Error             = $ErrorMsg

}

########################################################################   System Overview End  ##########################################################################

########################################################################     SSL Certificates   ##########################################################################

$Ssls = [System.Collections.ArrayList]@()

$MyCerts = @(Get-ChildItem -Path Cert:\LocalMachine\My)

Foreach ($MyCert in $MyCerts) {

    $KeyName = $MyCert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
    $KeyPath = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\"
    $FullPath = $KeyPath + $KeyName
    $ACL = (Get-Item $FullPath).GetAccessControl('Access')
    $Full = (($ACL.Access | Group-Object FileSystemRights | Where-Object { $_.Name -eq 'FullControl' } ).group.IdentityReference.value -replace 'BUILTIN\\' -replace 'NT AUTHORITY\\' | Sort -Unique ) -join ','
    $Read = (($ACL.Access | Group-Object FileSystemRights | Where-Object { $_.Name -like 'Read*' }).group.IdentityReference.value -replace 'BUILTIN\\' -replace 'NT AUTHORITY\\' | Sort -Unique ) -join ','
    $ReadWrite = (($ACL.Access | Group-Object FileSystemRights | Where-Object { $_.Name -like 'Write*' }).group.IdentityReference.value -replace 'BUILTIN\\' -replace 'NT AUTHORITY\\' | Sort -Unique ) -join ','
    $SSLThumbprint = $MyCert.Thumbprint
    $Friendly = "$($MyCert.FriendlyName)"
    $NotAfter = "$($MyCert.NotAfter)"
    $NotBefore = "$($MyCert.NotBefore)"
    $Subject = "$($MyCert.Subject)"
    $Issuer = "$($MyCert.Issuer)"
    $SSLSerial = "$($MyCert.SerialNumber)"
    $NameList = "$($MyCert.DnsNameList -join ',')"
    $Days = "$((New-TimeSpan -Start (Get-Date) -End $NotAfter).Days)"

    if ($Days -like '-*') { $Expired = $TRUE }else { $Expired = $FALSE }

    $null = $Ssls.Add( [pscustomobject]@{

            Computername = $env:Computername
            Store        = 'LocalMachine\Personal'
            Friendly     = $Friendly
            Expired      = $Expired
            StartDate    = $NotBefore
            Expires      = $NotAfter
            ExpiresDays  = $Days
            DNSNames     = $NameList
            Thumbprint   = $SSLThumbprint
            Serial       = $SSLSerial
            Issuer       = $Issuer
            Subject      = $Subject 
            Full         = $Full
            ReadWrite    = $ReadWrite
            Read         = $Read    

        } )

}

$MyRoots = @(Get-ChildItem -Path Cert:\LocalMachine\Root)

ForEach ($MyRoot in $MyRoots) {

    $KeyName = $MyRoot.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
    $KeyPath = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\"
    $FullPath = $KeyPath + $KeyName
    $ACL = (Get-Item $FullPath).GetAccessControl('Access')
    $Full = (($ACL.Access | Group-Object FileSystemRights | Where-Object { $_.Name -eq 'FullControl' } ).group.IdentityReference.value -replace 'BUILTIN\\' -replace 'NT AUTHORITY\\' | Sort -Unique ) -join ','
    $Read = (($ACL.Access | Group-Object FileSystemRights | Where-Object { $_.Name -like 'Read*' }).group.IdentityReference.value -replace 'BUILTIN\\' -replace 'NT AUTHORITY\\' | Sort -Unique ) -join ','
    $ReadWrite = (($ACL.Access | Group-Object FileSystemRights | Where-Object { $_.Name -like 'Write*' }).group.IdentityReference.value -replace 'BUILTIN\\' -replace 'NT AUTHORITY\\' | Sort -Unique ) -join ','
    $SSLThumbprint = $MyRoot.Thumbprint
    $Friendly = "$($MyRoot.FriendlyName)"
    $NotAfter = "$($MyRoot.NotAfter)"
    $NotBefore = "$($MyRoot.NotBefore)"
    $Subject = "$($MyRoot.Subject)"
    $Issuer = "$($MyRoot.Issuer)"
    $SSLSerial = "$($MyRoot.SerialNumber)"
    $NameList = "$($MyRoot.DnsNameList -join ',')"
    $Days = "$((New-TimeSpan -Start (Get-Date) -End $NotAfter).Days)"

    if ($Days -like '-*') { $Expired = $TRUE }else { $Expired = $FALSE }

    $null = $Ssls.Add( [pscustomobject]@{

            Computername = $env:Computername
            Store        = 'LocalMachine\Root'
            Friendly     = $Friendly
            Expired      = $Expired
            StartDate    = $NotBefore
            Expires      = $NotAfter
            ExpiresDays  = $Days
            DNSNames     = $NameList
            Thumbprint   = $SSLThumbprint
            Serial       = $SSLSerial
            Issuer       = $Issuer
            Subject      = $Subject 
            Full         = ''
            ReadWrite    = ''
            Read         = ''   

        } )

}

$Ssls_Expired = $Ssls.Where({ $_.expired -eq $True })

$CompanySSLs = $Ssls.Where({ $_.friendly -match "COMPANY" -or $_.issuer -match "COMPANY" }) | Sort-Object -Property { $_.ExpiresDays -as [int] }

########################################################################   SSL Certificates End ##########################################################################

########################################################################          Drives        ##########################################################################

$GetDisks = @(Get-Disk)

if ($Manufacturer -match 'VMware') {
    ###########################################################          VMware Drives        ################################################################
    try {

        add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
public bool CheckValidationResult(
ServicePoint srvPoint, X509Certificate certificate,
WebRequest request, int certificateProblem) {
return true;
}
}
"@

        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    }
    catch {}

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $vsphereRO = New-Object System.Management.Automation.PSCredential('VSPHEREREADONLYACCOUNT@vsphere.local', (ConvertTo-SecureString 'PASSWORDHERE' -AsPlainText -Force))
    $Header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]" 
    $Header = @{"Authorization" = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($vsphereRO.GetNetworkCredential().UserName + ":" + $vsphereRO.GetNetworkCredential().Password)) }
    
    $vCenter = switch ($ENV:COMPUTERNAME.Substring(0, 2)) {

        { $_ -eq 'X1' -and $Domain -match 'domain.local' } { 'X1vcenter01.domain.local' }
        { $_ -eq 'X1' -and $Domain -match 'domain2.local' } { 'X1vcenter01.domain2.local' }
        { $_ -eq 'X2' -and $Domain -match 'domain.local' } { 'X2vcenter01.domain.local' }
        { $_ -eq 'X2' -and $Domain -match 'domain2.local' } { 'X2vcenter01.domain2.local' }
        { $_ -eq 'X3' -and $Domain -match 'domain2.local' } { 'X3vcenter01.domain2.local' }

    }

    try {

        $Token = (Invoke-RestMethod "https://$vCenter/rest/com/vmware/cis/session" -Method 'POST' -Headers $Header -ContentType 'application/json' -SessionVariable Session -ErrorAction Stop).Value
        $Header = New-Object 'System.Collections.Generic.Dictionary[[String],[String]]'
        $Header = @{'vmware-api-session-id' = $Token }
        $VMwareVMID = ((Invoke-RestMethod "https://$vcenter/rest/vcenter/vm" -Method 'GET' -Headers $Header ).Value | Where-Object { $_.name -match "$ENV:COMPUTERNAME" }).VM
        $VM = (Invoke-RestMethod "https://$VCenter/rest/vcenter/vm/$VMwareVMID" -Method 'GET'  -Headers $Header).value
        $HotAddEnable_CPU = $VM.CPU.hot_add_enabled
        $HotAddEnable_CPU = $VM.memory.hot_add_enabled
        $VMXVersion = $VM.hardware.version
        $UEFIBIOS = $VM.boot.type
        $VMDisks = @($VM.disks.value | ForEach-Object {

                [PSCustomObject]@{
                    Date         = (Get-date -Format 'MM-dd-yyyy hh:mm:ss tt')
                    Computername = $Computername
                    DiskLabel    = $_.label
                    Datastore    = ($_.backing.vmdk_file.Split(' ')[0] -replace "\[|\]").split('_')[0..1] -join '-'
                    LUN          = ($_.backing.vmdk_file.Split(' ')[0] -replace "\[|\]").split('_')[-1]
                    VMDK         = $_.backing.vmdk_file.split('/')[-1]
                    CapacityGB   = [math]::Round($_.Capacity / 1GB, 0)
                    CapacityTB   = [math]::Round($_.Capacity / 1TB, 0)
                    ScsiUnit     = $_.scsi.unit
                    ScsiBus      = $_.scsi.bus
                    Type         = $_.backing.type
                }

            }) | Sort 

    }
    catch {

        $DS = $Error[2].Exception.Message
        $VMDKLabel = $Error[2].Exception.Message
        $VMDKFile = $Error[2].Exception.Message

    }

}
else {

    $DS = 'Physical'
    $VMDKLabel = 'Physical'
    $VMDKFile = 'Physical'

}#If VMware

$Drives = @()

(Get-CimInstance win32_logicaldisk -Filter "DriveType=3" | ForEach-Object {

    $LogDisk = $_
            
    $DriveLetter = $($LogDisk.DeviceID -Replace ':')
    $Partition = Get-CimAssociatedInstance -InputObject $LogDisk -ResultClass Win32_DiskPartition
    $Disk = Get-CimAssociatedInstance -InputObject $Partition -ResultClassName Win32_DiskDrive
    $Free = [int]([math]::Round(([math]::Round($LogDisk.FreeSpace / 1GB)) / ([math]::Round($LogDisk.Size / 1GB)) * 100))
    $Health = Switch ($Free) { { $Free -ge 10 } { 'Healthy' } { $Free -lt 10 } { 'Warning' } }
    $Volume = Get-CimInstance -ClassName win32_Volume -Filter "DriveLetter='$($LogDisk.DeviceID)'" -Property *
    $VolumeBlockSize = $Volume.BlockSize
    $GetDisk = Get-Disk -Number $disk.Index
    $DiskNumber = $Disk.DeviceID.ToCharArray()[-1]
    $TargetID = $Disk.SCSITargetId

    if ($Manufacturer -match 'VMware') {

        $DiskNumber = $Disk.DeviceID.ToCharArray()[-1]
        $TargetID = $Disk.SCSITargetId

        if ($OS -match '2012') {

            $DiskNumber = $Disk.DeviceID.ToCharArray()[-1]
            $TargetID = $Disk.SCSITargetId
            $VMDKFound = $VMDisks | Where-Object { $_.scsiunit -eq $TargetID }

        }
        else {

            $VMDKFound = $VMDisks | Where-Object { "$($GetDisk.location -replace 'SCSI')" -eq "$($_.scsibus)" -and $TargetID -eq "$($_.scsiunit)" }

        }

        $DS = $VMDKFound.DataStore
        $VMDKLabel = $VMDKFound.DiskLabel
        $VMDKFile = $VMDKFound.VMDK
        $ArrayName = 'VM' 
        $ArrayVolumeName = 'VM'     
        $ArrayHosts = 'VM' 
        $ArrayHostsConnected = 'VM'
        $ArrayWWNS = 'VM'

    }
    ELSE {
            
        $PureFound = 'WIP' #$PuresBySerial | Where-Object { $_.serial -eq $disk.SerialNumber }
        $ArrayName = 'WIP' #($PureFound.ArrayName | Sort -Unique) -join ','
        $ArrayVolumeName = 'WIP' #($PureFound.VolumeName | Sort -Unique) -join ','
        $ArrayHosts = 'WIP' # ($PureFound.Computername -join ',')
        $ArrayHostsConnected = 'WIP' #($PureFound.HostConnected | Sort -Unique) -join ','
        $ArrayWWNS = 'WIP' #($PureFound.WWNs | Sort -Unique) -join ','
            
    }

    $Drives += [PSCustomObject]@{

        Date                    = (Get-Date -Format "MM-dd-yyyy HH:MM:ss")
        Computername            = $env:COMPUTERNAME
        Drive                   = $LogDisk.DeviceID
        Description             = $LogDisk.VolumeName
        Size                    = $LogDisk.Size
        'Free%'                 = $Free
        FreeHealth              = $Health
        SizeMB                  = ([math]::Round($LogDisk.Size / 1MB))
        SizeGB                  = ([math]::Round($LogDisk.Size / 1GB))
        FreeMB                  = ([math]::Round($LogDisk.FreeSpace / 1MB))
        FreeGB                  = ([math]::Round($LogDisk.FreeSpace / 1GB))
        Compressed              = $LogDisk.Compressed
        FileSystem              = $LogDisk.FileSystem
        VolumeDirty             = $LogDisk.VolumeDirty
        VolumeName              = $LogDisk.VolumeName
        VolumeSerial            = $LogDisk.VolumeSerialNumber
        VolumeBlockSize         = $VolumeBlockSize
        Datastore               = "$DS"
        DatastoreVMDK           = "$VMDKFile"
        VMHardDiskLabel         = $VMDKLabel
        ArrayName               = $ArrayName
        ArrayVolumeName         = $ArrayVolumeName
        ArrayHosts              = $ArrayHosts
        ArrayHostsConnected     = $ArrayHostsConnected
        ArrayWWNS               = $ArrayWWNS
        DiskModel               = $Disk.Model
        DiskProvisioned         = $GetDisk.ProvisioningType
        DiskSCSIBus             = $Disk.SCSIBus
        DiskSCSIPort            = $Disk.SCSIPort
        DiskSCSITargetId        = $Disk.SCSITargetId
        DiskSize                = $Disk.Size
        DiskSizeMB              = ([math]::Round($Disk.Size / 1MB))
        DiskSizeGB              = ([math]::Round($Disk.Size / 1GB))
        DiskInterfaceType       = $Disk.InterfaceType
        DiskIndex               = $Disk.Index
        DiskPNPDeviceId         = $Disk.PNPDeviceID
        DiskDeviceId            = $Disk.DeviceID
        DiskName                = $Disk.Name
        DiskSerialNumber        = $Disk.SerialNumber
        DiskSignature           = $Disk.Signature
        PartitionPrimary        = $Partition.PrimaryPartition
        PartitionSize           = $Partition.Size
        PartitionSizeMB         = ([math]::Round($Partition.Size / 1MB))
        PartitionSizeGB         = ([math]::Round($Partition.Size / 1GB))
        PartitionDiskIndex      = $Partition.DiskIndex
        PartitionBootable       = $Partition.Bootable
        PartitionBoot           = $Partition.BootPartition
        PartitionNumberOfBlocks = $Partition.NumberOfBlocks
        PartitionBlockSize      = $Partition.BlockSize
        PartitionCaption        = $Partition.Caption
        PartitionName           = $Partition.Name
        PartitionIndex          = $Partition.Index
        IsClustered             = $GetDisk.IsClustered
        IsHighlyAvailable       = $GetDisk.IsHighlyAvailable
        IsOffline               = $GetDisk.IsOffline
        Location                = $GetDisk.Location
    }

} ) | Sort-Object 'Drive' -Descending 

########################################################################        Drives End      ##########################################################################

########################################################################      Installed Apps    ##########################################################################

$InstalledApplications = @(Get-gApplications)

########################################################################    Installed Apps End  ##########################################################################

########################################################################     Windows Updates    ##########################################################################

#If GetWsusOfflineScan -eq $True. Can take several minutes as it queries Microsoft

if ($GetWsusOfflineScan -eq $True) {

    (Copy-Item $WsusRemoteCabPath -Destination $WsusLocalCabPath -Verbose -Force)

    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager 
    $UpdateService = $UpdateServiceManager.AddScanPackageService("Offline Sync Service", $CabPath, 1) 
    
    Write-Verbose "$($DuhDate.Invoke())Creating OFFLINE Windows Update Searcher"
    
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()  
    $UpdateSearcher.ServerSelection = 3
    $UpdateSearcher.ServiceID = $UpdateService.ServiceID.ToString()
    
    Write-Verbose "$($DuhDate.Invoke())Searching for missing updates"
    
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
    $MissingOfflineUpdates = $SearchResult.Updates
   
    Write-Verbose "$($DuhDate.Invoke())Finished searching"
    $ResultsTime = Get-Date

    $MissingUpdateOfflineSummary = $MissingOfflineUpdates | ForEach-Object {

        [pscustomobject]@{

            Date                     = Get-Date -Format "MM-dd-yyyy HH:mm:ss"
            Computername             = $ComputerName.ToUpper() 
            Title                    = $_.Title
            Description              = $_.Description
            CveIDs                   = $($_.CveIDs -join ',')
            KB                       = $($_.KBArticleIDs -join ',')
            Severity                 = $_.MsrcSeverity
            LastDeploymentChangeTime = ( $_.LastDeploymentChangeTime ).tostring()
            UninstallationNotes      = $_.UninstallationNotes
            Categories               = $($_.categories).Name -join ', '
            Type                     = $(switch ($_.type) { 1 { 'Software' }2 { 'Driver' } })
            SupportURL               = $_.SupportURL

        }

    }

}
else {

    $MissingUpdateOfflineSummary = [pscustomobject]@{

        Date                     = Get-Date -Format "MM-dd-yyyy HH:mm:ss"
        Computername             = $ComputerName.ToUpper() 
        Title                    = '$GetWsusOfflineScan was set to FALSE'
        Description              = '$GetWsusOfflineScan was set to FALSE'
        CveIDs                   = '$GetWsusOfflineScan was set to FALSE'
        KB                       = '$GetWsusOfflineScan was set to FALSE'
        Severity                 = '$GetWsusOfflineScan was set to FALSE'
        LastDeploymentChangeTime = '$GetWsusOfflineScan was set to FALSE'
        UninstallationNotes      = '$GetWsusOfflineScan was set to FALSE'
        Categories               = '$GetWsusOfflineScan was set to FALSE'
        Type                     = '$GetWsusOfflineScan was set to FALSE'
        SupportURL               = '$GetWsusOfflineScan was set to FALSE'

    }

}#If GetWsusOfflineScan -eq $True. Can take several minutes as it queries Microsoft

###################  Installed Updates   #########################
            
$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager 
$WsusSearcher = $UpdateSession.CreateUpdateSearcher()

Write-Verbose "$($DuhDate.Invoke())Searching for Installed updates" 

$HistoryCount = $WsusSearcher.GetTotalHistoryCount()

if ($HistoryCount -gt 0) {

    $WsusHistory = @($WsusSearcher.QueryHistory(0, $HistoryCount) | ForEach-Object {

            [pscustomobject]@{
                Date                = Get-Date -Format "MM-dd-yyyy HH:mm:ss"
                Computername        = $ComputerName.ToUpper() 
                Title               = $_.Title
                Description         = $_.Description
                KB                  = ([regex]::matches($_.Title, "KB(\d{4,8})").Value)
                ResultCode          = switch ( $_.ResultCode ) { 0 { "Not Started" } 1 { "In Progress" } 2 { "Succeeded" } 3 { "Succeeded With Errrors" } 4 { "Failed" } 5 { "Aborted" } }
                InstalledDate       = ( $_.date ).tostring()
                ServerSelection     = "$(switch ( $_.ServerSelection ) { 0 { "Default ($_)" } 1 { "ManagedServer ($_)" } 3 { "Other ($_)" } })"
                UninstallationNotes = $_.UninstallationNotes
                Categories          = $($_.categories).Name -join ', '
                Type                = ($($_.categories).Type | Select -Unique) -join ', '
                ServiceID           = $_.ServiceID
                SupportURL          = $_.SupportURL
                ScanResult          = 'Success'

            }

        } | Sort-Object InstalledDate -Descending)

    ###################  Installed Updates End  #########################

    ###################    Pending Updates      #########################

}

try { 

    $IsHiddenInstalled = @($WsusSearcher.Search("IsHidden=0 and IsInstalled=0").Update)

}
catch {
 
    $IsHiddenInstalled = $null
}

if ($null -ne $IsHiddenInstalled) {

    $PendingMissingUpdates = @($IsHiddenInstalled | ForEach-Object {

            if ($null -ne $_) {

                [pscustomobject]@{
                    Date                     = Get-Date -Format "MM-dd-yyyy HH:mm:ss"
                    Computername             = $ComputerName.ToUpper() 
                    Title                    = $_.Title
                    Description              = $_.Description
                    CveIDs                   = $($_.CveIDs -join ',')
                    KB                       = $($_.KBArticleIDs -join ',')
                    Severity                 = $_.MsrcSeverity
                    LastDeploymentChangeTime = ( $_.LastDeploymentChangeTime ).tostring()
                    UninstallationNotes      = $_.UninstallationNotes
                    Categories               = $($_.categories).Name -join ', '
                    Type                     = $(switch ($_.type) { 1 { 'Software' }2 { 'Driver' } })
                    SupportURL               = $_.SupportURL

                }

            }

        })
}
###################  Pending Updates End    #########################

########################################################################   Windows Updates End  ##########################################################################

########################################################################        Web Server      ##########################################################################

if (Get-Service w3svc -ErrorAction SilentlyContinue) {

    $Web = $True
    $IsWeb = $True

    Remove-Module WebAdministration -ErrorAction SilentlyContinue
    Import-Module WebAdministration

    $AllSites = @(Get-Website)
    $AllSiteNames = $AllSites.Name
    $AllSitesCount = $AllSites.Count

    if ($AllSites.Count -ge 1) {

        $Sites = Foreach ($Site in $AllSites) {
            $i++
            $Name = $Site.name
            $SitePath = $Site.physicalPath
            $AllBinds = (Get-WebBinding -Name $Site.Name -Protocol https)
            $Binds = $AllBinds.bindinginformation
            $WebConnCFG = (Get-ChildItem -Recurse "$SitePath" -Directory  -Filter '*' | Select -First 1 | Get-ChildItem -Filter "WebConn.config"   | Where-Object { $_.FullName -like '*' }).FullName
            $SiteDirs = Get-ChildItem -Path IIS:\Sites\$($Site.name) 
            $VirtualDirs = $SiteDirs | Where-Object { $_.nodetype -eq 'virtualDirectory' }

            $AllVirtDirs = Foreach ($VirtualDir in $VirtualDirs) {

                [PSCustomObject]@{

                    WebSite       = $($Site.Name)
                    Computername  = $env:COMPUTERNAME
                    DirectoryName = $VirtualDir.Name
                    DirectoryPath = $VirtualDir.PhysicalPath
                    DirectoryType = $VirtualDir.NodeType
                    ConfigCorrect = switch ($VirtualDir.Name) {
                
                        { $_ -like 'SOMEFOLDER' } {
                
                            switch ($VirtualDir.PhysicalPath) {
                                { $_ -eq "\\$Domain\PATHHERE\$($Site.Name)\SOMEFOLDER" } { $True }
                                default { $False }
                
                            }#Switch Fullname
                
                        }#Switch SOMEFOLDER
                
                        { $_ -eq 'SOMEOTHERFOLDER' } {
                
                            switch ($VirtualDir.PhysicalPath) {
                                { $_ -eq "\\$Domain\PATHHERE\$($Site.Name)\SOMEOTHERFOLDER" } { $True }
                                default { $False }
                
                            }#Switch Fullname
                
                
                        }#Switch SOMEOTHERFOLDER
                
                        { $_ -eq 'PATHHERE\SOMEOTHEROTHERFOLDER' } {
                
                            switch ($VirtualDir.PhysicalPath) {
                                { $_ -eq "\\$Domain\PATHHERE\$($Site.Name)\SOMEOTHEROTHERFOLDER" } { $True }
                                default { $False }
                
                            }#Switch Fullname
                
                
                        }#Switch PATHHERE\Uploads
                
                        default { 'UNKNOWN' }
                    }
                
                }

            }#All Virtual Directories

            $LogFilePath = "$($Site.logFile.directory -replace '%SystemDrive%','C:')"
            $LogFiles = Get-ChildItem -Path $LogFilePath -File -Recurse | Select * -ExcludeProperty PS*
            $AppPoolNames = @($site.applicationPool) + @(Get-WebApplication -Site $Site.Name).applicationPool | Sort -Unique

            $null = [Reflection.Assembly]::LoadWithPartialName('Microsoft.Web.Administration')
            $ServerManager = New-Object Microsoft.Web.Administration.ServerManager
            $ApplicationPools = $ServerManager.ApplicationPools 

            $AppPools = Foreach ($ApplicationPool in $ApplicationPools) {     
   
                $ID = $ApplicationPool.WorkerProcesses.processid 
                $AppPoolName = $ApplicationPool.Name
                $Error.Clear()

                if ($ID) {

                    try {

                        $WP = (Get-Process -id $ID -ErrorAction SilentlyContinue)
                        $WorkerProcessStarted = try { ($WP).StartTime.tostring("MM-dd-yyyy HH:mm:ss") }catch { ; $id }

                    }
                    catch {

                        $ID = "No WorkerProcess"
                        $WorkerProcessStarted = $ID

                    }

                }
                else {

                    $ID = "No WorkerProcess"
                    $WorkerProcessStarted = $ID

                }

                $UserSID = New-Object System.Security.Principal.SecurityIdentifier("$($ApplicationPool.GetAttributeValue('applicationPoolSid'))")
                $User = $UserSID.Translate([System.Security.Principal.NTAccount])

                [PSCustomObject]@{

                    Computername                = $ENV:COMPUTERNAME
                    Name                        = $ApplicationPool.name
                    Site                        = ($Site.name -split "_" | Where-Object { $_ -match '\.' })
                    Started                     = $WorkerProcessStarted
                    PID                         = $id
                    QueueLength                 = $ApplicationPool.queueLength
                    AutoStart                   = $ApplicationPool.autoStart   
                    Enable32BitAppOnWin64       = $ApplicationPool.enable32BitAppOnWin64       
                    ManagedRuntimeVersion       = $ApplicationPool.managedRuntimeVersion       
                    ManagedRuntimeLoader        = $ApplicationPool.GetAttributeValue('managedRuntimeLoader')       
                    EnableConfigurationOverride = $ApplicationPool.GetAttributeValue('enableConfigurationOverride') 
                    ManagedPipelineMode         = $ApplicationPool.managedPipelineMode         
                    CLRConfigFile               = $ApplicationPool.GetAttributeValue('CLRConfigFile')              
                    PassAnonymousToken          = $ApplicationPool.GetAttributeValue('passAnonymousToken')
                    StartMode                   = $ApplicationPool.startMode   
                    State                       = $ApplicationPool.state       
                    AppPoolUsername             = $User
                    AppPoolSid                  = $ApplicationPool.GetAttributeValue('applicationPoolSid')
                    IdentityType                = $ApplicationPool.processmodel.identityType
                    IdentityUsername            = $ApplicationPool.processmodel.UserName
                    IdentifyPassword            = $ApplicationPool.processmodel.password
                    IdleTimeout                 = $ApplicationPool.processmodel.idleTimeout
                    IdleTimeoutAction           = $ApplicationPool.processmodel.idleTimeoutAction
                    ProcessModel                = $ApplicationPool.processModel
                    Recycling                   = $ApplicationPool.recycling   
                    Failure                     = $ApplicationPool.failure     
                    Cpu                         = $_.cpu         
                    WorkerProcesses             = $ApplicationPool.workerProcesses
                    Success                     = $True             

                }

            }#Foreach AppPool 

            $CurrentRequests = Foreach ($AppName in $AppPoolNames) {

                $Error.Clear()

                $WorkerProcesses = Get-ChildItem "IIS:\AppPools\$AppName\WorkerProcesses" #| Select Name,ProcessId,AppPoolName,State,StartTime,guid,AppDomains 

                If ($WorkerProcesses) {

                    $SiteInfo = ($WorkerProcesses ).AppDomains.Collection | Select SiteId, Id, VirtualPath, PhysicalPath
                    $Requests = ($WorkerProcesses.GetRequests().collection | Where-Object { $_.url -notmatch 'Signalr' })

                    Foreach ($Request in $Requests) {

                        [PSCustomObject]@{

                            Computername = $Request.hostname.toupper()
                            AppPool      = $AppName
                            TimeElapsed  = $Request.timeElapsed
                            ClientIP     = $Request.ClientIpAddress
                            LocalIP      = $Request.localipaddress
                            SiteId       = $Request.SiteId
                            Port         = $Request.LocalPort
                            Verb         = $Request.Verb
                            URL          = $Request.URL

                            RequestID    = $Request.RequestID
                            ConnectionId = $Request.ConnectionId

                        }

                    } sort TimeElapsed -Descending

                }
                else {

                    [PSCustomObject]@{

                        Computername = $env:COMPUTERNAME
                        AppPool      = $AppName
                        ClientIP     = 'No Requests'
                        LocalIP      = 'No Requests'
                        SiteId       = 'No Requests'
                        Port         = 'No Requests'
                        Verb         = 'No Requests'
                        URL          = 'No Requests'
                        TimeElapsed  = 'No Requests'
                        RequestID    = 'No Requests'
                        ConnectionId = 'No Requests'

                    }

                }

            }#Foreach AppName 

            [xml]$WebConnCFGXML = (Get-Content $WebConnCFG ) 
            $Split = (( $WebConnCFGXML | Select-Xml -XPath /connectionStrings/add | Where-Object { $_.node.name -eq "MATCHESSOMETHINGHERE" }).Node.connectionstring.trim().split(';') | Where-Object { $null -notlike $_ }).trim()
            $SQLServer = $Split[0] -replace 'server='
            $DB = ($Split[1] -replace 'database=').ToUpper()
            $SQLMaxPool = ($Split[-1] -replace 'Max Pool Size=').ToUpper()
            $SQLPacketSize = ($Split[-2] -replace 'PACKET SIZE=').ToUpper()

            $Counters = @(
                '\Processor Information(_Total)\% Processor Time',
                '\Memory\Available Mbytes',
                "\Web Service($Name)\Current Connections",
                "\Web Service($Name)\Current Anonymous Users",
                "\Web Service($Name)\Bytes Received/sec",
                "\Web Service($Name)\Bytes Sent/sec",
                '\W3SVC_W3WP(_Total)\% 500 HTTP Response Sent',
                '\.NET CLR Exceptions(w3wp*)\# of Exceps Thrown / sec',
                '\.NET CLR Memory(w3wp)\% Time in GC',
                "\.Net Data Provider for SqlServer(*SomethingNet*)\NumberOfPooledConnections",
                '\ASP.NET Applications(__total__)\Requests/Sec',
                '\ASP.NET Applications(__total__)\Requests in Application Queue',
                '\ASP.NET Applications(__total__)\Errors Unhandled During Execution/Sec',
                '\ASP.NET Applications(__total__)\Errors Total/Sec'
            ) 

            $ResolveSQL = Switch ($SQLServer) {

                { $_ -like '*,*' } {

                    $SQLServer.Split(',')[0]
                }
                { $_ -like '*\*' } {

                    $SQLServer.Split('\')[0]
                }

            }

            IF ($SQLServer -like 'AG*') {

                $IP = (Resolve-DnsName ($ResolveSQL)).IP4Address -join ','
                $SQLServerName = "$((Get-WmiObject  win32_computersystem).Name)($(($SQLServer.Split(',')[0] -replace ".$Domain")))"
                $SQLServerIP = $IP

            }
            else {

                $IP = (Resolve-DnsName ($ResolveSQL) -ErrorAction SilentlyContinue).IP4Address -join ','
                $SQLServerIP = $IP
                $SQLServerName = $SQLServer

            }

            ForEach ($Binding in $AllBinds) {

                $Bind = $Binding.bindinginformation

                $Thumbprint = $Binding.certificatehash
                $Cert = Get-ChildItem -Path CERT:LocalMachine/My | Where-Object { $_.Thumbprint -eq $Thumbprint }
                $Friendly = "$($Cert.FriendlyName)"
                $NotAfter = "$($Cert.NotAfter)"
                $NotBefore = "$($Cert.NotBefore)"
                $Subject = "$($Cert.Subject)"
                $Issuer = "$($Cert.Issuer)"
                $Serial = "$($cert.SerialNumber)"
                $NameList = "$($Cert.DnsNameList)"
                $Days = "$((New-TimeSpan -Start (Get-Date) -End $NotAfter).Days)"
                $BName = $Bind.split(':')[-1].split('.')[0]
                $Domain = $Bind.split(':')[-1].split('.')
                $Bound = $Bind.split(':')[2]
                $IP = $Bind.split(':')[0]

                switch ($BName) {

                    { $_ -like '*-*' } { $Stack = ($_.Split('-')[0]).ToUpper() }
                    { $_ -like '*node*' } { $Node = $_.Split('-').ToUpper() | Where-Object { $_ -Like '*node*' } }

                }       

                if ($null -notlike $Bound) {

                    if ($Bound -like '*node*') {

                        $Resolve = ($Site.name -split "_" | Where-Object { $_ -match '\.' }) -replace 'www.' 

                    }
                    else {

                        $Resolve = $Bound -replace 'www.' 

                    }
                    $URLInternalDns = (Resolve-DnsName ($Resolve -replace 'www.' ) -ErrorAction SilentlyContinue).IP4Address -join ','
                    try {

                        $URLExternalDns = (Resolve-DnsName -Name $Resolve -Server 8.8.8.8 -NoHostsFile -ErrorAction SilentlyContinue).IP4Address -join ','
                    }
                    catch {
                        #Write-Host "break"
                        $URLLBDns = $Error.exception.message
                        break
                    }

                    try {

                        $URLLBDns = (Resolve-DnsName -Name ($Bound -replace 'www.')-NoHostsFile).IP4Address -join ','
                    }
                    catch {
                        #Write-Host "break"
                        $URLExternalDns = $Error.exception.message
                        break
                    }
            
                }
                else {

                    $URLDns = 'No bound hostname'
                    $Bound = 'No bound hostname'

                }

                try {

                    [PSCustomObject]@{

                        Site           = $Site.Name
                        Computername   = $env:COMPUTERNAME
                        # Description      = $Found.NAME
                        IP             = $IP
                        IPs            = $IPDns
                        Url            = "https://$Bound"
                        URLDnsLB       = $URLLBDns
                        URLDnsInt      = $URLInternalDns
                        URLDnsExt      = $URLExternalDns
                        # State            = $Found.STATE
                        # Version          = $Found.VERSION
                        Bound          = $Bound
                        BoundIP        = $IP
                        Stack          = $Stack
                        Node           = $Node
                        SQLServer      = $SQLServerName
                        SQLServerIP    = $SQLServerIP
                        SQLDatabase    = $DB
                        SQLMaxPoolSize = $SQLMaxPool
                        SQLPacketSize  = $SQLPacketSize
                        SSLFriendly    = $Friendly
                        SSLStartDate   = $NotBefore
                        SSLExpires     = $NotAfter
                        SSLExpiresDays = $Days
                        SSLDNSNames    = $NameList
                        SSLThumbprint  = $Thumbprint
                        SSLSerial      = $Serial
                        SSLIssuer      = $Issuer
                        SSLSubject     = $Subject
                        Imache         = ($AllVirtDirs | Where-Object { $_.DirectoryName -eq 'IMAGE' }  ).DirectoryPath
                        ImacheValid    = ($AllVirtDirs | Where-Object { $_.DirectoryName -eq 'IMAGE' }  ).ConfigCorrect
                        Scan           = ($AllVirtDirs | Where-Object { $_.DirectoryName -eq 'SCAN' }  ).DirectoryPath
                        ScanValid      = ($AllVirtDirs | Where-Object { $_.DirectoryName -eq 'SCAN' }  ).ConfigCorrect
                        UploadCache    = ($AllVirtDirs | Where-Object { $_.DirectoryName -eq 'PATHHERE\Uploads' }  ).DirectoryPath
                        UploadValid    = ($AllVirtDirs | Where-Object { $_.DirectoryName -eq 'PATHHERE\Uploads' }  ).ConfigCorrect
                    }

                }
                catch {

                    Write-Verbose "error"
                    #$Error

                }

            }#Foreach Binding

            $Samples = ((Get-Counter -Counter $Counters -SampleInterval 5 -ErrorAction SilentlyContinue).counterSamples)

            $IISPerf = [PSCustomObject]@{

                Date                                    = (Get-Date -Format "MM-dd-yyyy HH:mm:ss")
                Computername                            = $env:COMPUTERNAME
                Site                                    = $Name
                'CPU'                                   = [Math]::Round(($Samples | Where-Object { $_.Path -like '*% Processor Time*' }).CookedValue, 0)
                'MemoryFree(Mb)'                        = [Math]::Round(($Samples | Where-Object { $_.Path -like '*Available Mbytes*' }).CookedValue, 0)
                'Connections'                           = ($Samples | Where-Object { $_.Path -like '*current connections*' }).CookedValue
                'Anon Users'                            = ($Samples | Where-Object { $_.Path -like '*Anonymous Users*' }).CookedValue
                'ReceivedKBps'                          = [Math]::Round(($Samples | Where-Object { $_.Path -like '*Bytes Received/sec*' }).CookedValue)
                'ReceivedMBps'                          = [Math]::Round(($Samples | Where-Object { $_.Path -like '*Bytes Received/sec*' }).CookedValue / 1MB, 2)
                'SentKBps'                              = [Math]::Round(($Samples | Where-Object { $_.Path -like '*Bytes Sent/sec*' }).CookedValue)
                'SentMBps'                              = [Math]::Round(($Samples | Where-Object { $_.Path -like '*Bytes Sent/sec*' }).CookedValue / 1MB, 2)
                'ASP.NET App Req/Sec'                   = [Math]::Round(($Samples | Where-Object { $_.Path -like '*\ASP.NET Applications(__total__)\Requests/Sec*' }).CookedValue, 0)
                'ASP.NET App Req in Q'                  = ($Samples | Where-Object { $_.Path -like '*\ASP.NET Applications(__total__)\Requests in Application Queue*' }).CookedValue
                'Errors Unhandled During Execution/Sec' = ($Samples | Where-Object { $_.Path -like '*Errors Unhandled During Execution/Sec*' }).CookedValue
                'Errors Total/Sec'                      = ($Samples | Where-Object { $_.Path -like '*Errors Total/Sec*' }).CookedValue
                '% 500 HTTP Response Sent'              = ($Samples | Where-Object { $_.Path -like '*500 HTTP Response Sent*' }).CookedValue
                '.NET CLR of Except/Sec'                = [Math]::Round((($Samples | Where-Object { $_.Path -like '*\.NET CLR Exceptions(*)\# of Exceps Thrown / sec*' }).CookedValue | Measure-Object -Sum).Sum)
                '.NET CLR Memory'                       = [Math]::Round(($Samples | Where-Object { $_.Path -like '*% time in gc' }).CookedValue, 0)
                'SQLPoolConns'                          = (($Samples | Where-Object { $_.Path -like '*NumberOfPooledConnections*' }).CookedValue | Measure-Object -Sum).Sum
                'Errors'                                = "None"

            }
        }#Foreach $Site

    }
    else {
    
        $Sites = [PSCustomObject]@{

            WebSite       = $($Site.Name)
            Computername  = $env:COMPUTERNAME
            DirectoryName = 'No Sites'
            DirectoryPath = 'No Sites'
            DirectoryType = 'No Sites'
            ConfigCorrect = 'No Sites'

        }

    }

    ############## Com+ Compnonent Services ########################
    $ComPlus = New-Object -com ("COMAdmin.COMAdminCatalog.1")
    $ComApps = $ComPlus.GetCollection("Applications")

    $ComApps.Populate()

    $SB_ImpersonationLevel = { param($Item) switch ($Item) { 1 { 'Anonymous' } 2 { 'Identify' } 3 { 'Impersonate' } 4 { 'Delegate' } } }
    $SB_AuthenticationLevel = { param($Item) switch ($Item) { 0 { 'Default' } 1 { 'None' } 2 { 'Connect' } 3 { 'Call' } 4 { 'Packet' } 5 { 'Integrity' } 6 { 'Privacy' } } }
    $SB_ImpersonationLevel = { param($Item) switch ($Item) { 1 { 'Anonymous' } 2 { 'Identify' } 3 { 'Impersonate' } 4 { 'Delegate' } } }
    $SB_AccessChecksLevel = { param($Item) switch ($Item) { 0 { 'Process' } 1 { 'Process and Component' } } }
    $SB_ActivationLevel = { param($Item) switch ($Item) { 0 { 'Library' } 1 { 'Server' } } }

    $ComApps = foreach ($Application in ($ComApps | Where-Object { $_.Name -match 'SOMETHING' })) { 
        $AppName = $Application.Name

        if ($FixComPlusApps -eq $True) {

            $AppName = $Application.Name
            $Identity = $Application.Value("Identity") = "NT AUTHORITY\NetworkService"
            $SaveChanges = $ComApps.SaveChanges()
            $ApplicationAccessChecksEnabled = $Application.Value("ApplicationAccessChecksEnabled") = 0
            $SaveChanges = $ComApps.SaveChanges()
            $AccessChecksLevel = $Application.Value("AccessChecksLevel") = 1
            $SaveChanges = $ComApps.SaveChanges()
            $Activation = $Application.Value("Activation") = 1
            $SaveChanges = $ComApps.SaveChanges()
            $Authentication = $Application.Value("Authentication") = 4
            $SaveChanges = $ComApps.SaveChanges()
            $ImpersonationLevel = $Application.Value("ImpersonationLevel") = 3
            $SaveChanges = $ComApps.SaveChanges()
        
            $Complus.ShutdownApplication($AppName)
            try { $Complus.StartApplication($AppName) }Catch {}
            $Complus.RefreshComponents()

        }
       
        $IdentityPass = $Application.Value("Identity") -notmatch "Interactive"
        $ApplicationAccessChecksEnabledPass = $ApplicationAccessChecksEnabled -eq $True
        $AccessChecksLevelPass = $Application.Value("AccessChecksLevel") -eq 1
        $ActivationPass = $Application.Value("Activation") -eq 1
        $AuthenticationPass = $Application.Value("Authentication") -eq 4
        $ImpersonationLevelPass = $Application.Value("ImpersonationLevel") -eq 3
        
        $Identity = $Application.Value("Identity")
        $ApplicationAccessChecksEnabled = $Application.Value("ApplicationAccessChecksEnabled")
        $AccessChecksLevel = $SB_AccessChecksLevel.Invoke( $Application.Value("AccessChecksLevel") )
        $Activation = $SB_ActivationLevel.Invoke( $Application.Value("Activation"))
        $Authentication = $SB_AuthenticationLevel.Invoke( $Application.Value("Authentication") )
        $ImpersonationLevel = $SB_ImpersonationLevel.Invoke( $Application.Value("ImpersonationLevel") )

        IF ($ComPlusSomethingNetAppsHealth -eq $True) {

            [PSCustomObject]@{
                Date                               = Get-Date -Format 'MM-dd-yyyy hh:mm:ss tt'
                Computername                       = $env:COMPUTERNAME
                AppName                            = $AppName
                IdentityPass                       = "$IdentityPass"
                ApplicationAccessChecksEnabledPass = "$ApplicationAccessChecksEnabledPass"
                AccessChecksLevelPass              = "$AccessChecksLevelPass"
                ActivationPass                     = "$ActivationPass"
                AuthenticationPass                 = "$AuthenticationPass"
                ImpersonationLevelPass             = "$ImpersonationLevelPass"
            }

        }
        else {
        
            [PSCustomObject]@{
                Date                           = Get-Date -Format 'MM-dd-yyyy hh:mm:ss tt'
                Computername                   = $env:COMPUTERNAME
                AppName                        = $AppName
                Identity                       = "$Identity"
                ApplicationAccessChecksEnabled = "$ApplicationAccessChecksEnabled"
                AccessChecksLevel              = "$AccessChecksLevel"
                Activation                     = "$Activation"
                Authentication                 = "$Authentication"
                ImpersonationLevel             = "$ImpersonationLevel"
            }
        
        
        }
     
    }

}#IF Web Server

########################################################################  Web Server End  ##########################################################################

########################################################################    SQL Server    ##########################################################################

if (Get-Service | Where-Object { $_.name -like '*sql*' }) {

    $IsSQL = $True

}

########################################################################  SQL Server End  ##########################################################################


#########################################################################################################################################################################
########################################################################  GETTING INVENTORY END  ########################################################################
#########################################################################################################################################################################

#########################################################################################################################################################################
########################################################################  CREATING REPORT START  ########################################################################
#########################################################################################################################################################################
$ToFile = [ordered]@{}

# System Overview
$SysInfo_Table = Create-gDatatableHtml -Data $SysInfo -Title 'System Overview' -IDName 'sysaccord'
$SysInfo_Accordion = New-HTMLAccordion -Table $SysInfo_Table -Tabletitle "System Overview - &nbsp<b>VM:</b>&nbsp $($IsVM) &nbsp|&nbsp<b>SQL:</b>&nbsp $($IsSQL) &nbsp|&nbsp <b>CPU%:</b>&nbsp $(([math]::Round($SysInfo.'CPU%',0))) &nbsp|&nbsp <b>FreeMem%:</b>&nbsp  $($SysInfo.'FreeMem%') &nbsp|&nbsp <b>Cores:</b>&nbsp  $($SysInfo.Cores) &nbsp|&nbsp <b>Mem:</b>&nbsp $($SysInfo.Memory) &nbsp|&nbsp <b>IP:</b> &nbsp $($SysInfo.IP) &nbsp|&nbsp <b>LastBoot:&nbsp</b> $($SysInfo.LastBoot.ToString())&nbsp |&nbsp <b>OS:</b>&nbsp $($SysInfo.OS)&nbsp |&nbsp <b>.Net:</b>&nbsp $($SysInfo.dotNET)" -Id 'sysaccord'

# Applications
$ToFile.Applications = $InstalledApplications
$InstalledApplications_Table = Create-gDatatableHtml -Data $InstalledApplications -Title 'Installed Applications' -IDName 'installedappsaccord'
$InstalledApplications_Accordion = New-HTMLAccordion -Table $InstalledApplications_Table -Tabletitle "Applications -&nbsp <b>Count:</b>&nbsp $($InstalledApplications.count)" -Id 'installedappsaccord'

# Memory
$ToFile.Memory = $Win32_PhysicalMemory
$PhysicalMemory_Table = Create-gDatatableHtml -Data $Win32_PhysicalMemory -Title 'Memory Information' -IDName 'memoryaccord'
$PhysicalMemory_Accordion = New-HTMLAccordion -Table $PhysicalMemory_Table -Tabletitle "Memory Total: $($SysInfo.Memory)&nbsp |&nbsp Installed Count: &nbsp$(@($Win32_PhysicalMemory).Count) " -Id 'memoryaccord'

# Drives
$ToFile.Drives = $Drives
$Drives_Table = Create-gDatatableHtml -Data $Drives -Title 'Drives'  -IDName 'drivesaccord' 
$Drives_Accordion = New-HTMLAccordion -Table $Drives_Table -Tabletitle "Drives: $($Drives.Count) | DrivesTotalGB: $(($Drives.SizeGB|Measure-Object -Sum).sum)" -Id 'drivesaccord'

# Processor
$ToFile.Processor = $win32_processor 
$Processor_Table = Create-gDatatableHtml -Data $win32_processor -Title 'CPU Information' -IDName 'cpuaccord'
$Processor_Accordion = New-HTMLAccordion -Table $Processor_Table -Tabletitle "Processors - Sockets: $($SysInfo.Sockets) &nbsp |  &nbsp Cores: $($SysInfo.Cores) &nbsp |  &nbsp MaxClockSpeed: $($win32_processor[0].MaxClockSpeed) &nbsp |&nbsp CPU: $($SysInfo.CPU)" -Id 'cpuaccord'

# NetworkAdapter
$ToFile.NetworkAdapter = $Win32_NetworkAdapterConfiguration 
$NetworkAdapterConfiguration_Table = Create-gDatatableHtml -Data $Win32_NetworkAdapterConfiguration -Title 'Network Adapter Configuration' -IDName 'netadaptconfigaccord'
$NetworkAdapterConfiguration_Accordion = New-HTMLAccordion -Table $NetworkAdapterConfiguration_Table -Tabletitle "Network Adapters: $(@($Win32_NetworkAdapterConfiguration).count)" -Id 'netadaptconfigaccord'

# Services
$ToFile.Services = $Services 
$Services_Table = Create-gDatatableHtml -Data $Services -Title 'Services Information' -IDName 'servicesaccord'
$Services_Accordion = New-HTMLAccordion -Table $Services_Table -Tabletitle "Services - &nbsp<b>Count</b>:&nbsp $($Services.Count)" -Id 'servicesaccord'

# SSLs
$ToFile.SSLs = $Ssls 
$Ssls_Table = Create-gDatatableHtml -Data $Ssls -Title 'SSL Certificates' -IDName 'sslsaccord'
$Ssls_Accord = New-HTMLAccordion -Table $Ssls_Table -Tabletitle "SSL Certificates &nbsp- &nbsp<b>Count</b>: $($Ssls.Count)" -Id 'sslsaccord'

If ($Ssls_Expired) {
    $Ssls_Expired_Table = Create-gDatatableHtml -Data $Ssls_Expired -Title 'SSL Certificates Expired' -IDName 'sslsexpiredaccord'
    $Ssls_Expired_Accord = New-HTMLAccordion -Table $Ssls_Expired_Table -Tabletitle "SSL Certificates Expired: $($Ssls_Expired.Count)" -Id 'sslsexpiredaccord'
}

# Company SSLs
if ($CompanySSLs) {

    $CompanySSLs_Table = Create-gDatatableHtml -Data $CompanySSLs-Title 'Company SSL Certificates' -IDName 'CompanySSLsaccord'
    $CompanySSLs_Accord = New-HTMLAccordion -Table $CompanySSLs_Table -Tabletitle "Company SSL Certificates: $($CompanySSLs.Count)" -Id 'CompanySSLsaccord'

}

# Windows Features
if ($OS -match "Server") {

    $ToFile.WindowsFeatures = $WindowsFeatures 
    $WindowsFeatures_Table = Create-gDatatableHtml -Data $WindowsFeatures -Title 'Windows Featuress' -IDName 'winfeataccord' 
    $WindowsFeatures_Accord = New-HTMLAccordion -Table $WindowsFeatures_Table -Tabletitle "Windows Features Installed Count: $($WindowsFeatures.Count)" -Id 'winfeataccord'

}

# Wsus History
if ($HistoryCount -gt 0) {

    $ToFile.WsusHistory = $WsusHistory 
    $WsusHistory_Table = Create-gDatatableHtml -Data $WsusHistory -Title 'Installed Updates' -IDName 'wsushistory' 
    $WsusHistory_Accord = New-HTMLAccordion -Table $WsusHistory_Table -Tabletitle "Installed Updates: $($WsusHistory.Count)" -Id 'wsushistory'

}

# Wsus Missing/Pending
if ($PendingMissingUpdates.Count -gt 1) {
	
    $ToFile.WsusPendingMissing = $PendingMissingUpdates 
    $PendingMissingUpdates_Table = Create-gDatatableHtml -Data $PendingMissingUpdates -Title 'WSUS Missing, or Pending, Updates' -IDName 'wsusmissing' 
    $PendingMissingUpdates_Accord = New-HTMLAccordion -Table $PendingMissingUpdates_Table -Tabletitle "WSUS Missing, or Pending, Updates: $($PendingMissingUpdates.Count)" -Id 'wsusmissing'

}

# Wsus Offline MS Scan
if ($GetWsusOfflineScan -eq $True) {
    
    $ToFile.WsusOfflineScan = $MissingUpdateOfflineSummary 
    $MissingUpdateOfflineSummary_Table = Create-gDatatableHtml -Data $MissingUpdateOfflineSummary -Title 'Offline Microsoft Scan for missing updates' -IDName 'wsusmissingoffline' 
    $MissingUpdateOfflineSummary_Accord = New-HTMLAccordion -Table $MissingUpdateOfflineSummary_Table -Tabletitle "Offline Microsoft Scan for missing updates: $($MissingOfflineUpdates.Count)" -Id 'wsusmissingoffline'

}

# Web Server
If (Get-Service w3svc -ErrorAction SilentlyContinue) {

    $ToFile.IISSites = $Sites 
    $Sites_Table = Create-gDatatableHtml -Data $Sites -Title "Website" -IDName 'websitesaccord'
    $Sites_Accord = New-HTMLAccordion -Table $Sites_Table -Tabletitle "Websites Count: $(@($Sites -replace 'www.'| Sort Bound -Unique).Count)" -Id 'websitesaccord'

    $ToFile.IISAppPools = $AppPools
    $AppPools_Table = Create-gDatatableHtml -Data $AppPools -Title 'IIS Appplication Pools' -IDName 'iispoolsaccord'
    $AppPools_Accord = New-HTMLAccordion -Table $AppPools_Table -Tabletitle "IIS Appplication Pools Count: $($AppPools.Count) &nbsp| &nbsp Running: &nbsp $(($AppPools|Where-Object {$_.state -eq 'Started'}).count)&nbsp |&nbsp Stopped:&nbsp $(($AppPools|Where-Object {$_.state -ne 'Started'}).count)" -Id 'iispoolsaccord'

    if ($LogFiles) {

        $ToFile.IISLogFiles = $LogFiles 
        $LogFiles_Table = Create-gDatatableHtml -Data $LogFiles -Title 'IIS Log Files' -IDName 'iislogfilesaccord' 
        $LogFiles_Accord = New-HTMLAccordion -Table $LogFiles_Table -Tabletitle 'IIS Log Files' -Id 'iislogfilesaccord'
    }

    if ($AllVirtDirs) {

        $ToFile.IISAllVirtDirs = $AllVirtDirs 
        $AllVirtDirs_Table = Create-gDatatableHtml -Data $AllVirtDirs -Title 'Virtual Directories' -IDName 'virtualdirsaccord' 
        $AllVirtDirs_Accord = New-HTMLAccordion -Table $AllVirtDirs_Table -Tabletitle 'IIS Virtual Directories' -Id 'virtualdirsaccord'
    }

    if ($IISPerf) {

        $ToFile.IISPerf = $IISPerf 
        $IISPerf_Table = Create-gDatatableHtml -Data $IISPerf -Title 'IIS Performance Counters'  -IDName 'iisperfaccord' 
        $IISPerf_Accord = New-HTMLAccordion -Table $IISPerf_Table -Tabletitle  "CPU: $($IISPerf.CPU)% | MemFreeMB: $($IISPerf.'MemoryFree(Mb)') | Connections: $($IISPerf.Connections)" -ID 'iisperfaccord'
    }
    if ($CurrentRequests) {

	
        $SomethingNet = @(($CurrentRequests | Where-Object { $_.apppool -match 'Something' -and $_.timeelapsed -match "\d+" } | Sort TimeElapsed -Descending | Select -First 10).TimeElapsed -join ',' | Where-Object { $_ } )
        $UserGuides = @(($CurrentRequests | Where-Object { $_.apppool -match 'UserGuides' -and $_.timeelapsed -match "\d+" } | Sort TimeElapsed -Descending | Select -First 10).TimeElapsed -join ',' | Where-Object { $_ }  )
        $Wcf = @(($CurrentRequests | Where-Object { $_.apppool -match 'Wcf' -and $_.timeelapsed -match "\d+" } | Sort TimeElapsed -Descending | Select -First 10).TimeElapsed -join ',' | Where-Object { $_ } )
        $Scan = @(($CurrentRequests | Where-Object { $_.apppool -match 'Scan' -and $_.timeelapsed -match "\d+" } | Sort TimeElapsed -Descending | Select -First 10).TimeElapsed -join ',' | Where-Object { $_ } )
        $CurrentRequests_TabTitle = "AppPool Requests: $($CurrentRequests.Count) | Top 10 Elapsed - SomethingNet($($Something.count)): $SomethingNet WCF($($Wcf.Count)): $Wcf Scan($($Scann.count)): $Scan UserGuides($($UserGuides.Count)): $UserGuid"    
        $CurrentRequests_Table = Create-gDatatableHtml -Data $CurrentRequests -Title 'AppPool Requests' -IDName 'requestsaccord' 
        $CurrentRequests_Accord = New-HTMLAccordion -Table $CurrentRequests_Table -Tabletitle $CurrentRequests_TabTitle -Id 'requestsaccord'
        $ToFile.IISCurrentRequests = $CurrentRequests 
   
    }

    if ($ComApps) {

        $ToFile.IISComApps = $ComApps
        $ComApps_Table = Create-gDatatableHtml -Data $ComApps -Title 'Component Services COM+ applications' -IDName 'complusaccord' 
        $ComApps_Accord = New-HTMLAccordion -Table $ComApps_Table -Tabletitle "Component Services COM+ $($ComApps.AppName -join ', ') applications" -Id 'complusaccord'

    }

}

########################################################################  HTML Creation   ########################################################################
$HTML = @()

$Html = @()
$Accordions = @()
$Body = @()
$Accordions += $SysInfo_Accordion
$Accordions += $Processor_Accordion 
$Accordions += $PhysicalMemory_Accordion
$Accordions += $Drives_Accordion
$Accordions += $InstalledApplications_Accordion
$Accordions += $Services_Accordion
$Accordions += $NetworkAdapterConfiguration_Accordion
$Accordions += $Ssls_Accord
$Accordions += $Ssls_Expired_Accord
$Accordions += $CompanySSLs_Accord

if ($OS -match "Server") {

    $Accordions += $WindowsFeatures_Accord
}
$Accordions += $WsusHistory_Accord

if ($PendingMissingUpdates.Count -gt 1) {

    $Accordions += $PendingMissingUpdates_Accord

}

if ($GetWsusOfflineScan -eq $True) {

    $Accordions += $MissingUpdateOfflineSummary_Accord
}

if ($IsWeb -eq $True) {

    $Accordions += $Sites_Accord 
    $Accordions += $AppPools_Accord
    $Accordions += $IISPerf_Accord
    $Accordions += $CurrentRequests_Accord
    $Accordions += $LogFiles_Accord 
    $Accordions += $AllVirtDirs_Accord

    $Accordions += $ComApps_Accord
}

$Head = @"
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <title>$env:COMPUTERNAME Reports</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/1.11.3/css/dataTables.bootstrap5.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/responsive/2.2.9/css/responsive.bootstrap5.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/buttons/2.0.1/css/buttons.bootstrap5.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/colreorder/1.5.5/css/colReorder.bootstrap5.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/searchbuilder/1.3.0/css/searchBuilder.bootstrap5.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/datetime/1.1.1/css/dataTables.dateTime.min.css" rel="stylesheet">
    <style>
        div.col {
            width: 80%
        }

        #body-row {
            margin-left: 0;
            margin-right: 0;
        }

        #output tbody tr.selected {
            background-color: #0275d8;
        }
    </style>
</head>
"@

$Body = @"
$Head
<body>
    <div class="container-fluid">
        <div class="jumbotron text-center">
            <h1 class="h1-reponsive mb-3 blue-text"><strong>$env:computername Report $(Get-Date -format 'MM-dd-yyhh:mm:ss tt' )</strong></h1>

        </div>
        <div id="loading" style="display:block;">
            <h1 class="h1-reponsive mb-3 blue-text"><strong>LOADING...</strong></h1>
        </div>
        <div class="row">
            <div class="col-sm">
                <div class="accordion" id="accordion" style="display:none;">
                    $Accordions
                </div>
            </div>
        </div>
    </div>
    <script src="https://code.jquery.com/jquery-3.6.0.js"></script>
    <script src="https://cdn.datatables.net/1.10.25/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.10.25/js/dataTables.bootstrap5.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.1/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.datatables.net/buttons/2.0.1/js/dataTables.buttons.min.js"></script>
    <script src="https://cdn.datatables.net/buttons/2.0.1/js/buttons.bootstrap5.min.js"></script>
    <script src="https://cdn.datatables.net/fixedheader/3.1.9/js/dataTables.fixedHeader.min.js"></script>
    <script src="https://cdn.datatables.net/responsive/2.2.8/js/dataTables.responsive.min.js"></script>
    <script src="https://cdn.datatables.net/responsive/2.2.8/js/responsive.bootstrap.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.1.3/jszip.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.53/pdfmake.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.53/vfs_fonts.js"></script>
    <script src="https://cdn.datatables.net/buttons/2.0.1/js/buttons.html5.min.js"></script>
    <script src="https://cdn.datatables.net/buttons/2.0.1/js/buttons.print.min.js"></script>
    <script src="https://cdn.datatables.net/buttons/2.0.1/js/buttons.colVis.min.js"></script>
    <script src="https://cdn.datatables.net/colreorder/1.5.5/js/dataTables.colReorder.min.js"></script>
    <script src="https://cdn.datatables.net/searchbuilder/1.3.0/js/dataTables.searchBuilder.min.js"></script>
    <script src="https://cdn.datatables.net/searchbuilder/1.3.0/js/searchBuilder.bootstrap5.min.js"></script>
    <script src="https://cdn.datatables.net/datetime/1.1.1/js/dataTables.dateTime.min.js"></script>
    <script>
        `$(document).ready(function () {

            `$('#loading').css('display', 'none');

            `$("#accordion").css('display', 'block');

            `$(".collapse").on('show.bs.collapse', function (e) {

                let tab = "#" + this.id + "tb"

                `$(tab).DataTable({
                    destroy: true,
                    scrollx: false,
                    "deferRender": true,
                    responsive: true,
                    paging: false,
                    searching: true,
                    retrieve: true,
                    search: {
                        "smart": true
                    },
                    colReorder: true,
                    dom: 'Bfrtip',
                    buttons: [
                        'copy', 'csv', 'excel', 'pdf', 'print'
                    ],
                    colReorder: true,

                });

                setTimeout(function () {

                    `$.each($.fn.dataTable.tables(true), function () {
                        `$(this).DataTable().columns.adjust().draw();
                    });
                }, 5);

            });

        });
    </script>
</body>

</html>
"@
#########################################################################################################################################################################
########################################################################  CREATING REPORT END   #########################################################################
#########################################################################################################################################################################

############################################# Create Report File and History #######################################
$Body | Set-Content "C:\Temp\$env:COMPUTERNAME.html" -Force
($ToFile | ConvertTo-Json -Compress) | Set-Content "C:\SE\Inventory\History\$(Get-Date -Format 'MM-dd-yyyy_HH-mm')_$($env:COMPUTERNAME).json"
