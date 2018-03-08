
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
        $Data = Get-PXUsageStats -Raw | Select @{N="ByHour"; E={$_.timestamp.substring(0,11)}}

        ### Compute data
        $Stats = @()
        ForEach ($item in ($Data | Group-Object -NoElement -Property ByHour))
        {
          $Stats += [PSCustomObject]@{
            Count = $item.Count
            Name = $item.Name
          }
        }
        ForEach ($Day in ($Stats | select @{N="Day";E={$_.Name.split('-')[0]}} -unique).day)
        {
          ForEach ($Hour in 0..23)
          {
            if (([string]$Hour).length -eq 1)
            {
              $Hour = "0$Hour"
            }
            if (!($Stats | where {$_.Name -eq "$Day-$Hour"}) -and "$Day-$Hour" -le (Get-Date -format "yyyyMMdd-HHmmss"))
            {
              $Stats += [PSCustomObject]@{
                Count = 0
                Name = "$Day-$Hour"
              }
            }
          }
        }
        $Stats = $Stats | sort Name | select -Last 24

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
