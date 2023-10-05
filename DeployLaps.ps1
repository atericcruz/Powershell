#Creates and deploys LAPS
<#
*Must be member of EnterpriseAdmins and SchemaAdmins temporarily in order to extend the AD schema
Prompts with a pop-up gridview of all OUs. Select the parent OU where LAPS should be deployed to
Checks that "C:\Windows\SYSVOL\sysvol\$env:USERDNSDOMAIN\Policies\PolicyDefinitions\en-US" exists for gpo store
    If not creates PolicyDefinistions and PolicyDefinitions\en-US folders
Checks "C:\Windows\SYSVOL\sysvol\$env:USERDNSDOMAIN\Policies\PolicyDefinitions" default GPO admx and adml files exists
    If no it copies the default set of GPOs from C:\Windows\PolicyDefinitions to C:\Windows\SYSVOL\sysvol\$env:USERDNSDOMAIN\Policies\PolicyDefinitions
Downloads the LAPS x64 msi from Microsoft
Copies the LAPS msi to "\\$env:USERDNSDOMAIN\NETLOGON" 
Installs the LAPS tool and GPO admx files quietly and without reboot
Copies the LAPS GPO admx files to the gpo store
Creates a security group named LAPSAdmins which grants permissions to read the current administrator password from either ADUC or the LAPS GUI tool installed in step 6
Sets computer permissions to update their own respective passwords to the OU selected in step 1
Recursively sets LAPSAdmins read password permissions to the OU selected in step 1 and all of its sub OUs 
Creates a new GPO named LAPS
Sets all the settings for the LAPS GPO 
Finally it links and enables the GPO to the OU selected in step 1
With great power...
I said good day - Fez 70s show
#>
$OU = "$((Get-ADOrganizationalUnit -Filter * | Out-GridView -PassThru -Title 'Please select the parent OU to apply LAPS to').DistinguishedName)"

$Copy_LAPS_MSI_To_Path = "\\$env:USERDNSDOMAIN\NETLOGON"
$PolicyDefinitions = "C:\Windows\SYSVOL\sysvol\$env:USERDNSDOMAIN\Policies\PolicyDefinitions\en-US"

$DL_LAPS_MSI = 'C:\Temp\LAPS'
$LAPS_MSI_Path = "$DL_LAPS_MSI\LAPS.msi"
$LAPS_URI = 'https://download.microsoft.com/download/C/7/A/C7AAD914-A8A6-4904-88A1-29E657445D03/LAPS.x64.msi'

if ((Test-Path $PolicyDefinitions -EA 0) -eq $False) {

    $null = New-Item -Path $PolicyDefinitions -ItemType Directory -Force -EA 0

}

$null = New-Item -Path $DL_LAPS_MSI -ItemType Directory -Force -EA 0
$iwr = Invoke-WebRequest $LAPS_URI -OutFile $LAPS_MSI_Path
$copyto = Copy-Item $LAPS_MSI_Path $Copy_LAPS_MSI_To_Path -Force -Recurse

($install_laps_mgmt_tools = Start-Process msiexec -ArgumentList "/i $LAPS_MSI_Path ADDLOCAL=Management.UI,Management.PS,Management.ADMX /quiet /norestart" -Wait -NoNewWindow -PassThru)

IF ((Get-ChildItem C:\Windows\PolicyDefinitions -Recurse -Filter "*.admx" -EA 0).count -lt 10) {

    $null = Copy-Item -Path C:\Windows\PolicyDefinitions -Destination "C:\Windows\SYSVOL\sysvol\$env:USERDNSDOMAIN\Policies\PolicyDefinitions" -Recurse -Force -EA 0

}

Copy-Item "C:\Windows\PolicyDefinitions\en-US\AdmPwd.adml" "C:\Windows\SYSVOL\sysvol\$env:USERDNSDOMAIN\Policies\PolicyDefinitions\en-US" -Force
Copy-Item "C:\Windows\PolicyDefinitions\AdmPwd.admx" "C:\Windows\SYSVOL\sysvol\$env:USERDNSDOMAIN\Policies\PolicyDefinitions" -Force

Import-Module AdmPwd.PS
Update-AdmPwdADSchema
New-ADGroup -DisplayName 'LAPSAdmins' -GroupCategory Security -GroupScope Global -Name 'LAPSAdmins' -Confirm:$false
Set-AdmPwdComputerSelfPermission -OrgUnit $OU
Find-AdmPwdExtendedRights -identity:$OU | % { Set-AdmPwdReadPasswordPermission -Identity $_.ObjectDN  -AllowedPrincipals "LAPSAdmins" }

$GPO_LAPS = New-GPO -Name LAPS 
Set-GPRegistryValue -Name $GPO_LAPS.DisplayName -key "HKLM\SOFTWARE\Policies\Microsoft Services\AdmPwd" -ValueName "PwdExpirationProtectionEnabled" -Type DWord -Value 1
Set-GPRegistryValue -Name $GPO_LAPS.DisplayName -key "HKLM\SOFTWARE\Policies\Microsoft Services\AdmPwd" -ValueName "AdmPwdEnabled" -Type DWord -Value 00000001
Set-GPRegistryValue -Name $GPO_LAPS.DisplayName -key "HKLM\SOFTWARE\Policies\Microsoft Services\AdmPwd" -ValueName "PasswordComplexity" -Type DWord -Value 00000004
Set-GPRegistryValue -Name $GPO_LAPS.DisplayName -Key "HKLM\SOFTWARE\Policies\Microsoft Services\AdmPwd" -ValueName "PasswordLength" -Type DWord -Value 15
Set-GPRegistryValue -Name $GPO_LAPS.DisplayName -key "HKLM\SOFTWARE\Policies\Microsoft Services\AdmPwd" -ValueName "PasswordAgeDays" -Type DWord -Value 30
New-GPLink -Guid $GPO_LAPS.Id -Target $OU -LinkEnabled Yes
