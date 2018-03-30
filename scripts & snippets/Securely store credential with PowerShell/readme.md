# Securily store (and retrieve) credentials with powershell
I you have ever written PowerShell, you probably encountered the challenge that you need to store credentials for your script.  While debugging you probably hard code your credentials in your script, but once you have the script in production (manually or scheduled), you probably don't want them in the script in clear text.

This piece of code is pretty old but still does the trick.

Use Save-Credentials (host based) or Save-DefaultCredentials (default fallback) to store credentials.
It will prompt you for credentials and save text-files in a .\input directory.  the password will be encrypted (within the user context).

Later in your script you can use Get-SavedCredentials to get them.  When you get the credentials, it will have to be in the same user context. (So when scheduling your script, run it as the same user !)
Getting them within a different user context will fail to decrypt the password.

## Examples
Save defaults
``` powershell
Save-DefaultCredentials -username wfaguy -password awesome
```
Save specific credentials
``` powershell
Save-Credentials -name my_host -username wfaguy -password awesome
```
Get credentials (secure object)
``` powershell
Get-SavedCredentials -name my_host
```

## Extra's
The Get-SavedCredentials cmd-let is pretty intelligent, if there no stored credentials, if will prompt for it.  
You have a flag -save, that will save your new credentials.