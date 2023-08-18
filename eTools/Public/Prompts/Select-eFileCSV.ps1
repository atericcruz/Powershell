<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Prompt for CSV file
#>
Function Select-gFileCSV {

	[CmdletBinding()]

	param()

	try { 
		
		Add-Type -AssemblyName System.Windows.Forms
	
	}
	Catch {}

	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.Title = "Select CSV Users List"
	$OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
	$OpenFileDialog.CheckFileExists = $true
	$OpenFileDialog.Multiselect = $false
	$OpenFileDialog.CheckPathExists = $true
	$OpenFileDialog.Filter = 'CSV UTF-8 (Comma delimited) (*.csv)|*.csv'
	$OpenFileDialog.ValidateNames = $true
	$null = $OpenFileDialog.ShowDialog()

	if ($OpenFileDialog.FileNames.Count -eq 0) {

		#if ($OpenFileDialog.ShowDialog() -eq "Cancel") {
		$null = [System.Windows.Forms.MessageBox]::Show("No File Selected. Please select a file !", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
		$result = 0

	}
 else { 

		$result = $OpenFileDialog.FileName

	}

	$OpenFileDialog.Dispose()
	return $result

}