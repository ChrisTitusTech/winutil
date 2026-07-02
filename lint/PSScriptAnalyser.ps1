@{
    # Only diagnostic records of the specified severity will be generated.
    # Uncomment the following line if you only want Errors and Warnings but
    # not Information diagnostic records.
    # Severity = @('Error','Warning')

    # Analyze **only** the following rules. Use IncludeRules when you want
    # to invoke only a small subset of the default rules.
<#
    IncludeRules = @('PSAvoidDefaultValueSwitchParameter',
                     'PSMisleadingBacktick',
                     'PSMissingModuleManifestField',
                     'PSReservedCmdletChar',
                     'PSReservedParams',
                     'PSShouldProcess',
                     'PSUseApprovedVerbs',
                     'PSUseDeclaredVarsMoreThanAssignments')
#>
    # Do not analyze the following rules. Use ExcludeRules when you have
    # commented out the IncludeRules settings above and want to include all
    # the default rules except for those you exclude below.
    # Note: if a rule is in both IncludeRules and ExcludeRules, the rule
    # will be excluded.
    ExcludeRules = @(
        # WinUtil is a WPF utility script that intentionally logs progress to the host/transcript.
        'PSAvoidUsingWriteHost',

        # Public and XAML-wired function names are part of the existing WinUtil surface.
        'PSUseSingularNouns',
        'PSUseApprovedVerbs',

        # UI helpers and internal state helpers are not exposed as WhatIf-capable cmdlets.
        'PSUseShouldProcessForStateChangingFunctions',

        # Shared WPF/runspace state is intentionally stored in $sync/global state.
        'PSAvoidGlobalVars',

        # Source files are UTF-8 without BOM and are verified by parser tests.
        'PSUseBOMForUnicodeEncodedFile',

        # WPF dispatcher closures and Pester mocks intentionally keep callback-style parameters.
        'PSReviewUnusedParameter'
    )
}
