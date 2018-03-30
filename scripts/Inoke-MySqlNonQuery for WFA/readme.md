# Invoke-MySqlNonQuery function
You may or may not know that WFA, when coding in PowerShell, comes with the CmdLet "Invoke-MySqlQuery" (aliased as imysql for the gurus).

The cmdlet comes in handy very often but is built for "QueryCommands".
What I mean by that is that it assumes that your Query will return "Records".

But what if you want to execute an insert, update or delete statement ?

[Read the original post](http://www.wfaguy.com/2018/02/wfa-execute-mysql-nonquery-powershell.html)

## DevArt
WFA comes with the Devart MySql DLL, which is a library to execute against MySql.
So the component is at our disposal.

## Regular Query
The Invoke-MySqlQuery (comes with WFA) works as follows.

Record 1 contains the number of records returned
The following records (if record 1 > 0), returns the actual dataset.
So by coding something like :
``` powershell
$results = Invoke-MySqlQuery "SELECT * FROM cm_storage.volume"
if($results[0] -gt 0){
    $results | select -skip 1
}
```
you get a list of volumes.

## The New Non-Query function
If you want to insert, delete or update, you could potentially use this cmdlet as well.  In 99% of the cases it will work, however, it's missing 2 features :
Return the affected row count
Set the database (scheme)
In some rare cases (1%), MySql will give you the error "No database selected".  Even if you hard-code the scheme name in the query, for some reason it just seems to ignore them.  I noticed this behavior in a DELETE FROM JOIN scenario.

A connection string allows you to set a database as well, and does fix the problem.

A second feature is the affected rows.  If you update, delete or insert, it's always nice to know how many records were affected.  With the Invoke-MySqlQuery, you wont get the information.

So that's why I hacked the original cmdlet and created a new Invoke-MySqlNonQuery, that optionally accept the parameter "Database".

And it returns the affected row count !
