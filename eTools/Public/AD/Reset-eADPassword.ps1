Function ReSet-eADPassword {

    [CmdletBinding()]

    param(
    
        [ValidateNotNullOrEmpty()]
        [string]$Username,
    
        [string]$Password, 

        [int]$Length = 15,

        [switch]$Clip,

        [switch]$PassThru

    )

    IF (!($Password)) {

        $Password = New-eRandomPassword

    }

    $User = ([adsisearcher]::new("(&(objectCategory=user)(samaccountname=$Username))").FindOne())
   
    if ($User.Path) {

        try {

            $UserAD = [ADSI]"$($User.Path)"
            $null = $UserAD.psbase.Invoke("SetPassword", $Password)
            $null = $UserAD.psbase.CommitChanges()

            Write-Host "$Username password has been reset" -ForegroundColor Green

            IF (!($PassThru) -and !($Clip)) {

                Write-Warning "About to display the password for 30 seconds before clearing the screen"

                Write-Host "$Password" -ForegroundColor Cyan

                Start-Sleep -Seconds 30

                Clear-Host
                
            }
            elseif ($Clip) {

                $Password | clip

                Write-Host "Copied to your clipboard" -ForegroundColor Green

            }
            elseif ($PassThru) {

                Write-Output $Password

            }

            $null = Remove-Variable Password -Force -EA 0

            Write-Host "I said good day!" -ForegroundColor Green

            return $true

        }
        catch {

            Write-Output $Error
            return $false
            break

        }

    }
    else {

        Write-Host "$Username not found" -ForegroundColor Yellow
        return $false

    }

}