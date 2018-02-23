<#
  .SYNOPSIS
    PowerXaaS

  .DESCRIPTION
    Powershell module for exposing features "as a Service" through a HTTP server

  .LINK
    https://github.com/otabut/PowerXaaS

  .NOTES
    Author: Olivier TABUT
    1.2.0 release (24/02/2018)

  .PARAMETER Version
    Display this script version and exit

  .PARAMETER Status
    Get the current service status: Not installed / Stopped / Running

  .PARAMETER Setup
    Install the service
    Optionally use the -Credential argument to specify the user account for running the service
    By default, uses the LocalSystem account

  .PARAMETER Ip
    Optionnal
    IP address the server will listen to
    Default value is localhost

  .PARAMETER Port
    Mandatory
    Port number the server will listen to

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
    Quiesce transactions for a given delay

  .PARAMETER Delay
    Mandatory
    Delay in seconds

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
  [Parameter(ParameterSetName='Setup',Mandatory=$false)][string]$Ip="localhost",                                        # IP address the server will listen to
  [Parameter(ParameterSetName='Setup',Mandatory=$true)][string]$Port,                                                   # Port number the server will listen to
  [Parameter(ParameterSetName='Setup',Mandatory=$false)][Switch]$CustomLogging,                                         # Switch to use custom logging function
  [Parameter(ParameterSetName='Setup',Mandatory=$false)][System.Management.Automation.PSCredential]$Credential,         # Service account credential
  [Parameter(ParameterSetName='Start',Mandatory=$true)][Switch]$Start,                                                  # Start the service
  [Parameter(ParameterSetName='Stop',Mandatory=$true)][Switch]$Stop,                                                    # Stop the service
  [Parameter(ParameterSetName='Restart',Mandatory=$true)][Switch]$Restart,                                              # Restart the service
  [Parameter(ParameterSetName='Remove',Mandatory=$true)][Switch]$Remove,                                                # Uninstall the service
  [Parameter(ParameterSetName='Quiesce',Mandatory=$true)][Switch]$Quiesce,                                              # Quiesce
  [Parameter(ParameterSetName='Quiesce',Mandatory=$true)][int]$Delay,                                                   # Delay
  [Parameter(ParameterSetName='Service',Mandatory=$true)][Switch]$Service,                                              # Run the service (Internal use only)
  [Parameter(ParameterSetName='Service',Mandatory=$false)][Switch]$Console,                                             # Displays log in console (Internal use only)
  [Parameter(ParameterSetName='SCMStart',Mandatory=$true)][Switch]$SCMStart,                                            # Process SCM Start requests (Internal use only)
  [Parameter(ParameterSetName='SCMStop',Mandatory=$true)][Switch]$SCMStop                                               # Process SCM Stop requests (Internal use only)
)

### GLOBAL SETTINGS ###

# This script name, with various levels of details
$scriptVersion = "1.2.0"
$argv0 = Get-Item $MyInvocation.MyCommand.Definition
$script = $argv0.basename                                         # Ex: PowerXaaS
$scriptName = $argv0.name                                         # Ex: PowerXaaS.ps1
$scriptFullName = $argv0.fullname                                 # Ex: C:\Temp\PowerXaaS.ps1

# Service management
$serviceName = $script                                            # A one-word name used for net start commands
$serviceDisplayName = $script
$ServiceDescription = "Exposes features as REST API"

# Thread management
$PSThreadCount = 0                                                # Counter of PSThread IDs generated so far
$PSThreadList = @{}                                               # Existing PSThreads indexed by Id
$pipeThreadName = "ControlPipeHandler"
$pipeName = "Service_$serviceName"                                # Named pipe name. Used for sending messages to the service task

# Directories and files
$installDir = "${ENV:ProgramFiles}\$serviceName"                  # Where to install the service files
$scriptCopy = "$installDir\$scriptName"
$scriptCopyCname = $scriptCopy -replace "\\", "\\"                # Double backslashes. (The first \\ is a regexp with \ escaped; The second is a plain string.)
$exeName = "$serviceName.exe"
$exeFullName = "$installDir\$exeName"
$logDir = $installDir
$logFile = "$logDir\$serviceName.log"

# Miscellanious
$logName = "Application"                                          # Event Log name (Unrelated to the logFile!)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()    # Identify the user name. We use that for logging.
$currentUserName = $identity.Name                                 # Ex: "NT AUTHORITY\SYSTEM" or "Domain\Administrator"

# Redefine scope of parameters used by logging function
$Global:LogFile = $LogFile
$Global:Console = $Console
$Global:CustomLogging = $CustomLogging


### LOAD FUNCTIONS ###
. $PSScriptRoot\functions\private\PowerXaaS-helper.ps1            # Call helper script which contains thread management functions
. $PSScriptRoot\functions\private\Write-PXLog.ps1                 # Call logging function
. $PSScriptRoot\functions\private\Start-PXCustomLogging.ps1       # Call custom logging function
. $PSScriptRoot\functions\private\Receive-PXRequest.ps1           # Call main function
. $PSScriptRoot\functions\private\Request-PXAuthorization.ps1     # Call authorization function


### MAIN ###

if ($Version) {         # If the -Version switch is specified, display the script version and exit.
  Write-Host $scriptVersion
  return
}

# The following commands write to the event log, but we need to make sure the PowerXaaS source is defined.
New-EventLog -LogName $logName -Source $serviceName -ErrorAction SilentlyContinue

if ($SCMStart) {        # The SCM tells us to start the service
  Write-PXLog -Status "Information" -Context "SCMStart" -Description "Starting script '$scriptFullName' -Service"
  Write-EventLog -LogName $logName -Source $serviceName -EventId 1001 -EntryType Information -Message "$scriptName -SCMStart: Starting script '$scriptFullName' -Service"
  Start-Process PowerShell.exe -ArgumentList ("-c & '$scriptFullName' -Service") -WorkingDirectory $installDir
  return
}

if ($Start) {           # The user tells us to start the service
  Write-PXLog -Status "Information" -Context "Start" -Description "Starting service $serviceName"
  Write-EventLog -LogName $logName -Source $serviceName -EventId 1002 -EntryType Information -Message "$scriptName -Start: Starting service $serviceName"
  Start-Service $serviceName # Ask Service Control Manager to start it
  return
}

if ($SCMStop) {         # The SCM tells us to stop the service
  Write-PXLog -Status "Information" -Context "SCMStop" -Description "Sending exit message to the event queue"
  Write-EventLog -LogName $logName -Source $serviceName -EventId 1003 -EntryType Information -Message "$scriptName -SCMStop: Sending exit message to the event queue"
  Send-PipeMessage $pipeName "exit"
  return
}

if ($Stop) {            # The user tells us to stop the service
  Write-PXLog -Status "Information" -Context "Stop" -Description "Stopping service $serviceName"
  Write-EventLog -LogName $logName -Source $serviceName -EventId 1004 -EntryType Information -Message "$scriptName -Stop: Stopping service $serviceName"
  Stop-Service $serviceName # Ask Service Control Manager to stop it
  return
}

if ($Restart) {         # Restart the service
  Write-PXLog -Status "Information" -Context "Restart" -Description "Restarting service $serviceName"
  & $scriptFullName -Stop
  & $scriptFullName -Start
  return
}

if ($Quiesce) {         # Quiesce
  Write-PXLog -Status "Information" -Context "Quiesce" -Description "Quiesce for $delay seconds has been required"
  "" > "$installDir\pause.$delay"
  return
}

if ($Status) {          # Get the current service status
  $spid = $null
  $processes = @(Get-WmiObject Win32_Process -filter "Name = 'powershell.exe'" | Where-Object { $_.CommandLine -match ".*$scriptCopyCname.*-Service" })
  foreach ($process in $processes) { # There should be just one, but be prepared for surprises.
    $spid = $process.ProcessId
    Write-Host "$serviceName Process ID = $spid"
  }
  try {
    $pss = Get-Service $serviceName -ErrorAction stop # Will error-out if not installed
  }
  catch {
    Write-Host "Not Installed"
    return
  }
  if (($pss.Status -eq "Running") -and (!$spid)) { # This happened during the debugging phase
    Write-Host "The Service Control Manager thinks $serviceName is started, but $serviceName.ps1 -Service is not running." -ForegroundColor Red
    exit 1
  }
  if (($pss.Status -eq "Stopped") -and ($spid)) { # This happened during the debugging phase
    Write-Host "The Service Control Manager thinks $serviceName is stopped, but $serviceName.ps1 -Service is running." -ForegroundColor Red
    exit 1
  }
  Write-Host "$($pss.Status)"
  return
}

if ($Setup) {           # Install the service
  # Check if it's necessary
  try {
    $pss = Get-Service $serviceName -ErrorAction stop # Will error-out if not installed
    # Check if this script is newer than the installed copy.
    if ((Get-Item $scriptCopy -ErrorAction SilentlyContinue).LastWriteTime -lt (Get-Item $scriptFullName -ErrorAction SilentlyContinue).LastWriteTime) {
      Write-Host "Service $serviceName is already Installed, but requires upgrade"
      & $scriptFullName -Remove
      throw "continue"
    } else {
      Write-Host "Service $serviceName is already Installed, and up-to-date"
    }
    exit 0
  }
  catch {
    # This is the normal case here. Do not throw or write any error!
    Write-Host "Starting installation..." # Also avoids a ScriptAnalyzer warning
    # And continue with the installation.
  }
  try {
    # Create the installation directory if it doesn't exist
    if (!(Test-Path $installDir)) {
      New-Item -ItemType directory -Path $installDir -ErrorAction stop | Out-Null
    }
    # Copy the sources into the installation directory
    if ($ScriptFullName -ne $scriptCopy) {
      Write-Host "Copying files"
      $length = (Get-Item .).FullName.Length
      Get-ChildItem -Path . -recurse -include * | Copy-Item -Destination {
        if ($_.PSIsContainer) {
          Join-Path $installDir $_.Parent.FullName.Substring($length)
        } else {
          Join-Path $installDir $_.FullName.Substring($length)
        }
      } -Force -Exclude $exclude -ErrorAction stop
    }
  }
  catch
  {
    Write-Error "Failed to copy files to installation directory. Please check rights."
    exit 1
  }
  # Generate the service .EXE from the C# source embedded in this script
  try {
    Write-Host "Compiling $exeFullName"
    Add-Type -TypeDefinition $source -Language CSharp -OutputAssembly $exeFullName -OutputType ConsoleApplication -ReferencedAssemblies "System.ServiceProcess" -Debug:$false
  }
  catch {
    $msg = $_.Exception.Message
    Write-error "Failed to create the $exeFullName service stub. $msg"
    exit 1
  }
  # Set some registry keys
  New-Item -Path HKLM:\Software\PowerXaaS -Force | Out-Null
  New-ItemProperty -Path HKLM:\Software\PowerXaaS -Name Bindings -Value "https://$ip`:$port/" -PropertyType String -Force | Out-Null
  # Register the service
  Write-Host "Registering service $serviceName"
  if ($Credential.UserName) {
    Write-PXLog -Status "Information" -Context "Setup" -Description "Configuring the service to run as $($Credential.UserName)"
    $pss = New-Service $serviceName $exeFullName -DisplayName $serviceDisplayName -Description $ServiceDescription -StartupType Automatic -Credential $Credential
  } else {
    Write-PXLog -Status "Information" -Context "Setup" -Description "Configuring the service to run by default as LocalSystem"
    $pss = New-Service $serviceName $exeFullName -DisplayName $serviceDisplayName -Description $ServiceDescription -StartupType Automatic
  }

  return
}

if ($Remove) {          # Uninstall the service
  # Check if it's necessary
  try {
    $pss = Get-Service $serviceName -ErrorAction stop # Will error-out if not installed
  }
  catch {
    Write-Host "Already uninstalled"
    return
  }
  Write-Host "Stopping service $serviceName"
  Stop-Service $serviceName  # Make sure it's stopped
  Write-Host "Removing service $serviceName"
  $msg = sc.exe delete $serviceName  # In the absence of a Remove-Service applet, use sc.exe instead.
  if ($LastExitCode) {
    Write-Error "Failed to remove the service ${serviceName}: $msg"
    exit 1
  }
  # Remove the installed files
  if (Test-Path $installDir) {
    Write-Host "Deleting files"
    Write-Host "Removing directory $installDir"
    Remove-Item $installDir -Recurse -ErrorAction silentlyContinue
  }
  return
}

if ($Service) {         # Run the service as a background job
  Write-PXLog -Status "Information" -Context "Start" -Description ""         # Insert one blank line to separate sessions logs
  Write-PXLog -Status "Information" -Context "Start" -Description $MyInvocation.Line   # The exact command line that was used to start us
  Write-EventLog -LogName $logName -Source $serviceName -EventId 1005 -EntryType Information -Message "$scriptName -Service # Beginning background job"
  try {
    # Start the control pipe handler thread
    $pipeThread = Start-PipeHandlerThread $pipeName -Event "ControlMessage"
    # Start Web Server
    $Listener = New-Object System.Net.HttpListener
    $Bindings = (Get-ItemProperty -Path HKLM:\Software\PowerXaaS -Name Bindings).Bindings
    $Listener.Prefixes.Add($Bindings)
    $Listener.Start()  # Start listening
    Write-PXLog -Status "Information" -Context "HTTPD" -Description "Server started listening on $bindings"
    $RequestID = 1
    $Context = $null
    $Task = $Listener.GetContextAsync()  # Listen (Async)
    # Now enter the main service event loop
    do {  # Keep running until told to exit by the -Stop handler
      if ($Task.Wait(100))
      {
        $Context = $Task.Result  # Get context, if any
        if ($Context)
        {
          Write-PXLog -Status "Information" -Context "HTTPD" -Description "Client request has been received"
          Receive-PXRequest -Id $RequestID -Context $Context
          Write-PXLog -Status "Information" -Context "HTTPD" -Description "Client response has been sent"
          $RequestID++
          $Context = $null
          $Task = $Listener.GetContextAsync()  # Listen (Async)
        }
        else
        {
          if (Test-Path .\pause.*)  # Pause condition
          {
            $Delay = (get-item .\pause.*).Extension.substring(1)
            Write-PXLog -Status "Warning" -Context "HTTPD" -Description "Server has been paused for $delay seconds"
            Start-Sleep -Seconds $Delay
            Remove-Item .\pause.*
            Write-PXLog -Status "Warning" -Context "HTTPD" -Description "Server has resumed"
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
        Write-PXLog -Status "Information" -Context "Service" -Description "Event at $EventTime from ${Source}: $Message"
        $event | Remove-Event  # Flush the event from the queue
        switch ($Source) {
          $pipeThreadName {
            switch ($message) {
              "ControlMessage" {  # Required. Message received by the control pipe thread
                $State = $Event.SourceEventArgs.InvocationStateInfo.state
                Write-PXLog -Status "Information" -Context "Service" -Description "Thread $Source state changed to $State"
                switch ($state) {
                  "Completed" {
                    $Message = Receive-PipeHandlerThread $pipeThread
                    Write-PXLog -Status "Information" -Context "Service" -Description "Received control message: $Message"
                    if ($Message -ne "exit") { # Start another thread waiting for control messages
                      $pipeThread = Start-PipeHandlerThread $pipeName -Event "ControlMessage"
                    }
                  }
                  "Failed" {
                    $Error = Receive-PipeHandlerThread $pipeThread
                    Write-PXLog -Status "Information" -Context "Service" -Description "$Source thread failed: $Error"
                    Start-Sleep 1 # Avoid getting too many errors
                    $pipeThread = Start-PipeHandlerThread $pipeName -Event "ControlMessage" # Retry
                  }
                  default {  # Should not happen
                    Write-PXLog -Status "Information" -Context "Service" -Description "Unexpected state $State from ${source}: $Message"
                  }
                }
              }
              default {  # Should not happen
                Write-PXLog -Status "Information" -Context "Service" -Description "Unexpected event from ${Source}: $Message"
              }
            }
          }
          default {  # Should not happen
            Write-PXLog -Status "Information" -Context "Service" -Description "Unexpected source ${Source}"
          }
        }
      }
    }
    While ($Message -ne "exit")
    Write-PXLog -Status "Information" -Context "Service" -Description "Exit command has been received"
  }
  catch  # An exception occurred while runnning the service
  {
    $msg = $_.Exception.Message
    $line = $_.InvocationInfo.ScriptLineNumber
    Write-PXLog -Status "Information" -Context "Service" -Description "Error at line ${line}: $msg"
  }
  finally   # Invoked in all cases: Exception or normally by -Stop
  {
    Get-PSThread | Remove-PSThread  # Remove all remaining threads
    $events = Get-Event | Remove-Event  # Flush all leftover events (There may be some that arrived after we exited the while event loop, but before we unregistered the events)
    
    # Stop listening
    $Listener.Stop()
    Write-PXLog -Status "Warning" -Context "HTTPD" -Description "Server has stopped"
    
    # Log a termination event, no matter what the cause is.
    Write-EventLog -LogName $logName -Source $serviceName -EventId 1006 -EntryType Information -Message "$script -Service # Exiting"
    Write-PXLog -Status "Information" -Context "Service" -Description "Exiting"

    exit
  }
}
