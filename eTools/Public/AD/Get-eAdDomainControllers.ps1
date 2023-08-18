Function Get-eADDomainControllers {

    [CmdletBinding()]
    
    param()
    
    $CurrentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $CurrentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
    $DomainControllers = (([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).DomainControllers)
    
    $Output = Foreach ($DomainController in $DomainControllers) {
    
        $PDCRoleOwner = $RidRoleOwner = $InfrastructureMaster = $SchemaRoleOwner = $NamingRoleOwner = $False
    
        switch ($DomainController.Name) {
    
            { $CurrentDomain.PDCRoleOwner -match $_ } { $PDCRoleOwner = $True }
            { $CurrentDomain.RidRoleOwner -match $_ } { $RidRoleOwner = $True }
            { $CurrentDomain.InfrastructureMaster -match $_ } { $InfrastructureMaster = $True }
            { $CurrentForest.SchemaRoleOwner.Name -match $_ } { $SchemaRoleOwner = $True }
            { $CurrentForest.NamingRoleOwner.Name -match $_ } { $NamingRoleOwner = $True }
    
        }
    
        [PSCustomObject]@{
    
            Computername         = $DomainController.Name -replace ".$($DomainController.Forest)"
            IP                   = $DomainController.IPAddress
            OS                   = $DomainController.OSVersion
            Forest               = $DomainController.Forest
            Domain               = $DomainController.Domain
            Site                 = $DomainController.SiteName
            IsGC                 = $DomainController.IsGlobalCatalog()
            PDCRoleOwner         = $PDCRoleOwner
            RidRoleOwner         = $RidRoleOwner
            InfrastructureMaster = $InfrastructureMaster
            SchemaRoleOwner      = $SchemaRoleOwner
            NamingRoleOwner      = $NamingRoleOwner
    
        }
    
    }
    
    Write-Output $Output
    
}