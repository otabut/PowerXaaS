Function Get-PXRights
{
  param (
    [Parameter(Mandatory=$false)]$User
  )

  $ErrorActionPreference = "stop"
  try
  {
    $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
    $Config = (Get-Content $ConfigurationFile | ConvertFrom-Json)
    if ($User)
    {
      If ($Config.users | where {$_.Name -eq $User})
      {
        return $Config.rights | where {$_.users -match $User} | select Role
      }
      else
      {
        Write-Warning "User $Name doesn't exist"
      }
    }
    else
    {
      return $Config.rights | select Role,Users
    }
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
