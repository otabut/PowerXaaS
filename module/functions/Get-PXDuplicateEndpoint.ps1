Function Get-PXDuplicateEndpoint
{
  $ErrorActionPreference = "stop"
  try
  {
    $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
    $Config = (Get-Content $ConfigurationFile | ConvertFrom-Json).features | select -ExpandProperty endpoints -Property @{Label="feature";Expression={$_.Name}}, active

    Return ($Config | Group-Object url,method | where {$_.count -gt 1}).group
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
