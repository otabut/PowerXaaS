Function Write-PXLog
{
  Param (
    [parameter(Mandatory=$true)][ValidateSet("Information","Warning","Error")][String]$Status,
    [parameter(Mandatory=$true)][String]$Context,
    [parameter(Mandatory=$true)][String]$Description
  )

  #Format message to log
  $Date = Get-Date -format "dd/MM/yyyy HH:mm:ss.fff"
  $Message = "$Date - $Status - $Context`: $Description"
  
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
  }

  #Handle custom logging function
  if ($Global:CustomLogging.IsPresent)
  {
    $Line = [PSCustomObject]@{
      Date = $Date
      Hostname = $HostName
      Step = $Step
      Status = $Status
      Comment = $Comment
    }
    Start-PXCustomLogging $Line
  }
}
