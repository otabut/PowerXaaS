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
    
    $EndpointObject = [PSCustomObject]@{
      method = $Method
      url = $Url
    }

    if (!($Config.features | where {$_.Name -eq $Feature}))
    {
      $FeatureObject = [PSCustomObject]@{
        name = $Feature
        active = 'no'
        endpoints = @($EndpointObject)
      }
      $Config.features += $FeatureObject
    }
    else
    {
      $OtherEndpoints = ($Config.features | where {$_.Name -eq $Feature}).endpoints | where {($_.url -ne $Url) -or ($_.method -ne $Method)}
      if ($OtherEndpoints)
      {
        if ($OtherEndpoints.count -gt 1)
        {
          $AllEndpoints = $OtherEndpoints + $EndpointObject
        }
        else
        {
          $AllEndpoints = @($OtherEndpoints,$EndpointObject)
        }
      }
      else
      {
        $AllEndpoints = @($EndpointObject)
      }
      ($Config.features | where {$_.Name -eq $Feature}).endpoints = $AllEndpoints
    }
    $Config | ConvertTo-Json -Depth 5 | Set-Content $ConfigurationFile
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
