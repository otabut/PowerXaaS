Function Remove-PXFeature
{
  param (
    [Parameter(Mandatory=$true)]$Name
  )

  $ErrorActionPreference = "stop"
  try
  {
    If ($Name -eq 'builtin')
    {
      Write-Warning "Builtin feature can't be removed"
      return
    }
    
    $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
    $Config = Get-Content $ConfigurationFile | ConvertFrom-Json
    If ($Config.features | where {$_.Name -eq $Name})
    {
      $Config.features = $Config.features | where {$_.name -ne $Name}
      $Config | ConvertTo-Json -Depth 5 | Set-Content $ConfigurationFile
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
