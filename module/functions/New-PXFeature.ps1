Function New-PXFeature
{
  param (
    [Parameter(Mandatory=$true)]$Name,
    [Parameter(Mandatory=$false)][ValidateSet("yes","no")]$Active='no',
    [Parameter(Mandatory=$false)][switch]$CreateFile,
    [Parameter(Mandatory=$false)][ValidatePattern("v\d*")]$APIversion='v1'
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

      if ($CreateFile)
      {
        if (!(test-path "${ENV:ProgramFiles}\PowerXaaS\api\$APIversion"))
        {
          New-Item "${ENV:ProgramFiles}\PowerXaaS\api\$APIversion" -ItemType Directory | Out-Null
        }
        Copy-Item $PSScriptRoot\feature-template.txt "${ENV:ProgramFiles}\PowerXaaS\api\$APIversion\$Name.ps1" | Out-Null
      }
    }
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
