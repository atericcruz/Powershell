function New-eRandomPassword {

    [CmdletBinding()]

    param(

        [int]$Length = 12

    )
    
    $Alphabet = "abcdefghijklmnopqrstuvwxyz"
    $UpperCaseAlphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $Numbers = "23456789"
    $SpecialChars = '!@$?_#-'
    
    $Password = New-Object System.Security.SecureString
    
    $Password.AppendChar($Alphabet[(Get-Random -Minimum 0 -Maximum $Alphabet.Length)])
    
    1..($Length - 1) | ForEach-Object {
        $CharType = Get-Random -Minimum 1 -Maximum 5
        
        switch ($CharType) {
            1 {
                # Add a lowercase letter
                $Password.AppendChar($Alphabet[(Get-Random -Minimum 0 -Maximum $Alphabet.Length)])
            }
            2 {
                # Add an Uppercase letter
                $Password.AppendChar($UppercaseAlphabet[(Get-Random -Minimum 0 -Maximum $UppercaseAlphabet.Length)])
            }
            3 {
                # Add a number
                $Password.AppendChar($Numbers[(Get-Random -Minimum 0 -Maximum $Numbers.Length)])
            }
            4 {
                # Add a special Character
                $Password.AppendChar($specialChars[(Get-Random -Minimum 0 -Maximum $specialChars.Length)])
            }
            5 {
                # Add a random Character (letter, number, or special Character)
                $Char = $Alphabet + $UppercaseAlphabet + $Numbers + $specialChars
                $Password.AppendChar($Char[(Get-Random -Minimum 0 -Maximum $Char.Length)])
            }
        }
    }
    
    $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
    
    return $PlainPassword
}