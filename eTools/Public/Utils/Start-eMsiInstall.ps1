Function Start-eMsiInstall{

[CmdletBinding()]

param(

$MsiPath,
$Log

)

$arg = @("/I","$MsiPath","/qn","/norestart","/l $Log")

$ReturnedCode = [int]((Start-Process -FilePath msiexec.exe -ArgumentList $arg -PassThru -Wait -Verb RunAs).ExitCode)

$Code  = [ComponentModel.Win32Exception]$ReturnedCode

$Output = [PSCustomObject]@{

File = $MsiPath

ExitCode = $Code.NativeErrorCode

ExitMessage = $Code.Message

}

Write-Output $Output

}
