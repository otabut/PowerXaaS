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
        Content = "Version 9.0.0"
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
