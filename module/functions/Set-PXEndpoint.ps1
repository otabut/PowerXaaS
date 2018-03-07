Function Set-PXEndpoint
{
  param (
    [Parameter(Mandatory=$true)]$Feature,
    [Parameter(Mandatory=$true)][ValidateSet("GET","POST","PUT","PATCH","DELETE")]$Method,
    [Parameter(Mandatory=$true)]$Url
  )

  $ErrorActionPreference = "stop"
  try
  {
    $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
    $Config = Get-Content $ConfigurationFile | ConvertFrom-Json
    
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
    ($Config.features | where {$_.Name -eq $Feature}).endpoints = @((($Config.features | where {$_.Name -eq $Feature}).endpoints | where {($_.url -ne $Url) -and ($_.method -ne $Method)}),$endpoint)
    $Config | ConvertTo-Json -Depth 5 | Set-Content $ConfigurationFile
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
