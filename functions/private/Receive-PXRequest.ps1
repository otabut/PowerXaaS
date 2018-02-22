Function Receive-PXRequest
{
  param (
    [Parameter(Mandatory=$true)]$Context
  )

  ### INITIALIZE ###
  $Request = $Context.Request
  $Response = $Context.Response
  $StreamData = $null
  $Body = $null
  $Authorized = $false
  $Malformed = $false

  ### PROCESS REQUEST ###
  Write-PXLog -Status "Information" -Context "SERVER" -Description "****** REQUEST RECEIVED ******"
  Write-PXLog -Status "Information" -Context "CLIENT" -Description "local path is $($Request.Url.LocalPath)"
  Write-PXLog -Status "Information" -Context "CLIENT" -Description "HTTP method is $($Request.HttpMethod)"
  Write-PXLog -Status "Information" -Context "CLIENT" -Description "host name is $($Request.UserHostName)"
  Write-PXLog -Status "Information" -Context "CLIENT" -Description "user agent is $($Request.UserAgent)"
  foreach ($key in $Request.headers.AllKeys)
  {
    Write-PXLog -Status "Information" -Context "CLIENT" -Description "$key`: $($Request.headers.GetValues($key))"
  }

  #Read body
  $StreamReader = New-Object System.IO.StreamReader $request.InputStream
  $StreamData = $StreamReader.ReadToEnd()
  if ($StreamData)
  {
    try
    {
      $Body = $StreamData | ConvertFrom-Json
      Write-PXLog -Status "Information" -Context "SERVER" -Description "body is $($body -replace '(?<begin>[\;\{\s]password=)(?<pass>.*)(?<end>[\;\}])','${begin}********${end}')"
    }
    catch
    {
      #Prevent from malformed JSON files
      Write-PXLog -Status "Error" -Context "SERVER" -Description "$StreamData is not a valid JSON file"
      $Malformed = $true
    }
  }
  if ($Malformed)
  {
    $Result = [PSCustomObject]@{
      ReturnCode = 400
      Content = "Provided body is not a valid JSON file"
    }
  }
  else
  {
    #Read config and get action
    Write-PXLog -Status "Information" -Context "SERVER" -Description "------ processing request ------"
    $Endpoint = ($Request.url.localpath.substring(1) -replace 'api/v.','')
    $Method = $Request.httpmethod
    Write-PXLog -Status "Information" -Context "SERVER" -Description "reading configuration file"
    $Config = Get-Content .\PowerXaaS.conf | ConvertFrom-Json
    $AllEndpoints = $Config.features | select -ExpandProperty endpoints -Property @{Label="feature";Expression={$_.Name}}, active | where {$_.Active -eq 'yes'}
    $Feature = ($AllEndpoints | where {($Method -eq $_.Method) -and ($Endpoint -match ("^$($_.url)$".replace("{","(?<").replace("}", ">.*)")).substring(1))} | Select-Object -First 1).feature
    $Parameters = ([PSCustomObject]$Matches)
      
    if ($Feature)
    {
      Write-PXLog -Status "Information" -Context "SERVER" -Description "matching feature: $feature"
      #Check authorization
      if ($Request.headers.GetValues("Authorization") -eq $null)
      {
        if ($Endpoint -eq '/connect')
        {
          $Authorized = $true
        }
        else
        {
          $Authorized = $false
        }
      }
      else
      {
        $Token = $Request.headers.GetValues("Authorization").split(' ')[1]
        $Authorized = Request-PXAuthorization -Token $Token -Feature $Feature -Endpoint $Endpoint -Method $Method
      }

      if ($Authorized)
      {
        Write-PXLog -Status "Information" -Context "SERVER" -Description "authorization granted"
        $Folder = ".\$($Request.Url.Segments[1].substring(0,$Request.Url.Segments[1].length-1))\$($Request.Url.Segments[2].substring(0,$Request.Url.Segments[2].length-1))"
        $Script = "$Folder\$Feature.ps1"
        $Parameters.PSObject.Properties.Remove('0')
        $Inputs = [PSCustomObject]@{
          URL = $($Request.url.localpath.substring(1) -replace 'api/v.','')
          Method = $($Request.httpmethod)
          Body = $Body
          Parameters = $Parameters
        }

        #Run action
        Write-PXLog -Status "Information" -Context "SERVER" -Description "calling - $Script"
        try
        {
          $Result = & "$Script" $Inputs
        }
        catch
        {
          Write-PXLog -Status "Error" -Context "FEATURE" -Description "internal error"
          $Result = [PSCustomObject]@{
            ReturnCode = 500
            Content = "error while processing $Script"
          }
        }
      }
      else
      {
        Write-PXLog -Status "Error" -Context "SERVER" -Description "authorization denied"
        $Result = [PSCustomObject]@{
          ReturnCode = 403
          Content = 'authorization denied'
        }
      }
    }
    else
    {
      #Endpoint not found
      Write-PXLog -Status "Error" -Context "SERVER" -Description "endpoint not found"
      $Result = [PSCustomObject]@{
        ReturnCode = 404
        Content = "endpoint not found"
      }
    }
  }
        
  if ($Result.ReturnCode -notmatch "\d\d\d")
  {
    Write-PXLog -Status "Error" -Context "FEATURE" -Description "invalid return code"
    $Result = [PSCustomObject]@{
      ReturnCode = 500
      Content = "invalid return code"
    }
  }
  Write-PXLog -Status "Information" -Context "SERVER" -Description "------  request processed  ------"

  ### SEND RESPONSE ###    
  Write-PXLog -Status "Information" -Context "SERVER" -Description "return code is $($Result.ReturnCode)"
  $Response.statuscode = $Result.ReturnCode
  if ($Result.Content)
  {
    Write-PXLog -Status "Information" -Context "SERVER" -Description "content is $($Result.Content)"
    $Buffer = [Text.Encoding]::UTF8.GetBytes($Result.Content)
    $Response.ContentType = 'application/json'
    $Response.ContentLength64 = $Buffer.length
    $Response.OutputStream.Write($Buffer, 0, $Buffer.length)
  }
  else
  {
    Write-PXLog -Status "Information" -Context "SERVER" -Description "no content"
  }
  $Response.Close()
  Write-PXLog -Status "Information" -Context "SERVER" -Description "******  RESPONSE SENT  ******"
}
