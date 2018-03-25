Function Revoke-PXRight
{
  param (
    [Parameter(Mandatory=$true)]$Role,
    [Parameter(Mandatory=$true)]$User
  )

  $ErrorActionPreference = "stop"
  try
  {
    $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
    $Config = Get-Content $ConfigurationFile | ConvertFrom-Json
    if ($Config.rights | where {$_.Role -eq $Role})
    {
      $OtherUsers = ($Config.rights | where {$_.Role -eq $Role}).users | where {$_.name -ne $User}
      if ($OtherUsers)
      {
        $AllUsers = @($OtherUsers)
      }
      else
      {
        $AllUsers = @()
      }
      ($Config.rights | where {$_.Role -eq $Role}).users = $AllUsers
      $Config | ConvertTo-Json -Depth 5 | Set-Content $ConfigurationFile
    }
    else
    {
      Write-Warning "Role $Role doesn't exist"
    }
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
