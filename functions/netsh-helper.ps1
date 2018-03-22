
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
    [Parameter(Mandatory=$false)][String]$CertHash
  )

  begin
  {
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not ((New-Object Security.Principal.WindowsPrincipal $CurrentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)))
    {
      Write-Error -Message "Elevated privileges required" -ErrorAction Stop
    }
  }

  process
  {
    $guid = ([guid]::NewGuid()).guid

    if(!($CertHash))
    {
      $reg = Get-ItemProperty  HKLM:\system\CurrentControlSet\Services\tcpip\parameters 
      $dns = $reg.hostname + "." + $reg.'NV Domain'
      $CertHash = (New-SelfSignedCertificate -DnsName $dns -CertStoreLocation Cert:\LocalMachine\My).thumbprint
    }
    
    if (Get-ChildItem -path cert:\LocalMachine -recurse | where {$_.Thumbprint -eq $CertHash})
    {
      #Add-NetIPHttpsCertBinding -IpPort $IpPort -CertificateHash $Certhash -CertificateStoreName "My" -ApplicationId "{$guid}" -NullEncryption $false
      $netsh_cmd = "netsh http add sslcert ipport=""$IpPort"" certhash=""$CertHash"" appid=""{$guid}"" certstorename=""My"""
      Write-Verbose "Registering SSL certificate using $netsh_cmd"
      $result = Invoke-Expression -Command "$netsh_cmd"
    }
    else
    {
      Write-Error -Message "Unable to find certificate" -ErrorAction Stop
    }

    $result -match 'SSL certificate successfully added'
  }

  end {}
}


function Unregister-SSLCertificate
{
<#
  .SYNOPSIS
      Unregisters a SSL certificate
  .DESCRIPTION
      Requires elevated privileges to unregister a SSL certificate using netsh
  .PARAMETER IpPort
      The target IP/Port the certificate will be associated
  .INPUTS
      None
  .OUTPUTS
      None
#>

  [CmdletBinding()]

  param(
    [Parameter(Mandatory=$true)][String]$IpPort
  )

  begin
  {
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not ((New-Object Security.Principal.WindowsPrincipal $CurrentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)))
    {
      Write-Error -Message "Elevated privileges required" -ErrorAction Stop
    }
  }

  process
  {
    $netsh_cmd = "netsh http delete sslcert ipport=""$IpPort"""
    Write-Verbose "Unregistering SSL certificate using $netsh_cmd"
    $result = Invoke-Expression -Command "$netsh_cmd"
    $result -match 'SSL certificate successfully deleted'
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
      if ($Line -match 'URL.*\: (?<url>.*)')
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
    [Parameter(Mandatory=$false)][String]$User
  )

  begin
  {
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not ((New-Object Security.Principal.WindowsPrincipal $CurrentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)))
    {
      Write-Error -Message "Elevated privileges required" -ErrorAction Stop
    }
  }

  process
  {
    if ($User)
    {
      $netsh_cmd = "netsh http add urlacl url=$Prefix user=$User"
    }
    else
    {
      $netsh_cmd = "netsh http add urlacl url=$Prefix sddl=D:(A;;GA;;;WD)"
    }
    Write-Verbose "Registering URL prefix using $netsh_cmd"
    $result = Invoke-Expression -Command $netsh_cmd
    $result -match 'URL reservation successfully added'
  }

  end {}
}


function Unregister-URLPrefix
{
<#
  .SYNOPSIS
      Unregisters a URL Prefix
  .DESCRIPTION
      Requires elevated privileges to unregister a URL prefix using netsh
  .PARAMETER Prefix
      The prefix to unregister
  .INPUTS
      None
  .OUTPUTS
      None
#>

  [CmdletBinding()]

  param(
    [Parameter(Mandatory=$true)][String]$Prefix
  )

  begin
  {
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not ((New-Object Security.Principal.WindowsPrincipal $CurrentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)))
    {
      Write-Error -Message "Elevated privileges required" -ErrorAction Stop
    }
  }

  process
  {
    $netsh_cmd = "netsh http delete urlacl url=$Prefix"
    Write-Verbose "Unregistering URL prefix using $netsh_cmd"
    $result = Invoke-Expression -Command $netsh_cmd
    $result -match 'URL reservation successfully deleted'
  }

  end {}
}
