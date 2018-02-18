Function Remove-PXEndpoint
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
    If ($Config.features | where {$_.Name -eq $Feature})
    {
      $Endpoint = ($Config.features | where {$_.Name -eq $Feature}).endpoints | where {($_.url -eq $Url) -and ($_.method -eq $Method)}
      If ($Endpoint)
      {
        ($Config.features | where {$_.Name -eq $Feature}).endpoints = ($Config.features | where {$_.Name -eq $Feature}).endpoints | where {($_.url -ne $Url) -and ($_.method -ne $Method)}
        $Config | ConvertTo-Json -Depth 5 | Set-Content $ModulePath\PowerXaaS.conf
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
