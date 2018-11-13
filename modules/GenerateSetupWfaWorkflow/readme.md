# GenerateSetupWorkflow
If you create advanced workflows, you might have the need to upload you own files.  Typically modules.
These are best copied tot the \posh\modules directory.  Because a wfa backup will backup these too.
That means that you need to create a setup manual saying the customer should copy this folder to that directory.

But why not just create a workflow that does this for you.  it can be done, if the content is limited in size.
The idea is this : in a workflow we can embed help files.  Typically some html files and some images.  These are part of the dar file of the workflow.
If you import the dar file, these help files are nicely copied along in a fixed directory and using the workflow guid.
So if we can zip our files, rename that zip to setup.jpg for example, we can have our package copied along during the import of the dar.

The only thing left is then have the customer run a workflow that will grab that jpg file, rename it to zip, unzip it into the modules directory.

I've done it before with my PSWord/PSExcel installer, but it's a bit of a messy process to get it processed.  So I figured, let's create a powershell script that does it for you :).


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
New-WfaSetupWorkflow -Path C:\temp\demo -FriendlyName Testje -name test -DestinationPathType
Custom -CustomPath c:\temp\test
Generating setup dar for 'Testje'

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
