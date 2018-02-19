Function Request-PXAuthorization
{
  param (
    [Parameter(Mandatory=$true)]$Authorization
  )

  if ($Authorization.split(' ')[0] -eq "Bearer")
  {
    $Claims = (Decode-JWT $Authorization.split(' ')[1]).Claims
    if (($Claims.username -eq "otabut") -and ([datetime]$Claims."expiration-date" -gt (Get-Date)))
    {
      return $true
    }
    else
    {
      return $false
    }
  }
  else
  {
    return $false
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
