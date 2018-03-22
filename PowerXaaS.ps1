<#
  .SYNOPSIS
    PowerXaaS

  .DESCRIPTION
    Powershell module for exposing features "as a Service" through a HTTP server

  .LINK
    https://github.com/otabut/PowerXaaS

  .NOTES
    Author: Olivier TABUT
    1.5.0 release (08/04/2018)

  .PARAMETER Version
    Display this script version and exit

  .PARAMETER Status
    Get the current service status: Not installed / Stopped / Running

  .PARAMETER Setup
    Install the service
    Optionally use the -Credential argument to specify the user account for running the service
    By default, uses the LocalSystem account

  .PARAMETER Protocol
    Optionnal
    Protocol the server will use
    Default value is https
    
  .PARAMETER Ip
    Optionnal
    IP address the server will listen to
    Default value is localhost

  .PARAMETER Port
    Mandatory
    Port number the server will listen to

  .PARAMETER CertHash
    Optionnal
    The thumbprint of the certificate to use
    If omitted, a self-signed certificate will be generated 

  .PARAMETER WithoutAuth
    Switch to specify that authentification and role-based authorization should not be used

  .PARAMETER Customlogging
    Optionnal
    Switch to use custom logging function

  .PARAMETER Credential
    User and password credential to use for running the service
    For use with the -Setup command
    Generate a PSCredential variable with the Get-Credential command

  .PARAMETER Start
    Start the service

  .PARAMETER Stop
    Stop the service

  .PARAMETER Restart
    Stop then restart the service

  .PARAMETER Quiesce
    Quiesce transactions for given delay in seconds

  .PARAMETER Remove
    Uninstall the service

  .PARAMETER Service
    Run the service in the background. Used internally by the script
    Do not use, except for test purposes

  .PARAMETER Console
    Optionnal
    Switch to display logs on the console
    Do not use, except for test purposes
    
  .PARAMETER SCMStart
    Process Service Control Manager start requests
    Used internally by the script
    Do not use, except for test purposes

  .PARAMETER SCMStop
    Process Service Control Manager stop requests
    Used internally by the script
    Do not use, except for test purposes


  .EXAMPLE
    # Setup the service and run it for the first time
    C:\PS>.\PowerXaaS.ps1 -Status
    Not installed
    C:\PS>.\PowerXaaS.ps1 -Setup -Port 8087
    C:\PS>.\PowerXaaS.ps1 -Status
    Stopped
    C:\PS>.\PowerXaaS.ps1 -Start
    C:\PS>.\PowerXaaS.ps1 -Status
    Running

  .EXAMPLE
    # Stop the service and uninstall it.
    C:\PS>.\PowerXaaS.ps1 -Stop
    C:\PS>.\PowerXaaS.ps1 -Status
    Stopped
    C:\PS>.\PowerXaaS.ps1 -Remove
    C:\PS>.\PowerXaaS.ps1 -Status
    Not installed

  .EXAMPLE
    # Configure the service to run as a different user
    C:\PS>$cred = Get-Credential -UserName LAB\Assistant
    C:\PS>.\PowerXaaS.ps1 -Setup -Port 8087 -Credential $cred
#>

[CmdletBinding(DefaultParameterSetName='Status')]
Param(
  [Parameter(ParameterSetName='Version',Mandatory=$true)][Switch]$Version,                                              # Get this script version
  [Parameter(ParameterSetName='Status',Mandatory=$false)][Switch]$Status,                                               # Get the current service status
  [Parameter(ParameterSetName='Setup',Mandatory=$true)][Switch]$Setup,                                                  # Install the service
  [Parameter(ParameterSetName='Setup',Mandatory=$false)][ValidateSet("http","https")][string]$Protocol="https",         # Protocol the server will use
  [Parameter(ParameterSetName='Setup',Mandatory=$false)][string]$Ip="localhost",                                        # IP address the server will listen to
  [Parameter(ParameterSetName='Setup',Mandatory=$true)][string]$Port,                                                   # Port number the server will listen to
  [Parameter(ParameterSetName='Setup',Mandatory=$false)][string]$CertHash,                                              # The thumbprint of the certificate to use
  [Parameter(ParameterSetName='Setup',Mandatory=$false)][Switch]$WithoutAuth,                                           # Specify that authentification and role-based authorization should not be used  
  [Parameter(ParameterSetName='Setup',Mandatory=$false)][Switch]$CustomLogging,                                         # Switch to use custom logging function
  [Parameter(ParameterSetName='Setup',Mandatory=$false)][System.Management.Automation.PSCredential]$Credential,         # Service account credential
  [Parameter(ParameterSetName='Setup',Mandatory=$false)]
  [Parameter(ParameterSetName='Start',Mandatory=$true)][Switch]$Start,                                                  # Start the service
  [Parameter(ParameterSetName='Stop',Mandatory=$true)][Switch]$Stop,                                                    # Stop the service
  [Parameter(ParameterSetName='Restart',Mandatory=$true)][Switch]$Restart,                                              # Restart the service
  [Parameter(ParameterSetName='Remove',Mandatory=$true)][Switch]$Remove,                                                # Uninstall the service
  [Parameter(ParameterSetName='Quiesce',Mandatory=$true)][int]$Quiesce,                                                 # Quiesce
  [Parameter(ParameterSetName='Service',Mandatory=$true)][Switch]$Service,                                              # Run the service (Internal use only)
  [Parameter(ParameterSetName='Service',Mandatory=$false)][Switch]$Console,                                             # Displays log in console (Internal use only)
  [Parameter(ParameterSetName='SCMStart',Mandatory=$true)][Switch]$SCMStart,                                            # Process SCM Start requests (Internal use only)
  [Parameter(ParameterSetName='SCMStop',Mandatory=$true)][Switch]$SCMStop                                               # Process SCM Stop requests (Internal use only)
)

### GLOBAL SETTINGS ###

# This script name, with various levels of details
$ScriptVersion = "1.5.0"
$argv0 = Get-Item $MyInvocation.MyCommand.Definition
$Script = $argv0.basename                                         # Ex: PowerXaaS
$ScriptName = $argv0.name                                         # Ex: PowerXaaS.ps1
$ScriptFullName = $argv0.fullname                                 # Ex: C:\Temp\PowerXaaS.ps1

# Service management
$ServiceName = $Script                                            # A one-word name used for net start commands
$ServiceDisplayName = $Script
$ServiceDescription = "Exposes features as REST API"

# Thread management
$PSThreadCount = 0                                                # Counter of PSThread IDs generated so far
$PSThreadList = @{}                                               # Existing PSThreads indexed by Id
$pipeThreadName = "ControlPipeHandler"
$pipeName = "Service_$ServiceName"                                # Named pipe name. Used for sending messages to the service task

# Directories and files
$InstallDir = "${ENV:ProgramFiles}\$ServiceName"                  # Where to install the service files
$ScriptCopy = "$InstallDir\$ScriptName"
$ScriptCopyCname = $ScriptCopy -replace "\\", "\\"                # Double backslashes. (The first \\ is a regexp with \ escaped; The second is a plain string.)
$exeName = "$ServiceName.exe"
$exeFullName = "$InstallDir\$exeName"
$logDir = $InstallDir
$logFile = "$logDir\$ServiceName.log"

# Miscellanious
$LogName = "Application"                                          # Event Log name (Unrelated to the logFile!)
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()    # Identify the user name. We use that for logging.
$CurrentUserName = $Identity.Name                                 # Ex: "NT AUTHORITY\SYSTEM" or "Domain\Administrator"

# Redefine scope of parameters used by logging function
$Global:LogFile = $LogFile
$Global:Console = $Console
$Global:CustomLogging = $CustomLogging


### LOAD FUNCTIONS ###
. $PSScriptRoot\functions\PowerXaaS-helper.ps1                    # Call helper script which contains thread management functions
. $PSScriptRoot\functions\netsh-helper.ps1                        # Call helper script which contains netsh related functions
. $PSScriptRoot\functions\Write-Log.ps1                           # Call logging function
. $PSScriptRoot\functions\Start-CustomLogging.ps1                 # Call custom logging function
. $PSScriptRoot\functions\Receive-Request.ps1                     # Call main function
. $PSScriptRoot\functions\Request-Authorization.ps1               # Call authorization function


### MAIN ###

# The following commands write to the event log, but we need to make sure the PowerXaaS source is defined.
New-EventLog -LogName $LogName -Source $ServiceName -ErrorAction SilentlyContinue

if ($Version)          # If the -Version switch is specified, display the script version and exit.
{
  return $ScriptVersion
}

if ($Setup)            # Install the service
{
  # Check if it's necessary
  try
  {
    $pss = Get-Service $ServiceName -ErrorAction stop # Will error-out if not installed
    # Check if this script is newer than the installed copy.
    if (((Get-Item $ScriptCopy -ErrorAction SilentlyContinue).LastWriteTime -lt (Get-Item $ScriptFullName -ErrorAction SilentlyContinue).LastWriteTime) -or ((Get-ItemProperty -Path HKLM:\Software\PowerXaaS -Name Bindings).Bindings) -notmatch $ip)
    {
      Write-Output "Service $ServiceName is already Installed, but requires upgrade"
      & $ScriptFullName -Remove
      throw "continue"
    }
    else
    {
      Write-Output "Service $ServiceName is already Installed, and up-to-date"
    }
    exit 0
  }
  catch
  {
    # This is the normal case here. Do not throw or write any error! And continue with the installation.
    Write-Output "Starting installation..." # Also avoids a ScriptAnalyzer warning
  }
  
  # Copy the sources into the installation directory
  try
  {
    # Create the installation directory if it doesn't exist
    if (!(Test-Path $InstallDir))
    {
      New-Item -ItemType directory -Path $InstallDir -ErrorAction stop | Out-Null
    }
    if (!(Test-Path "$InstallDir\logs"))
    {
      New-Item -ItemType directory -Path "$InstallDir\logs" -ErrorAction stop | Out-Null
    }
    if ($ScriptFullName -ne $ScriptCopy)
    {
      Write-Output "Copying files"
      Copy-Item -Path $PSScriptRoot\PowerXaaS.* -Destination $InstallDir
      Copy-Item -Path $PSScriptRoot\functions -Recurse -Destination $InstallDir -Container
      Copy-Item -Path $PSScriptRoot\api -Recurse -Destination $InstallDir -Container
      Write-Output "Copying Powershell module"
      if (!(Test-Path "${ENV:ProgramFiles}\WindowsPowerShell\Modules\$Script"))
      {
        New-Item -ItemType directory -Path "${ENV:ProgramFiles}\WindowsPowerShell\Modules\$Script" -ErrorAction stop | Out-Null
      }
      Copy-Item -Path $PSScriptRoot\module\*.* -Destination "${ENV:ProgramFiles}\WindowsPowerShell\Modules\$Script"
      Copy-Item -Path $PSScriptRoot\module\functions -Recurse -Destination "${ENV:ProgramFiles}\WindowsPowerShell\Modules\$Script" -Container
    }
  }
  catch
  {
    Write-Error "Failed to copy files to installation directory. Please check rights."
    exit 1
  }

  # Generate the service .EXE from the C# source embedded in this script
  try
  {
    Write-Output "Compiling $exeFullName"
    Add-Type -TypeDefinition $source -Language CSharp -OutputAssembly $exeFullName -OutputType ConsoleApplication -ReferencedAssemblies "System.ServiceProcess" -Debug:$false
  }
  catch
  {
    $msg = $_.Exception.Message
    Write-error "Failed to create the $exeFullName service stub. $msg"
    exit 1
  }
  
  # Set some registry keys
  [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$InstallDir", [EnvironmentVariableTarget]::Machine)
  New-Item -Path HKLM:\Software\PowerXaaS -Force | Out-Null
  New-ItemProperty -Path HKLM:\Software\PowerXaaS -Name Bindings -Value "$protocol`://$ip`:$port/" -PropertyType String -Force | Out-Null
  New-ItemProperty -Path HKLM:\Software\PowerXaaS -Name TokenLifetime -Value "4" -PropertyType String -ErrorAction SilentlyContinue | Out-Null    # value in hours
  New-ItemProperty -Path HKLM:\Software\PowerXaaS -Name LogSize -Value "2" -PropertyType String -ErrorAction SilentlyContinue | Out-Null          # value in Mb
  if ($WithoutAuth.IsPresent)
  { New-ItemProperty -Path HKLM:\Software\PowerXaaS -Name WithoutAuth -Value "True" -PropertyType String -Force | Out-Null }
  else
  { New-ItemProperty -Path HKLM:\Software\PowerXaaS -Name WithoutAuth -Value "False" -PropertyType String -Force | Out-Null }
  
  # Configure HTTP server
  Write-Output "Configuring HTTP server"
  $IpPort = "$ip`:$port"
  $Url = "$Protocol`://$IpPort/"
  Register-URLPrefix -Prefix $Url | Out-Null
  if (!(Get-URLPrefix | Where-Object {$_.url -eq $Url}))
  {
    Write-error "Failed to create the bindings"
    exit 1
  }
  if ($Protocol -eq 'https')
  {
    Write-Output "Registering SSL certificate"
    if ($CertHash)
    {
      Register-SSLCertificate -IpPort $IpPort -CertHash $CertHash | Out-Null
    }
    else
    {
      Register-SSLCertificate -IpPort $IpPort | Out-Null
    }
    if (!(Get-SSLCertificate | Where-Object {$_.IpPort -eq $IpPort}))
    {
      Write-error "Failed to associate the SSL certificate"
      exit 1
    }
  }
  
  # Register the service
  Write-Output "Registering service $ServiceName"
  if ($Credential.UserName)
  {
    Write-Log -Status "Information" -Context "Setup" -Description "Configuring the service to run as $($Credential.UserName)"
    $pss = New-Service $ServiceName $exeFullName -DisplayName $ServiceDisplayName -Description $ServiceDescription -StartupType Automatic -Credential $Credential
  }
  else
  {
    Write-Log -Status "Information" -Context "Setup" -Description "Configuring the service to run by default as LocalSystem"
    $pss = New-Service $ServiceName $exeFullName -DisplayName $ServiceDisplayName -Description $ServiceDescription -StartupType Automatic
  }
}

if ($Remove)           # Uninstall the service
{
  # Check if it's necessary
  try
  {
    $pss = Get-Service $ServiceName -ErrorAction stop # Will error-out if not installed
    Write-Output "Stopping service $ServiceName"
    Stop-Service $ServiceName  # Make sure it's stopped
    Write-Output "Removing service $ServiceName"
    $msg = sc.exe delete $ServiceName  # In the absence of a Remove-Service applet, use sc.exe instead.
    if ($LastExitCode)
    {
      Write-Error "Failed to remove the service ${ServiceName}: $msg"
      exit 1
    }
  }
  catch
  {
    Write-Output "Service already uninstalled"
  }
  
  # Unconfigure HTTP server
  Write-Output "Unconfiguring HTTP server"
  $Bindings = (Get-ItemProperty -Path HKLM:\Software\PowerXaaS -Name Bindings).Bindings
  $IpPort = $Bindings.split('/')[2]
  Unregister-URLPrefix -Prefix $Bindings | Out-Null
  Unregister-SSLCertificate -IpPort $IpPort | Out-Null

  # Remove the installed files
  if (Test-Path $InstallDir)
  {
    Write-Output "Deleting files"
    Remove-Item $InstallDir -Recurse -Exclude *.log,*.conf -ErrorAction silentlyContinue
    Remove-Item "${ENV:ProgramFiles}\WindowsPowerShell\Modules\$Script" -Recurse -ErrorAction silentlyContinue
  }
  [Environment]::SetEnvironmentVariable("Path", $env:Path.replace(";$InstallDir",""), [EnvironmentVariableTarget]::Machine)
  return
}

if ($SCMStart)         # The SCM tells us to start the service
{
  Write-Log -Status "Information" -Context "SCMStart" -Description "Starting script '$ScriptFullName' -Service"
  Write-EventLog -LogName $LogName -Source $ServiceName -EventId 1001 -EntryType Information -Message "SCMStart: Starting script '$ScriptFullName' -Service"
  Start-Process PowerShell.exe -ArgumentList ("-c & '$ScriptFullName' -Service") -WorkingDirectory $InstallDir
  return
}

if ($Start)            # The user tells us to start the service. This block must be placed after setup block in case the user asked to start the service just after setup.
{
  try
  {
    $pss = Get-Service $ServiceName -ErrorAction stop  # Will error-out if not installed
    Write-Log -Status "Information" -Context "Start" -Description "Starting service $ServiceName" -ErrorAction SilentlyContinue
    Write-EventLog -LogName $LogName -Source $ServiceName -EventId 1002 -EntryType Information -Message "Start: Starting service $ServiceName"
    Start-Service $ServiceName  # Ask Service Control Manager to start it
    return
  }
  catch
  {
    return "Not Installed"
  }
}

if ($SCMStop)          # The SCM tells us to stop the service
{
  try
  {
    $pss = Get-Service $ServiceName -ErrorAction stop  # Will error-out if not installed
    Write-Log -Status "Information" -Context "SCMStop" -Description "Sending exit message to the event queue"
    Write-EventLog -LogName $LogName -Source $ServiceName -EventId 1003 -EntryType Information -Message "SCMStop: Sending exit message to the event queue"
    Send-PipeMessage $pipeName "exit"
    return
  }
  catch
  {
    return "Not Installed"
  }
}

if ($Stop)             # The user tells us to stop the service
{
  Write-Log -Status "Information" -Context "Stop" -Description "Stopping service $ServiceName" -ErrorAction SilentlyContinue
  Write-EventLog -LogName $LogName -Source $ServiceName -EventId 1004 -EntryType Information -Message "Stop: Stopping service $ServiceName"
  Stop-Service $ServiceName  # Ask Service Control Manager to stop it
  return
}

if ($Restart)          # Restart the service
{
  Write-Log -Status "Information" -Context "Restart" -Description "Restarting service $ServiceName"
  & $ScriptFullName -Stop
  & $ScriptFullName -Start
  return
}

if ($Quiesce)          # Quiesce
{
  Write-Log -Status "Information" -Context "Quiesce" -Description "Quiesce for $Quiesce seconds has been required"
  Write-EventLog -LogName $LogName -Source $ServiceName -EventId 1003 -EntryType Information -Message "Quiesce: Sending pause message to the event queue"
  Send-PipeMessage $pipeName "pause.$Quiesce"
  return
}

if ($Status)           # Get the current service status
{
  $spid = $null
  $processes = @(Get-WmiObject Win32_Process -filter "Name = 'powershell.exe'" | Where-Object { $_.CommandLine -match ".*$ScriptCopyCname.*-Service" })
  foreach ($process in $processes) # There should be just one, but be prepared for surprises.
  {
    $spid = " - pid: $($process.ProcessId)"
  }
  try
  {
    $pss = Get-Service $ServiceName -ErrorAction stop  # Will error-out if not installed
  }
  catch
  {
    return "Not Installed"
  }
  if (($pss.Status -eq "Running") -and (!$spid))  # This happened during the debugging phase
  {
    Write-Host "The Service Control Manager thinks $ServiceName is started, but $ServiceName.ps1 -Service is not running." -ForegroundColor Red
    exit 1
  }
  if (($pss.Status -eq "Stopped") -and ($spid))   # This happened during the debugging phase
  {
    Write-Host "The Service Control Manager thinks $ServiceName is stopped, but $ServiceName.ps1 -Service is running." -ForegroundColor Red
    exit 1
  }
  return "$($pss.Status)$spid"
}

if ($Service)          # Run the service as a background job
{
  Write-Log -Status "Information" -Context "Service" -Description $MyInvocation.Line   # The exact command line that was used to start us
  Write-EventLog -LogName $LogName -Source $ServiceName -EventId 1005 -EntryType Information -Message "Service: Beginning background job"
  try
  {
    # Start the control pipe handler thread
    $pipeThread = Start-PipeHandlerThread $pipeName -Event "ControlMessage"
    # Start Web Server
    $Listener = New-Object System.Net.HttpListener
    $Bindings = (Get-ItemProperty -Path HKLM:\Software\PowerXaaS -Name Bindings).Bindings
    $Listener.Prefixes.Add($Bindings)
    $Listener.Start()  # Start listening
    Write-Log -Status "Information" -Context "HTTPD" -Description "Server started listening on $bindings"
    $RequestID = 1
    $Context = $null
    $Task = $Listener.GetContextAsync()  # Listen (Async)
    # Now enter the main service event loop
    do   # Keep running until told to exit by the -Stop handler
    {
      if ($Task.Wait(100))
      {
        $Context = $Task.Result  # Get context, if any
        if ($Context)
        {
          Write-Log -Status "Information" -Context "Service" -Description "------------------------------------------------"  # Insert one line to separate client request logs
          Write-Log -Status "Information" -Context "HTTPD" -Description "#### Client request $RequestID has been received ####"
          Receive-Request -RequestId $RequestID -Context $Context
          Write-Log -Status "Information" -Context "HTTPD" -Description "#### Client response $RequestID has been sent ####"
          $RequestID++
          $Context = $null
          $Task = $Listener.GetContextAsync()  # Listen (Async)
        }
        else
        {
          if (Test-Path .\pause.*)  # Pause condition
          {
            $Delay = (get-item .\pause.*).Extension.substring(1)
            Write-Log -Status "Warning" -Context "HTTPD" -Description "Server has been paused for $delay seconds"
            Start-Sleep -Seconds $Delay
            Remove-Item .\pause.*
            Write-Log -Status "Warning" -Context "HTTPD" -Description "Server has resumed"
          }
        }
      }
      $EventQueue = Get-Event
      if ($EventQueue)  # Get the next incoming event
      {
        $Event = ($EventQueue | sort TimeGenerated)[0]
        $EventId = $Event.EventIdentifier
        $Source = $Event.SourceIdentifier
        $Message = $Event.MessageData
        $EventTime = $Event.TimeGenerated.TimeofDay
        #Write-Log -Status "Information" -Context "Service" -Description "Event at $EventTime from ${Source}: $Message"
        $event | Remove-Event  # Flush the event from the queue
        switch ($Source)
        {
          $pipeThreadName
          {
            switch ($message)
            {
              "ControlMessage"  # Required. Message received by the control pipe thread
              {
                $State = $Event.SourceEventArgs.InvocationStateInfo.state
                #Write-Log -Status "Information" -Context "Service" -Description "Thread $Source state changed to $State"
                switch ($state)
                {
                  "Completed"
                  {
                    $Message = Receive-PipeHandlerThread $pipeThread
                    Write-Log -Status "Information" -Context "Service" -Description "Received control message: $Message"
                    if ($Message -match "Pause")
                    {
                      $Delay = $Message.split('.')[1]
                      Write-Log -Status "Warning" -Context "HTTPD" -Description "Server has been paused for $delay seconds"
                      Start-Sleep -Seconds $Delay
                      Write-Log -Status "Warning" -Context "HTTPD" -Description "Server has resumed"
                    }
                    if ($Message -ne "exit")
                    {
                      $pipeThread = Start-PipeHandlerThread $pipeName -Event "ControlMessage"  # Start another thread waiting for control messages
                    }
                  }
                  "Failed"
                  {
                    $Error = Receive-PipeHandlerThread $pipeThread
                    Write-Log -Status "Information" -Context "Service" -Description "$Source thread failed: $Error"
                    Start-Sleep 1  # Avoid getting too many errors
                    $pipeThread = Start-PipeHandlerThread $pipeName -Event "ControlMessage"  # Retry
                  }
                  default  # Should not happen
                  {
                    Write-Log -Status "Information" -Context "Service" -Description "Unexpected state $State from ${source}: $Message"
                  }
                }
              }
              default  # Should not happen
              {
                Write-Log -Status "Information" -Context "Service" -Description "Unexpected event from ${Source}: $Message"
              }
            }
          }
          default  # Should not happen
          {
            Write-Log -Status "Information" -Context "Service" -Description "Unexpected source ${Source}"
          }
        }
      }
    }
    While ($Message -ne "exit")
    Write-Log -Status "Information" -Context "Service" -Description "Exit command has been received"
  }
  catch  # An exception occurred while runnning the service
  {
    $msg = $_.Exception.Message
    $line = $_.InvocationInfo.ScriptLineNumber
    Write-Log -Status "Information" -Context "Service" -Description "Error at line ${line}: $msg"
  }
  finally   # Invoked in all cases: Exception or normally by -Stop
  {
    # Stop listening
    $Listener.Stop()
    Write-Log -Status "Warning" -Context "HTTPD" -Description "Server has stopped listening"
    
    # Remove all remaining threads and events
    Get-PSThread | Remove-PSThread  
    $events = Get-Event | Remove-Event  # Flush all leftover events (There may be some that arrived after we exited the while event loop, but before we unregistered the events)
    Write-Log -Status "Information" -Context "Service" -Description "Threads and events are flushed"

    # Log a termination event, no matter what the cause is.
    Write-EventLog -LogName $LogName -Source $ServiceName -EventId 1006 -EntryType Information -Message "Service: Exiting"
    Write-Log -Status "Information" -Context "Service" -Description "Exiting"

    exit
  }
}
