Function Write-Log
{
  Param (
    [parameter(Mandatory=$true)][ValidateSet("Information","Warning","Error")][String]$Status,
    [parameter(Mandatory=$true)][String]$Context,
    [parameter(Mandatory=$true)][String]$Description
  )

  #Format message to log
  $Date = Get-Date -format "dd/MM/yyyy HH:mm:ss.fff"
  $Message = "$Date - $Status - $Context - $Description"
  
  #Handle Console Output
  if ($Global:Console.IsPresent)
  {
    switch ($Status)
    {
      "Information"
      { 
        Write-Host $Message
      }
      "Warning"
      { 
        Write-Host $Message -ForegroundColor Yellow
      }
      "Error"
      { 
        Write-Host $Message -ForegroundColor Red
      }
    }
  }

  #Handle writing in log file
  if ($Global:LogFile)
  {
    Add-Content $Global:Logfile $Message
    try
    {
      $LogSize = (Get-ItemProperty -Path HKLM:\Software\PowerXaaS -Name LogSize).LogSize
    }
    catch
    {
      $LogSize = "2"
    }

    if ((Get-Item $Global:Logfile).length -gt (iex "$LogSize`Mb"))
    {
      $Parent = "$(Split-Path $Global:Logfile -Parent)\logs"
      $Leaf = "$(Split-Path $Global:Logfile -Leaf)".split('.')[0]
      $Leaf += Get-Date -Format "_yyyy-MM-dd_HH-mm-ss-fff."
      $Leaf += "$(Split-Path $Global:Logfile -Leaf)".split('.')[1]
      $Target = "$Parent\$Leaf"
      Move-Item $Global:Logfile $Target
    }
  }

  #Handle custom logging function
  if ($Global:CustomLogging.IsPresent)
  {
    $Line = [PSCustomObject]@{
      Date = $Date
      Status = $Status
      Context = $Context
      Description = $Description
    }
    Start-CustomLogging $Line
  }
}
