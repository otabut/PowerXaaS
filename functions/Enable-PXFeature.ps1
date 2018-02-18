Function Enable-PXFeature
{
  param (
    [Parameter(Mandatory=$true)]$Name
  )

  $ErrorActionPreference = "stop"
  try
  {
    $ModulePath = split-path (Get-Module PowerXaaS).path
    $Config = Get-Content "$ModulePath\PowerXaaS.conf" | ConvertFrom-Json
    If ($Config.features | where {$_.Name -eq $Name})
    {
      ($Config.features | where {$_.name -eq $Name}).active = 'yes'
      $Config | ConvertTo-Json -Depth 5 | Set-Content $ModulePath\PowerXaaS.conf
    }
    else
    {
      Write-Warning "Feature $Name doesn't exist"
    }
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
