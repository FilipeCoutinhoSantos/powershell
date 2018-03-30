# converts a psobject to wfa csv
function ConvertTo-WfaCsv($psobj,$csvpath){
    try {
        New-Item -Path $csvpath -type file -force | Out-Null
    } catch [System.Exception] {
        $msg = "Data Source: Could not create output file path: $($_.Exception)"
        # LogFatal($msg) - log
        # Throw $msg - throw
    }
    if($psobj){
        $csv = $psobj | convertto-csv -NoTypeInformation -Delimiter "`t"
        $csv = $csv | %{$_ -replace '"'} | select -skip 1
        $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
        $csv = $csv | %{[System.IO.File]::AppendAllText((resolve-path $csvpath), "$_`n",$Utf8NoBomEncoding)}
    }
}