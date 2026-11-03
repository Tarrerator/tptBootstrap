# Get-tptSuiteStatus.ps1 - Obtiene el estado de la suite tpt y sus dependencias

<#
.SYNOPSIS
    Obtiene el estado de los componentes de la suite tpt e indica la disponibilidad de dependencias externas.

.DESCRIPTION
    Verifica si cada módulo de la suite tpt está instalado y si las dependencias externas requeridas están disponibles.
    Proporciona un objeto PSCustomObject con información sobre el estado de cada componente.

.EXAMPLE
    Get-tptSuiteStatus
    Muestra el estado de todos los componentes de la suite tpt.

.NOTES
    Archivo: Get-tptSuiteStatus.ps1
    Autor: TPT Suite
    Versión: 0.0.1
    Requisitos: PowerShell 5.1+
#>
function Get-tptSuiteStatus {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param()

    try {
        $components = @('tptVMware', 'tptAD', 'tptCentreon', 'tptGLPI', 'tptOracleDB', 'tptPostgreDB')
        $results = @()

        foreach ($comp in $components) {
            $moduleInfo = Get-Module -ListAvailable $comp -ErrorAction SilentlyContinue
            $installed = [bool]$moduleInfo
            $version = if ($installed) { $moduleInfo.Version } else { $null }

            $dependencies = @()
            $dependenciesOk = $true

            switch ($comp) {
                'tptVMware' {
                    $depName = 'VMware.VimAutomation.Core'
                    $depInstalled = Get-Module -ListAvailable $depName -ErrorAction SilentlyContinue
                    $dependencies += @{ Name = $depName; Installed = [bool]$depInstalled }
                    $dependenciesOk = $dependenciesOk -and [bool]$depInstalled
                }

                'tptPostgreDB' {
                    $depName = 'psql'
                    $depInstalled = Get-Command $depName -ErrorAction SilentlyContinue
                    $dependencies += @{ Name = $depName; Installed = [bool]$depInstalled }
                    $dependenciesOk = $dependenciesOk -and [bool]$depInstalled
                }

                'tptOracleDB' {
                    $depName = 'sqlplus'
                    $depInstalled = Get-Command $depName -ErrorAction SilentlyContinue
                    $dependencies += @{ Name = $depName; Installed = [bool]$depInstalled }
                    $dependenciesOk = $dependenciesOk -and [bool]$depInstalled
                }

                'tptAD' {
                    $depName = 'ActiveDirectory'
                    $depInstalled = Get-Module -ListAvailable $depName -ErrorAction SilentlyContinue
                    $dependencies += @{ Name = $depName; Installed = [bool]$depInstalled }
                    $dependenciesOk = $dependenciesOk -and [bool]$depInstalled

                    if ($PSVersionTable.Platform -eq 'Win32' -or $PSVersionTable.Platform -eq 'Win64') {
                        if (-not $dependencies[0].Installed) {
                            $dependenciesOk = $false
                        }
                    } else {
                        $dependenciesOk = $false
                    }
                }

                default {
                    $dependencies += @{ Name = 'N/A'; Installed = $true }
                }
            }

            $results += [PSCustomObject]@{ Component = $comp; Installed = $installed; Version = $version; Dependencies = $dependencies; DependenciesOk = $dependenciesOk }
        }

        $results
    } catch {
        Write-Error "Error al obtener el estado de la suite tpt: $($_.Exception.Message)"
        throw
    }
}
