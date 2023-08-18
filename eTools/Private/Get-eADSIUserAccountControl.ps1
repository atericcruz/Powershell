<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Convert the ADSI User Account Control Value

#>
Function Get-eADSIUserAccountControl {

    param(

        [int]$UserAccountControl
        
    )

    $UACPropertyFlags = @(
        "SCRIPT",
        "ACCOUNTDISABLE",
        "RESERVED",
        "HOMEDIR_REQUIRED",
        "LOCKOUT",
        "PASSWD_NOTREQD",
        "PASSWD_CANT_CHANGE",
        "ENCRYPTED_TEXT_PWD_ALLOWED",
        "TEMP_DUPLICATE_ACCOUNT",
        "NORMAL_ACCOUNT",
        "RESERVED",
        "INTERDOMAIN_TRUST_ACCOUNT",
        "WORKSTATION_TRUST_ACCOUNT",
        "SERVER_TRUST_ACCOUNT",
        "RESERVED",
        "RESERVED",
        "DONT_EXPIRE_PASSWORD",
        "MNS_LOGON_ACCOUNT",
        "SMARTCARD_REQUIRED",
        "TRUSTED_FOR_DELEGATION",
        "NOT_DELEGATED",
        "USE_DES_KEY_ONLY",
        "DONT_REQ_PREAUTH",
        "PASSWORD_EXPIRED",
        "TRUSTED_TO_AUTH_FOR_DELEGATION",
        "RESERVED",
        "PARTIAL_SECRETS_ACCOUNT"
        "RESERVED"
        "RESERVED"
        "RESERVED"
        "RESERVED"
        "RESERVED"
    )
    <#
{$_ -eq 2}{"ACCOUNTDISABLE"}
{$_ -eq 8}{"HOMEDIR_REQUIRED"}
{$_ -eq 16}{"LOCKOUT"}
{$_ -eq 32}{"PASSWD_NOTREQD"}
{$_ -eq 64}{"PASSWD_CANT_CHANGE"}
{$_ -eq 128}{"ENCRYPTED_TEXT_PWD_ALLOWED"}
{$_ -eq 256}{"TEMP_DUPLICATE_ACCOUNT"}
{$_ -eq 512}{"NORMAL_ACCOUNT"}
{$_ -eq 2048}{"INTERDOMAIN_TRUST_ACCOUNT"}
{$_ -eq 4096}{"WORKSTATION_TRUST_ACCOUNT"}
{$_ -eq 8192}{"SERVER_TRUST_ACCOUNT"}
{$_ -eq 65536}{"DONT_EXPIRE_PASSWORD"}
{$_ -eq 131072}{"MNS_LOGON_ACCOUNT"}
{$_ -eq 262144}{"SMARTCARD_REQUIRED"}
{$_ -eq 524288}{"TRUSTED_FOR_DELEGATION"}
{$_ -eq 1048576}{"NOT_DELEGATED"}
{$_ -eq 2097152}{"USE_DES_KEY_ONLY"}
{$_ -eq 4194304}{"DONT_REQ_PREAUTH"}
{$_ -eq 8388608}{"PASSWORD_EXPIRED"}
{$_ -eq 16777216}{"TRUSTED_TO_AUTH_FOR_DELEGATION"}
{$_ -eq 67108864}{"PARTIAL_SECRETS_ACCOUNT"}
#>
    $Output = (0..($UACPropertyFlags.Length) | Where-Object { $UserAccountControl[0] -bAnd [math]::Pow(2, $_) } | Foreach-Object {

            $UACPropertyFlags[$_]

        }

    ) -join " | "

    Write-Output $Output

}