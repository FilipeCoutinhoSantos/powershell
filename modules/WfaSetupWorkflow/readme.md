# GenerateSetupWorkflow
If you create advanced workflows, you might have the need to upload you own files.  Typically modules, or some config files.
Modules need to be copied tot the \posh\modules directory.  Other files you might want to copy to the WFA root directoy or maybe just a custom directory.
That means that you need to create a setup manual saying where the customer should copy the files you provide.

But why not just create a workflow that does this for you.  it can be done, if the content is limited in size (Max 2MB).

## How
The idea is this : in a workflow we can embed help files.  Typically some html files and some images.  These are part of the dar file of the workflow.
If you import the dar file, these help files are nicely copied along in a fixed directory and using the workflow guid.  So if we can zip our files, rename that zip to setup.jpg for example, we can have our custom files/modules copied along during the import of the dar.

The only thing left is then to tell the customer to run your setup workflow that will grab that jpg (actually a zip file) file and unzip it into the modules,wfa or custom directory.

I've done it before with my PSWord/PSExcel installer, but it's a bit of a messy process to get it processed.  So I figured, let's create a powershell script that does it for you :).

## Cmdlets
- New-WfaSetupWorkflow
- Update-WfaSetupWorkflow

## New-WfaSetupWorkflow Parameters
- path : path of your files (it will not copy the parent directory, only the files in it)
- name : a short friendly name of your package/files
- workflow name : the name of the eventual install workflow
- destination folder name : the name of your destination folder
- destination type : the type of destination (module/wfa/custom)
- custom path : the custom destination path (if custom is chosen)

## New-WfaSetupWorkflow Types
It allows 3 types
- module : will copy your files to the module directory under a folder of your preference (name)
- wfa : will copy your files to the wfa root directory under a folder of your preference (name)
- custom : will copy your files to a custom directory under a folder of your preference (name) and the end-user is still capable of changing the customer directory path

## Update-WfaSetupWorkflow Parameters
- path : path of your files (it will not copy the parent directory, only the files in it)
- darpath : path of existing dar file
- version : new version of the containing workflow

## Setup
Download this module, import it and use the cmdlet "New-WfaSetupWorkflow".  The end result is a ready-to-import dar file, containing a workflow that will copy your files.

## Notes
The files will always be copied into a sub folder.  it's the only way to also provide a remove action.

## Examples
``` powershell
New-WfaSetupWorkflow -Path C:\temp\svmtool -DestinationFolderName svmtool -Name "Svm Dr Module" -WorkflowName "Svm Dr - Install Module" -DestinationPathType Module
Generating your dar for ''


    Directory: C:\Users\Mirko\Documents\GitHub\powershell\modules


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----       13/11/2018     12:54                WfaSetupWorkflows

7-Zip (A) 9.20  Copyright (c) 1999-2010 Igor Pavlov  2010-11-18
Scanning

Creating archive C:\Users\Mirko\AppData\Local\Temp\tmpC45D.zip

Compressing  svmtool.ps1
Compressing  svmtool.psd1
Compressing  svmtool.psm1
Compressing  svmtools\log4net.dll
Compressing  svmtools\svmtools.psd1
Compressing  svmtools\svmtools.psm1
Compressing  wfa.ini

Everything is Ok

7-Zip (A) 9.20  Copyright (c) 1999-2010 Igor Pavlov  2010-11-18
Scanning

Creating archive C:\Users\Mirko\Documents\GitHub\powershell\modules\WfaSetupWorkflows\Svm Dr Module.dar

Compressing  CommandDefinition_96439f56-9193-4b88-9556-847c75a93d76.xml
Compressing  META-INF\MANIFEST.MF
Compressing  TabularWorkflow_3df5012c-2ba2-467a-b088-f3d20d69e29a.xml
Compressing  workflow-help\TabularWorkflow_3df5012c-2ba2-467a-b088-f3d20d69e29a\files\svmtool.zip.jpg
Compressing  workflow-help\TabularWorkflow_3df5012c-2ba2-467a-b088-f3d20d69e29a\index.htm

Everything is Ok
Finished
Find your new dar file in [C:\Users\Mirko\Documents\GitHub\powershell\modules\WfaSetupWorkflows]
```
```powershell
New-WfaSetupWorkflow -Path C:\temp\demo -DestinationFolderName demo -Name "Demo Files" -WorkflowName "Copy demo files to Wfa" -DestinationPathType Custom -CustomPath c:\temp
Generating your dar for ''

7-Zip (A) 9.20  Copyright (c) 1999-2010 Igor Pavlov  2010-11-18
Scanning

Creating archive C:\Users\Mirko\AppData\Local\Temp\tmp6647.zip

Compressing  config.xlsx
Compressing  demo.xlsx

Everything is Ok

7-Zip (A) 9.20  Copyright (c) 1999-2010 Igor Pavlov  2010-11-18
Scanning

Creating archive C:\Users\Mirko\Documents\GitHub\powershell\modules\WfaSetupWorkflows\Demo Files to copy.dar

Compressing  CommandDefinition_37dbc0a8-19cf-4e28-badf-4624d8dd95c4.xml
Compressing  META-INF\MANIFEST.MF
Compressing  TabularWorkflow_e76cb49b-7815-482f-8265-067cc04aa762.xml
Compressing  workflow-help\TabularWorkflow_e76cb49b-7815-482f-8265-067cc04aa762\files\demo.zip.jpg
Compressing  workflow-help\TabularWorkflow_e76cb49b-7815-482f-8265-067cc04aa762\index.htm

Everything is Ok
Finished
Find your new dar file in [C:\Users\Mirko\Documents\GitHub\powershell\modules\WfaSetupWorkflows]
```
```powershell
Update-WfaSetupWorkflow c:\temp\demo -DarPath '.\WfaSetupWorkflows\test.dar' -Version 1.0.1 -Verbose
VERBOSE: Creating tmp directory C:\Users\Mirko\AppData\Local\Temp\tmp6B33.tmp
VERBOSE: Unzipping to C:\Users\Mirko\AppData\Local\Temp\tmp6B33.tmp
Dar file seems ok
Removing old zip file
Updating dar with new zip file
VERBOSE: Zipping your files
VERBOSE: creating zip file C:\Users\Mirko\AppData\Local\Temp\tmp6B54.zip [from c:\temp\demo]

7-Zip (A) 9.20  Copyright (c) 1999-2010 Igor Pavlov  2010-11-18
Scanning

Creating archive C:\Users\Mirko\AppData\Local\Temp\tmp6B54.zip

Compressing  config.xlsx
Compressing  demo.xlsx

Everything is Ok
VERBOSE: Moving your zip file
VERBOSE: Updating version
VERBOSE: Rezipping
VERBOSE: Removing previous zip file .\WfaSetupWorkflows\test_1.0.1.dar
VERBOSE: creating zip file .\WfaSetupWorkflows\test_1.0.1.dar [from C:\Users\Mirko\AppData\Local\Temp\tmp6B33.tmp]

7-Zip (A) 9.20  Copyright (c) 1999-2010 Igor Pavlov  2010-11-18
Scanning

Creating archive .\WfaSetupWorkflows\test_1.0.1.dar

Compressing  CommandDefinition_7d124585-4285-4741-a3e7-de80c77b02e9.xml
Compressing  META-INF\MANIFEST.MF
Compressing  TabularWorkflow_aafd0f7f-a16d-476d-9d8f-54389aa5be60.xml
Compressing  workflow-help\TabularWorkflow_aafd0f7f-a16d-476d-9d8f-54389aa5be60\files\test.zip.jpg
Compressing  workflow-help\TabularWorkflow_aafd0f7f-a16d-476d-9d8f-54389aa5be60\index.htm

Everything is Ok
VERBOSE: Removing directory C:\Users\Mirko\AppData\Local\Temp\tmp6B33.tmp
Finished
Find your new dar file in [.\WfaSetupWorkflows\test_1.0.1.dar]
```