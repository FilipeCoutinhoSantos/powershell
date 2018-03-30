# ReversionWfa
Ever got a dar file that had a higher version than you wanted ?
Now, if you are a clever guy, and you know the package might still work in the lower version, then you must have done the following :
Unzip the dar, Change the manifest file, Rezip the files, Rename to dar
I'm pretty sure, I know I did, you have made the common mistake of rezipping the top folder instead of files, breaking your dar,  Right :) ?

Anyhow, I bumped into the same issue over and over this week (my local wfa = 4.1 and my customer was on 4.0), so I (finally) build a powershell script (even better : a module) that will do this for you.

# Notes
* This isn't a guaranteed fix.  If your workflows are using new features, it might still not work.
* Add your own manifests if needed
* 3.0 -> 4.2 support
* Includes 7zip.exe
* Since 4.0, there are packs and dependencies, they sometime get in your way, so you can optionally remove the dependencies too.

## How to install
Just create a new folder in your modules folder, name it "reversionWfa" and copy the "reversionWfa.psm1" file in it.  Or you can always manually import the module.
you should now have a cmdlet called : Set-WfaVersion

You can do something like : dir *.dar | Set-WfaVersion 4.0 -force -verbose
Check out the help too ! (get-help set-wfaversion -full)

## Feature list 
* accepts pipeline input (Name)
* allows verbose logging
* allows force overwrites
* allows remove dependencies
* doesn't touch your originals
* new dars are in a new directory (per version)

## Examples
``` powershell
dir *.dar | Set-WfaVersion -Version 4.0
```
``` powershell
Set-WfaVersion -Name .\myworkflow.dar -Version 4.1
```

