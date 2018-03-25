param (
  [Parameter(Mandatory=$true)]$Inputs
)

$ErrorActionPreference = 'stop'
try
{
  Import-Module PowerXaaS
  . "${ENV:ProgramFiles}\PowerXaaS\Functions\JWT-helper.ps1"
  
  switch -regex ($Inputs.url)
  {
    "/connect"
    {
      if (Test-PXAuthentication -User $Inputs.body.username -Password $Inputs.body.password)  ### Credentials validation
      {
        try
        {
          $TokenLifetime = (Get-ItemProperty -Path HKLM:\Software\PowerXaaS -Name TokenLifetime).TokenLifetime 
        }
        catch
        {
          $TokenLifetime = "4"
        }
        $ExpirationDate = (Get-Date).AddHours($TokenLifetime)
        $JSONheader = '{"alg":"HS256","typ":"JWT"}'
        $JSONpayload = '{"APIVersion":"1.0.0","username":"'+$Inputs.body.username+'","expiration-date":"'+$ExpirationDate+'"}'
        $JWTHeader = MAA-ConvertTo-Base64 $JSONheader
        $JWTPayload = MAA-ConvertTo-Base64 $JSONpayload
        $JWTHeaderandPayload = $JWTHeader + "." + $JWTpayload
        $JWTtoken = $JWTHeaderandPayload + "." + (MAA-JWT-EncodeSignature $JWTHeaderandPayload "secret")

        $Content = [PSCustomObject]@{
          Token = $JWTtoken
          APIVersion = "1.0.0"
          Username = $inputs.body.username
          ExpirationDate = $ExpirationDate
        }

        $result = [PSCustomObject]@{
          ReturnCode = [Int][System.Net.HttpStatusCode]::OK
          Content = $Content | ConvertTo-JSON
          ContentType = "application/json"
        }
      }
      else
      {
        $result = [PSCustomObject]@{
          ReturnCode = [Int][System.Net.HttpStatusCode]::Unauthorized
          Content = "Authentication has failed"
          ContentType = "text/plain"
        }
      }
    }

    "/version"
    {
      $result = [PSCustomObject]@{
        ReturnCode = [Int][System.Net.HttpStatusCode]::OK
        Content = "Version 1.0.0"
        ContentType = "text/plain"
      }
    }

    "/endpoints"
    {
      $result = [PSCustomObject]@{
        ReturnCode = [Int][System.Net.HttpStatusCode]::OK
        Content = Get-PXEndpoint | ConvertTo-Json
        ContentType = "application/json"
      }
    }

    "/stats"
    {
      $result = [PSCustomObject]@{
        ReturnCode = [Int][System.Net.HttpStatusCode]::OK
        Content = Get-PXUsageStats -raw | ConvertTo-Json
        ContentType = "application/json"
      }
    }
    
    default
    {
      $result = [PSCustomObject]@{
        ReturnCode = [Int][System.Net.HttpStatusCode]::NotFound
        Content = "This endpoint is not managed by this API version"
        ContentType = "text/plain"
      }
    }
  }
}
catch
{
  $msg = $_.Exception.Message
  $line = $_.InvocationInfo.ScriptLineNumber
  $result = [PSCustomObject]@{
    ReturnCode = [Int][System.Net.HttpStatusCode]::InternalServerError
    Content = "Error while processing : error at line ${line}: $msg"
    ContentType = "text/plain"
  }
}

return $result
