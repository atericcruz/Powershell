Function Remove-eIisDefaultSite {

    [CmdletBinding()]

    param()

    Process {

        Remove-Module WebAdministration -Force -ErrorAction SilentlyContinue
        Import-Module WebAdministration -Force

        $DefaultWebSite = Get-WebSite -Name "Default Web Site" -ErrorAction SilentlyContinue

        If ($DefaultWebSite) {

            Write-Host "$(gDate) - Found Default Web Site" -ForegroundColor Gray

            Write-Host "$(gDate) - Deleting Default Web Site" -ForegroundColor Yellow

            $DefaultWebSite | Remove-WebSite -Confirm:$false

            Write-Host "$(gDate) - Deleted Default Web Site" -ForegroundColor Green

        }

        $DefaultAppPool = Get-IISAppPool -Name 'DefaultAppPool' -ErrorAction SilentlyContinue

        If ($DefaultAppPool -and $RemoveDefaults) {

            Write-Host "$(gDate) - Found DefaultAppPool" -ForegroundColor Gray

            Write-Host "$(gDate) -      Deleting DefaultAppPool" -ForegroundColor Yellow

            Remove-WebAppPool -Name "DefaultAppPool" -Confirm:$false 

            Write-Host "$(gDate) -      Deleted DefaultAppPool" -ForegroundColor Green

        }

        Write-Host "$(gDate) - Finished" -ForegroundColor Green

    }

}