Function New-PXFeature
{
  param (
    [Parameter(Mandatory=$true)]$Name,
    [Parameter(Mandatory=$false)][ValidateSet("yes","no")]$Active='no'
  )

  $ErrorActionPreference = "stop"
  try
  {
    $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
    $Config = Get-Content $ConfigurationFile | ConvertFrom-Json
    If ($Config.features | where {$_.Name -eq $Name})
    {
      Write-Warning "Feature $Name already exists"
    }
    else
    {
      $Feature = [PSCustomObject]@{
        name = $Name
        active = $Active
        endpoints = @()
      }
      $Config.features += $Feature
      $Config | ConvertTo-Json -Depth 5 | Set-Content $ConfigurationFile
    }
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
