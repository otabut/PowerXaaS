param (
  [Parameter(Mandatory=$true)]$inputs
)

$ErrorActionPreference = 'stop'
try
{
  switch -regex ($inputs.url)
  {
    "/echo"
    {
      if ([string]::IsNullOrEmpty($inputs.Body) -or [string]::IsNullOrEmpty($inputs.Body.text))
      {
        $result = [PSCustomObject]@{
          ReturnCode = [Int][System.Net.HttpStatusCode]::BadRequest
          Content = "null or empty body"
          ContentType = "text/plain"
        }
      }
      else
      {
        $result = [PSCustomObject]@{
          ReturnCode = [Int][System.Net.HttpStatusCode]::OK
          Content = $inputs.Body.text
          ContentType = "text/plain"
        }
      }
    }

    "/addition/*"
    {
      if ($inputs.Parameters.op -match "\d+\+\d+")
      {
        $numbers = $inputs.Parameters.op.split('+')
        $add = [int]$numbers[0] + [int]$numbers[1]
        $result = [PSCustomObject]@{
          ReturnCode = [Int][System.Net.HttpStatusCode]::OK
          Content = "$add"
          ContentType = "text/plain"
        }
      }
      else
      {
        $result = [PSCustomObject]@{
          ReturnCode = [Int][System.Net.HttpStatusCode]::BadRequest
          Content = "Not an addition"
          ContentType = "text/plain"
        }
      }
    }

    "/invalid"
    {
      $result = [PSCustomObject]@{
        ReturnCode = ""
        Content = ""
        ContentType = "text/plain"
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
