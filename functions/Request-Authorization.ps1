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


function Convert-FromBase64StringWithNoPadding([string]$data)
{
    $data = $data.Replace('-', '+').Replace('_', '/')
    switch ($data.Length % 4)
    {
        0 { break }
        2 { $data += '==' }
        3 { $data += '=' }
        default { throw New-Object ArgumentException('data') }
    }
    return [System.Convert]::FromBase64String($data)

}


function Decode-JWT([string]$rawToken)
{
    $parts = $rawToken.Split('.');
    $headers = [System.Text.Encoding]::UTF8.GetString((Convert-FromBase64StringWithNoPadding $parts[0]))
    $claims = [System.Text.Encoding]::UTF8.GetString((Convert-FromBase64StringWithNoPadding $parts[1]))
    $signature = (Convert-FromBase64StringWithNoPadding $parts[2])

    $customObject = [PSCustomObject]@{
        headers = ($headers | ConvertFrom-Json)
        claims = ($claims | ConvertFrom-Json)
        signature = $signature
    }

    Write-Verbose -Message ("JWT`r`n.headers: {0}`r`n.claims: {1}`r`n.signature: {2}`r`n" -f $headers,$claims,[System.BitConverter]::ToString($signature))
    return $customObject
}
