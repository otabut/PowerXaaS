
$Load = 50

Describe "Validate PowerXaaS module" {

  Context "'Functionnal unitary testing'" {

     It "GET version v1" {

       (invoke-webrequest -Uri 'http://localhost:8082/api/v1/version' -Method GET).content | should be "Version 1.0.0"
     }

     It "GET version v9 (check API versions are handled properly)" {

       (invoke-webrequest -Uri 'http://localhost:8082/api/v9/version' -Method GET).content | should be "Version 9.0.0"
     }

     It "POST echo" {
     
       $json = '{"text":"My own text"}'
       (invoke-webrequest -Uri 'http://localhost:8082/api/v1/echo' -Method POST -Body $json).content | should be "My own text"
     }

     It "GET addition (parameters in URL)" {

       (invoke-webrequest -Uri 'http://localhost:8082/api/v1/addition/3+4' -Method GET).content | should be 7
     }
  }

  Context "'Error management'" {

     It "non-existing endpoint" {

       try
       {
         invoke-webrequest -Uri 'http://localhost:8082/api/v1/whatever' -Method GET
       }
       catch
       {
         $StatusCode = $_.Exception.Response.StatusCode.Value__
         $StatusMessage = $_.ErrorDetails.Message
       }
       $StatusCode | Should be 404
     }
     
     It "unmanaged endpoint" {

       try
       {
         invoke-webrequest -Uri 'http://localhost:8082/api/v9/addition/3+4' -Method GET
       }
       catch
       {
         $StatusCode = $_.Exception.Response.StatusCode.Value__
         $StatusMessage = $_.ErrorDetails.Message
       }
       $StatusCode | Should be 404
     }

     It "malformatted JSON" {

       try
       {
         $malformattedjson = '{"text":"My own text"'
         invoke-webrequest -Uri 'http://localhost:8082/api/v1/display' -Method POST -Body $malformattedjson
       }
       catch
       {
         $StatusCode = $_.Exception.Response.StatusCode.Value__
         $StatusMessage = $_.ErrorDetails.Message
       }
       $StatusCode | Should be 400
     }

     It "POST without body" {
      
       try
       {
         invoke-webrequest -Uri 'http://localhost:8082/api/v1/echo' -Method POST
       }
       catch
       {
         $StatusCode = $_.Exception.Response.StatusCode.Value__
         $StatusMessage = $_.ErrorDetails.Message
       }
       $StatusCode | Should be 400
     }

     It "Invalid return code" {

       try
       {
         invoke-webrequest -Uri 'http://localhost:8082/api/v1/invalid' -Method GET
       }
       catch
       {
         $StatusCode = $_.Exception.Response.StatusCode.Value__
         $StatusMessage = $_.ErrorDetails.Message
       }
       $StatusCode | Should be 500
     }

     It "Access denied" {

       #$StatusCode = 403
       #$StatusCode | Should be 403
     }
  }

  Context "'Load testing'" {

    It "start $Load calls" {

      $nbSuccess = 0
      $i = 0
      do
      {
        $Random = Get-Random -Maximum 3
        switch ($Random)
        {
          0 { $result=invoke-webrequest -Uri 'http://localhost:8082/api/v1/version' -Method GET }
          1 { $json='{"text":"My own text"}'; $result=invoke-webrequest -Uri 'http://localhost:8082/api/v1/echo' -Method POST -Body $json }
          2 { $result=invoke-webrequest -Uri 'http://localhost:8082/api/v1/addition/3+4' -Method GET }
        }
        if (($result.StatusCode -eq 200) -or ($result.StatusCode -eq 201))
        {
          $nbSuccess++
        }
        $i++
      }
      until ($i -eq $Load)

      $nbSuccess | should be $Load
    }
    
    BeforeEach {
      
    }

    AfterEach {
      
    }
  }
}


