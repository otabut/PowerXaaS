Function Get-PXUsageStats
{
  param(
    $StartTimestamp,
    $EndTimestamp,
    [switch]$Raw,
    [switch]$ByReturnCode,
    [switch]$Count
  )

  $Data = Get-Content "${ENV:ProgramFiles}\PowerXaaS\data.log" | ConvertFrom-Csv -Delimiter ';' -Header timestamp,method,url,returncode #| Where {$_.timestamp -ge 1 -and $_.timestamp -le 5}

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

