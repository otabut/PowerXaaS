Function Request-Authorization
{
  param (
    [Parameter(Mandatory=$true)]$Token,
    [Parameter(Mandatory=$true)]$Feature
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
        return [PSCustomObject]@{
          Username = $Claims.username
          Authorization = "Granted"
        }
      }
      else
      {
        return [PSCustomObject]@{
          Username = $Claims.username
          Authorization = "Denied"
        }
      }
    }
    else
    {
      return [PSCustomObject]@{
        Username = $Claims.username
        Authorization = "Expired"
      }
    }
  }
  catch
  {
    return [PSCustomObject]@{
      Username = $Claims.username
      Authorization = "NotAuthenticated"
    }
  }
}
