Function Remove-PXRole
{
  param (
    [Parameter(Mandatory=$true)]$Role
  )

  $ErrorActionPreference = "stop"
  try
  {
    $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
    $Config = Get-Content $ConfigurationFile | ConvertFrom-Json
    if ($Config.roles | where {$_.Name -eq $Role})
    {
      #First, revoke rights
      $OtherRoles = $Config.rights | where {$_.Role -ne $Role}
      if ($OtherRoles)
      {
        $AllRoles = @($OtherRoles)
      }
      else
      {
        $AllRoles = @()
      }
      $Config.rights = $AllRoles

      #Then, delete role
      $OtherRoles = $Config.roles | where {$_.name -ne $Role}
      if ($OtherRoles)
      {
        $AllRoles = @($OtherRoles)
      }
      else
      {
        $AllRoles = @()
      }
      $Config.roles = $AllRoles
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

