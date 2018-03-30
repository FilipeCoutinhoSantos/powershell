# WriteLog Module
I've seen many PowerShell scripts in my career.  Fantastic ones and aweful ones.  But I have very very rarely seen scripts where proper logging has been done.  Everyone seems to know write-output.  The clever ones know write-verbose and write-warning.  Some are really smart and write their own logging functions, allowing some level of customization.

But...

If you really want to show off with your logging, you need the full monty.  You want screen logging, rolling log files with automated time-stamps and you want event viewer logging.  Obviously, you want to have control of what and when.
Well, today is you lucky day, because I've written it for you :)

Visit more info on [my blog http://wfaguy.com](http://www.wfaguy.com/2016/12/powershell-logging-professional-way.html)

## Log4Net
If you want professional logging, why re-invent the wheel in the first place.  Microsoft wrote this dll ages ago and it does the job flawlessly.  But you need to know how it works.  It took me a very long time to have it configured correctly.
I could post the code here, but do you really want to see it ?  I've made you a nice module.  Just copy it to your modules and you should be all set.

## WriteLog module
I have full help enabled, so use the powershell get-help cmd-let to find out more.
* **Write-LogInfo** : Info message
* **Write-LogWarning** : Warning message
* **Write-LogError** : Error message
* **Write-LogFatal** : Fatal message
* **Write-Verbose** : Verbose message
* **Write-LogTitle** : Title message (with nice underline)
* **Write-LogErrorObject** : Error Object message (just pass the error object)
* **Write-LogSuccess** : Info-like message, but green in the console

``` powershell
PS C:\jumpstart\wfaguy> Write-LogTitle "This is a nice title"
This is a nice title
--------------------

PS C:\jumpstart\wfaguy> Write-LogInfo "This is a message"
This is a message

PS C:\jumpstart\wfaguy> Write-LogWarning "Watch out!"
WARNING: Watch out!

PS C:\jumpstart\wfaguy> Write-LogError "Ouch, that wasn't ok"
Ouch, that wasn't ok

PS C:\jumpstart\wfaguy> $service = Get-Service W32Time

PS C:\jumpstart\wfaguy> $service | Select Name,DisplayName,Status

Name    DisplayName   Status
----    -----------   ------
W32Time Windows Time Running


PS C:\jumpstart\wfaguy> Write-LogObject ($service | Select Name,DisplayName,Status)

Name        : [W32Time]
DisplayName : [Windows Time]
Status      : [Running]

PS C:\jumpstart\wfaguy> try { this_is_going_wrong } catch { Write-LogErrorObject $_ }
PS C:\jumpstart\wfaguy> Write-LogError "Ouch, that wasn't ok"
ENDED WITH ERROR
Message               : [The term 'this_is_going_wrong' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is correct and try again.]
Type                  : [System.Management.Automation.CommandNotFoundException]
CategoryInfo          : [ObjectNotFound: (this_is_going_wrong:String) [], CommandNotFoundException]
Exception             : [System.Management.Automation.CommandNotFoundException: The term 'this_is_going_wrong' is not recognized as the name of a cmdlet,  function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
   at System.Management.Automation.ExceptionHandlingOps.CheckActionPreference(FunctionContext funcContext, Exception exception)
   at System.Management.Automation.Interpreter.ActionCallInstruction`2.Run(InterpretedFrame frame)
   at System.Management.Automation.Interpreter.EnterTryCatchFinallyInstruction.Run(InterpretedFrame frame)
   at System.Management.Automation.Interpreter.EnterTryCatchFinallyInstruction.Run(InterpretedFrame frame)]
FullyQualifiedErrorId : [CommandNotFoundException]
InvocationInfo        : [System.Management.Automation.InvocationInfo]
ScriptStackTrace      : [at <ScriptBlock>, <No file>: line 1]
TargetObject          : [this_is_going_wrong] 
```

Now this is just the console logging part, here is the cool part :

## Initialize-Logger
Watch what happens, if you initialize the logger...  Note that I have added help in the code, get-help is your friend.

``` powershell
Initialize-Logger -LoggerName "WfaGuy"


EmittedNoAppenderWarning : False
Root                     : log4net.Repository.Hierarchy.RootLogger
LoggerFactory            : log4net.Repository.Hierarchy.DefaultLoggerFactory
Name                     : WfaGuyLogger
Threshold                : ALL
RendererMap              : log4net.ObjectRenderer.RendererMap
PluginMap                : log4net.Plugin.PluginMap
LevelMap                 : log4net.Core.LevelMap
Configured               : False
ConfigurationMessages    : {}
Properties               : {}

LastWriteTime : 9/12/2016 18:50:41
Length        : 0
Name          : WfaGuy.log

PS C:\jumpstart\wfaguy> Write-LogTitle "This is a nice title"
This is a nice title
--------------------

PS C:\jumpstart\wfaguy> Write-LogInfo "This is a message"
This is a message

PS C:\jumpstart\wfaguy> Write-LogVerbose "This is a verbose message"

PS C:\jumpstart\wfaguy> Write-LogWarning "Watch out!"
WARNING: Watch out!

PS C:\jumpstart\wfaguy> Write-LogError "Oooh, that hurts"
Oooh, that hurts

PS C:\jumpstart\wfaguy> type .\WfaGuy.log

2016-12-09 18:51:07,663 INFO  WfaGuy : This is a nice title
2016-12-09 18:51:07,679 INFO  WfaGuy : --------------------
2016-12-09 18:51:15,235 INFO  WfaGuy : This is a message
2016-12-09 18:51:37,116 WARN  WfaGuy : Watch out!
2016-12-09 18:51:47,554 ERROR WfaGuy : Oooh, that hurts

PS C:\jumpstart\wfaguy> Remove-Logger

PS C:\jumpstart\wfaguy> Initialize-Logger "WfaGuy" -logLevel debug

PS C:\jumpstart\wfaguy> Write-LogVerbose "This is a verbose message"

PS C:\jumpstart\wfaguy> type .\WfaGuy.log

2016-12-09 18:51:07,663 INFO  WfaGuy : This is a nice title
2016-12-09 18:51:07,679 INFO  WfaGuy : --------------------
2016-12-09 18:51:15,235 INFO  WfaGuy : This is a message
2016-12-09 18:51:37,116 WARN  WfaGuy : Watch out!
2016-12-09 18:51:47,554 ERROR WfaGuy : Oooh, that hurts
2016-12-09 18:53:38,748 DEBUG WfaGuy : This is a verbose message

```

## EventViewer
Note that it will log to the eventviewer too !  By default I've set the EventLevel to "warn". 
PS : first time, the eventlog source needs to be created, run-as administrator is required here !

All logging cmd-lets support "-eventid" and "-category".