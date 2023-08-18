<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Creates Bootstrap and datatable head for HTML page. Used in conjuction with Create-gDatatableHtml & New-HTMLAccordion
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
Function New-eHTMLBootStrapDatatablesHead {

    param (

        $Title = "$env:computername - Inventory"

    )
    
$Head = @"
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <title>$Title</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/1.11.3/css/dataTables.bootstrap5.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/responsive/2.2.9/css/responsive.bootstrap5.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/buttons/2.0.1/css/buttons.bootstrap5.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/colreorder/1.5.5/css/colReorder.bootstrap5.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/searchbuilder/1.3.0/css/searchBuilder.bootstrap5.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/datetime/1.1.1/css/dataTables.dateTime.min.css" rel="stylesheet">
    <style>
        div.col {
            width: 80%
        }

        #body-row {
            margin-left: 0;
            margin-right: 0;
        }

        #output tbody tr.selected {
            background-color: #0275d8;
        }
    </style>
</head>
"@

    Write-Output $Head

}