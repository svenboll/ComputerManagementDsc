ConvertFrom-StringData @'
    InvalidDesiredValuesError          = Property 'DesiredValues' in Test-DscParameterState must be either a Hashtable or CimInstance. Type detected was '{0}'.
    InvalidValuesToCheckError          = If 'DesiredValues' is a CimInstance then property 'ValuesToCheck' must contain a value.
    TestDscParameterCompareMessage     = Comparing values in property '{0}'.
    MatchPsCredentialUsernameMessage   = MATCH: PSCredential username match. Current state is '{0}' and desired state is '{1}'.
    NoMatchPsCredentialUsernameMessage = NOTMATCH: PSCredential username mismatch. Current state is '{0}' and desired state is '{1}'.
    NoMatchTypeMismatchMessage         = NOTMATCH: Type mismatch for property '{0}' Current state type is '{1}' and desired type is '{2}'.
    MatchValueMessage                  = MATCH: Value (type '{0}') for property '{1}' does match. Current state is '{2}' and desired state is '{3}'.
    NoMatchValueMessage                = NOTMATCH: Value (type '{0}') for property '{1}' does not match. Current state is '{2}' and desired state is '{3}'.
    NoMatchValueDifferentCountMessage  = NOTMATCH: Value (type '{0}') for property '{1}' does have a different count. Current state count is '{2}' and desired state count is '{3}'.
    NoMatchElementTypeMismatchMessage  = NOTMATCH: Type mismatch for property '{0}' Current state type of element [{1}] is '{2}' and desired type is '{3}'.
    NoMatchElementValueMismatchMessage = NOTMATCH: Value [{0}] (type '{1}') for property '{2}' does match. Current state is '{3}' and desired state is '{4}'.
    MatchElementValueMessage           = MATCH: Value [{0}] (type '{1}') for property '{2}' does match. Current state is '{3}' and desired state is '{4}'.
    TestDscParameterResultMessage      = Test-DscParameter result is '{0}'.
    CurrentTimeZoneMessage             = Current time zone is set to '{0}'
    GettingTimeZoneCimMessage          = Getting current time zone using {0}.
    SettingTimeZoneMessage             = Setting time zone to '{0}' using {1}.
    TimeZoneUpdatedMessage             = Time zone has been updated to '{0}'.
    AddingSetTimeZoneDotNetTypeMessage = Adding .NET Set time zone Type.
    UnableToGetPowerPlans              = Unable to get available power plans with powercfg.exe /l. Unexpected empty output from powercfg.exe.
'@
