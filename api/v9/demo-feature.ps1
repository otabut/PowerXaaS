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
        Content = "Version 9.0.0"
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
