Function Set-PXEndpoint
{
  param (
    [Parameter(Mandatory=$true)]$Feature,
    [Parameter(Mandatory=$true)][ValidateSet("GET","POST","PUT","DELETE")]$Method,
    [Parameter(Mandatory=$true)]$Url
  )

  $ErrorActionPreference = "stop"
  try
  {
    $ModulePath = split-path (Get-Module PowerXaaS).path
    $Config = Get-Content "$ModulePath\PowerXaaS.conf" | ConvertFrom-Json
    
    $Endpoint = [PSCustomObject]@{
      method = $Method
      url = $Url
    }

    if (!($Config.features | where {$_.Name -eq $Feature}))
    {
      $Feature = [PSCustomObject]@{
        name = $Feature
        active = 'no'
        endpoints = @()
      }
      $Config.features += $Feature
    }
    ($Config.features | where {$_.Name -eq $Feature}).endpoints += $Endpoint
    $Config | ConvertTo-Json -Depth 5 | Set-Content $ModulePath\PowerXaaS.conf
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
