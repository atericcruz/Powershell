function New-HTMLAccordion {

    [CmdletBinding()] 

    param (
        [Parameter(Mandatory = $false)]
        $Table,
        [string]$Tabletitle,
        $Id,
        [bool]$Collapsed = $true
    
    )

$accordionclosed = 
@"
<div class="accordion-item">
    <div class="accordion-header" id="a$($ID  -replace " ")1">
        <h5 class="mb-0">
            <button id="$Id" class="accordion-button collapsed" type="button" data-bs-toggle="collapse"
                data-bs-target="#a$($Id -replace " ")" aria-expanded="false"
                aria-controls="a$($Id -replace " ")">
               $($Tabletitle  -replace ':',': ' -replace '-','- ')
            </button>
        </h5>

        <div id="a$($Id  -replace " ")" class="accordion-collapse collapse"
            aria-labelledby="a$($Id -replace " ")1" data-bs-parent="#accordion">
            <div class="accordion-body">
                <div class="table-responsive">
                    <table id="a$($Id  -replace " ")tb" class="table table-bordered table-striped table-sm"
                        style="width:100%" cellspacing="0">$table</table>
                </div>
            </div>
        </div>
    </div>
</div>
"@


$accordionopen = 
@"
<div class="accordion-item">
    <div class="accordion-header" id="a$($Id  -replace " ")1">
        <h5 class="mb-0">
            <button id="$Id" class="accordion-button collapsed" type="button" data-bs-toggle="collapse"
                data-bs-target="#a$($Id -replace " ")" aria-expanded="false"
                aria-controls="a$($Id -replace " ")">
                $Tabletitle
            </button>
        </h5>

        <div id="a$($Id  -replace " ")" class="accordion-collapse show"
            aria-labelledby="a$($Id -replace " ")1" data-bs-parent="#accordion">
            <div class="accordion-body">

                <div class="table-responsive">
                    <table id="a$($Id  -replace " ")tb" class="table table-bordered table-striped table-sm"
                        style="width:100%" cellspacing="0">$table</table>
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
