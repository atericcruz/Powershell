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
Function New-eHTMLBootStrapDatatablesBody {

    param (

        $Heading = "$env:computername Report $(Get-Date -format 'MM-dd-yyhh:mm:ss tt' )",
        
        [ValidateNotNullOrEmpty()]
        $Head,

        [ValidateNotNullOrEmpty()]
        $Accordions

        #$SaveToHtmlPath = "C:\Temp\$env:COMPUTERNAME.html"

    )
    
    $Body = @"
$Head
<body>
    <div class="container-fluid">
        <div class="jumbotron text-center">
            <h1 class="h1-reponsive mb-3 blue-text"><strong>$Heading</strong></h1>

        </div>
        <div id="loading" style="display:block;">
            <h1 class="h1-reponsive mb-3 blue-text"><strong>LOADING...</strong></h1>
        </div>
        <div class="row">
            <div class="col-sm">
                <div class="accordion" id="accordion" style="display:none;">
                    $Accordions
                </div>
            </div>
        </div>
    </div>
    <script src="https://code.jquery.com/jquery-3.6.0.js"></script>
    <script src="https://cdn.datatables.net/1.10.25/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.10.25/js/dataTables.bootstrap5.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.1/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.datatables.net/buttons/2.0.1/js/dataTables.buttons.min.js"></script>
    <script src="https://cdn.datatables.net/buttons/2.0.1/js/buttons.bootstrap5.min.js"></script>
    <script src="https://cdn.datatables.net/fixedheader/3.1.9/js/dataTables.fixedHeader.min.js"></script>
    <script src="https://cdn.datatables.net/responsive/2.2.8/js/dataTables.responsive.min.js"></script>
    <script src="https://cdn.datatables.net/responsive/2.2.8/js/responsive.bootstrap.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.1.3/jszip.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.53/pdfmake.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.53/vfs_fonts.js"></script>
    <script src="https://cdn.datatables.net/buttons/2.0.1/js/buttons.html5.min.js"></script>
    <script src="https://cdn.datatables.net/buttons/2.0.1/js/buttons.print.min.js"></script>
    <script src="https://cdn.datatables.net/buttons/2.0.1/js/buttons.colVis.min.js"></script>
    <script src="https://cdn.datatables.net/colreorder/1.5.5/js/dataTables.colReorder.min.js"></script>
    <script src="https://cdn.datatables.net/searchbuilder/1.3.0/js/dataTables.searchBuilder.min.js"></script>
    <script src="https://cdn.datatables.net/searchbuilder/1.3.0/js/searchBuilder.bootstrap5.min.js"></script>
    <script src="https://cdn.datatables.net/datetime/1.1.1/js/dataTables.dateTime.min.js"></script>
    <script>
        `$(document).ready(function () {

            `$('#loading').css('display', 'none');

            `$("#accordion").css('display', 'block');

            `$(".collapse").on('show.bs.collapse', function (e) {

                let tab = "#" + this.id + "tb"

                `$(tab).DataTable({
                    destroy: true,
                    scrollx: false,
                    "deferRender": true,
                    responsive: true,
                    paging: false,
                    searching: true,
                    retrieve: true,
                    search: {
                        "smart": true
                    },
                    colReorder: true,
                    dom: 'Bfrtip',
                    buttons: [
                        'copy', 'csv', 'excel', 'pdf', 'print'
                    ],
                    colReorder: true,

                });

                setTimeout(function () {

                    `$.each($.fn.dataTable.tables(true), function () {
                        `$(this).DataTable().columns.adjust().draw();
                    });
                }, 5);

            });

        });
    </script>
</body>

</html>
"@

    Write-Output $Body

}