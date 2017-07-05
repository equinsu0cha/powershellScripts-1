<#
.SYNOPSIS
    powershell script to manage event logs on multiple machines

.DESCRIPTION
    To enable script execution, you may need to Set-ExecutionPolicy Bypass -Force

    This script will optionally enable / disable debug and analytic event logs.
    This can be against both local and remote machines.
    It will also take a regex filter pattern for both event log names and traces.
    For each match, all event logs will be exported to csv format.
    Each export will be in its own file named with the event log name.
    Script has ability to 'listen' to new events by continuously polling configured event logs.

    https://gallery.technet.microsoft.com/Windows-Event-Log-ad958986
    https://aka.ms/event-log-manager.ps1

.NOTES
   File Name  : event-log-manager.ps1
   Author     : jagilber
   Version    : 170705 add -merge
   History    : 
                170616 add set-strictmode
                170614 add $command
                
.EXAMPLE
    .\event-log-manager.ps1 -rds -minutes 10
    Example command to query rds event logs for last 10 minutes.

.EXAMPLE
    .\event-log-manager.ps1 -minutes 10 -eventLogNamePattern * -machines rds-gw-1,rds-gw-2
    Example command to query all event logs. It will query machines rds-gw-1 and rds-gw-2 for all events in last 10 minutes:

.EXAMPLE
    .\event-log-manager.ps1 -machines rds-gw-1,rds-gw-2
    Example command to query rds event logs. It will query machines rds-gw-1 and rds-gw-2 for events for today from Application and System logs (default logs):

.EXAMPLE
    .\event-log-manager.ps1 -enableDebugLogs -eventLogNamePattern dns -rds
    Example command to enable "debug and analytic" event logs for 'rds' event logs and 'dns' event logs:

.EXAMPLE
    .\event-log-manager.ps1 -eventLogNamePattern * -eventTracePattern "fail"
    Example command to export all event logs entries that have the word 'fail' in the event Message:

.EXAMPLE
    .\event-log-manager.ps1 -eventLogNamePattern * -eventTracePattern "fail" -eventLogLevel Warning
    Example command to export all event logs entries that have the word 'fail' in the event Message and log level 'Warning':

.EXAMPLE
    .\event-log-manager.ps1 -listEventLogs -disableDebugLogs
    Example command to disable "debug and analytic" event logs:

.EXAMPLE
    .\event-log-manager.ps1 -cleareventlogs -eventLogNamePattern "^system$"
    Example command to clear 'System' event log:

.EXAMPLE
    .\event-log-manager.ps1 -eventStartTime "12/15/2015 10:00 am"
    Example command to query for all events after specified time:

.EXAMPLE
    .\event-log-manager.ps1 -eventStopTime "12/15/2016 10:00 am"
    Example command to query for all events up to specified time:

.EXAMPLE
    .\event-log-manager.ps1 -listEventLogs
    Example command to query all event log names:

.EXAMPLE
    .\event-log-manager.ps1 -listen -rds -machines rds-rds-1,rds-rds-2,rds-cb-1
    Example command to listen to multiple machines for all eventlogs for Remote Desktop Services:

.EXAMPLE
    .\event-log-manager.ps1 -eventLogPath c:\temp -eventLogNamePattern *
    Example command to query path c:\temp for all *.evt* files and convert to csv:

.EXAMPLE
    .\event-log-manager.ps1 -listen -rds -eventLogIds 4105 -command "powershell.exe .\somescript.ps1" -commandCount 5
    Example command to listen to event logs for Remote Desktop Services for event id 4105.
    If event is logged, run command "powershell.exe .\somescript.ps1 <event message>" will be started in a new process

.PARAMETER clearEventLogs
    clear all event logs matching 'eventLogNamePattern'

.PARAMETER clearEventLogsOnGather
    clear all event logs matching 'eventLogNamePattern' after eventlogs have been gathered.

.PARAMETER command
    run a command on -eventLogIds match or -eventTracePattern match.
    NOTE: requires -listen and -eventLogIds or -eventTracePattern arguments.
    NOTE: by default will only run command one time but can be modified with -commandCount argument.
    event string will be added to command given as a quoted argument when command is started.
    see EXAMPLE

.PARAMETER commandCount
    modify default value of 1 for number of times to execute command on match.

.PARAMETER days
    number of days to query from the event logs. The number specified is a positive number

.PARAMETER disableDebugLogs
    disable the 'analytic and debug' event logs matching 'eventLogNamePattern'

.PARAMETER displayMergedResults
    display merged results in default viewer for .csv files.

.PARAMETER enableDebugLogs
    enable the 'analytic and debug' event logs matching 'eventLogNamePattern'
    NOTE: at end of troubleshooting, remember to 'disableEventLogs' as there is disk and cpu overhead for debug logs
    WARNING: enabling too many debug eventlogs can make system non responsive and may make machine unbootable!
    Only enable specific debug logs needed and only while troubleshooting.

.PARAMETER eventDetails
    output event log items including xml data found on 'details' tab.

.PARAMETER eventDetailsFormatted
    output event log items including xml data found on 'details' tab with xml formatted.

.PARAMETER eventLogIds
    comma separated list of event logs id's to query.
    Default is all id's.

.PARAMETER eventLogLevels
    comma separated list of event log levels to query.
    Default is all event levels.
    Options are Critical,Error,Warning,Information,Verbose

.PARAMETER eventLogNamePattern
    string or regex pattern to specify event log names to modify / query.
    If not specified, the default value is for 'Application' and 'System' event logs
    If 'rds $true' and this argument is not specified, the following regex will be used "RemoteApp|RemoteDesktop|Terminal"

.PARAMETER eventLogPath
    If specified as a directory, will be used as a directory path to search for .evt and .evtx files. 
    If specified as a file, will be used as a file path to open .evt or .evtx file. 
    This parameter is not compatible with '-machines'

.PARAMETER eventStartTime
    time and / or date string that can be used as a starting time to query event logs
    If not specified, the default is for today only

.PARAMETER eventStopTime
    time and / or date string that can be used as a stopping time to query event logs
    If not specified, the default is for current time

.PARAMETER eventTracePattern
    string or regex pattern to specify event log traces to query.
    If not specified, all traces matching other criteria are displayed

.PARAMETER getUpdate
    compare the current script against the location in github and will update if different.

.PARAMETER hours
    number of hours to query from the event logs. The number specified is a positive number

.PARAMETER listen
    listen and display new events from event logs matching specifed pattern with eventlognamepattern

.PARAMETER listeventlogs
    list all eventlogs matching specified pattern with eventlognamepattern

.PARAMETER machines
    run script against remote machine(s). List is comma separated. argument also accepts file name and path of text file 
    with machine names.
    If not specified, script will run against local machine

.PARAMETER merge
    merge all .csv output files into one file sorted by time

.PARAMETER minutes
    number of minutes to query from the event logs. The number specified is a positive number

.PARAMETER months
    number of months to query from the event logs. The number specified is a positive number

.PARAMETER noDynamicPath
    store output files in a non-timestamped folder which is useful if calling from another script.

.PARAMETER rds
    set the default 'eventLogNamePattern' to "RemoteApp|RemoteDesktop|Terminal" if value not populated

.PARAMETER uploadDir
    directory where all files will be created.
    default is .\gather
#>

Param(
    [parameter(Position = 0, Mandatory = $false, HelpMessage = "Select to clear events")]
    [switch] $clearEventLogs,
    [parameter(Position = 0, Mandatory = $false, HelpMessage = "Select to clear events after gather")]
    [switch] $clearEventLogsOnGather,
    [parameter(HelpMessage = "Enter process command to run on event match. requires -listen and -eventLogIds or -eventTracePattern switches")]
    [string] $command,
    [parameter(HelpMessage = "Enter number of times to execute command on a match. default is 1.")]
    [int] $commandCount = 1,
    [parameter(HelpMessage = "Enter days")]
    [int] $days = 0,
    [parameter(HelpMessage = "Enable to debug script")]
    [switch] $debugScript = $false,
    [parameter(HelpMessage = "Select to disable debug event logs")]
    [switch] $disableDebugLogs,
    [parameter(HelpMessage = "Display merged event results in viewer. Requires log-merge.ps1")]
    [switch] $displayMergedResults,
    [parameter(HelpMessage = "Select to enable debug event logs")]
    [switch] $enableDebugLogs,
    [parameter(HelpMessage = "Select this switch to export event entry details tab")]
    [switch] $eventDetails,
    [parameter(HelpMessage = "Select this switch to export event entry details tab with xml formatted")]
    [switch] $eventDetailsFormatted,
    [parameter(HelpMessage = "Enter comma separated list of event log levels Critical,Error,Warning,Information,Verbose")]
    [string[]] $eventLogLevels = @("critical", "error", "warning", "information", "verbose"),
    [parameter(HelpMessage = "Enter comma separated list of event log Id")]
    [int[]] $eventLogIds = @(),
    [parameter(HelpMessage = "Enter regex or string pattern for event log name match")]
    [string] $eventLogNamePattern = "",
    [parameter(HelpMessage = "Enter path and file name of event log file to open")]
    [string] $eventLogPath = "",
    [parameter(HelpMessage = "Enter start time / date (the default is events for today)")]
    [string] $eventStartTime,
    [parameter(HelpMessage = "Enter stop time / date (the default is current time)")]
    [string] $eventStopTime,
    [parameter(HelpMessage = "Enter regex or string pattern for event log trace to match")]
    [string] $eventTracePattern = "",
    [parameter(HelpMessage = "Select to check for new version of file")]
    [switch] $getUpdate,
    [parameter(HelpMessage = "Enter hours")]
    [int] $hours = 0,
    [parameter(HelpMessage = "Listen to event logs either all or by -eventLogNamePattern")]
    [switch] $listen,
    [parameter(HelpMessage = "List event logs either all or by -eventLogNamePattern")]
    [switch] $listEventLogs,
    [parameter(HelpMessage = "Enter comma separated list of machine names")]
    [string[]] $machines = @(),
    [parameter(HelpMessage = "Select to merge event log csv files into one file.")]
    [switch] $merge,
    [parameter(HelpMessage = "Enter minutes")]
    [int] $minutes = 0,
    [parameter(HelpMessage = "Enter months")]
    [int] $months = 0,
    [parameter(HelpMessage = "Select to force all files to be flat when run on a single machine")]
    [switch] $nodynamicpath,
    [parameter(HelpMessage = "Enter minutes")]
    [switch] $rds,
    [parameter(HelpMessage = "Enter path for upload directory")]
    [string] $uploadDir
)

Set-StrictMode -Version Latest
$appendOutputFiles = $false
$debugLogsMax = 100
$errorActionPreference = "Continue"
$global:commandCountExecuted = 0
$global:debugLogsCount = 0
$global:eventLogLevelsQuery = $null
$global:eventLogIdsQuery = $null
$global:eventLogFiles = ![string]::IsNullOrEmpty($eventLogPath)
$global:eventLogNameSearchPattern = $eventLogNamePattern
$global:jobs = New-Object Collections.ArrayList
$global:machineRecords = @{}
$global:uploadDir = $uploadDir
$jobThrottle = 10
$listenEventReadCount = 1000
$listenSleepMs = 100
$logFile = "event-log-manager-output.txt"
$global:logStream = $null
$global:logTimer = new-object Timers.Timer 
$maxSortCount = 10000
$silent = $true
$startTimer = [DateTime]::Now
$startTime = [DateTime]::Now.ToString("yyyy-MM-dd-HH-mm-ss")
$updateUrl = "https://raw.githubusercontent.com/jagilber/powershellScripts/master/event-log-manager.ps1"

# ----------------------------------------------------------------------------------------------------------------
function main()
{
    $error.Clear()

    log-info "starting $([DateTime]::Now.ToString()) $([Diagnostics.Process]::GetCurrentProcess().StartInfo.Arguments)"

    # log arguments
    log-info $PSCmdlet.MyInvocation.Line;
    log-arguments

    # set upload directory
    set-uploadDir

    # clean up old jobs
    remove-jobs $silent

    # some functions require admin
    if ($clearEventLogs -or $enableDebugLogs -or $disableDebugLogs)
    {
        runas-admin -force $true

        if ($clearEventLogs)
        {
            log-info "clearing event logs"
        }

        if ($enableDebugLogs)
        {
            log-info "enabling debug event logs"
        }

        if ($disableDebugLogs)
        {
            log-info "disabling debug event logs"
        }
    }

    # check
    runas-admin

    # see if new (different) version of file
    if ($getUpdate)
    {
        get-update -updateUrl $updateUrl -destinationFile $MyInvocation.ScriptName
    }

    # add local machine if empty
    if ($machines.Count -lt 1)
    {
        $machines += $env:COMPUTERNAME
    }
    elseif ($machines.Count -eq 1 -and $machines[0].Contains(","))
    {
        # when passing comma separated list of machines from bat, it does not get separated correctly
        $machines = $machines[0].Split(",")
    }
    elseif ($machines.Count -eq 1 -and [IO.File]::Exists($machines))
    {
        # file passed in
        $machines = [IO.File]::ReadAllLines($machines);
    }

    # setup for rds
    if ($rds)
    {
        log-info "setting up for rds environment"
        $rdsPattern = "RDMS|RemoteApp|RemoteDesktop|Terminal|^System$|^Application$|User-Profile-Service" #CAPI|^Security$|VHDMP|"
        if ([string]::IsNullOrEmpty($global:eventLogNameSearchPattern))
        {
            $global:eventLogNameSearchPattern = $rdsPattern
        }
        else
        {
            $global:eventLogNameSearchPattern = "$($global:eventLogNameSearchPattern)|$($rdsPattern)"
        }
    }

    # set default event log names if not specified
    if (!$listEventLogs -and [string]::IsNullOrEmpty($global:eventLogNameSearchPattern))
    {
        $global:eventLogNameSearchPattern = "^Application$|^System$"
    }
    elseif ($listEventLogs -and [string]::IsNullOrEmpty($global:eventLogNameSearchPattern))
    {
        # just listing eventlogs and pattern not specified so show all
        $global:eventLogNameSearchPattern = "."
    }
    elseif ($global:eventLogNameSearchPattern -eq "*")
    {
        # using wildcard to use regex wildcard
        $global:eventLogNameSearchPattern = ".*"
    }

    # set to local host if not specified
    if ($machines.Length -lt 1)
    {
        $machines = @($env:COMPUTERNAME)
    }

    # create xml query
    [string]$global:eventLogLevelsQuery = build-eventLogLevels -eventLogLevels $eventLogLevels
    [string]$global:eventLogIdsQuery = build-eventLogIds -eventLogIds $eventLogIds

    # make sure start stop and other time range values were not all specified
    if (![string]::IsNullOrEmpty($eventStartTime) -and ![string]::IsNullOrEmpty($eventStopTime) -and ($months + $days + $minutes -gt 0))
    {
        log-info "invalid parameter combination. cannot specify start and stop and other time range attributes in same command. exiting"
        exit
    }

    # determine start time if specified else just search for today
    if ($listen)
    {
        $appendOutputFiles = $true
        $eventStartTime = [DateTime]::Now
        $eventStopTime = [DateTime]::MaxValue
    }

    if ([string]::IsNullOrEmpty($eventStartTime))
    {
        $origStartTime = ""
    }
    else
    {
        $origStartTime = $eventStartTime
    }

    # determine start and stop times for xml query
    $eventStartTime = configure-startTime -eventStartTime $eventStartTime `
        -eventStopTime $eventStopTime `
        -months $months `
        -days $days `
        -hours $hours `
        -minutes $minutes

    $eventStopTime = configure-stopTime -eventStarTime $origStartTime `
        -eventStopTime $eventStopTime `
        -months $months `
        -days $days `
        -hours $hours `
        -minutes $minutes

    try
    {
        # process all machines
        process-machines -machines $machines `
            -eventStartTime $eventStartTime `
            -eventStopTime $eventStopTime
    }
    catch
    {
        log-info "main:exception $($error)"
    }
    finally
    {
        # clean up
        remove-jobs -silent $true

        if ($listen -and $enableDebugLogs)
        {
            $enableDebugLogs = $false
            $disableDebugLogs = $true
            $listen = $false

            log-info "disabling debug logs that were enabled while listening"
            # process all machines
            process-machines -machines $machines `
                -eventStartTime $eventStartTime `
                -eventStopTime $eventStopTime
        }
        
        if ($global:debugLogsCount)
        {
            show-debugWarning -count $global:debugLogsCount
        }

        if (!$listEventLogs -and @([IO.Directory]::GetFiles($global:uploadDir, "*.*")).Count -gt 0)
        {
            start $global:uploadDir
            log-info "files are located here: $($global:uploadDir)"
        }
   
        log-info "finished total seconds:$([DateTime]::Now.Subtract($startTimer).TotalSeconds)"

        if ($global:logStream -ne $null)
        {
            $global:logStream.Close()
        }

        $global:logTimer.Stop() 
        Unregister-Event logTimer -ErrorAction SilentlyContinue
    }
}

# ----------------------------------------------------------------------------------------------------------------
function build-eventLogIds($eventLogIds)
{
    [Text.StringBuilder] $sb = new-object Text.StringBuilder

    foreach ($eventLogId in $eventLogIds)
    {
        [void]$sb.Append("EventID=$($eventLogId) or ")
    }

    return $sb.ToString().TrimEnd(" or ")
}

# ----------------------------------------------------------------------------------------------------------------
function build-eventLogLevels($eventLogLevels)
{
    [Text.StringBuilder] $sb = new-object Text.StringBuilder

    foreach ($eventLogLevel in $eventLogLevels)
    {
        switch ($eventLogLevel.ToLower())
        {
            "critical" { [void]$sb.Append("Level=1 or ") }
            "error" { [void]$sb.Append("Level=2 or ") }
            "warning" { [void]$sb.Append("Level=3 or ") }
            "information" { [void]$sb.Append("Level=4 or Level=0 or ") }
            "verbose" { [void]$sb.Append("Level=5 or ") }
        }
    }

    return $sb.ToString().TrimEnd(" or ")
}

# ----------------------------------------------------------------------------------------------------------------
function configure-startTime( $eventStartTime, $eventStopTime, $months, $hours, $days, $minutes )
{
    [DateTime] $time = new-object DateTime
    [void][DateTime]::TryParse($eventStartTime, [ref] $time)

    if ($time -eq [DateTime]::MinValue -and ![string]::IsNullOrEmpty($eventLogPath))
    {
        # parsing existing evtx files so do not override $eventStartTime if it was not provided
        [DateTime] $eventStartTime = $time
    }
    elseif ($time -eq [DateTime]::MinValue -and [string]::IsNullOrEmpty($eventStopTime) -and ($months + $hours + $days + $minutes -eq 0))
    {
        # default to just today
        $time = [DateTime]::Now.Date
        [DateTime] $eventStartTime = $time
    }
    elseif ($time -eq [DateTime]::MinValue -and [string]::IsNullOrEmpty($eventStopTime))
    {
        # subtract from current time
        $time = [DateTime]::Now
        [DateTime] $eventStartTime = $time.AddMonths( - $months).AddDays( - $days).AddHours( - $hours).AddMinutes( - $minutes)
    }
    else
    {
        # offset should not be applied if $eventStartTime specified
        [DateTime] $eventStartTime = $time
    }

    log-info "searching for events newer than: $($eventStartTime.ToString("yyyy-MM-ddTHH:mm:sszz"))"
    return $eventStartTime
}

# ----------------------------------------------------------------------------------------------------------------
function configure-stopTime($eventStartTime, $eventStopTime, $months, $hours, $days, $minutes)
{
    [DateTime] $time = new-object DateTime
    [void][DateTime]::TryParse($eventStopTime, [ref] $time)

    if ([string]::IsNullOrEmpty($eventStartTime) -and $time -eq [DateTime]::MinValue -and ($months + $hours + $days + $minutes -gt 0))
    {
        # set to current and return
        [DateTime] $eventStopTime = [DateTime]::Now
    }
    elseif ($time -eq [DateTime]::MinValue -and $months -eq 0 -and $hours -eq 0 -and $days -eq 0 -and $minutes -eq 0)
    {
        [DateTime] $eventStopTime = [DateTime]::Now
    }
    elseif ($time -eq [DateTime]::MinValue)
    {
        # subtract from current time
        $time = [DateTime]::Now
        [DateTime] $eventStopTime = $time.AddMonths( - $months).AddDays( - $days).AddHours( - $hours).AddMinutes( - $minutes)
    }
    else
    {
        # offset should not be applied if $eventStopTime specified
        [DateTime] $eventStopTime = $time
    }

    log-info "searching for events older than: $($eventStopTime.ToString("yyyy-MM-ddTHH:mm:sszz"))"
    return $eventStopTime
}

# ----------------------------------------------------------------------------------------------------------------
function dump-events( $eventLogNames, [string] $machine, [DateTime] $eventStartTime, [DateTime] $eventStopTime)
{
    $newEvents = New-Object Collections.ArrayList 
    $listenJobItem = @{}
    $preader = $null

    # build query string from ids and levels
    if (![string]::IsNullOrEmpty($global:eventLogLevelsQuery) -and ![string]::IsNullOrEmpty($global:eventLogIdsQuery))
    {
        $eventQuery = "($($global:eventLogLevelsQuery)) and ($($global:eventLogIdsQuery)) and "
    }
    elseif (![string]::IsNullOrEmpty($global:eventLogLevelsQuery))
    {
        $eventQuery = "($($global:eventLogLevelsQuery)) and "
    }
    elseif (![string]::IsNullOrEmpty($global:eventLogIdsQuery))
    {
        $eventQuery = "($($global:eventLogIdsQuery)) and "
    }

    # used to peek at events
    $psession = New-Object Diagnostics.Eventing.Reader.EventLogSession ($machine)

    # loop through each log
    foreach ($eventLogName in $eventLogNames)
    {
        $outputCsv = [string]::Empty
        $recordid = ($global:machineRecords[$machine])[$eventLogName]

        $queryString = "<QueryList>
        <Query Id=`"0`" Path=`"$($eventLogName)`">
        <Select Path=`"$($eventLogName)`">*[System[$($eventQuery)" `
            + "TimeCreated[@SystemTime &gt;=`'$($eventStartTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:sszz"))`' " `
            + "and @SystemTime &lt;=`'$($eventStopTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:sszz"))`']]]</Select>
        </Query>
        </QueryList>"

        try
        {
            $pathType = $null

            # peek to see if any records, if so start job
            if (!$global:eventLogFiles)
            {
                $pathType = [Diagnostics.Eventing.Reader.PathType]::LogName
            }
            else
            {
                $pathType = [Diagnostics.Eventing.Reader.PathType]::FilePath
            }

            $pquery = New-Object Diagnostics.Eventing.Reader.EventLogQuery ($eventLogName, $pathType, $queryString)
            $pquery.Session = $psession
            $preader = New-Object Diagnostics.Eventing.Reader.EventLogReader $pquery

            # create csv file name
            $cleanName = $eventLogName.Replace("/", "-").Replace(" ", "-")

            if (!$global:eventLogFiles)
            {
                $outputCsv = ("$($global:uploadDir)\$($machine)-$($cleanName).csv")
            }
            else
            {
                $outputCsv = ("$($global:uploadDir)\$([IO.Path]::GetFileNameWithoutExtension($cleanName)).csv")
            }

            if (!$appendOutputFiles -and (test-path $outputCsv))
            {
                log-info "removing existing file: $($outputCsv)"
                Remove-Item -Path $outputCsv -Force
            }

            if ($listen)
            {
                if (!$listenJobItem -or $listenJobItem.Keys.Count -eq 0)
                {
                    $listenJobItem = @{}
                    $listenJobItem.Machine = $machine
                    $listenJobItem.EventLogItems = @{}
                }
            
                $listenJobItem.EventLogItems.Add($eventLogName, @{
                        EventQuery = $eventQuery
                        QueryString = $queryString
                        OutputCsv = $outputCsv
                        RecordId = 0
                    }
                )
            }

            $event = $preader.ReadEvent()

            if ($event -eq $null)
            {
                continue
            }

            if ($recordid -eq $event.RecordId)
            {
                #sometimes record id's come back as 0 causing dupes
                $recordid++
            }

            $oldrecordid = ($global:machineRecords[$machine])[$eventLogName]
            $recordid = [Math]::Max($recordid, $event.RecordId)

            log-info "dump-events:machine: $($machine) event log name: $eventLogName old index: $($oldRecordid) new index: $($recordId)" -debugOnly
            ($global:machineRecords[$machine])[$eventLogName] = $recordid
        }
        catch
        {
            log-info "FAIL:$($eventLogName): $($Error)" -debugOnly
            [void]$error.Clear()
            continue
        }

        if (!$listen)
        {
            $job = start-exportJob -machine $machine `
                -eventLogName $eventLogName `
                -queryString $queryString `
                -outputCsv $outputCsv

            if ($job -ne $null)
            {
                log-info "job $($job.id) started for eventlog: $($eventLogName)"
                $global:jobs.Add($job)
            }
        } # end if
    } # end for

    if ($listenJobItem -and $listenJobItem.Count -gt 0)
    {
        $job = start-listenJob -jobItem $listenJobItem
    }

    $preader.CancelReading()
    $preader.Dispose()
    $psession.CancelCurrentOperations()
    $psession.Dispose()

    return , $newEvents
}

# ----------------------------------------------------------------------------------------------------------------
function enable-logs($eventLogNames, $machine)
{
    log-info "enabling logs on $($machine)."
    [Text.StringBuilder] $sb = new-object Text.StringBuilder
    $debugLogsEnabled = New-Object Collections.ArrayList

    [void]$sb.Appendline("event logs:")

    foreach ($eventLogName in $eventLogNames)
    {
        $session = New-Object Diagnostics.Eventing.Reader.EventLogSession ($machine)
        $eventLog = New-Object Diagnostics.Eventing.Reader.EventLogConfiguration ($eventLogName, $session)

        if ($clearEventLogs)
        {
            [void]$sb.AppendLine("clearing event log: $($eventLogName)")
            if ($eventLog.IsEnabled -and !$eventLog.IsClassicLog)
            {
                $eventLog.IsEnabled = $false
                $eventLog.SaveChanges()
                $eventLog.Dispose()

                $session.ClearLog($eventLogName)

                $eventLog = New-Object Diagnostics.Eventing.Reader.EventLogConfiguration ($eventLogName, $session)
                $eventLog.IsEnabled = $true
                $eventLog.SaveChanges()
            }
            elseif ($eventLog.IsClassicLog)
            {
                $session.ClearLog($eventLogName)
            }
        }

        if ($enableDebugLogs -and $eventLog.IsEnabled -eq $false)
        {
            [void]$sb.AppendLine("enabling debug log for $($eventLog.LogName) $($eventLog.LogMode)")
            $eventLog.IsEnabled = $true
            $eventLog.SaveChanges()
        }

        if ($disableDebugLogs -and $eventLog.IsEnabled -eq $true -and ($eventLog.LogType -ieq "Analytic" -or $eventLog.LogType -ieq "Debug"))
        {
            [void]$sb.AppendLine("disabling debug log for $($eventLog.LogName) $($eventLog.LogMode)")
            $eventLog.IsEnabled = $false
            $eventLog.SaveChanges()
        }

        if ($eventLog.LogType -ieq "Analytic" -or $eventLog.LogType -ieq "Debug")
        {
            if ($eventLog.IsEnabled -eq $true)
            {
                [void]$sb.AppendLine("$($eventLog.LogName) $($eventLog.LogMode): ENABLED")
                $debugLogsEnabled.Add($eventLog.LogName)

                if ($debugLogsMax -le $debugLogsEnabled.Count)
                {
                    log-info "Error: too many debug logs enabled ($($debugLogsMax))."
                    log-info "Error: this can cause system performance / stability issues as well as inability to boot!"
                    log-info "Error: rerun script again with these switches: .\event-log-manager.ps1 -listeventlogs -disableDebugLogs"
                    log-info "Error: this will disable all debug logs."
                    log-info "Warning: exiting script."
                    exit 1
                }
            }
            else
            {
                [void]$sb.AppendLine("$($eventLog.LogName) $($eventLog.LogMode): DISABLED")
            }
        }
        else
        {
            [void]$sb.AppendLine("$($eventLog.LogName)")
        }
    }

    log-info $sb.ToString() -nocolor
    log-info "-----------------------------------------"

    if ($debugLogsEnabled.Count -gt 0)
    {
        $global:debugLogsCount = $global:debugLogsCount + $debugLogsEnabled.Count
        foreach ($eventLogName in $debugLogsEnabled)
        {
            log-info $eventLogName
        }

        show-debugWarning -count $debugLogsEnabled.Count
    }
}

# ----------------------------------------------------------------------------------------------------------------
function filter-eventLogs($eventLogPattern, $machine, $eventLogPath)
{
    $filteredEventLogs = New-Object Collections.ArrayList
    try
    {
        if (!$global:eventLogFiles)
        {
            # query eventlog session
            $session = New-Object Diagnostics.Eventing.Reader.EventLogSession ($machine)
            $eventLogNames = $session.GetLogNames()
        }
        else
        {
            if ([IO.File]::Exists($eventLogPath))
            {
                $eventLogNames = @($eventLogPath)
            }
            else
            {
                # query eventlog path
                $eventLogNames = [IO.Directory]::GetFiles($eventLogPath, "*.evt*", [IO.SearchOption]::TopDirectoryOnly)
            }
        }

        [Text.StringBuilder] $sb = new-object Text.StringBuilder
        [void]$sb.Appendline("")

        foreach ($eventLogName in $eventLogNames)
        {
            if (![regex]::IsMatch($eventLogName, $eventLogPattern , [System.Text.RegularExpressions.RegexOptions]::IgnoreCase))
            {
                continue
            }

            [void]$filteredEventLogs.Add($eventLogName)
        }

        [void]$sb.AppendLine("filtered logs count: $($filteredEventLogs.Count)")
        log-info $sb.ToString()
        return $filteredEventLogs
    }
    catch
    {
        log-info "exception reading event log names from $($machine): $($error)"
        $error.Clear()
        return $null
    }
}

#----------------------------------------------------------------------------
function get-update($updateUrl, $destinationFile)
{
    log-info "get-update:checking for updated script: $($updateUrl)"

    try 
    {
        $git = Invoke-RestMethod -Method Get -Uri $updateUrl 
        $gitClean = [regex]::Replace($git, '\W+', "")

        if (![IO.File]::Exists($destinationFile))
        {
            $fileClean = ""    
        }
        else
        {
            $fileClean = [regex]::Replace(([IO.File]::ReadAllBytes($destinationFile)), '\W+', "")
        }

        if (([string]::Compare($gitClean, $fileClean) -ne 0))
        {
            log-info "copying script $($destinationFile)"
            [IO.File]::WriteAllText($destinationFile, $git)
            return $true
        }
        else
        {
            log-info "script is up to date"
        }
        
        return $false
        
    }
    catch [System.Exception] 
    {
        log-info "get-update:exception: $($error)"
        $error.Clear()
        return $false    
    }
}

# ----------------------------------------------------------------------------------------------------------------
function get-workingDirectory()
{
    $retVal = [string]::Empty
    if (Test-Path variable:\hostinvocation)
    {
        $retVal = $hostinvocation.MyCommand.Path
    }
    else
    {
        $retVal = (get-variable myinvocation -scope script).Value.Mycommand.Definition
    }
  
    if (Test-Path $retVal)
    {
        $retVal = (Split-Path $retVal)
    }
    else
    {
        $retVal = (Get-Location).path
        log-info "get-workingDirectory: Powershell Host $($Host.name) may not be compatible with this function, the current directory $retVal will be used."
    } 
 
    Set-Location $retVal | out-null
    return $retVal
}

# ----------------------------------------------------------------------------------------------------------------
function listen-forEvents()
{
    $unsortedEvents = New-Object Collections.ArrayList
    $sortedEvents = New-Object Collections.ArrayList
    $newEvents = New-Object Collections.ArrayList
    
    try
    {
        while ($listen)
        {
            # ensure sort by keeping two sets and comparing new to old then displaying old
            [void]$sortedEvents.Clear()
            $sortedEvents = $unsortedEvents.Clone()
            [void]$unsortedEvents.Clear()
            $color = $true

            # get events from jobs
            $newEvents = @(get-job * | Receive-Job)

            # run command if eventtracepattern or eventlogids were provided and command provided
            # will launch separate process
            if($newEvents.Count -gt 0 `
                -and $commandCount -gt $global:commandCountExecuted `
                -and ![string]::IsNullOrEmpty($command) `
                -and (![string]::IsNullOrEmpty($eventTracePattern) -or $eventLogIds.Count -gt 0))
                
            {
                log-info "information: starting command cmd.exe /c start $($command) `"$($newEvents[0] | Out-String)`""
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c start $($command) `"$($newEvents[0] | Out-String)`""
                
                $global:commandCountExecuted++
                log-info "information: finished starting command. number of commands started $($global:commandCountExecuted)"
                
                if($global:commandCountExecuted -eq $commandCountExecuted)
                {
                    log-info "Warning: no more command instances will be started on new matches. To modify use -commandCountExecuted argument"
                }
            }


            if ($debugScript)
            {
                log-info (get-job).Debug | fl * | out-string
            }

            if ($newEvents.Count -gt 0)
            {
                [void]$unsortedEvents.AddRange(@($newEvents | sort-object))
            }

            if ($unsortedEvents.Count -gt $maxSortCount)
            {
                # too many to sort, just display / save
                [void]$sortedEvents.AddRange($unsortedEvents)
                $unsortedEvents.Clear()
                log-info "Warning:listen: unsorted count too high, skipping sort" -debugOnly

                if ($sortedEvents.Count -gt 0)
                {
                    foreach ($sortedEvent in $sortedEvents)
                    {
                        log-info $sortedEvent -nocolor
                    }
                }

                $sortedEvents.Clear()

                if ($unsortedEvents.Count -gt 0)
                {
                    foreach ($sortedEvent in $unsortedEvents)
                    {
                        log-info $sortedEvent -nocolor
                    }
                }

                $unsortedEvents.Clear()
            }
            elseif ($unsortedEvents.Count -gt 0 -and $sortedEvents.Count -gt 0)
            {
                $result = [DateTime]::MinValue
                $trace = $sortedEvents[$sortedEvents.Count - 1]

                # date and time are at start of string separated by commas.
                # search for second comma splitting date and time from trace message to extract just date and time
                $traceDate = $trace.Substring(0, $trace.IndexOf(",", 11))

                if ([DateTime]::TryParse($traceDate, [ref] $result))
                {
                    $straceDate = $result
                }

                for ($i = 0; $i -lt $unsortedEvents.Count; $i++)
                {
                    $trace = $unsortedEvents[$i]
                    $traceDate = $trace.Substring(0, $trace.IndexOf(",", 11))

                    if ([DateTime]::TryParse($traceDate, [ref] $result))
                    {
                        $utraceDate = $result
                    }

                    if ($utraceDate -gt $straceDate)
                    {
                        log-info "moving trace to unsorted" -debugOnly
                        # move ones earlier than max of unsorted from sorted to unsorted keep timeline right
                        [void]$sortedEvents.Insert(0, $unsortedEvents[0])
                        [void]$unsortedEvents.RemoveAt(0)
                    }
                }
            }

            if ($sortedEvents.Count -gt 0)
            {
                foreach ($sortedEvent in $sortedEvents | Sort-Object)
                {
                    log-info $sortedEvent
                    write-host "------------------------------------------"
                }
            }

            log-info "listen: unsorted count:$($unsortedEvents.Count) sorted count: $($sortedEvents.Count)" -debugOnly
            Start-Sleep -Milliseconds ($listenSleepMs * 2)
        } # end while
    }
    catch
    {
        log-info "listen:exception: $($error)"
    }
}

# ----------------------------------------------------------------------------------------------------------------
function log-arguments()
{
    log-info "clearEventLogs:$($clearEventLogs)"
    log-info "clearEventLogsOnGather:$($clearEventLogsOnGather)"
    log-info "command:$($command)"
    log-info "commandCount:$($commandCount)"
    log-info "days:$($days)"
    log-info "debugScript:$($debugScript)"
    log-info "disableDebugLogs:$($disableDebugLogs)"
    log-info "displayMergedResults:$($displayMergedResults)"
    log-info "enableDebugLogs:$($enableDebugLogs)"
    log-info "eventDetails:$($eventDetails)"
    log-info "eventDetailsFormatted:$($eventDetailsFormatted)"
    log-info "eventLogLevels:$($eventLogLevels -join ",")"
    log-info "eventLogIds:$($eventLogIds -join ",")"
    log-info "eventLogNamePattern:$($eventLogNamePattern)"
    log-info "eventLogPath:$($eventLogPath)"
    log-info "eventStartTime:$($eventStartTime)"
    log-info "eventStopTime:$($eventStopTime)"
    log-info "eventTracePattern:$($eventTracePattern)"
    log-info "getUpdate:$($getUpdate)"
    log-info "hours:$($hours)"
    log-info "listen:$($listen)"
    log-info "listEventLogs:$($listEventLogs)"
    log-info "machines:$($machines -join ",")"
    log-info "minutes:$($minutes)"
    log-info "merge:$($merge)"
    log-info "months:$($months)"
    log-info "nodynamicpath:$($nodynamicpath)"
    log-info "rds:$($rds)"
    log-info "uploadDir:$($global:uploadDir)"
}

# ----------------------------------------------------------------------------------------------------------------
function log-info($data, [switch] $nocolor = $false, [switch] $debugOnly = $false)
{
    try
    {
        if ($debugOnly -and !$debugScript)
        {
            return
        }

        if(!$data)
        {
            return
        }

        $foregroundColor = "White"

        if (!$nocolor)
        {
            if ($data.ToString().ToLower().Contains("error"))
            {
                $foregroundColor = "Red"
            }
            elseif ($data.ToString().ToLower().Contains("fail"))
            {
                $foregroundColor = "Red"
            }
            elseif ($data.ToString().ToLower().Contains("warning"))
            {
                $foregroundColor = "Yellow"
            }
            elseif ($data.ToString().ToLower().Contains("exception"))
            {
                $foregroundColor = "Yellow"
            }
            elseif ($data.ToString().ToLower().Contains("debug"))
            {
                $foregroundColor = "Gray"
            }
            elseif ($data.ToString().ToLower().Contains("analytic"))
            {
                $foregroundColor = "Gray"
            }
            elseif ($data.ToString().ToLower().Contains("disconnected"))
            {
                $foregroundColor = "DarkYellow"
            }
            elseif ($data.ToString().ToLower().Contains("information"))
            {
                $foregroundColor = "Green"
            }
        }

        Write-Host $data -ForegroundColor $foregroundColor

        if ($global:logStream -eq $null)
        {
            $global:logStream = new-object System.IO.StreamWriter ($logFile, $true)
            $global:logTimer.Interval = 5000 #5 seconds

            Register-ObjectEvent -InputObject $global:logTimer -EventName elapsed -SourceIdentifier logTimer -Action `
            { 
                Unregister-Event -SourceIdentifier logTimer
                $global:logStream.Close() 
                $global:logStream = $null
            }

            $global:logTimer.start() 
        }

        # reset timer
        $global:logTimer.Interval = 5000 #5 seconds
        $global:logStream.WriteLine("$([DateTime]::Now.ToString())::$([Diagnostics.Process]::GetCurrentProcess().ID)::$($data)")
    }
    catch 
    {
        Write-Verbose "log-info:exception $($error)"
        $error.Clear()
    }
}

# ----------------------------------------------------------------------------------------------------------------
function log-merge($sourceFolder,$filePattern,$outputFile,$startDate,$endDate,$subDir = $false)
{

$Code = @'
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using System.IO;
    using System.Text.RegularExpressions;
    using System.Globalization;


    public class LogMerge
    {

        int precision = 0;
        Dictionary<string, string> outputList = new Dictionary<string, string>();
        //07/22/2014-14:48:10.909 for etl and 07/22/2014,14:48:10 PM for eventlog
        string datePattern = "(?<DateEtlPrecise>[0-9]{1,2}/[0-9]{1,2}/[0-9]{2,4}-[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}\\.[0-9]{7}) |" +
            "(?<DateEtl>[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}-[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}\\.[0-9]{3}) |" +
            "(?<DateEvt>[0-9]{1,2}/[0-9]{1,2}/[0-9]{4},[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2} [AP]M)|" +
            "(?<DateEvtSpace>[0-9]{1,2}/[0-9]{1,2}/[0-9]{4} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2} [AP]M)|" +
            "(?<DateEvtPrecise>[0-9]{1,2}/[0-9]{1,2}/[0-9]{4},[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}\\.[0-9]{6} [AP]M)|" +
            "(?<DateISO>[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}T[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}\\.[0-9]{3,7})";  
        string dateFormatEtl = "MM/dd/yyyy-HH:mm:ss.fff";
        string dateFormatEtlPrecise = "MM/dd/yy-HH:mm:ss.fffffff";
        string dateFormatEvt = "MM/dd/yyyy,hh:mm:ss tt";
        string dateFormatEvtSpace = "MM/dd/yyyy hh:mm:ss tt";
        string dateFormatEvtPrecise = "MM/dd/yyyy,hh:mm:ss.ffffff tt";
        string dateFormatISO = "yyyy-MM-ddTHH:mm:ss.ffffff"; // may have additional digits and Z
        
        bool detail = false;
        CultureInfo culture = new CultureInfo("en-US");
        Int64 missedMatchCounter = 0;
        Int64 missedDateCounter = 0;
        
        public static void Start(string sourceFolder, string filePattern, string outputFile,string defaultDir,bool subDir,DateTime startDate, DateTime endDate)
        {
            LogMerge program = new LogMerge();

            try
            {
                Directory.SetCurrentDirectory(defaultDir);

                if (!string.IsNullOrEmpty(sourceFolder) && !string.IsNullOrEmpty(filePattern) && !string.IsNullOrEmpty(outputFile))
                {
                    System.IO.SearchOption option; 

                    if(subDir)
                    {
                        option = System.IO.SearchOption.AllDirectories;
                    }
                    else
                    {
                        option = System.IO.SearchOption.TopDirectoryOnly;
                    }

                    string[] files = Directory.GetFiles(sourceFolder, filePattern, option);
                    if (files.Length < 1)
                    {
                        Console.WriteLine("unable to find files. returning");
                        return;
                    }

                    program.ReadFiles(files, outputFile, startDate, endDate);
                }
                else
                {
                    Console.WriteLine("utility combines *fmt.txt files into one file based on timestamp. provide folder and filter args and output file.");
                    Console.WriteLine("LogMerge takes three arguments; source dir, file filter, and output file.");
                    Console.WriteLine("example: LogMerge f:\\cases *fmt.txt c:\\temp\\all.csv");
                }
            }
            catch (Exception e)
            {
                Console.WriteLine(string.Format("exception:main:precision:{0}:missed:{1}:excetion:{2}",program.precision, program.missedMatchCounter, e));
            }
        }

        bool ReadFiles(string[] files, string outputfile, DateTime startDate, DateTime endDate)
        {
            Match match = Match.Empty;
            long lastTicks = 0;
            string line = string.Empty;

            try
            {

                foreach (string file in files)
                {
                    Console.WriteLine(file);
                    StreamReader reader = new StreamReader(file);
                    DateTime date = new DateTime();
                    string fileName = Path.GetFileName(file);
                    string pidPattern = "^(.*)::";
                    string lastPidString = string.Empty;
                    string traceDate = string.Empty;
                    string dateFormat = string.Empty;

                    while (reader.Peek() >= 0)
                    {
                        line = reader.ReadLine();

                        if (Regex.IsMatch(line, pidPattern))
                        {
                            lastPidString = Regex.Match(line, pidPattern).Value;
                        }

                        Match matchTraceDate = Regex.Match(line, datePattern);

                        if (!string.IsNullOrEmpty(matchTraceDate.Groups["DateEtlPrecise"].Value))
                        {
                            dateFormat = dateFormatEtlPrecise;
                            traceDate = matchTraceDate.Groups["DateEtlPrecise"].Value;
                        }
                        else if (!string.IsNullOrEmpty(matchTraceDate.Groups["DateEtl"].Value))
                        {
                            dateFormat = dateFormatEtl;
                            traceDate = matchTraceDate.Groups["DateEtl"].Value;
                        }
                        else if (!string.IsNullOrEmpty(matchTraceDate.Groups["DateEvt"].Value))
                        {
                            dateFormat = dateFormatEvt;
                            traceDate = matchTraceDate.Groups["DateEvt"].Value;
                        }
                        else if (!string.IsNullOrEmpty(matchTraceDate.Groups["DateEvtSpace"].Value))
                        {
                            dateFormat = dateFormatEvtSpace;
                            traceDate = matchTraceDate.Groups["DateEvtSpace"].Value;
                        }
                        else if (!string.IsNullOrEmpty(matchTraceDate.Groups["DateEvtPrecise"].Value))
                        {
                            dateFormat = dateFormatEvtPrecise;
                            traceDate = matchTraceDate.Groups["DateEvtPrecise"].Value;
                        }
                        else if (!string.IsNullOrEmpty(matchTraceDate.Groups["DateISO"].Value))
                        {
                            dateFormat = dateFormatISO;
                            traceDate = matchTraceDate.Groups["DateISO"].Value;
                        }
                        else
                        {
                            if (detail) Console.WriteLine("unable to parse date:{0}:{1}", missedDateCounter, line);
                            missedDateCounter++;
                        }

                        if (DateTime.TryParseExact(traceDate,
                            dateFormat,
                            culture,
                            DateTimeStyles.AssumeLocal,
                            out date))
                        {
                            if (lastTicks != date.Ticks)
                            {
                                lastTicks = date.Ticks;
                                precision = 0;
                            }
                        }
                        else if (DateTime.TryParse(traceDate, out date))
                        {
                            if (lastTicks != date.Ticks)
                            {
                                lastTicks = date.Ticks;
                                precision = 0;
                            }

                            dateFormat = dateFormatEvt;
                        }
                        else
                        {
                            // use last date and let it increment to keep in place
                            date = new DateTime(lastTicks);

                            // put cpu pid and tid back in

                            if (Regex.IsMatch(line, pidPattern))
                            {
                                line = string.Format("{0}::{1}", lastPidString, line);
                            }
                            else
                            {
                                line = string.Format("{0}{1} -> {2}", lastPidString, date.ToString(dateFormat), line);
                            }

                            missedMatchCounter++;
                            Console.WriteLine("unable to parse time:{0}:{1}", missedMatchCounter, line);
                        }

                        if(!(startDate < date && date < endDate))
                        {
                            continue;
                        }

                        while (precision < 99999999)
                        {
                            if (AddToList(date, string.Format("{0}, {1}", fileName, line)))
                            {
                                break;
                            }

                            precision++;
                        }
                    }
                }

                if (File.Exists(outputfile))
                {
                    File.Delete(outputfile);
                }

                using (StreamWriter writer = new StreamWriter(outputfile, true))
                {
                    Console.WriteLine("sorting lines.");
                    foreach (var item in outputList.OrderBy(i => i.Key))
                    {
                        writer.WriteLine(item.Value);
                    }
                }

                Console.WriteLine(string.Format("finished:missed {0} lines", missedMatchCounter));
                return true;
            }
            catch (Exception e)
            {
                Console.WriteLine(string.Format("ReadFiles:exception:lines count:{0}: dictionary count:{1}: exception:{2}", line.Length, outputList.Count, e));
                return false;
            }
        }

        bool AddToList(DateTime date, string line)
        {
            string key = string.Format("{0}{1}",date.Ticks.ToString(), precision.ToString("D8"));
            if(!outputList.ContainsKey(key))
            {
                outputList.Add(key,line);
            }
            else
            {
                return false;
            }

            return true;
        }
    }
'@

    Add-Type $Code -ErrorAction SilentlyContinue

    [DateTime] $time = new-object DateTime

    if(![DateTime]::TryParse($startDate,[ref] $time))
    {
       $startDate = [DateTime]::MinValue
    }

    if(![DateTime]::TryParse($endDate,[ref] $time))
    {
       $endDate = [DateTime]::Now
    }

    [LogMerge]::Start($sourceFolder, $filePattern, $outputFile, (get-location), $subDir, $startDate, $endDate)
}

# ----------------------------------------------------------------------------------------------------------------
function merge-files()
{
    # run logmerge on all files
    $uDir = $global:uploadDir

    foreach ($machine in $machines)
    {
        log-info "running merge for $($machine) in path $($uDir)"
        log-merge -sourceFolder $($uDir) -filePattern "*.csv" -outputFile "$($uDir)\events-$($machine)-all.csv" -subDir $true

        if ($displayMergedResults -and [IO.File]::Exists("$($uDir)\events-$($machine)-all.csv"))
        {
            & "$($uDir)\events-$($machine)-all.csv"
        }
    }
}

# ----------------------------------------------------------------------------------------------------------------
function process-eventLogs( $machines, $eventStartTime, $eventStopTime)
{
    $retval = $true
    $ret = $null
    $baseDir = $global:uploadDir

    if (!$global:eventLogFiles -and !$nodynamicpath)
    {
        $baseDir = "$($baseDir)\$($startTime)"
    }

    foreach ($machine in $machines)
    {
        # check connectivity
        if (!(test-path "\\$($machine)\admin$"))
        {
            log-info "$($machine) not accessible, skipping."
            continue
        }

        # filter log names
        $filteredLogs = filter-eventLogs -eventLogPattern $global:eventLogNameSearchPattern -machine $machine -eventLogPath $eventLogPath

        if (!$filteredLogs)
        {
            log-info "error retrieving event log names from machine $($machine)"
            $retval = $false
            continue
        }

        if (!$global:eventLogFiles)
        {
            # enable / disable eventlog
            $ret = enable-logs -eventLogNames $filteredLogs -machine $machine
        }

        # create machine list
        $global:machineRecords.Add($machine, @{})

        # create eventlog list for machine
        foreach ($eventLogName in $filteredLogs)
        {
            if (!($global:machineRecords[$machine]).ContainsKey($eventLogName))
            {
                ($global:machineRecords[$machine]).Add($eventLogName, 0)
            }
            else
            {
                log-info "warning:eventlog already exists in global list $($eventLogName)" -debugOnly
            }
        }

        # export all events from eventlogs
        if (($clearEventLogs -or $enableDebugLogs -or $disableDebugLogs -or $listEventLogs) -and !$listen)
        {
            $retval = $false
        }
        else
        {
            # check upload dir
            if (!$global:eventLogFiles -and !$nodynamicpath)
            {
                $global:uploadDir = "$($baseDir)\$($machine)"
            }
            
            log-info "upload dir:$($global:uploadDir)"

            if (!(test-path $global:uploadDir))
            {
                $ret = New-Item -Type Directory -Path $global:uploadDir
            }

            if ($listen)
            {
                log-info "listening for events on $($machine)"
            }
            else
            {
                log-info "dumping events on $($machine)"
            }

            $ret = dump-events -eventLogNames (New-Object Collections.ArrayList($global:machineRecords[$machine].Keys)) `
                    -machine $machine `
                    -eventStartTime $eventStartTime `
                    -eventStopTime $eventStopTime
        }
    } # end foreach machine

    if ($listen -and $retval)
    {
        log-info "listening for events from machines:"

        foreach ($machine in $machines)
        {
            log-info "`t$($machine)" -nocolor
        }

        listen-forEvents
    }

    $global:uploadDir = $baseDir
    return $retval
}

# ----------------------------------------------------------------------------------------------------------------
function process-machines( $machines, $eventStartTime, $eventStopTime)
{
    # process all event logs on all machines
    if (process-eventLogs -machines $machines `
        -eventStartTime $eventStartTime `
        -eventStopTime $eventStopTime)
    {
        log-info "jobs count:$($global:jobs.Count)"
        $count = 0

        # Wait for all jobs to complete
        if ($global:jobs -ne @())
        {
            while (get-job)
            {
                $showStatus = $false
                $count ++

                if ($count -eq 30)
                {
                    $count = 0
                    $showStatus = $true
                }
                
                receive-backgroundJobs -showStatus $showStatus
                Start-Sleep -Milliseconds 1000
            }
        }

        if($displayMergedResults -or $merge)
        {
            merge-files
        }
    }
}

# ----------------------------------------------------------------------------------------------------------------
function receive-backgroundJobs($showStatus = $false)
{
    foreach ($job in get-job)
    {
        $results = Receive-Job -Job $job
        log-info $results

        if ($job.State -ieq 'Completed')
        {
            log-info ("$([DateTime]::Now) job completed. job name: $($job.Name) job id:$($job.Id) job state:$($job.State)")

            if (![string]::IsNullOrEmpty($job.Error))
            {
                log-infog "job error:$($job.Error) job status:$($job.StatusMessage)"
            }

            Remove-Job -Job $job -Force
            $global:jobs.Remove($job)
        }
    }

    if ($showStatus)
    {
        foreach ($job in $global:jobs)
        {
            log-info ("$([DateTime]::Now) job name: $($job.Name) job id:$($job.Id) job state:$($job.State)") 

            if (![string]::IsNullOrEmpty($job.Error))
            {
                log-info "job error:$($job.Error) job status:$($job.StatusMessage)"
            }
        }
    }
}

# ----------------------------------------------------------------------------------------------------------------
function remove-jobs($silent)
{
    try
    {
        if (@(get-job).Count -gt 0)
        {
            if (!$silent -and !(Read-Host -Prompt "delete existing jobs?[y|n]:") -like "y")
            {
                return
            }

            foreach ($job in get-job)
            {
                $job.StopJob()
                Remove-Job $job -Force
            }
        }
    }
    catch
    {
        write-host $Error
        $error.Clear()
    }
}

# ----------------------------------------------------------------------------------------------------------------
function runas-admin([bool]$force)
{
    log-info "checking for admin"
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

    if ($force -and !$isAdmin)
    {
        log-info "please restart script as administrator. exiting..."
        exit 1
    }
    elseif ($isAdmin)
    {
        log-info "running as admin"
        return
    }
    
    log-info "warning:not running as admin"
   
}

# ----------------------------------------------------------------------------------------------------------------
function set-uploadDir()
{
    get-workingDirectory

    # if parsing a path for evtx files to convert and no upload path is given then use path of evtx
    if (!$global:uploadDir -and $global:eventLogFiles)
    {
        if ([IO.Directory]::Exists($eventLogPath))
        {
            $global:uploadDir = $eventLogPath
        }
        else
        {
            $global:uploadDir = [IO.Path]::GetDirectoryName($eventLogPath)
        }
    }
    elseif (!$global:uploadDir)
    {
        $global:uploadDir = "$(get-location)\gather"
    }

    # make sure directory exists
    if (!(test-path $global:uploadDir))
    {
        [IO.Directory]::CreateDirectory($global:uploadDir)
    }

    log-info "upload dir: $($global:uploadDir)"
}

# ----------------------------------------------------------------------------------------------------------------
function show-debugWarning ($count)
{
    $machineInfo = [string]::Empty
    if ((@($machines).Count -eq 1 -and @($machines)[0] -ine $env:COMPUTERNAME) -or @($machines).Count -gt 1)
    {
        $machineInfo = " -machines $([string]::Join(",",$machines))"
    }

    log-info "-----------------------------------------"
    log-info "WARNING: $($count) Debug eventlogs are enabled. Current limit configuration per machine in script is $($debugLogsMax)."
    log-info "`tEnabling too many debug event logs can cause performance / stability issues as well as inability to boot!" -nocolor
    log-info "`tWhen finished troubleshooting, rerun script again with these switches: .\event-log-manager.ps1 -listeventlogs -disableDebugLogs$($machineInfo)" -nocolor
    log-info "-----------------------------------------"
}

# ----------------------------------------------------------------------------------------------------------------
function start-exportJob([string]$machine, [string]$eventLogName, [string]$queryString, [string]$outputCsv)
{
    log-info "starting export job:$($machine) eventlog:$($eventLogName)" -debugOnly

    #throttle
    While (@(Get-Job | Where-Object { $_.State -eq 'Running' }).Count -gt $jobThrottle)
    {
        receive-backgroundJobs
        Start-Sleep -Milliseconds 100
    }

    $job = Start-Job -Name "$($machine):$($eventLogName)" -ScriptBlock {
        param($eventLogName,
            $appendOutputFiles,
            $logFile,
            $uploadDir,
            $machine,
            $eventStartTime,
            $eventStopTime,
            $clearEventLogsOnGather,
            $queryString,
            $eventTracePattern,
            $outputCsv,
            $eventLogFiles,
            $eventDetails,
            $eventDetailsFormatted
        )

        try
        {
            $session = New-Object Diagnostics.Eventing.Reader.EventLogSession ($machine)

            if (!$global:eventLogFiles)
            {
                $pathType = [Diagnostics.Eventing.Reader.PathType]::LogName
            }
            else
            {
                $pathType = [Diagnostics.Eventing.Reader.PathType]::FilePath
            }

            $query = New-Object Diagnostics.Eventing.Reader.EventLogQuery ($eventLogName, $pathType, $queryString)
            $query.Session = $session
            $reader = New-Object Diagnostics.Eventing.Reader.EventLogReader $query
            write-host "processing machine:$($machine) eventlog:$($eventLogName)" -ForegroundColor Green
        }
        catch
        {
            write-host "FAIL:$($eventLogName): $($Error)"
            $error.Clear()
            continue
        }

        if (!$appendOutputFiles -and (test-path $outputCsv))
        {
            write-host "removing existing file: $($outputCsv)"
            Remove-Item -Path $outputCsv -Force
        }

        $count = 0
        $timer = [DateTime]::Now
        $totalCount = 0
        $stream = $null

        while ($true)
        {
            if ($stream -eq $null)
            {
                $stream = new-object System.IO.StreamWriter ($outputCsv, $true)
            }

            try
            {
                $count++
                $event = $reader.ReadEvent()

                if ($event -eq $null)
                {
                    break
                }
                elseif ($event.TimeCreated)
                {
                    $description = $event.FormatDescription()
                    if (!$description)
                    {
                        $description = "$(([xml]$event.ToXml()).Event.UserData.InnerXml)"
                    }
                    else
                    {
                        $description = $description.Replace("`r`n", ";")
                    }

                    # event log 'details' tab
                    if ($eventdetails -or $eventDetailsFormatted -or !$description)
                    {
                        $eventXml = $event.ToXml()

                        if ($eventXml)
                        {
                            if ($eventDetailsFormatted)
                            {
                                # $eventxml may not be xml
                                try
                                {
                                    # format xml
                                    [Xml.XmlDocument] $xdoc = New-Object System.Xml.XmlDocument
                                    $xdoc.LoadXml($eventXml)
                                    [IO.StringWriter] $sw = new-object IO.StringWriter
                                    [Xml.XmlTextWriter] $xmlTextWriter = new-object Xml.XmlTextWriter ($sw)
                                    $xmlTextWriter.Formatting = [Xml.Formatting]::Indented
                                    $xdoc.PreserveWhitespace = $true
                                    $xdoc.WriteTo($xmlTextWriter)
                                    $description = "$($description)`r`n$($sw.ToString())"
                                }
                                catch
                                {
                                    $description = "$($description)$($eventXml)"
                                }
                            }
                            else
                            {
                                # display xml unformatted
                                $description = "$($description)$($eventXml)"
                            }
                        }
                    }

                    $outputEntry = (("$($event.TimeCreated.ToString("MM/dd/yyyy,hh:mm:ss.ffffff tt")),$($event.Id)," `
                        + "$($event.LevelDisplayName),$($event.ProviderName),$($event.ProcessId),$($event.ThreadId)," `
                        + "$($description)"))

                    if (!$eventTracePattern -or 
                        ($eventTracePattern -and 
                            [regex]::IsMatch($outputEntry, $eventTracePattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                                [Text.RegularExpressions.RegexOptions]::Singleline)))
                    {
                        if ($eventTracePattern)
                        {
                            write-host "------------------------------------------"
                            write-host $outputEntry
                        }
                    
                        $stream.WriteLine($outputEntry)
                    }
                    
                    if ([DateTime]::Now.Subtract($timer).TotalSeconds -gt 30)
                    {
                        $totalcount = $totalCount + $count
                        write-host "$($machine):$($eventLogName):$([decimal]($count / [DateTime]::Now.Subtract($timer).TotalSeconds)) records per second. total: $($totalCount)" -ForegroundColor Magenta
                        $timer = [DateTime]::Now
                        $count = 0
                    }
                }
                else
                {
                    write-host "empty event, skipping..."
                }
            }
            catch
            {
                if ($debugscript)
                {
                    write-host "job exception:$($error)"
                }

                $error.Clear()
            }
        }

        $stream.Flush()
        $stream.close()
        $stream = $null

        write-host "finished saving file $($outputCsv)" -for Cyan

        if ($clearEventLogsOnGather)
        {
            $eventLog = New-Object Diagnostics.Eventing.Reader.EventLogConfiguration ($eventLogName, $session)
            write-host "clearing event log: $($eventLogName)"
            if ($eventLog.IsEnabled -and !$eventLog.IsClassicLog)
            {
                $eventLog.IsEnabled = $false
                $eventLog.SaveChanges()
                $eventLog.Dispose()

                $session.ClearLog($eventLogName)

                $eventLog = New-Object Diagnostics.Eventing.Reader.EventLogConfiguration ($eventLogName, $session)
                $eventLog.IsEnabled = $true
                $eventLog.SaveChanges()
            }
            elseif ($eventLog.IsClassicLog)
            {
                $session.ClearLog($eventLogName)
            }
        }
    } -ArgumentList ($eventLogName,
        $appendOutputFiles,
        $logFile,
        $global:uploadDir,
        $machine,
        $eventStartTime,
        $eventStopTime,
        $clearEventLogsOnGather,
        $queryString,
        $eventTracePattern,
        $outputCsv,
        $global:eventLogFiles,
        $eventDetails,
        $eventDetailsFormatted
    )

    return $job
}

# ----------------------------------------------------------------------------------------------------------------
function start-listenJob([hashtable]$jobItem)
{
    log-info "starting listen job:$($jobItem.Machine)" -debugOnly
    
    # max job check
    if (@(Get-Job | Where-Object { $_.State -eq 'Running' }).Count -gt $jobThrottle)
    {
        log-info "error: too many listen jobs running. returning..."
        return
    }

    $job = Start-Job -Name "$($machine)" -ScriptBlock `
    {
        param([hashtable]$jobItem,
            $logFile,
            $uploadDir,
            $eventTracePattern,
            $eventDetails,
            $eventDetailsFormatted,
            $listenEventReadCount,
            $listenSleepMs,
            $debugscript
        )
  
        $checkMachine = $true
        $session = $null
        $pathType = [Diagnostics.Eventing.Reader.PathType]::LogName

        while ($true)
        {
            try
            {
                $machine = $jobItem.Machine
                $resultsList = @{}

                if ($checkMachine)
                {
                    # check connectivity
                    if (!(test-path "\\$($machine)\admin$"))
                    {
                        Write-Warning "unable to connect to machine: $($machine). sleeping."
                        start-sleep -Seconds 30
                        continue
                    }
                    else
                    {
                        Write-Host "successfully connected to machine: $($machine). enabling EventLog Session. Type Ctrl-C to stop execution cleanly." -ForegroundColor Green
                        $checkMachine = $false
                        $session = New-Object Diagnostics.Eventing.Reader.EventLogSession ($machine)
                    }
                }
    
                foreach ($eventLogItem in $jobItem.EventLogItems.GetEnumerator())
                {
                    $eventLogName = $eventLogItem.Name
                    $eventQuery = $eventLogItem.Value.EventQuery
                    $outputCsv = $eventLogItem.Value.OutputCsv
                    $queryString = $eventLogItem.Value.QueryString                
                    $recordId = $eventLogItem.Value.RecordId
                    $stream = $null

                    try
                    {
                        if ($recordid -gt 0)
                        {
                            $queryString = "<QueryList>
                                <Query Id=`"0`" Path=`"$($eventLogName)`">
                                <Select Path=`"$($eventLogName)`">*[System[$($eventQuery)(EventRecordID &gt;`'$($recordid)`')]]</Select>
                                </Query>
                                </QueryList>"
                        }

                        $query = New-Object Diagnostics.Eventing.Reader.EventLogQuery ($eventLogName, $pathType, $queryString)
                        $query.Session = $session
                        $reader = New-Object Diagnostics.Eventing.Reader.EventLogReader $query
                        write-Debug "processing machine:$($machine) eventlog:$($eventLogName)"
                    
                        $count = 0
                        $event = $reader.ReadEvent()

                        while ($count -le $listenEventReadCount)
                        {
                            if ($event -eq $null)
                            {
                                break
                            }
                            elseif ($event.TimeCreated)
                            {
                                $description = $event.FormatDescription()
                                if (!$description)
                                {
                                    $description = "$(([xml]$event.ToXml()).Event.UserData.InnerXml)"
                                }
                                else
                                {
                                    $description = $description.Replace("`r`n", ";")
                                }

                                # event log 'details' tab
                                if ($eventdetails -or $eventDetailsFormatted -or !$description)
                                {
                                    $eventXml = $event.ToXml()
                                    if ($eventXml)
                                    {
                                        if ($eventDetailsFormatted)
                                        {
                                            # $eventxml may not be xml
                                            try
                                            {
                                                # format xml
                                                [Xml.XmlDocument] $xdoc = New-Object System.Xml.XmlDocument
                                                $xdoc.LoadXml($eventXml)
                                                [IO.StringWriter] $sw = new-object IO.StringWriter
                                                [Xml.XmlTextWriter] $xmlTextWriter = new-object Xml.XmlTextWriter ($sw)
                                                $xmlTextWriter.Formatting = [Xml.Formatting]::Indented
                                                $xdoc.PreserveWhitespace = $true
                                                $xdoc.WriteTo($xmlTextWriter)
                                                $description = "$($description)`r`n$($sw.ToString())"
                                            }
                                            catch
                                            {
                                                $description = "$($description)$($eventXml)"
                                            }
                                        }
                                        else
                                        {
                                            # display xml unformatted
                                            $description = "$($description)$($eventXml)"
                                        }
                                    }
                                }

                                $outputEntry = (("$($event.TimeCreated.ToString("MM/dd/yyyy,hh:mm:ss.ffffff tt"))," `
                                    + "$($machine),$($event.Id),$($event.LevelDisplayName),$($event.ProviderName),$($event.ProcessId)," `
                                    + "$($event.ThreadId),$($description)"))

                                if (!$eventTracePattern -or 
                                    ($eventTracePattern -and 
                                        [regex]::IsMatch($outputEntry, $eventTracePattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                                            [Text.RegularExpressions.RegexOptions]::Singleline)))
                                {
                                    if ($stream -eq $null)
                                    {
                                        $stream = new-object System.IO.StreamWriter ($outputCsv, $true)
                                    }

                                    $stream.WriteLine($outputEntry)

                                    [DateTime]$timeadjust = $event.TimeCreated
                                    while ($resultsList.ContainsKey($timeadjust.ToString("o")))
                                    {
                                        $timeadjust = $timeadjust.AddTicks(1)
                                    }

                                    $resultsList.Add($timeadjust.ToString("o"), $outputEntry)
                                }
                            }
                            else
                            {
                                Write-host "empty event, skipping..."
                            }

                            # prevent recordid 0 duping events
                            $eventLogItem.Value.RecordId = [Math]::Max($eventLogItem.RecordId + 1, $event.RecordId)
                            $event = $reader.ReadEvent()
                            [void]$count++
                        } # end while

                        while ($count -ge $listenEventReadCount)
                        {
                            # to keep listen from getting behind
                            # if there are more records than $listenEventReadCount, read the rest
                            # cant seek in debug logs.
                            # keep reading events but dont process
               
                            if (!($event = $reader.ReadEvent()))
                            {
                                Write-Warning "$([DateTime]::Now):$($machine):$($eventLogName) max read count reached, skipping newest $($count - $listenEventReadCount) events." #-debugOnly
                                break
                            }

                            $eventLogItem.Value.RecordId = $event.RecordId
                            [void]$count++
                        }
                    }
                    catch
                    {
                        if ($debugscript)
                        {
                            Write-Host "$([DateTime]::Now):$($machine):Job listen event exception:$($eventLogName) id:$($event.RecordId) error: $($Error)" -ForegroundColor Red
                        }

                        $eventLogItem.Value.RecordId = [Math]::Max($eventLogItem.RecordId + 1, $event.RecordId)
                        $error.Clear()
                    }
                    finally
                    {
                        if ($stream -ne $null)
                        {
                            $stream.Flush()
                            $stream.close()
                            $stream = $null
                        }
                    }

                } # end foreach

                # output sorted
                foreach ($result in ($resultsList.GetEnumerator() | Sort-Object))
                {
                    $result.Value.ToString()
                }

                Write-Debug "$([DateTime]::Now) job $($machine) wrote $($resultsList.Count) records"
            }
            catch
            {
                if ($debugscript)
                {
                    Write-Host "$([DateTime]::Now):$($machine):Job listen exception: $($error)" -ForegroundColor Red
                }

                $checkMachine = $true
                $error.Clear()
            } # end try

            Start-Sleep -Milliseconds $listenSleepMs
        } # end while
    } -ArgumentList ($jobItem,
        $logFile,
        $global:uploadDir,
        $eventTracePattern,
        $eventDetails,
        $eventDetailsFormatted,
        $listenEventReadCount,
        $listenSleepMs,
        $debugscript
    )

    return $job 
}

# ----------------------------------------------------------------------------------------------------------------
main
