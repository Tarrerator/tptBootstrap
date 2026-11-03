@{
    RootModule = 'tptBootstrap.psm1'
    ModuleVersion = '0.0.1'
    Author = 'TPT Suite'
    Description = 'Module to install and manage the tpt suite of PowerShell modules and their dependencies.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Install-tptSuite'
        'Get-tptSuiteStatus'
        'Remove-tptSuite'
    )
}
