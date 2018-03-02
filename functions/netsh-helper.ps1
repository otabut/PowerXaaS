
function Get-SSLCertificate
{
<#
  .SYNOPSIS
      Gets registered SSL certificates
  .DESCRIPTION
      Gets the registered SSL certificates using netsh
  .INPUTS
      None
  .OUTPUTS
      PSObject
#>

  [CmdletBinding()]

  param()

  begin {}

  process
  {
    $LastLine = $false
    $netsh_cmd = "netsh http show sslcert"
    $result = Invoke-Expression -Command $netsh_cmd

    ForEach ($Line in $result)
    {
      if ($Line -match 'IP:port\s+\: (?<IpPort>.*)')
      {
        $IpPort = $matches.IpPort
      }
      elseif ($Line -match 'Certificate Hash\s+\: (?<CertHash>.*)')
      {
        $CertHash = $matches.CertHash
      }
      elseif ($Line -match 'Application ID\s+\: (?<AppId>.*)')
      {
        $AppId = $matches.AppId
      }
      elseif ($Line -match 'Certificate Store Name\s+\: (?<StoreName>.*)')
      {
        $StoreName = $matches.StoreName
        $LastLine = $true
      }
                 
      if ($LastLine)
      {
        [PSCustomObject]@{
          'IpPort' = $IpPort.Trim()
          'CertHash' = $CertHash.Trim()
          'AppId' = $AppId.Trim()
          'StoreName' = $StoreName.Trim()
        }
        $LastLine = $false
      }
    }
  }

  end {}
}


function Register-SSLCertificate
{
<#
  .SYNOPSIS
      Registers a SSL certificate
  .DESCRIPTION
      Requires elevated privileges to register a SSL certificate using netsh
  .PARAMETER IpPort
      The target IP/Port the certificate will be associated
  .PARAMETER CertHash
      The thumbprint of the certificate
  .INPUTS
      None
  .OUTPUTS
      None
#>

  [CmdletBinding()]

  param(
    [Parameter(Mandatory=$true)][String]$IpPort,
    [Parameter(Mandatory=$true)][String]$CertHash
  )

  begin
  {
    if (-not (Test-IsAdministrator))
    {
      Write-Error -Message  "Elevated privileges required" -ErrorAction Stop
    }
  }

  process
  {
    $guid = ([guid]::NewGuid()).guid
    
    if (Get-ChildItem -path cert:\LocalMachine -recurse | where {$_.Thumbprint -eq $CertHash})
    {
      #$CertHash = (New-SelfSignedCertificate -DnsName <yourdnsname> -CertStoreLocation Cert:\LocalMachine\My).thumbprint
      #Add-NetIPHttpsCertBinding -IpPort $IpPort -CertificateHash $Certhash -CertificateStoreName "My" -ApplicationId "{$guid}" -NullEncryption $false
      $netsh_cmd = 'netsh http add sslcert ipport="$IpPort" certhash="$CertHash" appid="{$guid}"'
      Write-Verbose "Registering SSL certificate using $netsh_cmd"
      $result = Invoke-Expression -Command "$netsh_cmd"
    }
    else
    {
      Write-Error -Message  "Unable to find certificate" -ErrorAction Stop
    }

    $result -match 'SSL certificate successfully added'
  }

  end {}
}


function Get-URLPrefix
{
<#
  .SYNOPSIS
      Gets registered URL Prefixes
  .DESCRIPTION
      Gets the registered URL Prefixes using netsh
  .INPUTS
      None
  .OUTPUTS
      PSObject
#>

  [CmdletBinding()]

  param(
    [Parameter(Mandatory=$false)][String]$Filter
  )

  begin {}

  process
  {
    $netsh_cmd = "netsh http show urlacl"
    $result = Invoke-Expression -Command $netsh_cmd

    $info = @()
    ForEach ($Line in $result)
    {
      if ($Line -match 'Reserved URL\s+\: (?<url>.*)')
      {
        $url = $matches.url
      }
      elseif ($Line -match 'User\: (?<user>.*)')
      {
        $user = $matches.user

        $info += [PSCustomObject]@{
          'URL' = $url.Trim()
          'User' = $user.Trim()
        }
      }
    }

    if ($Filter)
    {
      $Info | Where-Object {$_.url -match $Filter}
    }
    else
    {
      $Info
    }

  }

  end {}
}


function Register-URLPrefix
{
<#
  .SYNOPSIS
      Registers a URL Prefix
  .DESCRIPTION
      Requires elevated privileges to register a URL prefix using netsh
  .PARAMETER Prefix
      The prefix to register
  .PARAMETER User
      The user (DOMAIN\User) to register the prefix for
  .INPUTS
      None
  .OUTPUTS
      None
#>

  [CmdletBinding()]

  param(
    [Parameter(Mandatory=$true)][String]$Prefix,
    [Parameter()][String]$User=(Get-CurrentUserName)
  )

  begin
  {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not ((New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)))
    {
      Write-Error -Message  "Elevated privileges required." -ErrorAction Stop
    }
  }

  process
  {
    $netsh_cmd = "netsh http add urlacl url=$Prefix user=$User"
    Write-Verbose "Registering URL prefix using $netsh_cmd"
    $result = Invoke-Expression -Command $netsh_cmd
    $result -match 'URL reservation successfully added'
  }

  end {}
}
