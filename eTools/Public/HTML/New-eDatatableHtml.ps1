<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Creates HTML table formatted for use with datatables.net. Output is used to create a Bootstrap Accordion with New-HTMLAccordion with this table.
Example:

$Accordions = @()

$SysInfo = [PSCustomObject]@{

    Computername = $ENV:Computername

}

$SysInfo_Table = New-eDatatableHtml -Data $SysInfo -Title 'System Overview' -IDName 'sysaccord'
$SysInfo_Accordion = New-HTMLBootstrapAccordion -Table $SysInfo_Table -Tabletitle "System Overview - &nbsp<b>$($SysInfo.Computername)<b/>"

$Accordions += $SysInfo_Accordion

$Head = New-eHTMLBootStrapDatatablesHead -Title "$env:computername - Inventory"
$Body = New-eHTMLBootStrapDatatablesBody -Heading "$env:computername Report $(Get-Date -format 'MM-dd-yyhh:mm:ss tt' )" -Head $Head -Accordion $Accordions
$Body | Set-Content "C:\Temp\1$ENV:Computername.html" -Force

#>
Function New-eDatatableHtml {

    [CmdletBinding()]

    param(
        [ValidateNotNullorEmpty()]
        $Data,
        [string]$Title,
        [string]$IDName
    )

    $Html = @()
    $Html += "<div>`n"
    $Html += "<h4>$Title</h4>`n"
    $Html += "<table id=""a$($IDName)tb"" class=""table table-bordered table-striped table-sm"" style=""width:100%"">`n"
    $Html += "`t<thead>`n"

    ($Data[0]).psobject.Properties.ForEach({ 

            $Html += "`t`t<th>$($_.Name)</th>`n" 

        })

    $Html += "`t</thead>`n"
    $Html += "`t<tbody>`n"

    $Data | ForEach-Object {

        $Html += "`t`t<tr>`n"
    
        ($_).psobject.Properties.ForEach({ 
            
                $Html += "`t`t<td>$($_.value)</td>`n" 
        
            })

        $Html += "`t`t</tr>`n"
        
    }

    $Html += "`t</tbody>`n"
    $Html += "</table>`n"
    $Html += "</div>`n"
    $HTML += "<br>"

    Write-Output $Html

}