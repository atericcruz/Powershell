Function New-eAzureKeyVaultSecret {

    [CmdletBinding()]
    
    param(
    
        [string]$Domain = $env:UserDnsDomain,
    
        [string]$ResourceGroupName = "ResourceGroupName",
    
        [string]$KeyVaultName = "KeyVaultNAME",
    
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ "$_" -match "^[a-zA-Z0-9-]+$" })] 
        [string]$SecretName,
    
        [Parameter(ParameterSetName = 'PasswordProvided')]
        [string]$Password,

        [Parameter(ParameterSetName = 'GeneratePassword')]
        [switch]$GeneratePassword,
        [int]$PasswordLength = 12

    )
    
    $ModulePaths = $env:PSModulePath -split [System.IO.Path]::PathSeparator
    
    Test-eAzureModule
    
    $Error.Clear()
    
    try {
    
        Write-Host "Connecting to Azure" -ForegroundColor Yellow
        
        $AzAccount = Connect-AzAccount
        
        Write-Host "Connected to Azure" -ForegroundColor Green

        if ((!$Password) -or $GeneratePassword) {

            Write-Host "Generating random password with a length of $PasswordLength" -ForegroundColor Yellow
        
            $Password = New-eRandomPassword -Length $PasswordLength
        
            Write-Host "Generated random password with a length of $PasswordLength" -ForegroundColor Green

        }
        
        $PasswordSecureString = ConvertTo-SecureString -String $Password -AsPlainText -Force
        
        Write-Host "Creating secret $SecretName in Vault $KeyVaultName for Domain $Domain" -ForegroundColor Yellow

        $CreatedSecret = Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -SecretValue $PasswordSecureString -ContentType $Domain

        Write-Host "Created secret $SecretName in Vault $KeyVaultName for Domain $Domain" -ForegroundColor Green
    
        Write-Output $CreatedSecret
    
    }
    catch {
    
        Write-Output $Error
    
    }
    
}