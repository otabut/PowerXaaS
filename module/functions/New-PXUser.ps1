Function New-PXUser
{
  param (
    [Parameter(Mandatory=$true)]$User,
    [Parameter(Mandatory=$true)]$Password
  )

  $ErrorActionPreference = "stop"
  try
  {
    $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
    $Config = Get-Content $ConfigurationFile | ConvertFrom-Json
    if ($Config.users | where {$_.Name -eq $User})
    {
      Write-Warning "User $User already exists"
    }
    else
    {
      $UserObject = [PSCustomObject]@{
        name = $User
        password = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($Password))
      }
      
      $OtherUsers = $Config.users | where {$_.name -ne $User}
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
      $Config.users = $AllUsers
      $Config | ConvertTo-Json -Depth 5 | Set-Content $ConfigurationFile
    }
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
