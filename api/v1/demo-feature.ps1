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
        ReturnCode = 200
        Content = "Version 1.0.0"
      }
    }

    "/echo"
    {
      if ([string]::IsNullOrEmpty($inputs.Body) -or [string]::IsNullOrEmpty($inputs.Body.text))
      {
        $result = [PSCustomObject]@{
          ReturnCode = 400
          Content = "null or empty body"
        }
      }
      else
      {
        $result = [PSCustomObject]@{
          ReturnCode = 200
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
          ReturnCode = 200
          Content = "$add"
        }
      }
      else
      {
        $result = [PSCustomObject]@{
          ReturnCode = 400
          Content = "not an addition"
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
        ReturnCode = 404
        Content = "this endpoint is not managed by this API version"
      }
    }
  }
}
catch
{
  $result = [PSCustomObject]@{
    ReturnCode = 500
    Content = "Error while processing"
  }
}

return $result
