Function Get-PXDuplicateEndpoint
{
  $ErrorActionPreference = "stop"
  try
  {
    $ModulePath = split-path (Get-Module PowerXaaS).path
    $Config = (Get-Content "$ModulePath\PowerXaaS.conf" | ConvertFrom-Json).features | select -ExpandProperty endpoints -Property @{Label="feature";Expression={$_.Name}}, active

    Return ($Config | Group-Object url,method | where {$_.count -gt 1}).group
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
