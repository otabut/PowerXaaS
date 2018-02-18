Function New-PXFeature
{
  param (
    [Parameter(Mandatory=$true)]$Name,
    [Parameter(Mandatory=$false)][ValidateSet("yes","no")]$State='no'
  )

  $ErrorActionPreference = "stop"
  try
  {
    $ModulePath = split-path (Get-Module PowerXaaS).path
    $Config = Get-Content "$ModulePath\PowerXaaS.conf" | ConvertFrom-Json
    If ($Config.features | where {$_.Name -eq $Name})
    {
      Write-Warning "Feature $Name already exists"
    }
    else
    {
      $Feature = [PSCustomObject]@{
        name = $Name
        active = $State
        endpoints = @()
      }
      $Config.features += $Feature
      $Config | ConvertTo-Json -Depth 5 | Set-Content $ModulePath\PowerXaaS.conf
    }
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
