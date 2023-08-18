Function Get-eAzureKeyVaultSecret {

    [CmdletBinding()]
    
    param(
    
        [string]$Domain = $env:UserDnsDomain,
        
        [string]$KeyVaultName = "KeyVaultNAME",
                    
        [string[]]$SecretName
    
    )
 
    Test-eAzureModule -ErrorAction Stop   

    $AzAccount = Connect-AzAccount
     
    if (!$SecretName) {
 
        $AzKeyVaultSecrets = Get-AzKeyVaultSecret -VaultName KeyVaultNAME

        $SecretName = @($AzKeyVaultSecrets | Out-GridView -PassThru -Title 'Please select the secret(s)').Name
 
    }
    $i = 0

    $Secrets = Foreach ($Name in $SecretName) {

        $i++

        Write-Host "$i of $($SecretName.Count)" 
        
        $AzKeyVaultSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $Name

        [PSCustomObject]@{

            SecretName  = $AzKeyVaultSecret.Name
            ServiceName = ($AzKeyVaultSecret.Name)
            Domain      = $AzKeyVaultSecret.ContentType
            Password    = "$([System.Net.NetworkCredential]::new('',$AzKeyVaultSecret.SecretValue).Password)"
            Vault       = $KeyVaultName
            Created     = $AzKeyVaultSecret.Created
            Updated     = $AzKeyVaultSecret.Updated
            Expires     = $AzKeyVaultSecret.Expires

        }

    }

    Write-Output $Secrets

}