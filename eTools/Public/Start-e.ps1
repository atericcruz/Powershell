function Start-e {

    [CmdletBinding()]

    param ()
    
    #openssl der -in "C:\Users\user\Desktop\wildcard.pfxfx" -clcerts -nokeys -out "C:\Users\user\Desktop\wildcard.geoslinc.com_16MAY2023.crt"
    #openssl rsa -in "C:\Users\user\Desktop\wildcard.pfxfx" -out "C:\Users\user\Desktop\wildcard.geoslinc.com_16MAY2023.key"
    #openssl req –new –newkey rsa:2048 –nodes –keyout server.key –out server.csr
    #openssl pkcs12 -in yourpkcs12.pfx -out package.pem -nodes

    $inputXML = @"
<Window x:Class="ESXi_Upgrade.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:ESXi_Upgrade"
        mc:Ignorable="d"
    Title="MainWindow" Height="558" Width="918">
    <Grid>
        <Label x:Name="lblVcenter" Content="vCenter" HorizontalAlignment="Left" Margin="61,49,0,0" VerticalAlignment="Top"/>
        <Label Content="UCS" HorizontalAlignment="Left" Margin="68,270,0,0" VerticalAlignment="Top"/>
        <Label Content="ESXi Host" HorizontalAlignment="Left" Margin="55,101,0,0" VerticalAlignment="Top"/>
        <Label Content="Blade" HorizontalAlignment="Left" Margin="65,327,0,0" VerticalAlignment="Top"/>
        <ComboBox x:Name="ddlVcent" HorizontalAlignment="Left"  Margin="10,74,0,0" VerticalAlignment="Top" Width="152" IsEnabled="False" />
        <ComboBox x:Name="ddlUcs" HorizontalAlignment="Left" Margin="9,300,0,0" VerticalAlignment="Top" Width="152" IsEnabled="False" />
        <ComboBox x:Name="ddlUBlade" HorizontalAlignment="Left" Margin="9,353,0,0" VerticalAlignment="Top" Width="152" IsEnabled="False" />
        <ComboBox x:Name="ddlEsx" HorizontalAlignment="Left" Margin="10,127,0,0" VerticalAlignment="Top" Width="152" IsEnabled="False"/>
        <Label Content="Service Profile Template" HorizontalAlignment="Left" Margin="17,380,0,0" VerticalAlignment="Top" />
        <ComboBox x:Name="ddlUspt" HorizontalAlignment="Left" Margin="9,406,0,0" VerticalAlignment="Top" Width="152" IsEnabled="False" />
        <Button x:Name="btnVCred" Content="vCenter Credentials" HorizontalAlignment="Left" Margin="18,24,0,0" VerticalAlignment="Top" Height="25" Width="136" Foreground="Black"/>
        <Button x:Name="btnUCred" Content="UCS Credentials" HorizontalAlignment="Left" Margin="18,240,0,0" VerticalAlignment="Top" Width="136" Height="25"/>
        <DataGrid x:Name="dgESX"  Margin="187,10,10,441"/>
        <Button x:Name="btnESXMaintOn" Content="Enable" HorizontalAlignment="Left" Margin="26,185,0,0" VerticalAlignment="Top" Width="50" Height="20" IsEnabled="False"/>
        <Label Content="Maintenance Mode:" HorizontalAlignment="Left" Margin="26,154,0,0" VerticalAlignment="Top"/>
        <Button x:Name="btnESXMaintOff" Content="Disabled" HorizontalAlignment="Left" Margin="91,185,0,0" VerticalAlignment="Top" Width="50" Height="20" IsEnabled="False"/>
        <DataGrid x:Name="dgUCS" Margin="187,271,10,10"/>
        <DataGrid x:Name="dgESXVMs"  Margin="187,127,10,307"/>
        <Label x:Name="lblVMOnCt" Content="" HorizontalAlignment="Left" Margin="374,102,0,0" VerticalAlignment="Top" Width="106" Height="23"/>
        <Label x:Name="lblVMOffCt" Content="Text" HorizontalAlignment="Left" Margin="485,102,0,0" VerticalAlignment="Top" Width="168" Height="23"/>
        <Label x:Name="lblVMCount" Content="Label" HorizontalAlignment="Left" Margin="200,102,0,0" VerticalAlignment="Top" Width="169"/>
    </Grid>
</Window>
"@

    $inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    [xml]$XAML = $inputXML
 
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)

    try {

        $Form = [Windows.Markup.XamlReader]::Load( $reader )

    }
    catch {

        Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
        throw

    }
 
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object { 

        try {

            $Name = $_.Name
            $VName = "WPF$Name"

            Set-Variable -Name $VName -Value $Form.FindName($Name) -ErrorAction Stop
  
        }
        catch {
    
            throw
    
        }

    }

    $WPFbtnVCred.Add_Click({

            $Script:VCred = Get-Credential -UserName "$env:USERNAME@geosolinc.net" -Message 'Please enter your vCenter credentials'
        
            $WPFddlVcent.Items.Add('D1PVCENTER1')
            $WPFddlVcent.IsEnabled = $True

        })

    $WPFddlVcent.Add_SelectionChanged( {

            $Script:VServer = Connect-VIServer 'd1pvcenter1' -Force
            $Script:VMHosts = Get-VMHost -Server $VServer

            $WPFddlEsx.ItemsSource = @($VMHosts.Name)
            $WPFddlEsx.IsEnabled = $True
            $WPFdgESX.ItemsSource = @($VServer)

        })

    $WPFddlEsx.Add_SelectionChanged({

            $selected = $WPFddlEsx.SelectedItem
            $Script:TheHost = @($Script:VMHosts | Where-Object { $_.name -like "$selected" })
            $Global:DaHost = $selected -replace '.geosolinc.net'
            $HostInfo = $Script:TheHost | Select-Object Name, PowerState, ConnectionState, @{N = 'ESXi Version'; e = { $_.Version } }, @{N = 'Model'; e = { $_.Model } }  
            $WPFdgESX.ItemsSource = @($HostInfo)
            $VMs = @( $Script:TheHost | Get-VM | Sort-Object Name | Select-Object Name, PowerState, Guest, Notes )
            $On = $VMs | Where-Object { $_.PowerState -eq 'PoweredOn' }
            $Off = $VMs | Where-Object { $_.PowerState -ne 'PoweredOn' }
            $WPFlblVMCount.Content = "Total VMs on host: $($VMs.Count)"
            $WPFlblVMOnCt.Content = "Powered On: $($On.Count)"
            $WPFlblVMOffCt.Content = "Powered Off: $($Off.Count)"
            $WPFdgESXVMs.ItemsSource = $VMs
        
            Write-Host "Selected: $selected"
        
        })

    $WPFbtnUCred.Add_Click({
 
            $Script:UCSCred = Get-Credential -UserName "ucs-geosolinc.net\$env:USERNAME" -Message 'Please enter your UCS credentials'

            $WPFddlUcs.Items.Add('TA-UCS')
            $WPFddlUcs.Items.Add('TA-UCS2')
            $WPFddlUcs.IsEnabled = $True
   

        })

    $WPFddlUBlade.Add_SelectionChanged({

            $selected = $WPFddlUBlade.SelectedItem
 
            $WPFdgUCS.ItemsSource = @($Script:UCSBlades | Where-Object { $_.AssignedToDn -match "org-root/ls-$selected" })
            Write-Host "Selected: $selected"
    
        })

    $WPFddlUcs.Add_SelectionChanged({

            $selected = $WPFddlUcs.SelectedItem
            Write-Host "Selected: $selected $($Script:TheHost.Name)"
            $null = Set-UcsPowerToolConfiguration -SupportMultipleDefaultUcs $True -InvalidCertificateAction Ignore 
            $Script:UCSConnect = Connect-Ucs -Name $selected  -Credential $Script:UCSCred 
            $Script:UCSBlades = Get-UcsBlade -Ucs $UCSConnect 
            $Script:UcsServiceProfiles = Get-UcsServiceProfile -Ucs $UCSConnect
            $Script:UcsServiceProfilesTemplates = $UcsServiceProfiles | Where-Object { $_.type -ne 'Instance' }

            $Script:UCSBlades | ForEach-Object { $WPFddlUBlade.Items.Add("$($_.AssignedToDn -replace 'org-root/ls-')") }
            $WPFdgUCS.ItemsSource = @($UCSBlades | Where-Object { $_.AssignedToDn -match $Global:DaHost })
            $UcsServiceProfilesTemplates | ForEach-Object { $WPFddlUspt.Items.Add("$($_.Name)") }
   
            $WPFddlUBlade.IsEnabled = $True
            $WPFddlUspt.IsEnabled = $True

        })

    $WPFddlUspt.Add_SelectionChanged({

            $selected = $WPFddlUspt.SelectedItem
            $WPFdgUCS.ItemsSource = @($Script:UcsServiceProfilesTemplates | Where-Object { $_.name -match $selected })
            Write-Host "Selected: $selected"

        })



    $Form.ShowDialog()

}