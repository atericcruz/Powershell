Function Start-RoboCopy {

    [CmdletBinding()]

    param(

        [ValidateScript({ Test-Path $Source })]
        [string]$Source,

        [ValidateNotNullorEmpty()]
        [ValidateScript({ Test-Path $Destination })]
        [string]$Destination,

        [int]$Threads = 8,

        #[string]$Parameters = "*.* /S /E /DCOPY:DA /COPY:DAT /PURGE /MIR /NP /MT:$Threads /R:3 /W:1 "
        [string]$Parameters = "*.*"
    )

    Process {

        Write-Host "Executing: robocopy $Source $Destination $Parameters"

        robocopy $Source $Destination $Parameters.Split(' ')

        Write-Host "Finished: robocopy $Source $Destination $Parameters"

    }#Process

}
