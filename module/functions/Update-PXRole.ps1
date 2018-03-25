Function Update-PXRole
{
  param (
    [Parameter(Mandatory=$true)]$Role,
    [Parameter(Mandatory=$true)]$Features
  )

  $ErrorActionPreference = "stop"
  try
  {
    $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
    $Config = Get-Content $ConfigurationFile | ConvertFrom-Json
    if ($Config.roles | where {$_.Name -eq $Role})
    {
      if ($Features -ne '*')
      {
        $List = @()
        ForEach ($Feature in $Features.split(','))
        {
         if (Get-PXFeature | where {$_.Name -eq $Feature})
         {
           $List += $Feature
         }
         else
         {
           Write-Warning "Feature $Feature doesn't exist"
         }
        }
        $Features = $List
      }
      
      $RoleObject = [PSCustomObject]@{
        name = $Role
        features = $Features
      }

      $OtherRoles = $Config.roles | where {$_.name -ne $Role}
      if ($OtherRoles)
      {
        if ($OtherRoles.count -gt 1)
        {
          $AllRoles = $OtherRoles + $RoleObject
        }
        else
        {
          $AllRoles = @($OtherRoles,$RoleObject)
        }
      }
      else
      {
        $AllRoles = @($RoleObject)
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
