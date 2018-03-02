Function Get-PXEndpoint
{
  param (
    [Parameter(Mandatory=$false)]$Feature,
    [Parameter(Mandatory=$false)][ValidateSet("GET","POST","PUT","PATCH","DELETE")]$Method,
    [Parameter(Mandatory=$false)]$Url,
    [Parameter(Mandatory=$false)][switch]$Active
  )

  $ErrorActionPreference = "stop"
  try
  {
    $ConfigurationFile = "${ENV:ProgramFiles}\PowerXaaS\PowerXaaS.conf"
    $Config = (Get-Content $ConfigurationFile | ConvertFrom-Json).features | select -ExpandProperty endpoints -Property @{Label="feature";Expression={$_.Name}}, active

    if ($Feature)
    {
      $Config = $Config | where {$_.Feature -eq $Feature}
    }
    if ($Method)
    {
      $Config = $Config | where {$_.Method -eq $Method}
    }
    if ($Url)
    {
      $Config = $Config | where {$_.Url -eq $Url}
    }
    if ($Active.IsPresent)
    {
      $Config = $Config | where {$_.Active -eq 'yes'}
    }

    Return $Config
  }
  catch
  {
    $ErrorMessage = $_.Exception.Message
    $ErrorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Error "Error on line $ErrorLine. The error message was: $ErrorMessage"
  }
}
