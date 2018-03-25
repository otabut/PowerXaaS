Function Get-PXUsageStats
{
  param(
    [parameter(Mandatory=$false)][String]$StartTimestamp,
    [parameter(Mandatory=$false)][String]$EndTimestamp,
    [parameter(Mandatory=$false)][switch]$Raw,
    [parameter(Mandatory=$false)][switch]$ByReturnCode,
    [parameter(Mandatory=$false)][switch]$Count
  )

  $Data = Get-Content "${ENV:ProgramFiles}\PowerXaaS\data.log" | ConvertFrom-Csv -Delimiter ';' -Header timestamp,username,method,url,returncode 
  if ($StartTimestamp)
  {
    $Data = $Data | Where {$_.timestamp -ge $StartTimestamp}
  }
  if ($EndTimestamp)
  {
    $Data = $Data | Where {$_.timestamp -le $EndTimestamp}
  }

  if ($Raw.IsPresent)
  {
    return $Data
  }

  if ($ByReturnCode.IsPresent)
  {
    $data = $data | Group-Object -NoElement -Property ReturnCode | Select @{N="ReturnCode"; E={$_.Name}}, Count
    return $Data
  }

  if ($Count.IsPresent)
  {
    return $Data.count
  }

  $data = $data | Group-Object -NoElement -Property Method,Url,ReturnCode | Select @{N="Method"; E={$_.Name.split(',')[0].trim()}},@{N="Url"; E={$_.Name.split(',')[1].trim()}},@{N="ReturnCode"; E={$_.Name.split(',')[2].trim()}}, Count
  return $Data
}
