Function Remove-PXUser
{
  param (
    [Parameter(Mandatory=$true)]$User
  )

  $ErrorActionPreference = "stop"
  try
  {
    Import-Module PowerXaaS
    
    if (Get-PXUsers | where {$_.Name -eq $User})
    {
      #First, revoke rights
      Get-PXRights -User $User | %{Revoke-PXRight -Role $_.role -User $User}
      #Then, delete user
      $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
      $Config = Get-Content $ConfigurationFile | ConvertFrom-Json
      $OtherUsers = $Config.users | where {$_.name -ne $User}
      if ($OtherUsers)
      {
        $AllUsers = @($OtherUsers)
      }
      else
      {
        $AllUsers = @()
      }
      $Config.users = $AllUsers
      $Config | ConvertTo-Json -Depth 5 | Set-Content $ConfigurationFile
    }
    else
    {
      Write-Warning "User $User doesn't exist"
    }
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
