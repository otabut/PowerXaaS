param(
  [Parameter(Mandatory=$true)]$ip,
  [Parameter(Mandatory=$true)]$port
)

$BaseUrl = "https://$ip`:$port"
$Load = 50

add-type @"
  using System.Net;
  using System.Security.Cryptography.X509Certificates;
  public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
      ServicePoint srvPoint, X509Certificate certificate,
      WebRequest request, int certificateProblem) {
        return true;
      }
  }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


Describe "Validate PowerXaaS module" {

  Context "'Setup'" {

    It "Status" {

      & "$PSScriptRoot\..\PowerXaaS.ps1" -Remove | out-null
      $result = & "$PSScriptRoot\..\PowerXaaS.ps1" -Status
      $result | should be "Not installed"
    }
    
    It "Setup" {

      & "$PSScriptRoot\..\PowerXaaS.ps1" -Setup -Ip $ip -Port $port | Out-Null
      $result = & "$PSScriptRoot\..\PowerXaaS.ps1" -Status
      $result | should be "Stopped"
    }

    It "Version" {

      $result = & "$PSScriptRoot\..\PowerXaaS.ps1" -Version
      $result | should be "1.2.0"
    }

    It "Start" {

      & "$PSScriptRoot\..\PowerXaaS.ps1" -Start | Out-Null
      $result = & "$PSScriptRoot\..\PowerXaaS.ps1" -Status
      $result | should match "Running"
    }

    It "Stop" {

      & "$PSScriptRoot\..\PowerXaaS.ps1" -Stop | Out-Null
      start-sleep 1
      $result = & "$PSScriptRoot\..\PowerXaaS.ps1" -Status
      $result | should be "Stopped"
    }

    It "Remove" {

      & "$PSScriptRoot\..\PowerXaaS.ps1" -Remove | out-null
      $result = & "$PSScriptRoot\..\PowerXaaS.ps1" -Status
      $result | should be "Not installed"
      & "$PSScriptRoot\..\PowerXaaS.ps1" -Setup -Ip $ip -Port $port -Start | Out-Null
    }
  }
  
  Context "'Functionnal unitary testing'" {

    It "Connect" {

      $Result.APIVersion | should be "1.0.0"
    }
     
    It "GET version v1" {

      (invoke-webrequest -Uri "$BaseUrl/api/v1/version" -Method GET  -Headers $Headers).content | should be "Version 1.0.0"
    }

    It "GET version v9 (check API versions are handled properly)" {

      (invoke-webrequest -Uri "$BaseUrl/api/v9/version" -Method GET -Headers $Headers).content | should be "Version 9.0.0"
    }

    It "POST echo" {
     
      $json = '{"text":"My own text"}'
      (invoke-webrequest -Uri "$BaseUrl/api/v1/echo" -Method POST -Headers $Headers -Body $json).content | should be "My own text"
    }

    It "GET addition (parameters in URL)" {

      (invoke-webrequest -Uri "$BaseUrl/api/v1/addition/3+4" -Method GET -Headers $Headers).content | should be 7
    }

     
    BeforeEach {
      
      $json = '{"Username":"JohnDoe","password":"blabla"}'
      $Result = (invoke-webrequest -Uri "$BaseUrl/api/v1/connect" -Method POST -Body $json).content | ConvertFrom-Json
      $Token = $Result.token
      $Headers = @{"Authorization" = "Bearer " + $Token}
    }

    AfterEach {
      
    }

  }

  Context "'Error management'" {

    It "non-existing endpoint" {

      try
      {
        invoke-webrequest -Uri "$BaseUrl/api/v1/whatever" -Method GET -Headers $Headers
      }
      catch
      {
        $StatusCode = $_.Exception.Response.StatusCode.Value__
        $StatusMessage = $_.ErrorDetails.Message
      }
      $StatusCode | Should be $([Int][System.Net.HttpStatusCode]::NotFound)
    }
     
    It "unmanaged endpoint" {

      try
      {
        invoke-webrequest -Uri "$BaseUrl/api/v9/addition/3+4" -Method GET -Headers $Headers
      }
      catch
      {
        $StatusCode = $_.Exception.Response.StatusCode.Value__
        $StatusMessage = $_.ErrorDetails.Message
      }
      $StatusCode | Should be $([Int][System.Net.HttpStatusCode]::NotFound)
    }

    It "malformatted JSON" {

      try
      {
        $malformattedjson = '{"text":"My own text"'
        invoke-webrequest -Uri "$BaseUrl/api/v1/display" -Method POST -Headers $Headers -Body $malformattedjson
      }
      catch
      {
        $StatusCode = $_.Exception.Response.StatusCode.Value__
        $StatusMessage = $_.ErrorDetails.Message
      }
      $StatusCode | Should be $([Int][System.Net.HttpStatusCode]::BadRequest)
    }

    It "POST without body" {
      
      try
      {
        invoke-webrequest -Uri "$BaseUrl/api/v1/echo" -Method POST -Headers $Headers
      }
      catch
      {
        $StatusCode = $_.Exception.Response.StatusCode.Value__
        $StatusMessage = $_.ErrorDetails.Message
      }
      $StatusCode | Should be $([Int][System.Net.HttpStatusCode]::BadRequest)
    }

    It "Invalid return code" {

      try
      {
        invoke-webrequest -Uri "$BaseUrl/api/v1/invalid" -Method GET -Headers $Headers
      }
      catch
      {
        $StatusCode = $_.Exception.Response.StatusCode.Value__
        $StatusMessage = $_.ErrorDetails.Message
      }
      $StatusCode | Should be $([Int][System.Net.HttpStatusCode]::InternalServerError)
    }

    BeforeEach {
      
      $json = '{"Username":"JohnDoe","password":"blabla"}'
      $Result = (invoke-webrequest -Uri "$BaseUrl/api/v1/connect" -Method POST -Body $json).content | ConvertFrom-Json
      $Token = $Result.token
      $Headers = @{"Authorization" = "Bearer " + $Token}
    }

    AfterEach {
      
    }
  }

  Context "'Security management'" {

    It "Authentication failed" {

      try
      {
        $json = '{"Username":"JohnDoe","password":"nothingGood"}'
        $Result = (invoke-webrequest -Uri "$BaseUrl/api/v1/connect" -Method POST -Body $json).content | ConvertFrom-Json
      }
      catch
      {
        $StatusCode = $_.Exception.Response.StatusCode.Value__
        $StatusMessage = $_.ErrorDetails.Message
      }
      $StatusCode | Should be $([Int][System.Net.HttpStatusCode]::Unauthorized)
    }

    It "Not authenticated" {

      try
      {
        invoke-webrequest -Uri "$BaseUrl/api/v1/version" -Method GET
      }
      catch
      {
        $StatusCode = $_.Exception.Response.StatusCode.Value__
        $StatusMessage = $_.ErrorDetails.Message
      }
      $StatusCode | Should be $([Int][System.Net.HttpStatusCode]::Unauthorized)
    }

    It "Authorization denied" {

      try
      {
        $json = '{"Username":"DexterMorgan","password":"SliceOfLife"}'
        $Result = (invoke-webrequest -Uri "$BaseUrl/api/v1/connect" -Method POST -Body $json).content | ConvertFrom-Json
        $Token = $Result.token
        $Headers = @{"Authorization" = "Bearer " + $Token}
        invoke-webrequest -Uri "$BaseUrl/api/v1/version" -Method GET -Headers $Headers
      }
      catch
      {
        $StatusCode = $_.Exception.Response.StatusCode.Value__
        $StatusMessage = $_.ErrorDetails.Message
      }
      $StatusCode | Should be $([Int][System.Net.HttpStatusCode]::Forbidden)
    }
  }

  Context "'Load testing'" {

    It "start $Load calls" {

      $json = '{"username":"JohnDoe","password":"blabla"}'
      $Result = (invoke-webrequest -Uri "$BaseUrl/api/v1/connect" -Method POST -Body $json).content | ConvertFrom-Json
      $Token = $Result.token
      $Headers = @{"Authorization" = "Bearer " + $Token}

      $nbSuccess = 0
      $i = 0
      do
      {
        $Random = Get-Random -Maximum 3
        switch ($Random)
        {
          0 { $result=invoke-webrequest -Uri "$BaseUrl/api/v1/version" -Method GET -Headers $Headers }
          1 { $json='{"text":"My own text"}'; $result=invoke-webrequest -Uri "$BaseUrl/api/v1/echo" -Method POST -Headers $Headers -Body $json }
          2 { $result=invoke-webrequest -Uri "$BaseUrl/api/v1/addition/3+4" -Method GET -Headers $Headers }
        }
        if (($result.StatusCode -eq [Int][System.Net.HttpStatusCode]::OK) -or ($result.StatusCode -eq [Int][System.Net.HttpStatusCode]::Created))
        {
          $nbSuccess++
        }
        $i++
      }
      until ($i -eq $Load)

      $nbSuccess | should be $Load

      & "$PSScriptRoot\..\PowerXaaS.ps1" -Remove | Out-Null
    }
  }
}
