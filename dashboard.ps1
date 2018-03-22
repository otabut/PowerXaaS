
Get-UDDashboard | Stop-UDDashboard


$EndpointListPage = New-UDPage -Name "Endpoints list" -Icon link -Content {

  New-UDRow {
    New-UDColumn -Size 6 {

      New-UDGrid -Title "Endpoints list" -Headers @("Method","URL","Feature","Active") -Properties @("method","url","feature","active") -AutoRefresh -RefreshInterval 20 -Endpoint {
        Import-Module PowerXaaS
        Get-PXEndpoint | Out-UDGridData
      }
    }
  }
}

$UsagePage = New-UDPage -Name "Usage and return codes" -Icon link -Content {

  New-UDRow {
    New-UDColumn -Size 6 {
      New-UDGrid -Title "Usage stats" -Headers @("Method","URL","ReturnCode","Count") -Properties @("Method","Url","ReturnCode","Count") -AutoRefresh -RefreshInterval 20 -Endpoint {
        Import-Module PowerXaaS
        Get-PXUsageStats | Out-UDGridData
      }
    }
  }
}

$RequestCountPage = New-UDPage -Name "Requests count" -Icon link -Content {

  New-UDRow {
    New-UDColumn -Size 6 {
      New-UDChart -Title "Requests count (last 24 hours)" -Type Line -AutoRefresh -RefreshInterval 20 -Endpoint {
        ### Retrieve data
        Import-Module PowerXaaS
        $Data = Get-PXUsageStats -Raw | Select @{N="ByHour"; E={$_.timestamp.substring(0,11)}} | Group-Object -NoElement -Property ByHour

        ### Compute data
        $Stats = @()
        $h = [int]((get-date).AddHours(-24).tostring("HH"))
        $d = [int]((get-date).AddHours(-24).tostring("yyyyMMdd"))
        ForEach ($count in 1..24)
        {
          $hour = $h + $count
          $day = $d
          if ($hour -ge 24)
          {
            $hour = $hour - 24
            $day = $d + 1
          }
          if (([string]$hour).length -eq 1)
          {
            $hour = "0$hour"
          }

          $r = $Data | where {$_.Name -eq "$day-$hour"}
          if ($r)
          {
            $Stats += [PSCustomObject]@{
              Count = $r.Count
              Name = $r.Name
            }
          }
          else
          {
            $Stats += [PSCustomObject]@{
              Count = 0
              Name = "$day-$hour"
            }    
          }
        }
        $Stats = $Stats | sort Name

        ### Render data
        $Stats | Out-UDChartData -DataProperty "Name" -LabelProperty "Name" -Dataset @(
          New-UDChartDataset -DataProperty "Count" -Label "Requests" -BackgroundColor "#803AE8CE" -HoverBackgroundColor "#803AE8CE"
        )
      }
    }
  }
}

$Dashboard = New-UDDashboard -Title "IAS/SYS/WIN" -Page @($UsagePage, $RequestCountPage, $EndpointListPage)

Start-UDDashboard -Port 8086 -Dashboard ( $DashBoard )
Start-Process http://localhost:8086
