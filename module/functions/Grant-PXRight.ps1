Function Grant-PXRight
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
    
    if (!($Config.roles | where {$_.Name -eq $Role}))
    {
      Write-Warning "Role $Role doesn't exist"
      Return
    }
    if (!($Config.users | where {$_.Name -eq $User}))
    {
      Write-Warning "User $User doesn't exist"
      Return
    }

    $UserObject = [PSCustomObject]@{
      Name = $User
    }

    if ($Config.rights | where {$_.Role -eq $Role})
    {
      $OtherUsers = ($Config.rights | where {$_.Role -eq $Role}).users | where {$_.name -ne $User}
      if ($OtherUsers)
      {
        if ($OtherUsers.count -gt 1)
        {
          $AllUsers = $OtherUsers + $UserObject
        }
        else
        {
          $AllUsers = @($OtherUsers,$UserObject)
        }
      }
      else
      {
        $AllUsers = @($UserObject)
      }
      ($Config.rights | where {$_.Role -eq $Role}).users = $AllUsers
    }
    else
    {
      $RightObject = [PSCustomObject]@{
        role = $Role
        users = @($UserObject)
      }
      $Config.rights += $RightObject
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

