Function Test-IsAdmin {

  $IsAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  
  if ($IsAdmin -eq $false) {
    Write-Error "Finding all user applications requires administrative privileges"
    break
  }
  
}
