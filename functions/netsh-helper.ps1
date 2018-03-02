
function Get-SSLCertificate {
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



function Register-SSLCertificate {
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
      Write-Error -Message  "Elevated privileges required." -ErrorAction Stop
    }
  }

  process
  {
    $guid = ([guid]::NewGuid()).guid
    #$CertHash = (New-SelfSignedCertificate -DnsName <yourdnsname> -CertStoreLocation Cert:\LocalMachine\My).thumbprint
    $netsh_cmd = "netsh http add sslcert ipport=$IpPort certhash=$CertHash appid={$guid}"
    Add-NetIPHttpsCertBinding -IpPort $IpPort -CertificateHash $Certhash -CertificateStoreName "My" -ApplicationId "{$guid}" -NullEncryption $false

    Write-Verbose "Registering SSL certificate using $netsh_cmd"
    $result = Invoke-Expression -Command "$netsh_cmd"

    $result -match 'SSL certificate successfully added'
  }

  end {}
}



function Get-URLPrefix {
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

    param()

    begin {}

    process {
        $netsh_cmd = "netsh http show urlacl"

        $result = Invoke-Expression -Command $netsh_cmd

        $result |
            ForEach-Object {
                if ($_ -match 'Reserved URL\s+\: (?<url>.*)') {
                    $url = $matches.url
                } elseif ($_ -match 'User\: (?<user>.*)') {
                    $user = $matches.user
                    
                    New-Object -TypeName PSObject -Property @{
                        'URL' = $url.Trim()
                        'User' = $user.Trim()
                    }
                }
            }
    }

    end {}

}



function Register-URLPrefix {
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

    param([Parameter(Mandatory=$true)]
          [String]$Prefix,
          [Parameter()]
          [String]$User=(Get-CurrentUserName)
    )

    begin {
        if (-not (Test-IsAdministrator)) {
            Write-Error -Message  "Elevated privileges required." -ErrorAction Stop
        }
    }

    process {
        $netsh_cmd = "netsh http add urlacl url=$Prefix user=$User"

        Write-Verbose "Registering URL prefix using $netsh_cmd"
        $result = Invoke-Expression -Command $netsh_cmd

        $result -match 'URL reservation successfully added'
    }

    end {}
}



function Test-IsAdministrator {
<#
    .SYNOPSIS
        Tests whether the user is an admistrator.
    
    .DESCRIPTION
        Tests whether the current user is an administrator
    .INPUTS
        None
    .OUTPUTS
        Boolean
#>
    [CmdletBinding()]

    param(
    )

    begin {

    }

    process {
        $user = [Security.Principal.WindowsIdentity]::GetCurrent()
        (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }

    end {}
}
