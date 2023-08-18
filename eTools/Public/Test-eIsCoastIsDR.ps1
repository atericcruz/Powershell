<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Determine if the current host is East or West coast and whether DR or Production
#>
Function Test-eIsCoastIsDR {

    [CmdletBinding()]
    
    param(
        
        $Computername = $env:Computername

    )
    
    $DomainDN = ([adsi]'').distinguishedName
    $Searcher = [adsisearcher]"LDAP://$DomainDN"
    $Searcher.Filter = "(&(objectCategory=computer)(name=$Computername))"

    $Properties = 'accountexpires',
    'cn',
    'description',
    'displayname',
    'distinguishedname',
    'dnshostname',
    'guid',
    'instancetype',
    'iscriticalsystemobject',
    'lastlogontimestamp',
    'memberof',
    'name',
    'operatingsystem',
    'operatingsystemversion',
    'path',
    'pwdlastset',
    'samaccountname',
    'samaccounttype',
    'serviceprincipalname',
    'whencreated',
    'whenchanged'
		
    foreach ($Propertie in $Properties) {

        $null = $Searcher.PropertiesToLoad.Add($Propertie)

    }

    $FindOne = $Searcher.FindOne()
    
    $Prod = $False
    $DR = $False

    switch ($FindOne.Properties.distinguishedname) {

        { "$_" -match 'OU=DR' } {

            $DR = $True
            $Prod = $False

        }

        { ("$_" -match 'OU=East') } {
            
            $East = $True
            $Location = 'EastCoast'
            $West = $False


        }

        { ("$_" -match 'OU=West') } {
            
            $West = $True
            $Location = 'WestCoast'
            $East = $False

        }

    }# Switch

    $Output = [PSCustomObject]@{

        Date         = "$(Get-Date -Format 'MM-dd-yy HH:mm:ss')"
        Computername = $Computername
        Location     = $Location
        EastCoast    = $East
        WestCoast    = $West
        Prod         = $Prod
        DR           = $DR    

    }

    Write-Output $Output
    
}#