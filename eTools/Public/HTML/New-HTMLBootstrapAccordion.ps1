<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Creates Bootstrap accordion item with an embedded html datatable created from New-eDatatableHtml. 
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

Function New-HTMLBootstrapAccordion {

    [CmdletBinding()] 

    param (

        [Parameter(Mandatory = $false)]
        $Table,
        [string]$Tabletitle,
        $Id,
        [bool]$Collapsed = $true

    )

    $accordionclosed = @"
<div class="accordion-item">
    <div class="accordion-header" id="a$($Id  -replace " ")1">
        <h5 class="mb-0">
            <button id="$Id" class="accordion-button collapsed" type="button" data-bs-toggle="collapse"
                data-bs-target="#a$($Id -replace " ")" aria-expanded="false" aria-controls="$($Id -replace " ")">
                $($Tabletitle -replace ':',': ' -replace '-','- ')
            </button>
        </h5>

        <div id="a$($Id -replace " ")" class="accordion-collapse collapse" aria-labelledby="a$($Id -replace " ")1"
            data-bs-parent="#accordion">
            <div class="accordion-body">
                <div class="table-responsive">
                    $Table
                </div>
            </div>
        </div>
    </div>
</div>
"@

    $accordionopen = @"
<div class="accordion-item">
    <div class="accordion-header" id="a$($Id  -replace " ")1">
        <h5 class="mb-0">
            <button id="$Id" class="accordion-button collapsed" type="button" data-bs-toggle="collapse"
                data-bs-target="#a$($Id -replace " ")" aria-expanded="false" aria-controls="a$($Id -replace " ")">
                $Tabletitle
            </button>
        </h5>

        <div id="a$($Id  -replace " ")" class="accordion-collapse show" aria-labelledby="a$($Id -replace " ")1"
            data-bs-parent="#accordion">
            <div class="accordion-body">

                <div class="table-responsive">
                    $Table
                </div>
            </div>
        </div>
    </div>
</div>
"@

    if ($Collapsed -eq $true) {

        $accordionclosed

    }
    else {

        $accordionopen

    }

}
