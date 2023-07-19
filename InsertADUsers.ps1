# Inserting data into ADUsers
Function InsertADUser($userName, $email, $department)
{
    # Fetch user from Active Directory
    $adUser = Get-ADUser -Identity $userName

    # If user is not null, proceed
    if($adUser)
    {
        # SQL server details
        $sqlServer = "your_sql_server"
        $sqlDatabase = "your_database"
        $sqlUser = "your_user"
        $sqlPassword = ConvertTo-SecureString -String "your_password" -AsPlainText -Force
        $sqlCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqlUser, $sqlPassword
        
        # SQL query, with parameters
        $sqlQuery = @"
        INSERT INTO ADUsers(UserID, Email, Department)
        VALUES (@userID, @userEmail, @userDepartment)
        "@

        # Create SQL connection string
        $sqlConnectionString = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder
        $sqlConnectionString["Data Source"] = $sqlServer
        $sqlConnectionString["Initial Catalog"] = $sqlDatabase
        $sqlConnectionString["User ID"] = $sqlCred.UserName
        $sqlConnectionString["Password"] = $sqlCred.GetNetworkCredential().Password
        
        # Create SQL connection
        $sqlConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection
        $sqlConnection.ConnectionString = $sqlConnectionString.ToString()
        
        # Create SQL command
        $sqlCommand = New-Object -TypeName System.Data.SqlClient.SqlCommand
        $sqlCommand.Connection = $sqlConnection
        $sqlCommand.CommandText = $sqlQuery

        # Add parameters to command
        $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@userID", $adUser.SamAccountName)))
        $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@userEmail", $email)))
        $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@userDepartment", $department)))

        # Execute SQL command
        try
        {
            $sqlConnection.Open()
            $sqlCommand.ExecuteNonQuery() | Out-Null
        }
        finally
        {
            $sqlConnection.Close()
        }
    }
    else
    {
        Write-Output "User not found in Active Directory."
    }
}

# Invoke the function
InsertADUser -userName "your_AD_username" -email "email@example.com" -department "IT"
