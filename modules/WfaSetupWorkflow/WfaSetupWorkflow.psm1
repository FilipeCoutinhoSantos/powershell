$SCRIPT_PATH =(Split-Path (Resolve-Path $myInvocation.MyCommand.Path)) 
$FULL_SCRIPT_PATH = (Resolve-Path $myInvocation.MyCommand.Path)
$CURRENT_PATH = ((Get-Location).Path)

Add-Type -AssemblyName System.IO.Compression.FileSystem
function InvokeUnzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function InvokeZip{
    param([string]$zippath, [string]$sourcepath, [switch]$force=$true)
    if($force){
        if(Test-Path $zippath){
            Write-Verbose $("Removing previous zip file $zippath")
            Remove-Item -Path $zippath
        }
    }
    Write-Verbose $("creating zip file $zippath [from $sourcepath]")
    $cmd = "$SCRIPT_PATH\7za.exe"
    $prm = "a", "-r", "-tzip", $zippath, "$sourcepath\*.*"
    & $cmd $prm
    #[System.IO.Compression.ZipFile]::CreateFromDirectory($sourcepath,$zippath,[System.IO.Compression.CompressionLevel]::Fastest,$false,[System.Text.Encoding]::Default)
}

function GetTempDirectory(){
    $tempfile = [System.IO.Path]::GetTempFileName();
    remove-item $tempfile;
    Write-Verbose "Creating tmp directory $tempfile"
    $tempdir = new-item -type directory -path $tempfile
    return $tempdir.FullName
}

function RemoveTempDirectory($path){
    Write-Verbose "Removing directory $path"
    remove-item $path -Recurse -Force -Confirm:$false
}

function Write-Success($t){
    Write-Host $t -ForegroundColor Green
}

<#
.Synopsis
   Generates a wfa setup workflow
.DESCRIPTION
   Generates a wfa setup workflow
   - will take a folder pat has input
   - will generate a dar file with a setup workflow that can copy that folder in the modules folder of wfa
.EXAMPLE

#>
function New-WfaSetupWorkflow
{
    [CmdletBinding()]
    Param
    (
        # Path of the package (folder path)
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Path,

        # Name of the package you want installed (friendly name)
        [Parameter(Mandatory=$true)]
        [ValidatePattern("[a-zA-Z][a-zA-Z0-9_-]")]
        [string]$DestinationFolderName,    

        # Name of the package you want installed (friendly name)
        [Parameter(Mandatory=$true)]
        [string]$Name,       
        
        # destination path type of the package you want installed (module, custom, wfa)
        [Parameter(Mandatory=$true)]
        [ValidateSet("Module","Wfa","Custom")]
        [string]$DestinationPathType,

        # in case of custom path, this will be the default
        [Parameter(Mandatory=$false)]
        [string]$CustomPath
    )

    $CommandDefinition = ("CommandDefinition{0}_%guid1%.xml" -f $DestinationPathType)

    Write-Host "Generating your dar for '$FriendlyName'"
    $guid1 = New-Guid # guid for command
    $guid2 = New-Guid # guid for workflow
    $guid3 = New-Guid # guid for parameter
    $guid4 = New-Guid # guid for command alias
    $guid5 = New-Guid # guid for userinput
    $guid6 = New-Guid # guid for parameter2
    $guid7 = New-Guid # guid for userinput 2
    $newpath = "$pwd\WfaSetupWorkflows"
    $tmpSetupfile = ([System.IO.Path]::GetTempFileName()) -replace  "\.tmp",".zip"
    if(-not (Test-Path $newpath)){
        New-Item -ItemType Directory -Force -Path "$newpath"
    }
    $foldername = $Path.split("\")[-1]
    $tempdir = GetTempDirectory
    Write-Verbose "Zipping your files"
    InvokeZip -zippath $tmpSetupfile -sourcepath "$Path" -force

    # too big ?
    if((Get-Item $tmpSetupfile).length -gt 2MB){
        RemoveTempDirectory -path $tempdir
        Remove-Item -Path $tmpSetupfile        
        Throw "Your content is too big to include in a workflow (max 2MB)"
    }

    Write-Verbose "Copying Template files $SCRIPT_PATH\wf_install_template\*.* to $tempdir"
    Copy-Item -Path $SCRIPT_PATH\wf_install_template\* -Destination $tempdir -Recurse -Container

    Write-Verbose "Copying package zip file to $tempdir\workflow-help\TabularWorkflow_%guid2%\files"
    Copy-Item -Path $tmpSetupfile -Destination "$tempdir\workflow-help\TabularWorkflow_%guid2%\files\$DestinationFolderName.zip.jpg"
    
    Write-Verbose "Replacing placeholders"
    (Get-Content $tempdir\$CommandDefinition) | 
        % {$_ -replace '%guid1%',$guid1} |
        % {$_ -replace '%guid2%',$guid2} |
        % {$_ -replace '%guid3%',$guid3} | 
        % {$_ -replace '%guid4%',$guid4} | 
        % {$_ -replace '%guid5%',$guid5} | 
        % {$_ -replace '%guid6%',$guid6} |           
        % {$_ -replace '%guid7%',$guid7} |       
        % {$_ -replace '%name%',([System.Security.SecurityElement]::Escape($Name))} |
        % {$_ -replace '%dirname%',([System.Security.SecurityElement]::Escape($DestinationFolderName))} |
            Out-File $tempdir\$CommandDefinition -Encoding "UTF8"
    (Get-Content $tempdir\TabularWorkflow_%guid2%.xml) | 
    % {$_ -replace '%guid1%',$guid1} |
    % {$_ -replace '%guid2%',$guid2} |
    % {$_ -replace '%guid3%',$guid3} | 
    % {$_ -replace '%guid4%',$guid4} | 
    % {$_ -replace '%guid5%',$guid5} | 
    % {$_ -replace '%guid6%',$guid6} |     
    % {$_ -replace '%guid7%',$guid7} |       
    % {$_ -replace '%name%',([System.Security.SecurityElement]::Escape($Name))} |
    % {$_ -replace '%custompath%',([System.Security.SecurityElement]::Escape($CustomPath))} |         
    % {$_ -replace '%dirname%',([System.Security.SecurityElement]::Escape($DestinationFolderName))} |
        Out-File $tempdir\TabularWorkflow_%guid2%.xml -Encoding "UTF8"        
    Rename-Item -Path $tempdir\workflow-help\TabularWorkflow_%guid2% -NewName "TabularWorkflow_$guid2"
    Rename-Item -Path $tempdir\TabularWorkflow_%guid2%.xml -NewName "TabularWorkflow_$guid2.xml"
    Rename-Item -Path $tempdir\$CommandDefinition -NewName "CommandDefinition_$guid1.xml"

    remove-item -Path "$tempdir\*%guid*.xml" -Confirm:$false

    # rezip
    $newfile = "$Name.dar"
    Write-Verbose "Rezipping to $newfile"
    InvokeZip -zippath "$newpath\$newfile" -sourcepath "$tempdir" -force

    # cleanup
    RemoveTempDirectory -path $tempdir
    Remove-Item -Path $tmpSetupfile
    Write-Host "Finished"
    Write-Host "Find your new dar file in [$newpath]"

}

function Update-WfaSetupWorkflow
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Path of the package (folder path)
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Path,

        # Name of the package you want installed (friendly name)
        [Parameter(Mandatory=$true)]
        [ValidatePattern("\.dar$")]
        [string]$DarPath,

        # New version of the workflow (optional)
        [Parameter(Mandatory=$false)]
        [ValidatePattern("[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}")]
        [string]$Version
    )

    # unzip
    $tempdir = GetTempDirectory
    Write-Verbose "Unzipping to $tempdir"
    InvokeUnzip -zipfile "$DarPath" -outpath "$tempdir"

    $DarFileNoExt = $DarPath -replace "\.dar$",""

    # finding workflow path & files path
    $oZipPath = (Get-ChildItem -Path $tempdir -Filter "*.zip.jpg" -Recurse)
    if(-not $oZipPath){
        RemoveTempDirectory $tempdir
        Throw "This dar file does not seem to be a setup dar file (not finding previous zip package)"
    }
    $zipPath = @($oZipPath)[0].FullName
    if(($zipPath -split "\\")[-2] -ne "files"){
        RemoveTempDirectory $tempdir
        Throw "This dar file does not seem to be a setup dar file (not finding files directory)"        
    }

    $oWorkflowPath = (Get-ChildItem -Path $tempdir -Filter "TabularWorkflow_*.xml")
    if(-not $oWorkflowPath.Length -eq 1){
        RemoveTempDirectory $tempdir
        Throw "This dar file does not seem to be a setup dar file (there should be 1 workflow xml file)"
    }
    $workflowPath = @($oWorkflowPath)[0].FullName

    Write-Host "Dar file seems ok"
    Write-Host "Removing old zip file"
    Remove-Item $zipPath -Force -Confirm:$false
    Write-Host "Updating dar with new zip file"
    $tmpSetupfile = ([System.IO.Path]::GetTempFileName()) -replace  "\.tmp",".zip"
    Write-Verbose "Zipping your files"
    InvokeZip -zippath $tmpSetupfile -sourcepath "$Path" -force

    # too big ?
    if((Get-Item $tmpSetupfile).length -gt 2MB){
        RemoveTempDirectory -path $tempdir
        Remove-Item -Path $tmpSetupfile        
        Throw "Your content is too big to include in a workflow (max 2MB)"
    }

    Write-Verbose "Moving your zip file"
    Copy-Item -Path $tmpSetupfile -Destination $zipPath
    
    Write-Verbose "Updating version"
    (Get-Content $workflowPath) | 
        % {$_ -replace '<version>([0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2})<\/version>',"<version>$version</version>"} |
        Out-File $workflowPath -Encoding "UTF8"        

    # rezip
    Write-Verbose "Rezipping"
    $newpath = ("{0}_{1}.dar" -f $DarFileNoExt,$version)
    InvokeZip -zippath $newpath -sourcepath "$tempdir" -force

    # cleanup
    RemoveTempDirectory -path $tempdir
    Remove-Item -Path $tmpSetupfile
    Write-Host "Finished"
    Write-Host "Find your new dar file in [$newpath]"

}

Export-ModuleMember -Function *-WfaSetupWorkflow