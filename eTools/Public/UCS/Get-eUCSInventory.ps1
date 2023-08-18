<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Gets current UCS inventory and whether the CPU model is supported in VMware vSphere 8.
Note: The Credential username must be in this format: ucs-$env:userdnsdomain\USERNAME
#>

Function Get-eUCSInventory {

    [CmdletBinding()]
    
    param(

        [string[]]$UCSName = @('ucs1', 'ucs2'),

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty

    )

    $Error.Clear()

    try {
    
        Test-ePowershellGetNuget

        if (!(Get-Module -Name Cisco.IMC, Cisco.UCS.Common, Cisco.UCSCentral, Cisco.UCSManager -ListAvailable -ErrorAction SilentlyContinue)) {

            try {

                Install-Module -Name Cisco.IMC, Cisco.UCS.Common, Cisco.UCSCentral, Cisco.UCSManager -Force -AllowClobber -SkipPublisherCheck -Confirm:$false -ErrorAction Stop

            }
            catch {

                $null = Install-Module -Name Cisco.IMC, Cisco.UCS.Common, Cisco.UCSCentral, Cisco.UCSManager -Force -AllowClobber -SkipPublisherCheck -Confirm:$false -AcceptLicense  -ErrorAction Stop

            }

        }

        $null = Import-Module -Name Cisco.IMC, Cisco.UCS.Common, Cisco.UCSCentral, Cisco.UCSManager -Force
		
        $null = Set-UcsPowerToolConfiguration -InvalidCertificateAction Ignore -SupportMultipleDefaultUcs $true -Force 

        $OutPut = Foreach ($Name in $UCSName) {

            $Name = $Name.ToUpper()
			
            $AllItems = @()

            Write-Host "`nConnecting to UCS: $Name" -ForegroundColor Yellow
            
            if ($Credential -eq [System.Management.Automation.PSCredential]::Empty) {

                $Credential = Get-Credential

            }
            
            If ($Credential.GetNetworkCredential().Domain -ne "ucs-$env:userdnsdomain") {

                $Credential = New-Object System.Management.Automation.PSCredential("ucs-$env:userdnsdomain\$($Credential.GetNetworkCredential().UserName)", (ConvertTo-SecureString $($Credential.GetNetworkCredential().Password) -AsPlainText -Force))

            }

            $UCS = (Connect-Ucs -Name $Name -Credential $Credential -ErrorAction Stop )

            Write-Host "Connected to UCS: $Name" -ForegroundColor Green

            Write-Host "Getting $Name servers, processors, storage controllers, and firmwares" -ForegroundColor Yellow
        
            $UcsServers = Get-UcsServer -Ucs $UCS
            $UcsProcessorUnits = Get-UcsProcessorUnit -UCS $UCS
            $UcsStorageController = Get-UcsStorageController -UCS $UCS
            $UcsFirmwareRunnings = Get-UcsFirmwareRunning -UCS $UCS

            Write-Host "Finished getting $Name servers, processors, storage controllers, and firmwares" -ForegroundColor Green

            Write-Host "Getting $Name Blades and Racks" -ForegroundColor Yellow

            $Blades = @(Get-UcsBlade -UCS $UCS) 

            $B = 0
            $BCT = $Blades.count

            Foreach ($Blade in  $Blades) {

                $B++
                Write-Verbose "Blade $B out of $BCT"

                $AllItems += $Blade
    
            }
    
            $Racks = @(Get-UcsRackUnit -Ucs $UCS)
            $R = 0
            $RCT = $Blades.count

            Foreach ($Rack in $Racks) {
    
                $R++
                Write-Verbose "Blade $R out of $RCT"

                $AllItems += $Rack
    
            }

            Write-Host "Finished getting $Name Blades and Racks`n" -ForegroundColor Green
			
            $i = 0
            $ICT = $AllItems.count
			
            Write-Host "Processing $Name $ICT total items" -ForegroundColor Yellow

            Foreach ($AllItem in $AllItems) {
			
                $i++
			
			
                $AssignedToDn = "$($AllItem.AssignedToDn -replace 'org-root/ls-')"
			
                Write-Host "`tProcessing $Name`: $AssignedToDn $i of $ICT items" -ForegroundColor Green
			
                $CPUDN = "$($AllItem.Dn)/board/cpu-1"
    
                $CPU = $UcsProcessorUnits | Where-Object { $_.dn -eq $CPUDN }
                $Adapters = $UcsServers | Where-Object { $_.dn -eq $AllItems[0].dn } | Get-UcsAdaptorUnit
                $Firmware = ($UcsFirmwareRunnings | Where-Object { $_.dn -match $AllItems[0].dn -and $_.Type -eq "blade-controller" -and $_.Deployment -eq "system" }).Version
                $CpuModel = $CPU.Model
                $CpuModelNumber = $CpuModel -replace "Intel(R) Xeon(R) CPU"
                $CpuSpeed = $CPU.Speed
                $ServiceProfile = Get-UcsServiceProfile -PnDn $AllItem.Dn -Ucs $UCS
                $StorageControllers = "$(($UcsStorageController | Where-Object {$_.dn -match $AllItem.Dn}).Model -join '; ')"
    
                switch ($CpuModel) {
    
                    { $_ -like 'Intel(R) Xeon(R) CPU E5-2690 v3*' } { $Codename = 'Haswell'; $ESXiHCL = "$False" }
                    { $_ -like 'Intel(R) Xeon(R) CPU E5-2697 v4*' } { $Codename = 'Broadwell'; $ESXiHCL = "$False" }
                    { $_ -like 'Intel(R) Xeon(R) CPU E5-4627 v4*' } { $Codename = 'Broadwell'; $ESXiHCL = "$False" }
                    { $_ -like 'Intel(R) Xeon(R) Gold 5115 CPU*' } { $Codename = 'Skylake'; $ESXiHCL = "$True" }
                    { $_ -like 'Intel(R) Xeon(R) Gold 6148 CPU*' } { $Codename = 'Skylake'; $ESXiHCL = "$True" }
                    { $_ -like 'Intel(R) Xeon(R) Platinum 8168*' } { $Codename = 'Skylake'; $ESXiHCL = "$True" }
                    { $_ -like 'Intel(R) Xeon(R) Platinum 8280*' } { $Codename = 'Cascade'; $ESXiHCL = "$True" }
                    { $_ -like 'Intel(R) Xeon(R) Gold 6258R*' } { $Codename = 'Cascade'; $ESXiHCL = "$True" }
                    default { $Codename = $_; $ESXiHCL = "UNKNOWN" }
    
                }
    
                [PSCustomObject]@{
                    Date               = "$(Get-Date -Format 'MM-dd-yy HH:mm:ss')"
                    Name               = "$AssignedToDn"
                    UCSName            = $UCS.name
                    UCSVer             = "$($UCS.Version)"
                    UCSVirtIP          = $UCS.VirtualIpv4Address
                    DN                 = $AllItem.DN
                    RN                 = $AllItem.RN
                    Model              = $AllItem.Model
                    MfgDate            = (Get-Date $AllItem.MfgTime -Format 'MM-dd-yyyy')
                    CPU                = $CpuModel
                    CPUSpeed           = [double]$CpuSpeed
                    CPUCodeName        = $Codename
                    ESXiHCL            = $ESXiHCL
                    NumofCores         = $AllItem.NumofCores
                    NumOfCoresEnabled  = $AllItem.NumOfCoresEnabled
                    NumOfCPUS          = $AllItem.NumOfCPUS
                    NumOfThreads       = $AllItem.NumOfThreads
                    AvailableMemory    = $AllItem.AvailableMemory
                    MemorySpeed        = $AllItem.MemorySpeed
                    Serial             = $AllItem.Serial
                    Association        = $AllItem.Association
                    AdminState         = $AllItem.AdminState
                    Availability       = $AllItem.Availability
                    Discovery          = $AllItem.Discovery
                    OperState          = $AllItem.OperState
                    Operability        = $AllItem.Operability
                    ConnPath           = $AllItem.ConnPath -join '; '
                    ConnStatus         = $AllItem.ConnStatus -join '; '
                    ServiceProfile     = "$($ServiceProfile.Name | Sort -Unique)"
                    BootPolicy         = "$($ServiceProfile.BootPolicyName | Sort -Unique)"
                    BiosProfile        = "$($ServiceProfile.BiosProfileName | Sort -Unique)"
                    HostFWPolicy       = "$($ServiceProfile.HostFwPolicyName | Sort -Unique)"
                    DiskPolicy         = "$($ServiceProfile.LocalDiskPolicyName | Sort -Unique)"
                    StorageControllers = $StorageControllers
                    ChassisId          = $AllItem.ChassisId
                    ServerId           = $AllItem.ServerId
    
                }
    
            }
			
            Write-Host "Finished Processing $Name`: $i of $ICT items" -ForegroundColor Green
    
        }
		
        Write-Host "`n`nFinished Processing $($UCSName -join ', ')" -ForegroundColor Green
		
    }
    catch {
    
        Write-Host "Error Occurred $($Error)"

        $OUTPUT = [PSCustomObject]@{

            Date               = "$(Get-Date -Format 'MM-dd-yy HH:mm:ss')"
            Name               = 'ERROR'
            UCSName            = $Name
            UCSVer             = ($Error)
            UCSVirtIP          = 'ERROR'
            DN                 = 'ERROR'
            RN                 = 'ERROR'
            Model              = 'ERROR'
            MfgDate            = 'ERROR'
            CPU                = 'ERROR'
            CPUSpeed           = 'ERROR'
            CPUCodeName        = 'ERROR'
            ESXiHCL            = 'ERROR'
            NumofCores         = 'ERROR'
            NumOfCoresEnabled  = 'ERROR'
            NumOfCPUS          = 'ERROR'
            NumOfThreads       = 'ERROR'
            AvailableMemory    = 'ERROR'
            MemorySpeed        = 'ERROR'
            Serial             = 'ERROR'
            Association        = 'ERROR'
            AdminState         = 'ERROR'
            Availability       = 'ERROR'
            Discovery          = 'ERROR'
            OperState          = 'ERROR'
            Operability        = 'ERROR'
            ConnPath           = 'ERROR'
            ConnStatus         = 'ERROR'
            ServiceProfile     = 'ERROR'
            BootPolicy         = 'ERROR'
            BiosProfile        = 'ERROR'
            HostFWPolicy       = 'ERROR'
            DiskPolicy         = 'ERROR'
            StorageControllers = 'ERROR'
            ChassisId          = 'ERROR'
            ServerId           = 'ERROR'
        
        }

    }
    
    Write-Output $OutPut

}