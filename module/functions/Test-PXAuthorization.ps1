Function Test-PXAuthorization
{
  param (
    [Parameter(Mandatory=$true)]$User,
    [Parameter(Mandatory=$true)]$Feature
  )

  $ErrorActionPreference = "stop"
  try
  {
    Import-Module PowerXaaS
    
    if (!(Get-PXFeature | where {$_.Name -eq $Feature}))
    {
      Write-Warning "Feature $Feature doesn't exist"
      return $false
    }

    if (!(Get-PXUsers | where {$_.Name -eq $User}))
    {
      Write-Warning "User $User doesn't exist"
      return $false
    }

    $Found = $false
    ForEach ($Role in (Get-PXRights -User $User).role)
    {
      $Features = (Get-PXRoles | where {$_.name -eq $Role}).features
      if (($Features | where {$_ -eq $Feature}) -or ($Features -eq '*'))
      {
        $Found = $true
        break
      }
    }
    return $Found
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
