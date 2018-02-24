param (
  [Parameter(Mandatory=$true)]$inputs
)

$ErrorActionPreference = 'stop'
try
{
  switch -regex ($inputs.url)
  {
    "/version"
    {
      $result = [PSCustomObject]@{
        ReturnCode = [Int][System.Net.HttpStatusCode]::OK
        Content = "Version 1.0.0"
      }
    }

    "/echo"
    {
      if ([string]::IsNullOrEmpty($inputs.Body) -or [string]::IsNullOrEmpty($inputs.Body.text))
      {
        $result = [PSCustomObject]@{
          ReturnCode = [Int][System.Net.HttpStatusCode]::BadRequest
          Content = "null or empty body"
        }
      }
      else
      {
        $result = [PSCustomObject]@{
          ReturnCode = [Int][System.Net.HttpStatusCode]::OK
          Content = $inputs.Body.text
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
        }
      }
      else
      {
        $result = [PSCustomObject]@{
          ReturnCode = [Int][System.Net.HttpStatusCode]::BadRequest
          Content = "Not an addition"
        }
      }
    }

    "/invalid"
    {
      $result = [PSCustomObject]@{
        ReturnCode = ""
        Content = ""
      }
    }

    default
    {
      $result = [PSCustomObject]@{
        ReturnCode = [Int][System.Net.HttpStatusCode]::NotFound
        Content = "This endpoint is not managed by this API version"
      }
    }
  }
}
catch
{
  $result = [PSCustomObject]@{
    ReturnCode = [Int][System.Net.HttpStatusCode]::InternalServerError
    Content = "Error while processing"
  }
}

return $result
