function Invoke-MySqlNonQuery {
 
    Param(
 
      [Parameter(Mandatory = $true,  HelpMessage="Query to Execute")]
      [string]$Query,
 
      [Parameter(Mandatory = $false,  HelpMessage="Database Host to connect.")]
      [string]$HostName="localhost",
 
      [Parameter(Mandatory = $false,  HelpMessage="Database Username")]
      [string]$User="wfa",
 
      [Parameter(Mandatory = $false,  HelpMessage="Database Port")]
      [string]$Port="3306",
 
      [Parameter(Mandatory = $false,  HelpMessage="Database Password")]
      [string]$Password="Wfa123",
 
      [Parameter(Mandatory = $false,  HelpMessage="Database")]
      [string]$Database
 
      )
 
 
    $ConnectionString = "server=" + $HostName + ";port=" + $Port + ";uid=" + $User + ";pwd=" + $Password
 
    try {
        [void][System.Reflection.Assembly]::LoadWithPartialName("Devart.Data.Mysql")
        $Connection = New-Object Devart.Data.MySql.MySqlConnection
    } catch {
        throw("Failed to get MySql Connection. " + $_.exception) 
    }
   
    try { 
        $Connection.ConnectionString = $ConnectionString
        if($Database){
            $Connection.Database = $Database
        }
        $Connection.Open()
        $Command = New-Object Devart.Data.MySql.MySqlCommand($Query, $Connection)
        $affectedRows = $Command.ExecuteNonQuery()
        return $affectedRows
    }
 
    catch {
        throw($_.exception)
    }
 
    finally {
        $Connection.Close()
    }
}