Function Remove-PXEndpoint
{
  param (
    [Parameter(Mandatory=$true)]$Feature,
    [Parameter(Mandatory=$true)][ValidateSet("GET","POST","PUT","PATCH","DELETE")]$Method,
    [Parameter(Mandatory=$true)]$Url
  )

  $ErrorActionPreference = "stop"
  try
  {
    If ($Feature -eq 'builtin')
    {
      Write-Warning "Endpoints from builtin feature can't be removed"
      return
    }

    $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
    $Config = Get-Content $ConfigurationFile | ConvertFrom-Json
    If ($Config.features | where {$_.Name -eq $Feature})
    {
      $Endpoint = ($Config.features | where {$_.Name -eq $Feature}).endpoints | where {($_.url -eq $Url) -and ($_.method -eq $Method)}
      If ($Endpoint)
      {
        $OtherEndpoints = ($Config.features | where {$_.Name -eq $Feature}).endpoints | where {($_.url -ne $Url) -or ($_.method -ne $Method)}
        if ($OtherEndpoints)
        {
          $AllEndpoints = @($OtherEndpoints)
        }
        else
        {
          $AllEndpoints = @()
        }
        ($Config.features | where {$_.Name -eq $Feature}).endpoints = $AllEndpoints
        $Config | ConvertTo-Json -Depth 5 | Set-Content $ConfigurationFile
      }
      else
      {
        Write-Warning "Endpoint $Method - $Url doesn't exist"
      }
    }
    else
    {
      Write-Warning "Feature $Feature doesn't exist"
    }
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
