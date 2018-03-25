Function Get-PXUsers
{
  $ErrorActionPreference = "stop"
  try
  {
    $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
    return (Get-Content $ConfigurationFile | ConvertFrom-Json).users | select Name
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
