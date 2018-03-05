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
  $result = [PSCustomObject]@{
    ReturnCode = [Int][System.Net.HttpStatusCode]::InternalServerError
    Content = "Error while processing"
    ContentType = "text/plain"
  }
}

return $result
