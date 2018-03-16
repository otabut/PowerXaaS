Function Request-Authorization
{
  param (
    [Parameter(Mandatory=$true)]$Token,
    [Parameter(Mandatory=$true)]$Feature,
    [Parameter(Mandatory=$true)]$Endpoint,
    [Parameter(Mandatory=$true)]$Method
  )

  try
  {
    . "${ENV:ProgramFiles}\PowerXaaS\Functions\JWT-helper.ps1"

    $Claims = (Decode-JWT $Token).Claims
    if ([datetime]$Claims."expiration-date" -gt (Get-Date))
    {
      #do something with $Claims.username, $Feature, $Endpoint, $Method
      if ($Claims.username -eq 'JohnDoe')
      {
        return "Granted"
      }
      else
      {
        return "Denied"
      }
    }
    else
    {
      return "Expired"
    }
  }
  catch
  {
    return "NotAuthenticated"
  }
}
