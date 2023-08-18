<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Function to prompt for choices
Example:
$TwoButtons = Get-eAnswer -Prompt "PICK A BUTTON" -Choice1 'Button1' -Choice1Hint "Hint 1" -Choice2 'Button 2' -Choice2Hint "Hint 2"
$ThreeButtons = Get-eAnswer -Prompt "PICK A BUTTON" -Choice1 'Button1' -Choice1Hint "Hint 1" -Choice2 'Button 2' -Choice2Hint "Hint 2" -Choice3 'All' -Choice3Hint "Hint 3"

#>
function Get-eAnswer {

    [CmdletBinding()]

    param(

        [ValidateNotNullorEmpty()]
        [string]$Prompt,
        
        [ValidateNotNullorEmpty()]
        $Choice1,
        $Choice1Hint,
        
        [ValidateNotNullorEmpty()]
        $Choice2,
        $Choice2Hint,

        $Choice3,
        $Choice3Hint

    )

    $Choices1 = New-Object System.Management.Automation.Host.ChoiceDescription "&$Choice1", "$Choice1Hint"
    $Choices2 = New-Object System.Management.Automation.Host.ChoiceDescription "&$Choice2", "$Choice2Hint"

    If ($Choice3) {

        $Choices3 = New-Object System.Management.Automation.Host.ChoiceDescription "&$Choice3", "$Choice3Hint"
        $Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Choices1, $Choices2, $Choices3)

    }
    else {

        $Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Choices1, $Choices2)

    }

    $Result = switch ($Host.UI.PromptForChoice($null, "$Prompt", $Choices, 0)) {

        0 { $Choice1 }
        1 { $Choice2 }
        2 { $Choice3 }
        default { $null }

    }
    
    Write-Output $Result

}