Add-Type -TypeDefinition @'
namespace ScheduledTask
{
    public enum DaysOfWeek : ushort
    {
        Sunday = 1,
        Monday = 2,
        Tuesday = 4,
        Wednesday = 8,
        Thursday = 16,
        Friday = 32,
        Saturday = 64
    }
    public enum StateChange : uint
    {
        Undefined = 0,
        OnConnectionFromLocalComputer = 1,
        OnDisconnectFromLocalComputer = 2,
        OnConnectionFromRemoteComputer = 3,
        OnDisconnectFromRemoteComputer = 4,
        OnWorkstationLock = 7,
        OnWorkstationUnlock = 8
    }
}
'@

$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Gets the current state of the resource.

    .PARAMETER TaskName
        The name of the task.

    .PARAMETER TaskPath
        The path to the task - defaults to the root directory.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskName,

        [Parameter()]
        [System.String]
        $TaskPath = '\'
    )

    $TaskPath = ConvertTo-NormalizedTaskPath -TaskPath $TaskPath

    Write-Verbose -Message ($script:localizedData.GetScheduledTaskMessage -f $TaskName, $TaskPath)

    return Get-CurrentResource @PSBoundParameters
}

<#
    .SYNOPSIS
        Tests if the current resource state matches the desired resource state.

    .PARAMETER TaskName
        The name of the task.

    .PARAMETER TaskPath
        The path to the task - defaults to the root directory.

    .PARAMETER Description
        The task description.

    .PARAMETER ActionExecutable
        The path to the .exe for this task.

    .PARAMETER ActionArguments
        The arguments to pass the executable.

    .PARAMETER ActionWorkingPath
        The working path to specify for the executable.

    .PARAMETER ScheduleType
        When should the task be executed.

    .PARAMETER RepeatInterval
        How many units (minutes, hours, days) between each run of this task?

    .PARAMETER StartTime
        The date and time of day this task should start at, or activate on, represented
        as a string for local conversion to DateTime format - defaults to 1st January 1980 at 12:00 AM.

    .PARAMETER SynchronizeAcrossTimeZone
        Enable the scheduled task option to synchronize across time zones. This is enabled
        by including the timezone offset in the scheduled task trigger. Defaults to false
        which does not include the timezone offset.

    .PARAMETER Ensure
        Present if the task should exist, Absent if it should be removed.

    .PARAMETER Enable
        True if the task should be enabled, false if it should be disabled.

    .PARAMETER BuiltInAccount
        Run the task as one of the built in service accounts.
        When set ExecuteAsCredential will be ignored and LogonType will be set to 'ServiceAccount'.

    .PARAMETER ExecuteAsCredential
        The credential this task should execute as. If not specified defaults to running
        as the local system account. Cannot be used in combination with ExecuteAsGMSA.

    .PARAMETER ExecuteAsGMSA
        The gMSA (Group Managed Service Account) this task should execute as. Cannot be
        used in combination with ExecuteAsCredential.

    .PARAMETER DaysInterval
        Specifies the interval between the days in the schedule. An interval of 1 produces
        a daily schedule. An interval of 2 produces an every-other day schedule. This
        parameter is only valid in combination with the Daily Schedule Type.

    .PARAMETER RandomDelay
        Specifies a random amount of time to delay the start time of the trigger. The
        delay time is a random time between the time the task triggers and the time that
        you specify in this setting. This parameter is only valid in combination with the
        Once, Daily and Weekly Schedule Types.

    .PARAMETER RepetitionDuration
        Specifies how long the repetition pattern repeats after the task starts.

    .PARAMETER StopAtDurationEnd
        Indicates that Task Scheduler stops all running tasks at the end of the repetition
        duration. Defaults to $false.

    .PARAMETER TriggerExecutionTimeLimit
        Specifies the amount of time for the trigger that Task Scheduler is allowed to complete the task.

    .PARAMETER DaysOfWeek
        Specifies an array of the days of the week on which Task Scheduler runs the task. This
        parameter is only valid in combination with the Weekly Schedule Type.

    .PARAMETER WeeksInterval
        Specifies the interval between the weeks in the schedule. An interval of 1 produces
        a weekly schedule. An interval of 2 produces an every-other week schedule. This
        parameter is only valid in combination with the Weekly Schedule Type.

    .PARAMETER User
        Specifies the identifier of a user that will trigger the task to start. This
        parameter is only valid in combination with the AtLogon and OnSessionState Schedule Types.

    .PARAMETER DisallowDemandStart
        Indicates whether the task is prohibited to run on demand or not. Defaults
        to $false.

    .PARAMETER DisallowHardTerminate
        Indicates whether the task is prohibited to be terminated or not. Defaults
        to $false.

    .PARAMETER Compatibility
        The task compatibility level. Defaults to Vista.

    .PARAMETER AllowStartIfOnBatteries
        Indicates whether the task should start if the machine is on batteries or not.
        Defaults to $false.

    .PARAMETER Hidden
        Indicates that the task is hidden in the Task Scheduler UI.

    .PARAMETER RunOnlyIfIdle
        Indicates that Task Scheduler runs the task only when the computer is idle.

    .PARAMETER IdleWaitTimeout
        Specifies the amount of time that Task Scheduler waits for an idle condition to occur.

    .PARAMETER NetworkName
        Specifies the name of a network profile that Task Scheduler uses to determine
        if the task can run.
        The Task Scheduler UI uses this setting for display purposes. Specify a network
        name if you specify the RunOnlyIfNetworkAvailable parameter.

    .PARAMETER DisallowStartOnRemoteAppSession
        Indicates that the task does not start if the task is triggered to run in a Remote
        Applications Integrated Locally (RAIL) session.

    .PARAMETER StartWhenAvailable
        Indicates that Task Scheduler can start the task at any time after its scheduled
        time has passed.

    .PARAMETER DontStopIfGoingOnBatteries
        Indicates that the task does not stop if the computer switches to battery power.

    .PARAMETER WakeToRun
        Indicates that Task Scheduler wakes the computer before it runs the task.

    .PARAMETER IdleDuration
        Specifies the amount of time that the computer must be in an idle state before
        Task Scheduler runs the task.

    .PARAMETER RestartOnIdle
        Indicates that Task Scheduler restarts the task when the computer cycles into an
        idle condition more than once.

    .PARAMETER DontStopOnIdleEnd
        Indicates that Task Scheduler does not terminate the task if the idle condition
        ends before the task is completed.

    .PARAMETER ExecutionTimeLimit
        Specifies the amount of time that Task Scheduler is allowed to complete the task.

    .PARAMETER MultipleInstances
        Specifies the policy that defines how Task Scheduler handles multiple instances
        of the task.

    .PARAMETER Priority
        Specifies the priority level of the task. Priority must be an integer from 0 (highest priority)
        to 10 (lowest priority). The default value is 7. Priority levels 7 and 8 are
        used for background tasks. Priority levels 4, 5, and 6 are used for interactive tasks.

    .PARAMETER RestartCount
        Specifies the number of times that Task Scheduler attempts to restart the task.

    .PARAMETER RestartInterval
        Specifies the amount of time that Task Scheduler attempts to restart the task.

    .PARAMETER RunOnlyIfNetworkAvailable
        Indicates that Task Scheduler runs the task only when a network is available. Task
        Scheduler uses the NetworkID parameter and NetworkName parameter that you specify
        in this cmdlet to determine if the network is available.

    .PARAMETER RunLevel
        Specifies the level of user rights that Task Scheduler uses to run the tasks that
        are associated with the principal. Defaults to 'Limited'.

    .PARAMETER LogonType
        Specifies the security logon method that Task Scheduler uses to run the tasks that
        are associated with the principal.

    .PARAMETER EventSubscription
        The event subscription in a string that can be parsed as valid XML. This parameter is only
        valid in combination with the OnEvent Schedule Type. For the query schema please check:
        https://docs.microsoft.com/en-us/windows/desktop/WES/queryschema-schema

    .PARAMETER EventValueQueries
        Specifies event value queries. This parameter is only valid in combination with the OnEvent
        Schedule Type. Receives a hashtable where the key is a property value for an event and
        the value is an XPath event query. For more detailed syntax check:
        https://learn.microsoft.com/en-us/windows/win32/taskschd/eventtrigger-valuequeries.

    .PARAMETER Delay
        Specifies a delay to the start of the trigger. This parameter is only valid in combination
        with the AtLogon, AtStartup, OnEvent, AtCreation and OnSessionState Schedule Types.

    .PARAMETER StateChange
        The kind of session state change that would trigger a task launch. This parameter is
        only valid in combination with the OnSessionState Schedule Type.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskName,

        [Parameter()]
        [System.String]
        $TaskPath = '\',

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $ActionExecutable,

        [Parameter()]
        [System.String]
        $ActionArguments,

        [Parameter()]
        [System.String]
        $ActionWorkingPath,

        [Parameter()]
        [System.String]
        [ValidateSet('Once', 'Daily', 'Weekly', 'AtStartup', 'AtLogon', 'OnIdle', 'OnEvent', 'AtCreation', 'OnSessionState')]
        $ScheduleType,

        [Parameter()]
        [System.String]
        $RepeatInterval = '00:00:00',

        [Parameter()]
        [System.String]
        $StartTime = '1980-01-01T00:00:00',

        [Parameter()]
        [System.Boolean]
        $SynchronizeAcrossTimeZone = $false,

        [Parameter()]
        [System.String]
        [ValidateSet('Present', 'Absent')]
        $Ensure = 'Present',

        [Parameter()]
        [System.Boolean]
        $Enable = $true,

        [Parameter()]
        [ValidateSet('SYSTEM', 'LOCAL SERVICE', 'NETWORK SERVICE')]
        [System.String]
        $BuiltInAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ExecuteAsCredential,

        [Parameter()]
        [System.String]
        $ExecuteAsGMSA,

        [Parameter()]
        [System.UInt32]
        $DaysInterval = 1,

        [Parameter()]
        [System.String]
        $RandomDelay = '00:00:00',

        [Parameter()]
        [System.String]
        $RepetitionDuration = '00:00:00',

        [Parameter()]
        [System.Boolean]
        $StopAtDurationEnd = $false,

        [Parameter()]
        [System.String]
        $TriggerExecutionTimeLimit = '00:00:00',

        [Parameter()]
        [System.String[]]
        $DaysOfWeek,

        [Parameter()]
        [System.UInt32]
        $WeeksInterval = 1,

        [Parameter()]
        [System.String]
        $User,

        [Parameter()]
        [System.Boolean]
        $DisallowDemandStart = $false,

        [Parameter()]
        [System.Boolean]
        $DisallowHardTerminate = $false,

        [Parameter()]
        [ValidateSet('AT', 'V1', 'Vista', 'Win7', 'Win8')]
        [System.String]
        $Compatibility = 'Vista',

        [Parameter()]
        [System.Boolean]
        $AllowStartIfOnBatteries = $false,

        [Parameter()]
        [System.Boolean]
        $Hidden = $false,

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfIdle = $false,

        [Parameter()]
        [System.String]
        $IdleWaitTimeout = '02:00:00',

        [Parameter()]
        [System.String]
        $NetworkName,

        [Parameter()]
        [System.Boolean]
        $DisallowStartOnRemoteAppSession = $false,

        [Parameter()]
        [System.Boolean]
        $StartWhenAvailable = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopIfGoingOnBatteries = $false,

        [Parameter()]
        [System.Boolean]
        $WakeToRun = $false,

        [Parameter()]
        [System.String]
        $IdleDuration = '01:00:00',

        [Parameter()]
        [System.Boolean]
        $RestartOnIdle = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopOnIdleEnd = $false,

        [Parameter()]
        [System.String]
        $ExecutionTimeLimit = '08:00:00',

        [Parameter()]
        [ValidateSet('IgnoreNew', 'Parallel', 'Queue', 'StopExisting')]
        [System.String]
        $MultipleInstances = 'Queue',

        [Parameter()]
        [System.UInt32]
        $Priority = 7,

        [Parameter()]
        [System.UInt32]
        $RestartCount = 0,

        [Parameter()]
        [System.String]
        $RestartInterval = '00:00:00',

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfNetworkAvailable = $false,

        [Parameter()]
        [ValidateSet('Limited', 'Highest')]
        [System.String]
        $RunLevel = 'Limited',

        [Parameter()]
        [ValidateSet('Group', 'Interactive', 'InteractiveOrPassword', 'None', 'Password', 'S4U', 'ServiceAccount')]
        [System.String]
        $LogonType,

        [Parameter()]
        [System.String]
        $EventSubscription,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $EventValueQueries,

        [Parameter()]
        [System.String]
        $Delay = '00:00:00',

        [Parameter()]
        [System.String]
        [ValidateSet('OnConnectionFromLocalComputer', 'OnDisconnectFromLocalComputer', 'OnConnectionFromRemoteComputer', 'OnDisconnectFromRemoteComputer', 'OnWorkstationLock', 'OnWorkstationUnlock')]
        $StateChange
    )

    $TaskPath = ConvertTo-NormalizedTaskPath -TaskPath $TaskPath

    Write-Verbose -Message ($script:localizedData.SetScheduledTaskMessage -f $TaskName, $TaskPath)

    # Convert the strings containing dates & times to DateTime objects
    [System.DateTime] $StartTime = [System.DateTime]::Parse($StartTime)

    # Convert the strings containing time spans to TimeSpan Objects
    [System.TimeSpan] $RepeatInterval = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RepeatInterval
    [System.TimeSpan] $RandomDelay = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RandomDelay
    [System.TimeSpan] $RepetitionDuration = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RepetitionDuration -AllowIndefinitely
    [System.TimeSpan] $TriggerExecutionTimeLimit = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $TriggerExecutionTimeLimit
    [System.TimeSpan] $IdleWaitTimeout = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $IdleWaitTimeout
    [System.TimeSpan] $IdleDuration = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $IdleDuration
    [System.TimeSpan] $ExecutionTimeLimit = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $ExecutionTimeLimit
    [System.TimeSpan] $RestartInterval = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RestartInterval
    [System.TimeSpan] $Delay = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $Delay

    $currentValues = Get-CurrentResource -TaskName $TaskName -TaskPath $TaskPath

    if ($Ensure -eq 'Present')
    {
        <#
            If the scheduled task already exists and is enabled but it needs to be disabled
            and the action executable isn't specified then disable the task
        #>
        if ($currentValues.Ensure -eq 'Present' `
            -and $currentValues.Enable `
            -and -not $Enable `
            -and -not $PSBoundParameters.ContainsKey('ActionExecutable'))
        {
            Write-Verbose -Message ($script:localizedData.DisablingExistingScheduledTask -f $TaskName, $TaskPath)

            if ($PSVersionTable.PSVersion -gt [System.Version]'5.0.0.0')
            {
                Disable-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
            }
            else
            {
                Disable-ScheduledTaskEx -TaskName $TaskName -TaskPath $TaskPath
            }

            return
        }

        if ($RepetitionDuration -lt $RepeatInterval)
        {
            New-ArgumentException `
                -Message ($script:localizedData.RepetitionDurationLessThanIntervalError -f $RepetitionDuration, $RepeatInterval) `
                -ArgumentName RepeatInterval
        }

        if ($ScheduleType -eq 'Daily' -and $DaysInterval -eq 0)
        {
            New-ArgumentException `
                -Message ($script:localizedData.DaysIntervalError -f $DaysInterval) `
                -ArgumentName DaysInterval
        }

        if ($ScheduleType -eq 'Weekly' -and $WeeksInterval -eq 0)
        {
            New-ArgumentException `
                -Message ($script:localizedData.WeeksIntervalError -f $WeeksInterval) `
                -ArgumentName WeeksInterval
        }

        if ($ScheduleType -eq 'Weekly' -and $DaysOfWeek.Count -eq 0)
        {
            New-ArgumentException `
                -Message ($script:localizedData.WeekDayMissingError) `
                -ArgumentName DaysOfWeek
        }

        if ($ScheduleType -eq 'OnEvent')
        {
            try
            {
                $null = [xml]$EventSubscription
            }
            catch
            {
                New-ArgumentException `
                    -Message ($script:localizedData.OnEventSubscriptionError) `
                    -ArgumentName EventSubscription
            }
        }

        if ($ScheduleType -eq 'OnSessionState' -and [System.String]::IsNullOrEmpty($StateChange))
        {
            New-ArgumentException `
                -Message ($script:localizedData.OnSessionStateChangeError) `
                -ArgumentName StateChange
        }

        if ($ExecuteAsGMSA -and ($ExecuteAsCredential -or $BuiltInAccount))
        {
            New-ArgumentException `
                -Message ($script:localizedData.gMSAandCredentialError) `
                -ArgumentName ExecuteAsGMSA
        }

        # Configure the action
        $actionParameters = @{
            Execute = $ActionExecutable
        }

        if ($ActionArguments)
        {
            $actionParameters.Add('Argument', $ActionArguments)
        }

        if ($ActionWorkingPath)
        {
            $actionParameters.Add('WorkingDirectory', $ActionWorkingPath)
        }

        $action = New-ScheduledTaskAction @actionParameters

        $scheduledTaskArguments = @{
            Action = $action
        }

        # Configure the settings
        $settingParameters = @{
            DisallowDemandStart             = $DisallowDemandStart
            DisallowHardTerminate           = $DisallowHardTerminate
            Compatibility                   = $Compatibility
            AllowStartIfOnBatteries         = $AllowStartIfOnBatteries
            Disable                         = -not $Enable
            Hidden                          = $Hidden
            RunOnlyIfIdle                   = $RunOnlyIfIdle
            DisallowStartOnRemoteAppSession = $DisallowStartOnRemoteAppSession
            StartWhenAvailable              = $StartWhenAvailable
            DontStopIfGoingOnBatteries      = $DontStopIfGoingOnBatteries
            WakeToRun                       = $WakeToRun
            RestartOnIdle                   = $RestartOnIdle
            DontStopOnIdleEnd               = $DontStopOnIdleEnd
            Priority                        = $Priority
            RestartCount                    = $RestartCount
            RunOnlyIfNetworkAvailable       = $RunOnlyIfNetworkAvailable
        }

        if ($MultipleInstances -ne 'StopExisting')
        {
            $settingParameters.Add('MultipleInstances', $MultipleInstances)
        }

        if ($IdleDuration -gt [System.TimeSpan] '00:00:00')
        {
            $settingParameters.Add('IdleDuration', $IdleDuration)
        }

        if ($IdleWaitTimeout -gt [System.TimeSpan] '00:00:00')
        {
            $settingParameters.Add('IdleWaitTimeout', $IdleWaitTimeout)
        }

        if ($PSBoundParameters.ContainsKey('ExecutionTimeLimit'))
        {
            $settingParameters.Add('ExecutionTimeLimit', $ExecutionTimeLimit)
        }

        if ($RestartInterval -gt [System.TimeSpan] '00:00:00')
        {
            $settingParameters.Add('RestartInterval', $RestartInterval)
        }

        if (-not [System.String]::IsNullOrWhiteSpace($NetworkName))
        {
            $settingParameters.Add('NetworkName', $NetworkName)
        }

        $setting = New-ScheduledTaskSettingsSet @settingParameters

    <#  The following workaround is needed because the TASK_INSTANCES_STOP_EXISTING value of
        https://docs.microsoft.com/en-us/windows/win32/taskschd/tasksettings-multipleinstances is missing
        from the Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.MultipleInstancesEnum,
        which is used for the other values of $MultipleInstances. (at least currently, as of June, 2020)
    #>
        if ($MultipleInstances -eq 'StopExisting')
        {
            $setting.CimInstanceProperties.Item('MultipleInstances').Value = 3
        }

        $scheduledTaskArguments += @{
            Settings = $setting
        }

        <#
            On Windows Server 2012 R2 setting a blank timespan for ExecutionTimeLimit
            does not result in the PT0S timespan value being set. So set this
            if it has not been set.
        #>
        if ($PSBoundParameters.ContainsKey('ExecutionTimeLimit') -and `
                [System.String]::IsNullOrEmpty($setting.ExecutionTimeLimit))
        {
            $setting.ExecutionTimeLimit = 'PT0S'
        }

        # Configure the trigger
        $triggerParameters = @{}

        # A random delay is only supported when the scheduleType is set to Once, Daily or Weekly
        if ($RandomDelay -gt [System.TimeSpan]::FromSeconds(0) -and $ScheduleType -in @('Once', 'Daily', 'Weekly'))
        {
            $triggerParameters.Add('RandomDelay', $RandomDelay)
        }

        switch ($ScheduleType)
        {
            'Once'
            {
                $triggerParameters.Add('Once', $true)
                $triggerParameters.Add('At', $StartTime)

                break
            }

            'Daily'
            {
                $triggerParameters.Add('Daily', $true)
                $triggerParameters.Add('At', $StartTime)
                $triggerParameters.Add('DaysInterval', $DaysInterval)

                break
            }

            'Weekly'
            {
                $triggerParameters.Add('Weekly', $true)
                $triggerParameters.Add('At', $StartTime)

                if ($DaysOfWeek.Count -gt 0)
                {
                    $triggerParameters.Add('DaysOfWeek', $DaysOfWeek)
                }

                if ($WeeksInterval -gt 0)
                {
                    $triggerParameters.Add('WeeksInterval', $WeeksInterval)
                }

                break
            }

            'AtStartup'
            {
                $triggerParameters.Add('AtStartup', $true)

                break
            }

            'AtLogon'
            {
                $triggerParameters.Add('AtLogon', $true)

                if (-not [System.String]::IsNullOrWhiteSpace($User))
                {
                    $triggerParameters.Add('User', $User)
                }

                break
            }

            'OnIdle'
            {
                Write-Verbose -Message ($script:localizedData.ConfigureTaskIdleTrigger -f $TaskName)

                $cimTriggerClass = Get-CimClass -ClassName MSFT_TaskIdleTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskIdleTrigger
                $trigger = New-CimInstance -CimClass $cimTriggerClass -ClientOnly
                $trigger.Enabled = $true

                break
            }

            'OnEvent'
            {
                Write-Verbose -Message ($script:localizedData.ConfigureTaskEventTrigger -f $TaskName)

                $cimTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
                $trigger = New-CimInstance -CimClass $cimTriggerClass -ClientOnly
                $trigger.Enabled = $true
                $trigger.Subscription = $EventSubscription
                $trigger.ValueQueries = ConvertTo-TaskNamedValuePairCollectionFromKeyValuePairArray -Array $EventValueQueries

                break
            }

            'AtCreation'
            {
                Write-Verbose -Message ($script:localizedData.ConfigureTaskCreationTrigger -f $TaskName)

                $cimTriggerClass = Get-CimClass -ClassName MSFT_TaskRegistrationTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskRegistrationTrigger
                $trigger = New-CimInstance -CimClass $cimTriggerClass -ClientOnly
                $trigger.Enabled = $true

                break
            }

            'OnSessionState'
            {
                Write-Verbose -Message ($script:localizedData.ConfigureTaskSessionStateTrigger -f $TaskName)

                $cimTriggerClass = Get-CimClass -ClassName MSFT_TaskSessionStateChangeTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskSessionStateChangeTrigger
                $trigger = New-CimInstance -CimClass $cimTriggerClass -ClientOnly
                $trigger.Enabled = $true
                $trigger.StateChange = [ScheduledTask.StateChange] $StateChange
                if (-not [System.String]::IsNullOrWhiteSpace($User))
                {
                    $trigger.UserId = $User
                }

                break
            }
        }

        if ($ScheduleType -notin @('OnIdle', 'OnEvent', 'AtCreation', 'OnSessionState'))
        {
            $trigger = New-ScheduledTaskTrigger @triggerParameters -ErrorAction SilentlyContinue
        }

        # If there is no -At parameter in a PowerShell cmdlet for this trigger type, but we have a StartTime, supply it (used as time to Activate)
        if ($ScheduleType -notin @('Once', 'Daily', 'Weekly'))
        {
            if ($PSBoundParameters.ContainsKey('StartTime'))
            {
                $trigger.StartBoundary = Get-DateTimeString -Date $StartTime -SynchronizeAcrossTimeZone $SynchronizeAcrossTimeZone
            }
        }

        if ($PSBoundParameters.ContainsKey('TriggerExecutionTimeLimit'))
        {
            $trigger.ExecutionTimeLimit = [System.Xml.XmlConvert]::ToString($TriggerExecutionTimeLimit)
        }

        if (-not $trigger)
        {
            New-InvalidOperationException `
                -Message ($script:localizedData.TriggerCreationError) `
                -ErrorRecord $_
        }

        # Add to please strict mode
        $repetition = $null

        if ($RepeatInterval -gt [System.TimeSpan]::Parse('0:0:0'))
        {
            # A repetition pattern is required so create it and attach it to the trigger object
            Write-Verbose -Message ($script:localizedData.ConfigureTriggerRepetitionMessage)

            if ($RepetitionDuration -le $RepeatInterval)
            {
                New-ArgumentException `
                    -Message ($script:localizedData.RepetitionIntervalError -f $RepeatInterval, $RepetitionDuration) `
                    -ArgumentName RepetitionDuration
            }

            $tempTriggerParameters = @{
                Once               = $true
                At                 = '6:6:6'
                RepetitionInterval = $RepeatInterval
            }

            Write-Verbose -Message ($script:localizedData.CreateRepetitionPatternMessage)

            switch ($trigger.GetType().FullName)
            {
                'Microsoft.PowerShell.ScheduledJob.ScheduledJobTrigger'
                {
                    # This is the type of trigger object returned in Windows Server 2012 R2/Windows 8.1 and below
                    Write-Verbose -Message ($script:localizedData.CreateTemporaryTaskMessage)

                    $tempTriggerParameters.Add('RepetitionDuration', $RepetitionDuration)

                    # Create a temporary trigger and task and copy the repetition CIM object from the temporary task
                    $tempTrigger = New-ScheduledTaskTrigger @tempTriggerParameters
                    $tempTask = New-ScheduledTask -Action $action -Trigger $tempTrigger

                    # Store the repetition settings
                    $repetition = $tempTask.Triggers[0].Repetition
                }

                'Microsoft.Management.Infrastructure.CimInstance'
                {
                    # This is the type of trigger object returned in Windows Server 2016/Windows 10 and above
                    Write-Verbose -Message ($script:localizedData.CreateTemporaryTriggerMessage)

                    if ($RepetitionDuration -gt [System.TimeSpan]::Parse('0:0:0') -and $RepetitionDuration -lt [System.TimeSpan]::MaxValue)
                    {
                        $tempTriggerParameters.Add('RepetitionDuration', $RepetitionDuration)
                    }

                    # Create a temporary trigger and copy the repetition CIM object from it to the actual trigger
                    $tempTrigger = New-ScheduledTaskTrigger @tempTriggerParameters

                    # Store the repetition settings
                    $repetition = $tempTrigger.Repetition
                }

                default
                {
                    New-InvalidOperationException `
                        -Message ($script:localizedData.TriggerUnexpectedTypeError -f $trigger.GetType().FullName)
                }
            }

            # If we have some repetition settings, set StopAtDurationEnd to supplied value (not supported in PowerShell cmdlets)
            if ($repetition)
            {
                $repetition.StopAtDurationEnd = $StopAtDurationEnd
            }
        }

        if ($trigger.GetType().FullName -eq 'Microsoft.Management.Infrastructure.CimInstance')
        {
            # On W2016+ / W10+ the Delay property is supported on the AtLogon, AtStartup, OnEvent, AtCreation and OnSessionState trigger types
            $triggerSupportsDelayProperty = @('AtLogon', 'AtStartup', 'OnEvent', 'AtCreation', 'OnSessionState')

            if ($ScheduleType -in $triggerSupportsDelayProperty)
            {
                $trigger.Delay = [System.Xml.XmlConvert]::ToString($Delay)
            }
        }

        $scheduledTaskArguments += @{
            Trigger = $trigger
        }

        # Prepare the register arguments
        $registerArguments = @{}
        $username = $null

        if ($PSBoundParameters.ContainsKey('BuiltInAccount'))
        {
            <#
                The validateset on BuiltInAccount has already checked the
                non-null value to be 'LOCAL SERVICE', 'NETWORK SERVICE' or
                'SYSTEM'
            #>
            $username = Set-DomainNameInAccountName -AccountName $BuiltInAccount -DomainName 'NT AUTHORITY'
            $registerArguments.Add('User', $username)
            $LogonType = 'ServiceAccount'
        }
        elseif ($PSBoundParameters.ContainsKey('ExecuteAsGMSA'))
        {
            $username = $ExecuteAsGMSA
            $LogonType = 'Password'
        }
        elseif ($PSBoundParameters.ContainsKey('ExecuteAsCredential'))
        {
            $username = $ExecuteAsCredential.UserName
            # If the LogonType is not specified then set it to password
            if ([System.String]::IsNullOrEmpty($LogonType))
            {
                $LogonType = 'Password'
            }

            if ($LogonType -ne 'Group')
            {
                $registerArguments.Add('User', $username)
            }

            if ($LogonType -notin ('Interactive', 'S4U', 'Group'))
            {
                # Only set the password if the LogonType is not interactive or S4U
                $registerArguments.Add('Password', $ExecuteAsCredential.GetNetworkCredential().Password)
            }
        }
        else
        {
            <#
                'NT AUTHORITY\SYSTEM' basically gives the schedule task admin
                privileges, should we default to 'NT AUTHORITY\LOCAL SERVICE'
                instead?
            #>
            $username = Set-DomainNameInAccountName -AccountName 'SYSTEM' -DomainName 'NT AUTHORITY'
            $registerArguments.Add('User', $username)
            $LogonType = 'ServiceAccount'
        }

        # Prepare the principal arguments
        $principalArguments = @{
            Id        = 'Author'
        }

        if ($LogonType -eq 'Group')
        {
            $principalArguments.GroupId = $username
        }
        else
        {
            $principalArguments.LogonType = $LogonType
            $principalArguments.UserId = $username
        }

        # Set the Run Level if defined
        if ($PSBoundParameters.ContainsKey('RunLevel'))
        {
            $principalArguments.Add('RunLevel', $RunLevel)
        }

        # Create the principal object
        Write-Verbose -Message ($script:localizedData.CreateScheduledTaskPrincipalMessage -f $username, $LogonType)

        $principal = New-ScheduledTaskPrincipal @principalArguments

        $scheduledTaskArguments += @{
            Principal = $principal
        }

        $tempScheduledTask = New-ScheduledTask @scheduledTaskArguments -ErrorAction Stop

        if ($currentValues.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RetrieveScheduledTaskMessage -f $TaskName, $TaskPath)
            $tempScheduledTask = New-ScheduledTask @scheduledTaskArguments -ErrorAction Stop

            $scheduledTask = ScheduledTasks\Get-ScheduledTask `
                -TaskName $currentValues.TaskName `
                -TaskPath $currentValues.TaskPath `
                -ErrorAction Stop
            $scheduledTask.Actions = $action
            $scheduledTask.Triggers = $tempScheduledTask.Triggers
            $scheduledTask.Settings = $setting
            $scheduledTask.Principal = $principal
        }
        else
        {
            $scheduledTask = $tempScheduledTask
        }

        Write-Verbose -Message ($script:localizedData.CreateNewScheduledTaskMessage -f $TaskName, $TaskPath)

        if ($repetition)
        {
            Write-Verbose -Message ($script:localizedData.SetRepetitionTriggerMessage -f $TaskName, $TaskPath)

            $scheduledTask.Triggers[0].Repetition = $repetition
        }

        if (-not [System.String]::IsNullOrWhiteSpace($Description))
        {
            $scheduledTask.Description = $Description
        }

        if ($scheduledTask.Triggers[0].StartBoundary)
        {
            <#
                The way New-ScheduledTaskTrigger writes the StartBoundary has issues because it does not take
                the setting "Synchronize across time zones" in consideration. What happens if synchronize across
                time zone is enabled in the scheduled task GUI is that the time is written like this:

                2018-09-27T18:45:08+02:00

                When the setting synchronize across time zones is disabled, the time is written as:

                2018-09-27T18:45:08

                The problem in New-ScheduledTaskTrigger is that it always writes the time in the UTC format, which
                includes the full timezone offset: (W2016+ behaviour, W2012R2 does it the other way around)

                2018-09-27 16:45:08Z

                Which means "Synchronize across time zones" is enabled by default on W2016 and disabled by
                default on W2012R2. To prevent that, we are overwriting the StartBoundary here to insert
                the time in the format we want it, so we can enable or disable "Synchronize across time zones".
            #>

            $scheduledTask.Triggers[0].StartBoundary = Get-DateTimeString -Date $StartTime -SynchronizeAcrossTimeZone $SynchronizeAcrossTimeZone
        }

        if ($currentValues.Ensure -eq 'Present')
        {
            # Updating the scheduled task

            Write-Verbose -Message ($script:localizedData.UpdateScheduledTaskMessage -f $TaskName, $TaskPath)
            $null = Set-ScheduledTask -InputObject $scheduledTask @registerArguments
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.CreateNewScheduledTaskMessage -f $TaskName, $TaskPath)

            # Register the scheduled task

            $registerArguments.Add('TaskName', $TaskName)
            $registerArguments.Add('TaskPath', $TaskPath)
            $registerArguments.Add('InputObject', $scheduledTask)

            $null = Register-ScheduledTask @registerArguments
        }
    }

    if ($Ensure -eq 'Absent')
    {
        Write-Verbose -Message ($script:localizedData.RemoveScheduledTaskMessage -f $TaskName, $TaskPath)

        Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false -ErrorAction Stop
    }
}

<#
    .SYNOPSIS
        Tests if the current resource state matches the desired resource state.

    .PARAMETER TaskName
        The name of the task.

    .PARAMETER TaskPath
        The path to the task - defaults to the root directory.

    .PARAMETER Description
        The task description.

    .PARAMETER ActionExecutable
        The path to the .exe for this task.

    .PARAMETER ActionArguments
        The arguments to pass the executable.

    .PARAMETER ActionWorkingPath
        The working path to specify for the executable.

    .PARAMETER ScheduleType
        When should the task be executed.

    .PARAMETER RepeatInterval
        How many units (minutes, hours, days) between each run of this task?

    .PARAMETER StartTime
        The date and time of day this task should start at, or activate on, represented
        as a string for local conversion to DateTime format - defaults to 1st January 1980 at 12:00 AM.

    .PARAMETER SynchronizeAcrossTimeZone
        Enable the scheduled task option to synchronize across time zones. This is enabled
        by including the timezone offset in the scheduled task trigger. Defaults to false
        which does not include the timezone offset.

    .PARAMETER Ensure
        Present if the task should exist, Absent if it should be removed.

    .PARAMETER Enable
        True if the task should be enabled, false if it should be disabled.

    .PARAMETER BuiltInAccount
        Run the task as one of the built in service accounts.
        When set ExecuteAsCredential will be ignored and LogonType will be set to 'ServiceAccount'.

    .PARAMETER ExecuteAsCredential
        The credential this task should execute as. If not specified defaults to running
        as the local system account. Cannot be used in combination with ExecuteAsGMSA.

    .PARAMETER ExecuteAsGMSA
        The gMSA (Group Managed Service Account) this task should execute as. Cannot be
        used in combination with ExecuteAsCredential.

    .PARAMETER DaysInterval
        Specifies the interval between the days in the schedule. An interval of 1 produces
        a daily schedule. An interval of 2 produces an every-other day schedule. This
        parameter is only valid in combination with the Daily Schedule Type.

    .PARAMETER RandomDelay
        Specifies a random amount of time to delay the start time of the trigger. The
        delay time is a random time between the time the task triggers and the time that
        you specify in this setting. This parameter is only valid in combination with the
        Once, Daily and Weekly Schedule Types.

    .PARAMETER RepetitionDuration
        Specifies how long the repetition pattern repeats after the task starts.

    .PARAMETER StopAtDurationEnd
        Indicates that Task Scheduler stops all running tasks at the end of the repetition
        duration. Defaults to $false.

    .PARAMETER TriggerExecutionTimeLimit
        Specifies the amount of time for the trigger that Task Scheduler is allowed to complete the task.

    .PARAMETER DaysOfWeek
        Specifies an array of the days of the week on which Task Scheduler runs the task. This
        parameter is only valid in combination with the Weekly Schedule Type.

    .PARAMETER WeeksInterval
        Specifies the interval between the weeks in the schedule. An interval of 1 produces
        a weekly schedule. An interval of 2 produces an every-other week schedule. This
        parameter is only valid in combination with the Weekly Schedule Type.

    .PARAMETER User
        Specifies the identifier of a user that will trigger the task to start. This
        parameter is only valid in combination with the AtLogon and OnSessionState Schedule Types.

    .PARAMETER DisallowDemandStart
        Indicates whether the task is prohibited to run on demand or not. Defaults
        to $false.

    .PARAMETER DisallowHardTerminate
        Indicates whether the task is prohibited to be terminated or not. Defaults
        to $false.

    .PARAMETER Compatibility
        The task compatibility level. Defaults to Vista.

    .PARAMETER AllowStartIfOnBatteries
        Indicates whether the task should start if the machine is on batteries or not.
        Defaults to $false.

    .PARAMETER Hidden
        Indicates that the task is hidden in the Task Scheduler UI.

    .PARAMETER RunOnlyIfIdle
        Indicates that Task Scheduler runs the task only when the computer is idle.

    .PARAMETER IdleWaitTimeout
        Specifies the amount of time that Task Scheduler waits for an idle condition to occur.

    .PARAMETER NetworkName
        Specifies the name of a network profile that Task Scheduler uses to determine
        if the task can run.
        The Task Scheduler UI uses this setting for display purposes. Specify a network
        name if you specify the RunOnlyIfNetworkAvailable parameter.

    .PARAMETER DisallowStartOnRemoteAppSession
        Indicates that the task does not start if the task is triggered to run in a Remote
        Applications Integrated Locally (RAIL) session.

    .PARAMETER StartWhenAvailable
        Indicates that Task Scheduler can start the task at any time after its scheduled
        time has passed.

    .PARAMETER DontStopIfGoingOnBatteries
        Indicates that the task does not stop if the computer switches to battery power.

    .PARAMETER WakeToRun
        Indicates that Task Scheduler wakes the computer before it runs the task.

    .PARAMETER IdleDuration
        Specifies the amount of time that the computer must be in an idle state before
        Task Scheduler runs the task.

    .PARAMETER RestartOnIdle
        Indicates that Task Scheduler restarts the task when the computer cycles into an
        idle condition more than once.

    .PARAMETER DontStopOnIdleEnd
        Indicates that Task Scheduler does not terminate the task if the idle condition
        ends before the task is completed.

    .PARAMETER ExecutionTimeLimit
        Specifies the amount of time that Task Scheduler is allowed to complete the task.

    .PARAMETER MultipleInstances
        Specifies the policy that defines how Task Scheduler handles multiple instances
        of the task.

    .PARAMETER Priority
        Specifies the priority level of the task. Priority must be an integer from 0 (highest priority)
        to 10 (lowest priority). The default value is 7. Priority levels 7 and 8 are
        used for background tasks. Priority levels 4, 5, and 6 are used for interactive tasks.

    .PARAMETER RestartCount
        Specifies the number of times that Task Scheduler attempts to restart the task.

    .PARAMETER RestartInterval
        Specifies the amount of time that Task Scheduler attempts to restart the task.

    .PARAMETER RunOnlyIfNetworkAvailable
        Indicates that Task Scheduler runs the task only when a network is available. Task
        Scheduler uses the NetworkID parameter and NetworkName parameter that you specify
        in this cmdlet to determine if the network is available.

    .PARAMETER RunLevel
        Specifies the level of user rights that Task Scheduler uses to run the tasks that
        are associated with the principal. Defaults to 'Limited'.

    .PARAMETER LogonType
        Specifies the security logon method that Task Scheduler uses to run the tasks that
        are associated with the principal.

    .PARAMETER EventSubscription
        The event subscription in a string that can be parsed as valid XML. This parameter is only
        valid in combination with the OnEvent Schedule Type. For the query schema please check:
        https://docs.microsoft.com/en-us/windows/desktop/WES/queryschema-schema

    .PARAMETER EventValueQueries
        Specifies event value queries. This parameter is only valid in combination with the OnEvent
        Schedule Type. Receives a hashtable where the key is a property value for an event and
        the value is an XPath event query. For more detailed syntax check:
        https://learn.microsoft.com/en-us/windows/win32/taskschd/eventtrigger-valuequeries.

    .PARAMETER Delay
        Specifies a delay to the start of the trigger. This parameter is only valid in combination
        with the AtLogon, AtStartup, OnEvent, AtCreation and OnSessionState Schedule Types.

    .PARAMETER StateChange
        The kind of session state change that would trigger a task launch. This parameter is
        only valid in combination with the OnSessionState Schedule Type.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskName,

        [Parameter()]
        [System.String]
        $TaskPath = '\',

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $ActionExecutable,

        [Parameter()]
        [System.String]
        $ActionArguments,

        [Parameter()]
        [System.String]
        $ActionWorkingPath,

        [Parameter()]
        [System.String]
        [ValidateSet('Once', 'Daily', 'Weekly', 'AtStartup', 'AtLogon', 'OnIdle', 'OnEvent', 'AtCreation', 'OnSessionState')]
        $ScheduleType,

        [Parameter()]
        [System.String]
        $RepeatInterval = '00:00:00',

        [Parameter()]
        [System.String]
        $StartTime = '1980-01-01T00:00:00',

        [Parameter()]
        [System.Boolean]
        $SynchronizeAcrossTimeZone = $false,

        [Parameter()]
        [System.String]
        [ValidateSet('Present', 'Absent')]
        $Ensure = 'Present',

        [Parameter()]
        [System.Boolean]
        $Enable = $true,

        [Parameter()]
        [ValidateSet('SYSTEM', 'LOCAL SERVICE', 'NETWORK SERVICE')]
        [System.String]
        $BuiltInAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ExecuteAsCredential,

        [Parameter()]
        [System.String]
        $ExecuteAsGMSA,

        [Parameter()]
        [System.UInt32]
        $DaysInterval = 1,

        [Parameter()]
        [System.String]
        $RandomDelay = '00:00:00',

        [Parameter()]
        [System.String]
        $RepetitionDuration = '00:00:00',

        [Parameter()]
        [System.Boolean]
        $StopAtDurationEnd = $false,

        [Parameter()]
        [System.String]
        $TriggerExecutionTimeLimit = '00:00:00',

        [Parameter()]
        [System.String[]]
        $DaysOfWeek,

        [Parameter()]
        [System.UInt32]
        $WeeksInterval = 1,

        [Parameter()]
        [System.String]
        $User,

        [Parameter()]
        [System.Boolean]
        $DisallowDemandStart = $false,

        [Parameter()]
        [System.Boolean]
        $DisallowHardTerminate = $false,

        [Parameter()]
        [ValidateSet('AT', 'V1', 'Vista', 'Win7', 'Win8')]
        [System.String]
        $Compatibility = 'Vista',

        [Parameter()]
        [System.Boolean]
        $AllowStartIfOnBatteries = $false,

        [Parameter()]
        [System.Boolean]
        $Hidden = $false,

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfIdle = $false,

        [Parameter()]
        [System.String]
        $IdleWaitTimeout = '02:00:00',

        [Parameter()]
        [System.String]
        $NetworkName,

        [Parameter()]
        [System.Boolean]
        $DisallowStartOnRemoteAppSession = $false,

        [Parameter()]
        [System.Boolean]
        $StartWhenAvailable = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopIfGoingOnBatteries = $false,

        [Parameter()]
        [System.Boolean]
        $WakeToRun = $false,

        [Parameter()]
        [System.String]
        $IdleDuration = '01:00:00',

        [Parameter()]
        [System.Boolean]
        $RestartOnIdle = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopOnIdleEnd = $false,

        [Parameter()]
        [System.String]
        $ExecutionTimeLimit = '08:00:00',

        [Parameter()]
        [ValidateSet('IgnoreNew', 'Parallel', 'Queue', 'StopExisting')]
        [System.String]
        $MultipleInstances = 'Queue',

        [Parameter()]
        [System.UInt32]
        $Priority = 7,

        [Parameter()]
        [System.UInt32]
        $RestartCount = 0,

        [Parameter()]
        [System.String]
        $RestartInterval = '00:00:00',

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfNetworkAvailable = $false,

        [Parameter()]
        [ValidateSet('Limited', 'Highest')]
        [System.String]
        $RunLevel = 'Limited',

        [Parameter()]
        [ValidateSet('Group', 'Interactive', 'InteractiveOrPassword', 'None', 'Password', 'S4U', 'ServiceAccount')]
        [System.String]
        $LogonType,

        [Parameter()]
        [System.String]
        $EventSubscription,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $EventValueQueries,

        [Parameter()]
        [System.String]
        $Delay = '00:00:00',

        [Parameter()]
        [System.String]
        [ValidateSet('OnConnectionFromLocalComputer', 'OnDisconnectFromLocalComputer', 'OnConnectionFromRemoteComputer', 'OnDisconnectFromRemoteComputer', 'OnWorkstationLock', 'OnWorkstationUnlock')]
        $StateChange
    )

    $TaskPath = ConvertTo-NormalizedTaskPath -TaskPath $TaskPath

    Write-Verbose -Message ($script:localizedData.TestScheduledTaskMessage -f $TaskName, $TaskPath)

    $currentValues = Get-CurrentResource -TaskName $TaskName -TaskPath $TaskPath

    # Convert the strings containing dates & times to DateTime objects
    if ($PSBoundParameters.ContainsKey('StartTime'))
    {
        $PSBoundParameters['StartTime'] = [System.DateTime]::Parse($StartTime)
    }

    # Convert the strings containing time spans to TimeSpan Objects
    if ($PSBoundParameters.ContainsKey('RepeatInterval'))
    {
        $PSBoundParameters['RepeatInterval'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RepeatInterval).ToString()
    }

    if ($PSBoundParameters.ContainsKey('RandomDelay'))
    {
        if ($ScheduleType -notin @('Once', 'Daily', 'Weekly'))
        {
            # A random delay is only supported when the ScheduleType is set to Once, Daily or Weekly.
            Write-Verbose -Message ($script:localizedData.IgnoreRandomDelayWithUnsupportedTriggerType -f $TaskName)
            $null = $PSBoundParameters.Remove('RandomDelay')
        }
        else
        {
            $PSBoundParameters['RandomDelay'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RandomDelay).ToString()
        }
    }

    if ($PSBoundParameters.ContainsKey('RepetitionDuration'))
    {
        $RepetitionDuration = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RepetitionDuration -AllowIndefinitely
        if ($RepetitionDuration -eq [System.TimeSpan]::MaxValue)
        {
            $PSBoundParameters['RepetitionDuration'] = 'Indefinitely'
        }
        else
        {
            $PSBoundParameters['RepetitionDuration'] = $RepetitionDuration.ToString()
        }
    }

    if ($PSBoundParameters.ContainsKey('TriggerExecutionTimeLimit'))
    {
        $PSBoundParameters['TriggerExecutionTimeLimit'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $TriggerExecutionTimeLimit).ToString()
    }

    if ($PSBoundParameters.ContainsKey('IdleWaitTimeout'))
    {
        $PSBoundParameters['IdleWaitTimeout'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $IdleWaitTimeout).ToString()
    }

    if ($PSBoundParameters.ContainsKey('IdleDuration'))
    {
        $PSBoundParameters['IdleDuration'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $IdleDuration).ToString()
    }

    if ($PSBoundParameters.ContainsKey('ExecutionTimeLimit'))
    {
        $PSBoundParameters['ExecutionTimeLimit'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $ExecutionTimeLimit).ToString()
    }

    if ($PSBoundParameters.ContainsKey('RestartInterval'))
    {
        $PSBoundParameters['RestartInterval'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RestartInterval).ToString()
    }

    if ($PSBoundParameters.ContainsKey('Delay'))
    {
        if ($ScheduleType -notin @('AtLogon', 'AtStartup', 'OnEvent', 'AtCreation', 'OnSessionState'))
        {
            # A delay is only supported on the AtLogon, AtStartup, OnEvent, AtCreation and OnSessionState trigger types
            Write-Verbose -Message ($script:localizedData.IgnoreDelayWithUnsupportedTriggerType -f $TaskName)
            $null = $PSBoundParameters.Remove('Delay')
        }
        else
        {
            $PSBoundParameters['Delay'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $Delay).ToString()
        }
    }

    if ($PSBoundParameters.ContainsKey('StartTime'))
    {
        $PSBoundParameters['StartTime'] = Get-DateTimeString -Date $StartTime -SynchronizeAcrossTimeZone $SynchronizeAcrossTimeZone
        <#
            If the current StartTime is null then we need to set it to
            the desired StartTime (which defaults to 1st January 1980 at 12:00 AM if not passed)
            so that the test does not fail.
        #>
        if ($currentValues['StartTime'])
        {
            $currentValues['StartTime'] = Get-DateTimeString `
                -Date $currentValues['StartTime'] `
                -SynchronizeAcrossTimeZone $currentValues['SynchronizeAcrossTimeZone']
        }
        else
        {
            $currentValues['StartTime'] = Get-DateTimeString `
                -Date $StartTime `
                -SynchronizeAcrossTimeZone $SynchronizeAcrossTimeZone
        }
    }
    else
    {
        $null = $PSBoundParameters.Remove('StartTime')
        $null = $currentValues.Remove('StartTime')
    }

    if ($Ensure -eq 'Absent' -and $currentValues.Ensure -eq 'Absent')
    {
        return $true
    }

    if ($null -eq $currentValues)
    {
        Write-Verbose -Message ($script:localizedData.CurrentTaskValuesNullMessage)

        return $false
    }

    if ($PSBoundParameters.ContainsKey('BuiltInAccount'))
    {
        $PSBoundParameters.ExecuteAsCredential = $BuiltInAccount
        $currentValues.ExecuteAsCredential = $BuiltInAccount

        $PSBoundParameters['LogonType'] = 'ServiceAccount'
        $currentValues['LogonType'] = 'ServiceAccount'

        $PSBoundParameters['BuiltInAccount'] = $BuiltInAccount
    }
    elseif ($PSBoundParameters.ContainsKey('ExecuteAsCredential'))
    {
        # The password of the execution credential can not be compared
        $username = $ExecuteAsCredential.UserName
        $PSBoundParameters['ExecuteAsCredential'] = $username

        <#
            Windows Server 2019 and newer versions of Windows 10 don't return fully qualified
            username in the current ExecuteAsCredential if it is the local machine. Therefore
            the compare will fail and show a false positive (see Issue #350).

            To resolve this, add the computer name if it is missing and if it was passed in the
            ExecuteAsCredential parameter.
        #>
        if ($username -match "$ENV:COMPUTERNAME\\" -and $currentValues.ExecuteAsCredential)
        {
            $currentValues.ExecuteAsCredential = Set-DomainNameInAccountName `
                -AccountName $currentValues.ExecuteAsCredential `
                -DomainName $ENV:COMPUTERNAME
        }

        if ($username -match "$ENV:USERDOMAIN\\" -and $currentValues.ExecuteAsCredential)
        {
            $currentValues.ExecuteAsCredential = Set-DomainNameInAccountName `
                -AccountName $currentValues.ExecuteAsCredential `
                -DomainName $ENV:USERDOMAIN
        }
    }
    else
    {
        $PSBoundParameters.ExecuteAsCredential = 'SYSTEM'
        $currentValues.ExecuteAsCredential = 'SYSTEM'

        $PSBoundParameters.Add('BuiltInAccount', $BuiltInAccount)
        $currentValues.BuiltInAccount = $BuiltInAccount

        # Must be running as System, login type is ServiceAccount
        $PSBoundParameters['LogonType'] = 'ServiceAccount'
        $currentValues['LogonType'] = 'ServiceAccount'
    }

    if ($PSBoundParameters.ContainsKey('WeeksInterval') `
        -and ((-not $currentValues.ContainsKey('WeeksInterval')) -or ($null -eq $currentValues['WeeksInterval'])))
    {
        <#
            The WeeksInterval parameter of this function defaults to 1,
            even though the value of the WeeksInterval property maybe
            unset/undefined in the object $currentValues returned from
            Get-TargetResource. To avoid Test-TargetResource returning false
            and generating spurious calls to Set-TargetResource, default
            an undefined $currentValues.WeeksInterval to the value of
            $WeeksInterval.
        #>
        $currentValues.WeeksInterval = $PSBoundParameters['WeeksInterval']
    }

    if ($PSBoundParameters.ContainsKey('ExecuteAsGMSA'))
    {
        <#
            There is a difference in W2012R2 and W2016 behaviour,
            W2012R2 returns the gMSA including the DOMAIN prefix,
            W2016 returns this without. So to be sure strip off the
            domain part in Get & Test. This means we either need to
            remove everything before \ in the case of the DOMAIN\User
            format, or we need to remove everything after @ in case
            when the UPN format (User@domain.fqdn) is used.
        #>
        $PSBoundParameters['ExecuteAsGMSA'] = $PSBoundParameters.ExecuteAsGMSA -replace '^.+\\|@.+', $null
    }

    if ($PSBoundParameters.ContainsKey('Description'))
    {
        <#
            All forms of whitespace is automatically trimmed from the description
            when it is set, so we must not compare it here. See issue #258:
            https://github.com/dsccommunity/ComputerManagementDsc/issues/258
        #>
        $PSBoundParameters['Description'] = $PSBoundParameters.Description.Trim()
    }

    $desiredValues = $PSBoundParameters
    $desiredValues.TaskPath = $TaskPath

    if ($desiredValues.ContainsKey('Verbose'))
    {
        <#
            Initialise a missing or null Verbose to avoid spurious
            calls to Set-TargetResource
        #>
        $currentValues.Add('Verbose', $desiredValues['Verbose'])
    }

    Write-Verbose -Message ($script:localizedData.TestingDscParameterStateMessage)

    return Test-DscParameterState `
        -CurrentValues $currentValues `
        -DesiredValues $desiredValues `
        -SortArrayValues `
        -Verbose:$VerbosePreference
}

<#
    .SYNOPSIS
        Helper function to convert TaskPath to the right form

    .PARAMETER TaskPath
        The path to the task
#>
function ConvertTo-NormalizedTaskPath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskPath
    )

    $pathArray = $TaskPath.Split('\').Where( {$_})
    if ($pathArray.Count -gt 0)
    {
        $TaskPath = "\$($pathArray -join '\')\"
    }

    return $TaskPath
}

<#
    .SYNOPSIS
        Helper function convert a standard timespan string
        into a TimeSpan object. It can support returning the
        maximum timespan if the AllowIndefinitely switch is set
        and the timespan is set to 'indefinte'.

    .PARAMETER TimeSpan
        The standard timespan string to convert to a TimeSpan
        object.

    .PARAMETER AllowIndefinitely
        Allow the keyword 'Indefinitely' to be translated into
        the maximum valid timespan.
#>
function ConvertTo-TimeSpanFromTimeSpanString
{
    [CmdletBinding()]
    [OutputType([System.TimeSpan])]
    param
    (
        [Parameter()]
        [System.String]
        $TimeSpanString = '00:00:00',

        [Parameter()]
        [Switch]
        $AllowIndefinitely
    )

    if ($AllowIndefinitely -eq $True -and $TimeSpanString -eq 'Indefinitely')
    {
        return [System.TimeSpan]::MaxValue
    }

    return [System.TimeSpan]::Parse($TimeSpanString)
}

<#
    .SYNOPSIS
        Helper function convert a task schedule timespan string
        into a TimeSpan string. If AllowIndefinitely is set to
        true and the TimeSpan string is empty then return
        'Indefinitely'.

    .PARAMETER TimeSpan
        The scheduled task timespan string to convert to a TimeSpan
        string.

    .PARAMETER AllowIndefinitely
        Allow an empty TimeSpan to return the keyword 'Indefinitely'.

#>
function ConvertTo-TimeSpanStringFromScheduledTaskString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $TimeSpan,

        [Parameter()]
        [Switch]
        $AllowIndefinitely
    )

    # If AllowIndefinitely is true and the timespan is empty then return Indefinitely
    if ($AllowIndefinitely -eq $true -and [System.String]::IsNullOrEmpty($TimeSpan))
    {
        return 'Indefinitely'
    }

    $days = $hours = $minutes = $seconds = 0

    if ($TimeSpan -match 'P(?<Days>\d{0,3})D')
    {
        $days = $matches.Days
    }

    if ($TimeSpan -match '(?<Hours>\d{0,2})H')
    {
        $hours = $matches.Hours
    }

    if ($TimeSpan -match '(?<Minutes>\d{0,2})M')
    {
        $minutes = $matches.Minutes
    }

    if ($TimeSpan -match '(?<Seconds>\d{0,2})S')
    {
        $seconds = $matches.Seconds
    }

    return (New-TimeSpan -Days $days -Hours $hours -Minutes $minutes -Seconds $seconds).ToString()
}

<#
    .SYNOPSIS
        Helper function to disable an existing scheduled task.

    .PARAMETER TaskName
        The name of the task to disable.

    .PARAMETER TaskPath
        The path to the task to disable.
#>
function Disable-ScheduledTaskEx
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskName,

        [Parameter()]
        [System.String]
        $TaskPath = '\'
    )

    $existingTask = ScheduledTasks\Get-ScheduledTask @PSBoundParameters
    $existingTask.Settings.Enabled = $false
    $null = $existingTask | Register-ScheduledTask @PSBoundParameters -Force
}

<#
    .SYNOPSIS
        Returns a formatted datetime string for use in ScheduledTask resource.

    .PARAMETER Date
        The date to format.

    .PARAMETER SynchronizeAcrossTimeZone
        Boolean to specify if the returned string is formatted in synchronize
        across time zone format.
#>
function Get-DateTimeString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.DateTime]
        $Date,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $SynchronizeAcrossTimeZone
    )

    if ($SynchronizeAcrossTimeZone)
    {
        $format = (Get-Culture).DateTimeFormat.SortableDateTimePattern + 'zzz'
        $returnDate = Get-Date -Date $Date.ToLocalTime() -Format $format
    }
    else
    {
        $format = (Get-Culture).DateTimeFormat.SortableDateTimePattern
        $returnDate = Get-Date -Date $Date -Format $format
    }

    return $returnDate
}

<#
    .SYNOPSIS
        Returns the current values of the resource.

    .PARAMETER TaskName
        The name of the task.

    .PARAMETER TaskPath
        The path to the task - defaults to the root directory.
#>
function Get-CurrentResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskName,

        [Parameter()]
        [System.String]
        $TaskPath = '\'
    )

    $TaskPath = ConvertTo-NormalizedTaskPath -TaskPath $TaskPath

    Write-Verbose -Message ($script:localizedData.GettingCurrentTaskValuesMessage -f $TaskName, $TaskPath)

    $task = ScheduledTasks\Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue

    if ($null -eq $task)
    {
        Write-Verbose -Message ($script:localizedData.TaskNotFoundMessage -f $TaskName, $TaskPath)

        $result = @{
            TaskName = $TaskName
            TaskPath = $TaskPath
            Ensure   = 'Absent'
        }
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.TaskFoundMessage -f $TaskName, $TaskPath)

        $action = $task.Actions | Select-Object -First 1
        $trigger = $task.Triggers | Select-Object -First 1
        $settings = $task.Settings
        $returnScheduleType = 'Unknown'

        switch ($trigger.CimClass.CimClassName)
        {
            'MSFT_TaskTimeTrigger'
            {
                $returnScheduleType = 'Once'
                break
            }

            'MSFT_TaskDailyTrigger'
            {
                $returnScheduleType = 'Daily'
                break
            }

            'MSFT_TaskWeeklyTrigger'
            {
                $returnScheduleType = 'Weekly'
                break
            }

            'MSFT_TaskBootTrigger'
            {
                $returnScheduleType = 'AtStartup'
                break
            }

            'MSFT_TaskLogonTrigger'
            {
                $returnScheduleType = 'AtLogon'
                break
            }

            'MSFT_TaskIdleTrigger'
            {
                $returnScheduleType = 'OnIdle'
                break
            }

            'MSFT_TaskEventTrigger'
            {
                $returnScheduleType = 'OnEvent'
                break
            }

            'MSFT_TaskRegistrationTrigger'
            {
                $returnScheduleType = 'AtCreation'
                break
            }

            'MSFT_TaskSessionStateChangeTrigger'
            {
                $returnScheduleType = 'OnSessionState'
                break
            }

            default
            {
                $returnScheduleType = ''
                Write-Verbose -Message ($script:localizedData.TriggerTypeUnknown -f $trigger.CimClass.CimClassName)
            }
        }

        Write-Verbose -Message ($script:localizedData.DetectedScheduleTypeMessage -f $returnScheduleType)

        $daysOfWeek = @()

        foreach ($binaryAdductor in 1, 2, 4, 8, 16, 32, 64)
        {
            $day = $trigger.DaysOfWeek -band $binaryAdductor

            if ($day -ne 0)
            {
                $daysOfWeek += [System.String][ScheduledTask.DaysOfWeek] $day
            }
        }

        $startAt = $trigger.StartBoundary

        if ($startAt)
        {
            $synchronizeAcrossTimeZone = Test-DateStringContainsTimeZone -DateString $startAt
            $startTime = $startAt
        }
        else
        {
            $startTime = $null
            $synchronizeAcrossTimeZone = $false
        }

        if ($task.Principal.LogonType -ieq 'Group')
        {
            $PrincipalId = 'GroupId'
        }
        else
        {
            $PrincipalId = 'UserId'
        }

        <#  The following workaround is needed because Get-StartedTask currently returns NULL for the value
            of $settings.MultipleInstances when the started task is set to "Stop the existing instance".
            https://windowsserver.uservoice.com/forums/301869-powershell/suggestions/40685125-bug-get-scheduledtask-returns-null-for-value-of-m
        #>
        $MultipleInstances = [System.String] $settings.MultipleInstances

        if ([System.String]::IsNullOrEmpty($MultipleInstances))
        {
            if ($task.settings.CimInstanceProperties.Item('MultipleInstances').Value -eq 3)
            {
                $MultipleInstances = 'StopExisting'
            }
        }

        $result = @{
            TaskName                        = $task.TaskName
            TaskPath                        = $task.TaskPath
            StartTime                       = $startTime
            SynchronizeAcrossTimeZone       = $synchronizeAcrossTimeZone
            Ensure                          = 'Present'
            Description                     = $task.Description
            ActionExecutable                = $action.Execute
            ActionArguments                 = $action.Arguments
            ActionWorkingPath               = $action.WorkingDirectory
            ScheduleType                    = $returnScheduleType
            RepeatInterval                  = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $trigger.Repetition.Interval
            ExecuteAsCredential             = $task.Principal.$PrincipalId
            ExecuteAsGMSA                   = $task.Principal.UserId -replace '^.+\\|@.+', $null
            Enable                          = $settings.Enabled
            DaysInterval                    = [System.Uint32] $trigger.DaysInterval
            RandomDelay                     = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $trigger.RandomDelay
            RepetitionDuration              = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $trigger.Repetition.Duration -AllowIndefinitely
            StopAtDurationEnd               = $trigger.Repetition.StopAtDurationEnd
            TriggerExecutionTimeLimit       = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $trigger.ExecutionTimeLimit
            DaysOfWeek                      = [System.String[]] $daysOfWeek
            WeeksInterval                   = [System.Uint32] $trigger.WeeksInterval
            User                            = $trigger.UserId
            DisallowDemandStart             = -not $settings.AllowDemandStart
            DisallowHardTerminate           = -not $settings.AllowHardTerminate
            Compatibility                   = [System.String] $settings.Compatibility
            AllowStartIfOnBatteries         = -not $settings.DisallowStartIfOnBatteries
            Hidden                          = $settings.Hidden
            RunOnlyIfIdle                   = $settings.RunOnlyIfIdle
            IdleWaitTimeout                 = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $settings.IdleSettings.WaitTimeout
            NetworkName                     = $settings.NetworkSettings.Name
            DisallowStartOnRemoteAppSession = $settings.DisallowStartOnRemoteAppSession
            StartWhenAvailable              = $settings.StartWhenAvailable
            DontStopIfGoingOnBatteries      = -not $settings.StopIfGoingOnBatteries
            WakeToRun                       = $settings.WakeToRun
            IdleDuration                    = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $settings.IdleSettings.IdleDuration
            RestartOnIdle                   = $settings.IdleSettings.RestartOnIdle
            DontStopOnIdleEnd               = -not $settings.IdleSettings.StopOnIdleEnd
            ExecutionTimeLimit              = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $settings.ExecutionTimeLimit
            MultipleInstances               = $MultipleInstances
            Priority                        = $settings.Priority
            RestartCount                    = $settings.RestartCount
            RestartInterval                 = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $settings.RestartInterval
            RunOnlyIfNetworkAvailable       = $settings.RunOnlyIfNetworkAvailable
            RunLevel                        = [System.String] $task.Principal.RunLevel
            LogonType                       = [System.String] $task.Principal.LogonType
            EventSubscription               = $trigger.Subscription
            EventValueQueries               = ConvertTo-HashtableFromTaskNamedValuePairCollection -Array $trigger.ValueQueries
            Delay                           = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $trigger.Delay
            StateChange                     = [System.String][ScheduledTask.StateChange][System.UInt32] $trigger.StateChange # Cast to integer first to allow casting to enum with null
        }

        if (
            (($result.ContainsKey('LogonType')) -and ($result['LogonType'] -ieq 'ServiceAccount')) -or
            $result.Principal.UserID -in @('SYSTEM', 'LOCAL SERVICE', 'NETWORK SERVICE')
            )
        {
            $builtInAccount = $task.Principal.UserId
            $result.Add('BuiltInAccount', $builtInAccount)
        }
    }

    Write-Verbose -Message ($script:localizedData.CurrentTaskValuesRetrievedMessage -f $TaskName, $TaskPath)

    return $result
}

<#
    .SYNOPSIS
        Converts CimInstance array of type MSFT_TaskNamedValue to hashtable

    .PARAMETER Array
        The array of MSFT_TaskNamedValue to convert to a hashtable.
#>
function ConvertTo-HashtableFromTaskNamedValuePairCollection
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Array
    )

    $hashtable = @{}

    foreach ($item in $Array)
    {
        $hashtable += @{
            $item.Name = $item.Value
        }
    }

    return $hashtable
}

<#
    .SYNOPSIS
        Converts CimInstance array of type MSFT_KeyValuePair to array of type MSFT_TaskNamedValue

    .PARAMETER Array
        The array of MSFT_KeyValuePair to convert to an array of type MSFT_TaskNamedValue.
#>
function ConvertTo-TaskNamedValuePairCollectionFromKeyValuePairArray
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance[]])]
    param
    (
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Array
    )

    $cimNamedValueClass = Get-CimClass -ClassName MSFT_TaskNamedValue -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskNamedValue

    $namedValueArray = [Microsoft.Management.Infrastructure.CimInstance[]]@()

    foreach ($item in $Array)
    {
        $namedValue = New-CimInstance -CimClass $cimNamedValueClass `
            -Property @{
                Name = $item.key
                Value = $item.Value
            } `
            -ClientOnly
        $namedValueArray += $namedValue
    }

    return $namedValueArray
}

<#
    .SYNOPSIS
        Test if a date string contains a time zone.

    .DESCRIPTION
        This function returns true if the string contains a time
        zone appended to it. This is used to determine if the
        SynchronizeAcrossTimeZone parameter has been set in a
        trigger.

    .PARAMETER DateString
        The date string to test.
#>
function Test-DateStringContainsTimeZone
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DateString
    )

    # When parsing a DateTime, Kind will be 'Unspecified' unless parsed string includes time zone information
    # See https://learn.microsoft.com/en-us/dotnet/api/system.datetime.parse?view=netframework-4.5#the-return-value-and-datetimekind
    return [DateTime]::Parse($DateString).Kind -ne 'Unspecified'
}

<#
    .SYNOPSIS
        Set domain name in a down-level user or group name.

    .DESCRIPTION
        Set the domain name in a down-level user or group name.

    .PARAMETER AccountName
        The user or group name to set the domain name in.

    .PARAMETER DomainName
        If the AccountName does not contain a domain name them prefix
        it with this value. If the AccountName already contains a domain
        name then it will only be updated if the Force switch is set.

    .PARAMETER Force
        If the identity already contains a domain prefix then force
        it to the value in Domain.

    .EXAMPLE
        Set-DomainNameInAccountName -AccountName 'Users' -DomainName 'NT AUTHORITY'

        Returns 'NT AUTHORITY\Users'.

    .EXAMPLE
        Set-DomainNameInAccountName -AccountName 'MyDomain\Users' -DomainName 'NT AUTHORITY'

        Returns 'MyDomain\Users'.

    .EXAMPLE
        Set-DomainNameInAccountName -AccountName 'MyDomain\Users' -DomainName 'NT AUTHORITY' -Force

        Returns 'NT AUTHORITY\Users'.
#>
function Set-DomainNameInAccountName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $AccountName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DomainName,

        [Parameter()]
        [Switch]
        $Force
    )

    if ($AccountName.Contains('\'))
    {
        $existingDomainName, $name = ($AccountName -Split '\\')

        if (-not [System.String]::IsNullOrEmpty($existingDomainName) -and -not $force.IsPresent)
        {
            # Keep the existing domain name if it is set and force is not specified
            $DomainName = $existingDomainName
        }
    }
    else
    {
        $name = $AccountName
    }

    return "$DomainName\$name"
}
