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

## Parameters
- path : path of your files (it will not copy the parent directory, only the files in it)
- name : a short name, but also the name of the destination folder, so avoid special characters
- friendly name : the description of your package/setup/files
- destination type : the type of destination (module/wfa/custom)
- custom path : the custom destination path (if custom is chosen)

## Types
It allows 3 types
- module : will copy your files to the module directory under a folder of your preference (name)
- wfa : will copy your files to the wfa root directory under a folder of your preference (name)
- custom : will copy your files to a custom directory under a folder of your preference (name) and the end-user is still capable of changing the customer directory path

## Setup
Download this module, import it and use the cmdlet "New-WfaSetupWorkflow".  The end result is a ready-to-import dar file, containing a workflow that will copy your files.

## Examples
``` powershell
New-WfaSetupWorkflow -Path C:\temp\svmtool -FriendlyName "Svm Dr tool" -naGenerating setup dar for 'Svm Dr tool'

7-Zip (A) 9.20  Copyright (c) 1999-2010 Igor Pavlov  2010-11-18
Scanning

Creating archive C:\Users\Mirko\AppData\Local\Temp\tmpF7C6.zip

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

Creating archive C:\Users\Mirko\Documents\GitHub\powershell\modules\WfaSetupWorkflows\svmtool.dar

Compressing  CommandDefinition_bece4151-a144-4100-9864-b30e57582e88.xml
Compressing  META-INF\MANIFEST.MF
Compressing  TabularWorkflow_57b2903e-04a1-4957-bb13-75f4283dab2b.xml
Compressing  workflow-help\TabularWorkflow_57b2903e-04a1-4957-bb13-75f4283dab2b\files\svmtool.zip.jpg
Compressing  workflow-help\TabularWorkflow_57b2903e-04a1-4957-bb13-75f4283dab2b\index.htm

Everything is Ok
Finished
Find your new dar file in [C:\Users\Mirko\Documents\GitHub\powershell\modules\WfaSetupWorkflows]
```
```powershell
New-WfaSetupWorkflow -Path C:\temp\demo -FriendlyName "My Demo" -name test -DestinationPathType
Custom -CustomPath c:\temp
Generating setup dar for 'My Demo'

7-Zip (A) 9.20  Copyright (c) 1999-2010 Igor Pavlov  2010-11-18
Scanning

Creating archive C:\Users\Mirko\AppData\Local\Temp\tmpEEA2.zip

Compressing  config.xlsx
Compressing  demo.xlsx

Everything is Ok

7-Zip (A) 9.20  Copyright (c) 1999-2010 Igor Pavlov  2010-11-18
Scanning

Creating archive C:\Users\Mirko\Documents\GitHub\powershell\modules\WfaSetupWorkflows\test.dar

Compressing  CommandDefinition_7d124585-4285-4741-a3e7-de80c77b02e9.xml
Compressing  META-INF\MANIFEST.MF
Compressing  TabularWorkflow_aafd0f7f-a16d-476d-9d8f-54389aa5be60.xml
Compressing  workflow-help\TabularWorkflow_aafd0f7f-a16d-476d-9d8f-54389aa5be60\files\test.zip.jpg
Compressing  workflow-help\TabularWorkflow_aafd0f7f-a16d-476d-9d8f-54389aa5be60\index.htm

Everything is Ok
Finished
Find your new dar file in [C:\Users\Mirko\Documents\GitHub\powershell\modules\WfaSetupWorkflows]
```
