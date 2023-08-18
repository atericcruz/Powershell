Function Remove-eAzureKeyVaultSecret {

    [CmdletBinding()]
    
    param(
    
        [string]$Domain = $env:UserDnsDomain,
    
        [string]$ResourceGroupName = "ResourceGroupName",
    
        [string]$KeyVaultName = "KeyVaultNAME",
    
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ "$_" -match "^[a-zA-Z0-9-]+$" })] 
        [string]$SecretName

    )
    
    $ModulePaths = $env:PSModulePath -split [System.IO.Path]::PathSeparator
    
    Test-eAzureModule
    
    $Error.Clear()
    
    try {
    
        Write-Host "Connecting to Azure" -ForegroundColor Yellow
        
        $AzAccount = Connect-AzAccount
        
        Write-Host "Connected to Azure" -ForegroundColor Green

        Write-Host "Deleting secret $SecretName from Vault $KeyVaultName for Domain $Domain" -ForegroundColor Yellow

        $DeletedSecret = Remove-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -Force

        Write-Host "Deleted secret $SecretName in Vault $KeyVaultName for Domain $Domain" -ForegroundColor Green
    
        Write-Output $DeletedSecret
    
    }
    catch {
    
        Write-Output $Error
    
    }
    
}