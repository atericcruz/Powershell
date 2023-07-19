Install-Package Npgsql -ProviderName NuGet

# Required Libraries
Add-Type -Path "C:\path\to\Npgsql.dll"

# Inserting data into ADUsers
Function InsertADUser($userName, $email, $department)
{
    # Fetch user from Active Directory
    $adUser = Get-ADUser -Identity $userName

    # If user is not null, proceed
    if($adUser)
    {
        # PostgreSQL server details
        $pgServer = "your_pg_server"
        $pgDatabase = "your_database"
        $pgUser = "your_user"
        $pgPassword = "your_password"

        # PostgreSQL query, with parameters
        $pgQuery = @"
        INSERT INTO ADUsers(UserID, Email, Department)
        VALUES (@userID, @userEmail, @userDepartment)
        "@

        # Create PostgreSQL connection string
        $pgConnectionString = "Host=$pgServer;Username=$pgUser;Password=$pgPassword;Database=$pgDatabase"

        # Create PostgreSQL connection
        $pgConnection = New-Object Npgsql.NpgsqlConnection
        $pgConnection.ConnectionString = $pgConnectionString

        # Create PostgreSQL command
        $pgCommand = New-Object Npgsql.NpgsqlCommand
        $pgCommand.Connection = $pgConnection
        $pgCommand.CommandText = $pgQuery

        # Add parameters to command
        $pgCommand.Parameters.AddWithValue("userID", $adUser.SamAccountName)
        $pgCommand.Parameters.AddWithValue("userEmail", $email)
        $pgCommand.Parameters.AddWithValue("userDepartment", $department)

        # Execute PostgreSQL command
        try
        {
            $pgConnection.Open()
            $pgCommand.ExecuteNonQuery() | Out-Null
        }
        finally
        {
            $pgConnection.Close()
        }
    }
    else
    {
        Write-Output "User not found in Active Directory."
    }
}

# Invoke the function
InsertADUser -userName "your_AD_username" -email "email@example.com" -department "IT"
