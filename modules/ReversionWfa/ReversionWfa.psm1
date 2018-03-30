$SCRIPT_PATH =(Split-Path (Resolve-Path $myInvocation.MyCommand.Path)) 
$FULL_SCRIPT_PATH = (Resolve-Path $myInvocation.MyCommand.Path)
$CURRENT_PATH = ((Get-Location).Path)

$ManifestList = @{}
$ManifestList.Add('3.0',"$SCRIPT_PATH\MANIFEST3.0.MF")
$ManifestList.Add('3.1',"$SCRIPT_PATH\MANIFEST3.1.MF")
$ManifestList.Add('4.0',"$SCRIPT_PATH\MANIFEST4.0.MF")
$ManifestList.Add('4.1',"$SCRIPT_PATH\MANIFEST4.1.MF")
$ManifestList.Add('4.2',"$SCRIPT_PATH\MANIFEST4.2.MF")

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
    Write-Verbose "Creating tmp directory $path"
    $tempdir = new-item -type directory -path $tempfile;
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
   Re-version 1 or more dar files
.DESCRIPTION
   Re-version 1 or more dar files
   - accepts pipeline input (Name)
   - allows verbose logging
   - allows force overwrites
   - doesn't touch your originals
   - new dars are in a new directory
.EXAMPLE
    PS C:\Users\Mirko\Desktop> dir *.dar | Set-WfaVersion -Version 4.0

    DOWNGRADING DAR-FILES TO VERSION 4.0
    MAJOR : 4
    MINOR : 0
    Processing empty_aggr_101.dar
    Already current [4.0.0.0.0]
    Processing fcp_lif_fixed.dar
    Higher version detected [4.1.0.0.0], downgrading
    Processing modify_volume_autosize_threshold.dar
    Already current [4.0.0.0.0]
    Processing set_atime.dar
    Already current [4.0.0.0.0]
    Processing Update_Ontap_broken.dar
    Already current [4.0.0.0.0]
    Processing volume_move_pack.dar
    Already current [4.0.0.0.0]
    Finished
    Find your new dar files in [C:\Users\Mirko\Desktop\Wfa Versions 4.0]
.EXAMPLE
    PS C:\Users\Mirko\Desktop> dir *.dar | Set-WfaVersion -Version 3.1 -Verbose

    DOWNGRADING DAR-FILES TO VERSION 3.1
    MAJOR : 3
    MINOR : 1
    VERBOSE: Detecting lower than 4.0, removing dependencies
    Processing empty_aggr_101.dar
    VERBOSE: Creating tmp directory 
    VERBOSE: Unzipping to C:\Users\Mirko\AppData\Local\Temp\tmp7AF4.tmp
    VERBOSE: version 4.0 -> 3.1
    Higher version detected [4.0.0.0.0], downgrading
    VERBOSE: Overwriting manifest file
    VERBOSE: Removing dependencies file
    VERBOSE: Rezipping to empty_aggr_101_(3.1).dar
    VERBOSE: Removing previous zip file C:\Users\Mirko\Desktop\Wfa Versions 3.1\empty_aggr_101_(3.1).dar
    VERBOSE: creating zip file C:\Users\Mirko\Desktop\Wfa Versions 3.1\empty_aggr_101_(3.1).dar [from C:\Users\Mirko\AppData\Local\Temp\tmp7AF4.tmp]
    VERBOSE: Removing directory C:\Users\Mirko\AppData\Local\Temp\tmp7AF4.tmp
    Processing fcp_lif_fixed.dar
    VERBOSE: Creating tmp directory 
    VERBOSE: Unzipping to C:\Users\Mirko\AppData\Local\Temp\tmp7B43.tmp
    VERBOSE: version 4.1 -> 3.1
    Higher version detected [4.1.0.0.0], downgrading
    VERBOSE: Overwriting manifest file
    VERBOSE: Removing dependencies file
    VERBOSE: Rezipping to fcp_lif_fixed_(3.1).dar
    VERBOSE: Removing previous zip file C:\Users\Mirko\Desktop\Wfa Versions 3.1\fcp_lif_fixed_(3.1).dar
    VERBOSE: creating zip file C:\Users\Mirko\Desktop\Wfa Versions 3.1\fcp_lif_fixed_(3.1).dar [from C:\Users\Mirko\AppData\Local\Temp\tmp7B43.tmp]
    VERBOSE: Removing directory C:\Users\Mirko\AppData\Local\Temp\tmp7B43.tmp
    Finished
    Find your new dar files in [C:\Users\Mirko\Desktop\Wfa Versions 3.1]
#>
function Set-WfaVersion
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Dar File - Accepts Pipeline Input
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
        [string[]]$Name,

        # Wfa Version
        [Parameter(Mandatory=$true,Position=1)]
        [ValidateSet('3.0','3.1','4.0','4.1','4.2')]
        [string]$Version,

        # Remove Dependencies (anything lower than 4.0 is default true)
        [switch]$RemoveDependencies,

        # Force the change even if the version already seems right
        [switch]$Force,

        # Force the change even if the version is lower
        [switch]$ForceUpgrade
    )

    Begin
    {

        Write-Host "DOWNGRADING DAR-FILES TO VERSION $Version"
        $newpath = "$pwd\Wfa Versions $Version"
        if(-not (Test-Path $newpath)){
            New-Item -ItemType Directory -Force -Path "$pwd\Wfa Versions $Version"
        }
        $newMajorVersion = [int](($Version -split "\.")[0])
        $newMinorVersion = [int](($Version -split "\.")[1])
        Write-Host "MAJOR : $newMajorVersion"
        Write-Host "MINOR : $newMinorVersion"
        if($newMajorVersion -lt 4){
            Write-Verbose "Detecting lower than 4.0, removing dependencies"
            $RemoveDependencies=$true
        }
    }
    Process
    {
        foreach($dar in $Name){
            $filename = "$pwd\$dar"
            $filepart = [System.IO.Path]::GetFilenameWithoutExtension($dar)
            $fileextension = [System.IO.Path]::GetExtension($dar)
            if($fileextension -eq ".dar"){
                Write-Host "Processing $dar" -ForegroundColor Magenta
                
                # unzip
                $tempdir = GetTempDirectory
                Write-Verbose "Unzipping to $tempdir"
                InvokeUnzip -zipfile "$filename" -outpath "$tempdir"

                # check current version
                $iscurrent = $false
                $islower = $false
                $ishigher = $false
                $proceed = $true
                $fullversion = $null

                $manifestpath = "$tempdir\META-INF\MANIFEST.MF"
                foreach($l in ((Get-Content -Path $manifestpath) -split "`n")){
                    if($l -match "dar-version: (\d)\.(\d)\.\d\.\d\.\d"){
                        $fullversion = $Matches[0] -replace "dar-version: "
                        $majorversion = [int]$Matches[1]
                        $minorversion = [int]$Matches[2]
                        $currentversion = $("$majorversion")+"."+$("$minorversion")
                        break
                    }
                }

                if(-not $fullversion){
                    Write-Warning "No version found !!"
                }else{

                    Write-Verbose "version $currentversion -> $version"

                    # compare versions (first 2 only)
                    if($majorversion -lt $newMajorVersion){
                        $islower = $true
                    }elseif($majorversion -eq $newMajorVersion){
                        if($minorversion -lt $newMinorVersion){
                            $islower = $true
                        }elseif($minorversion -eq $newMinorVersion){
                            $iscurrent = $true
                        }elseif($minorversion -gt $newMinorVersion){
                            $ishigher = $true
                        }
                    }elseif($majorversion -gt $newMajorVersion){
                        $ishigher = $true
                    }
                
                    # check if we need to continue
                    if($iscurrent){
                        if($Force){
                            Write-Warning "Already current [$fullversion], but replacing anyway"
                        }else{
                            Write-Success "Already current [$fullversion]"
                            $proceed = $false
                        }
                    }

                    if($islower){
                        if($ForceUpgrade){
                            Write-Warning "Already lower [$fullversion], but upgrading anyway"
                        }else{
                            Write-Success "Already lower [$fullversion]"
                            $proceed = $false
                        }
                    }

                    if($ishigher){
                        Write-Success "Higher version detected [$fullversion], downgrading"
                    }

                    if($proceed){
                        Write-Verbose "Overwriting manifest file [$($ManifestList.Get_Item($Version)) -> $manifestpath]"
                        Copy-Item -Path $ManifestList.Get_Item($Version) -Destination $manifestpath -Force -Confirm:$false
                        $fileversion=$Version
                    }else{
                        $fileversion=$currentversion
                    }

                    if($RemoveDependencies){
                        $dependenciespath = "$tempdir\dependencies.xml"
                        if(Test-Path $dependenciespath){
                            Write-Verbose "Removing dependencies file"
                            Remove-Item -Path $dependenciespath -Force -Confirm:$false
                        }
                    }

                    # rezip
                    $newfile = $filepart + "_($fileversion).dar"
                    Write-Verbose "Rezipping to $newfile"
                    InvokeZip -zippath "$newpath\$newfile" -sourcepath "$tempdir" -force
                }
                # cleanup
                RemoveTempDirectory -path $tempdir
            }
        }
    }
    End
    {
        Write-Host "Finished"
        Write-Host "Find your new dar files in [$newpath]"
    }
}

Export-ModuleMember -Function Set-WfaVersion