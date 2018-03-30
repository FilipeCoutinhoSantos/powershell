$ErrorActionPreference = 'STOP'
Set-Variable -Name SCRIPT_PATH -Value (Split-Path (Resolve-Path $myInvocation.MyCommand.Path)) -Scope local
Set-Variable -Name FULL_SCRIPT_PATH -Value (Resolve-Path $myInvocation.MyCommand.Path) -Scope local
Set-Variable -Name CURRENT_PATH -Value ((Get-Location).Path) -Scope local
Set-Variable -Name LOGGER -Value $null -Scope global
Set-Variable -Name VERBOSE_ENABLED -Value $false -Scope global

# String Helpers
Function GetPadLength($Object,$Property){
    if($Object){
        return [int](($Object |%{($_.PsObject.Properties[$Property]).Value.length} | measure -Maximum).Maximum)
    }else{
        return 0
    }
}
# Host output Helpers
Function WriteHost{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$true,Position=1)]
        $Object,
        [switch]$NoNewLine,
        $Color="White"
    )
    process{
        Write-host -Object $Object -ForegroundColor $Color -NoNewline:$NoNewLine -Separator ","
    }
}
Function WritePadded{
    [CmdletBinding()]
    Param(
        [string]$Text="",
        [string]$Color="Yellow",
        [int]$PadLength,
        [switch]$AsValue,
        [string]$Prefix,
        [string]$Suffix,
        [switch]$NoNewLine=$true
    )
    begin{}
    process{

        if($Prefix){
            WriteHost $Prefix -NoNewline
        }
        if($AsValue){
            WriteHost "[" -NoNewLine
        }
        WriteHost $Text -NoNewline -Color $Color
        if($AsValue){
            WriteHost "]" -NoNewLine
        }
        if($PadLength -and ($PadLength -ge $Text.Length)){
            WriteHost "".PadRight(($PadLength-$Text.Length)," ") -NoNewline
        }
        if($Suffix){
            WriteHost $Suffix -NoNewline
        }
        if(-not $NoNewLine){
            WriteHost ""
        }
    }
}
<#
.Synopsis
   Logs a warning message
#>
Function Write-LogWarning{
    [CmdletBinding()]
    Param(
        [string]$Text,
        [int]$EventId=100,
        [int]$Category=0
    )
    Process{
        Write-Warning $Text

        try{
            SetLog4NetEventLogEventId -EventId $EventId -Category $Category
            $Global:LOGGER.Warn($Text)
        }catch{
        }
    }
}
<#
.Synopsis
   Logs a verbose message
#>
Function Write-LogVerbose{
    [CmdletBinding()]
    Param(
        [string]$Text
    )
    Begin{
    }
    Process{
        if($Global:VERBOSE_ENABLED){
            WriteHost "VERBOSE: $Text" -Color Cyan
        }
        try{
            $Global:LOGGER.Debug($Text)
        }catch{}
    }
}
<#
.Synopsis
   Logs a message
#>
Function Write-LogInfo{
    [CmdletBinding()]
    Param(
        [string]$Text,
        [int]$EventId=0,
        [int]$Category=0
    )
    Process{
        WriteHost $Text
        try{
            SetLog4NetEventLogEventId -EventId $EventId -Category $Category
            $Global:LOGGER.Info($Text)
        }catch{}
    }
}
<#
.Synopsis
   Logs a success message (in green)
#>
Function Write-LogSuccess{
    [CmdletBinding()]
    Param(
        [string]$Text,
        [int]$EventId=1,
        [int]$Category=0
    )
    Process{
        WriteHost $Text -Color Green
        try{
            SetLog4NetEventLogEventId -EventId $EventId -Category $Category
            $Global:LOGGER.Info($Text)
        }catch{}
    }
}
<#
.Synopsis
   Logs an error message (in red)
#>
Function Write-LogError{
    [CmdletBinding()]
    Param(
        [string]$Text,
        [int]$EventId=101,
        [int]$Category=0,
        # if you want the error to be verbose instead
        [switch]$AsVerbose
    )
    Process{
        WriteHost "$Text" -Color Red
        try{
            SetLog4NetEventLogEventId -EventId $EventId -Category $Category
            if($AsVerbose){
                $Global:LOGGER.Debug($Text)
            }else{
                $Global:LOGGER.Error($Text)
            }
        }catch{}
            
    }
}
<#
.Synopsis
   Logs a nice title
#>
Function Write-LogTitle{
    [CmdletBinding()]
    Param(
        [string]$Title,
        [string]$Color="Cyan",
        [int]$EventId=0,
        [int]$Category=0,
        # if you want the title to be verbose instead
        [switch]$AsVerbose
    )
    Begin{}
    Process{
        if($Title){
            WriteHost "`n$Title" -Color $Color 
            WriteHost "".PadRight($Title.Length,"-")
            try{
                SetLog4NetEventLogEventId -EventId $EventId -Category $Category
                if($AsVerbose){
                    $Global:LOGGER.Debug($Title)
                    $Global:LOGGER.Debug("".PadRight($Title.Length,"-"))
                }else{
                    $Global:LOGGER.Info($Title)
                    $Global:LOGGER.Info("".PadRight($Title.Length,"-"))
                }
            }catch{}
        }
    }
}
<#
.Synopsis
   Logs a powershell object
.DESCRIPTION
   All properties must be string !! or it will fail
.EXAMPLE
    Write-LogObject (Get-Service W32Time | select Name,ServiceType,Status,DisplayName)
    Name        : [W32Time]
    ServiceType : [Win32ShareProcess]
    Status      : [Running]
    DisplayName : [Windows Time]
.INPUTS
   AsValue:$false => drops the brackets
   ExcludeEmpty => empty values are not shown
#>
Function Write-LogObject{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        $Object,
        [string]$LabelColor="White",
        [string]$ValueColor="Cyan",
        # show the values between brackets (default true)
        [switch]$AsValue = $true,
        # exclude empty values
        [switch]$ExcludeEmpty,
        # if you want the logging to be error instead
        [switch]$AsError,
        # if you want the logging to be verbose instead
        [switch]$AsVerbose,
        [int]$EventId=0,
        [int]$Category=0
    )
    Begin{

    }
    Process{
        $props = $Object.PsObject.Properties | select Name,Value
        $pl = GetPadLength -Object $props -Property Name
        $log = ""
        foreach($p in $props){
            if($p.Value -or (-not $ExcludeEmpty)){
                WritePadded -Text $p.Name -PadLength $pl -Color $LabelColor -Suffix " : "
                WritePadded -Text $p.Value -AsValue:$AsValue -Color $ValueColor -NoNewLine:$false
                $log += ($p.Name + " : [" + $p.Value + "]`n")
            }
        }
        try{
            if($AsError){
                SetLog4NetEventLogEventId -EventId $EventId -Category $Category
                $Global:LOGGER.Error($log)
            }elseif($AsVerbose){
                SetLog4NetEventLogEventId -EventId $EventId -Category $Category
                $Global:LOGGER.Debug($log)
            }else{
                SetLog4NetEventLogEventId -EventId $EventId -Category $Category
                $Global:LOGGER.Info($log)
            }
        }catch{}
    }
}
<#
.Synopsis
   Logs an error object
.EXAMPLE
   try{
      do_something()
   }catch{
      Write-LogErrorObject $_
   }
.INPUTS
   A true error object is expected
#>
Function Write-LogErrorObject{
    [CmdletBinding()]
    Param(
        $ErrorObject,
        [int]$EventId=100,
        [int]$Category=0
    )
    Process{
        $oError = "" | 
            Select "Message","Item","Type","CategoryInfo","ErrorDetails","Exception","FullyQualifiedErrorId","InvocationInfo","PipelineIterationInfo","ScriptStackTrace","TargetObject"

        $oError."Message" = $ErrorObject.Exception.Message
        $oError."Item" = $ErrorObject.Exception.ItemName
        $oError."Type" = $ErrorObject.Exception.GetType().FullName
        $oError."CategoryInfo" = $ErrorObject.CategoryInfo
        $oError."ErrorDetails" = $ErrorObject.ErrorDetails
        $oError."Exception" = $ErrorObject.Exception
        $oError."FullyQualifiedErrorId" = $ErrorObject.FullyQualifiedErrorId
        $oError."InvocationInfo" = $ErrorObject.InvocationInfo
        $oError."PipelineIterationInfo" = $ErrorObject.PipelineIterationInfo
        $oError."ScriptStackTrace" = $ErrorObject.ScriptStackTrace
        $oError."TargetObject" = $ErrorObject.TargetObject

        Write-LogError "ENDED WITH ERROR" -AsVerbose
        Write-LogObject -Object $oError -LabelColor Magenta -ExcludeEmpty -AsError -EventId $EventId -Category $Category
    }
}

# Logging Helper
function SetLog4NetEventLogEventId{
    Param
    (
        [Parameter(Mandatory=$true)]
        [int] $EventId,
        [Parameter(Mandatory=$true)]
        [int] $Category
    )
    [log4net.ThreadContext]::Properties.Item("EventID") = $EventId
    [log4net.ThreadContext]::Properties.Item("Category") = $Category
}
function GetLog4NetLevel{
    Param
    (
        [Parameter(Mandatory=$true)]
        $level
    )
    switch($level){
        "info"  {return [log4net.Core.Level]::Info}
        "debug" {return [log4net.Core.Level]::Debug}
        "warn"  {return [log4net.Core.Level]::Warn}
        "fatal" {return [log4net.Core.Level]::Fatal}
        "error" {return [log4net.Core.Level]::Fatal}
        "off"   {return [log4net.Core.Level]::Off}
        default {return [log4net.Core.Level]::All}
    }
}

<#
.Synopsis
   Initialize log4net
.DESCRIPTION
   Run this once, the logger must be initialized to write to logfiles or eventviewer
.EXAMPLE
   Initialize-Logger "MyLog"
.INPUTS
   More input to set logging levels and logging patterns.
#>
function Initialize-Logger{
    [CmdletBinding()]
    Param
    (
        # A unique name for your logging events
        [Parameter(Mandatory=$true)]
        [string]$LoggerName,

        # A pattern of the log messages
        [string]$LogPattern = "%date %-5p %c : %message%newline",
        [string]$eventPattern = "%message%newline",

        # Maximum logfile size in megabyte
        [string]$maxLogsize = "50", 

        # Maximum number of logfiles (rolling)
        [string]$maxLogfileCount = "10",

        # The logging level for logfiles
        [ValidateSet('off','debug','info','warn','error','fatal')]
        [string]$logLevel = "info",

        # The logging level for eventviewer
        [ValidateSet('off','debug','info','warn','error','fatal')]
        [string]$eventLevel = "warn"
    )
    begin{
        $isError=$false
        $prevVerbose = $VerbosePreference
        if($logLevel -eq "debug"){
            $Global:VERBOSE_ENABLED = $true
        }else{
            $Global:VERBOSE_ENABLED = $false
        }
    }
    process{
        if(-not $Global:LOGGER){
            try{
                Write-Verbose "[LOG] Logger initialization"
                $log4netDllPath = Resolve-Path $SCRIPT_PATH\log4net.dll -ErrorAction SilentlyContinue -ErrorVariable Err
                if ($Err) {
                    throw "Log4net library cannot be found on the path $SCRIPT_PATH\log4net.dll"
                }
                else{
                    Write-Verbose "[LOG] Log4net dll path is : '$log4netDllPath'"
                    [Reflection.Assembly]::LoadFrom($log4netDllPath) | Out-Null

                    #Reset the log4net configuration
                    [log4net.LogManager]::ResetConfiguration()

                    #Define new logger for this module only
                    try{
                        [log4net.LogManager]::CreateRepository("$($LoggerName)Logger")
                    }catch{
                        Write-Verbose "[LOG] Repository already created"
                    }
                    [log4net.Repository.Hierarchy.Hierarchy]$repository = [log4net.LogManager]::GetRepository("$($LoggerName)Logger")

                    # create new appenders
                    $repository.Root.RemoveAllAppenders();
               
                    # create rolling file logging
                    $logFile=$CURRENT_PATH + "\$($LoggerName).log"
                    Write-Verbose "[LOG] LogFile path is : '$logFile'"
                    New-Item -Path $logFile -type file -ErrorAction SilentlyContinue
                    $rollingLogAppender = new-object log4net.Appender.RollingFileAppender
                    $rollingLogAppender.MaximumFileSize = $maxLogsize + "MB"
                    $rollingLogAppender.Name = "file"
                    $rollingLogAppender.File = $logFile
                    $rollingLogAppender.RollingStyle = "Size"
                    $rollingLogAppender.StaticLogFileName = $true
                    $rollingLogAppender.MaxSizeRollBackups = $maxLogfileCount
                    $rollingLogAppender.Layout = new-object log4net.Layout.PatternLayout($logPattern)
                    $rollingLogAppender.Threshold = GetLog4NetLevel -level $logLevel
                    $rollingLogAppender.ActivateOptions()
                    $repository.Root.AddAppender($rollingLogAppender)

                    # create eventlog logging
                    $eventAppender = new-object log4net.Appender.EventLogAppender
                    $eventAppender.Name = "event"
                    $eventAppender.ApplicationName = "$($LoggerName)"
                    $eventAppender.EventId = 1
                    $eventAppender.Layout = new-object log4net.Layout.PatternLayout($eventPattern)
                    $eventAppender.Threshold = GetLog4NetLevel -level $eventLevel
                    $eventAppender.ActivateOptions()
                    $repository.Root.AddAppender($eventAppender)

                    # mark as configured
                    $repository.Configured = $true
                }

            }catch{
                Write-Error $_.Exception.Message
                $isError=$true
            }

            Write-Verbose "[LOG] Logger is initialized"
            $Global:LOGGER=[log4net.LogManager]::GetLogger("$($LoggerName)Logger","$($LoggerName)")

        }else{
            Write-Verbose "[LOG] Logger is already initialized"
        }
    }
    end{
        if($isError){
            Write-Error "[LOG] Failed to initialize log4net"
        }
        Write-Verbose "[LOG] Tip : If your eventviewer is not showing anything, first time must be run as administrator to create teh eventsource.  Don't forget to set your eventLevel (default off)"
        $VerbosePreference = $prevVerbose        
    }

}

# You can only run one logger, to restart, remove first
function Remove-Logger(){
    $Global:LOGGER = $null
}