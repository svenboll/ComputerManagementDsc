<#PSScriptInfo
.VERSION 1.0.0
.GUID 282cba27-4cf3-43b8-86f2-f6ef0f8b4489
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ComputerManagementDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/ComputerManagementDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        This example creates a scheduled task called 'Test task Logon' in the folder
        task folder 'MyTasks' that starts a new powershell process when the specific
        user 'Domain\UserName' logs on, activating at 2018-10-01 01:00 and repeating every
        15 minutes for 8 hours. All running tasks will be stopped at the end of the
        repetition duration. The initial task trigger will be delayed for 15 minutes.
#>
Configuration ScheduledTask_CreateScheduledTasksAtLogon_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask ScheduledTaskLogonAdd
        {
            TaskName           = 'Test task Logon'
            TaskPath           = '\MyTasks'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtLogon'
            StartTime          = '2018-10-01T01:00:00'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            User               = 'Domain\UserName'
            Delay              = '00:15:00'
        }
    }
}
