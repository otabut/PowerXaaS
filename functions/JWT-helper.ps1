
function MAA-ConvertTo-Base64([string]$data)
{
    $temp = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($data))
    $temp = $temp -replace '=',''
    
    return $temp
}

function MAA-JWT-EncodeSignature([string]$data,[string]$secret)
{
    # Powershell HMAC SHA 256
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($secret)
    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($data))
    $signature = [Convert]::ToBase64String($signature)
    $signature = $signature -replace '=',''

    return $signature
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
