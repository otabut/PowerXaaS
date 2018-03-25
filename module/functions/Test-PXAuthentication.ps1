Function Test-PXAuthentication
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
    
    if (!($Config.users | where {$_.Name -eq $User}))
    {
      Write-Warning "User $User doesn't exist"
      Return
    }

    if ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($Config.users | where {$_.Name -eq $User}).password)) -ceq $Password)
    {
      return $true
    }
    else
    {
      return $false
    }
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
