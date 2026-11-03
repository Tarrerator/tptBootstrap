# Remove-tptSuite.ps1 - Desinstala componentes de la suite tpt

<#
.SYNOPSIS
    Desinstala componentes de la suite tpt.

.DESCRIPTION
    Elimina los módulos tpt seleccionados de la galería de módulos de PowerShell.
    NO elimina dependencias externas (psql, sqlplus) por seguridad.

.PARAMETER Component
    Qué módulos desinstalar. Valores permitidos: 'all', 'tptVMware', 'tptAD', 'tptCentreon', 'tptGLPI', 'tptOracleDB', 'tptPostgreDB'.

.EXAMPLE
    Remove-tptSuite -Component all
    Desinstala todos los componentes de la suite tpt.

.EXAMPLE
    Remove-tptSuite -Component tptVMware
    Solo desinstala el módulo tptVMware.

.NOTES
    Archivo: Remove-tptSuite.ps1
    Autor: TPT Suite
    Versión: 0.0.1
    Requisitos: PowerShell 5.1+
#>

function Remove-tptSuite {

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
[OutputType([PSCustomObject])]

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('all', 'tptVMware', 'tptAD', 'tptCentreon', 'tptGLPI', 'tptOracleDB', 'tptPostgreDB')]
    [string[]]$Component = @('all')
)

try {
    Write-Verbose "Iniciando la desinstalación de componentes de tptBootstrap v0.0.1"
    Write-Verbose "Componentes a desinstalar: $($Component -join ', ')"

    $componentsToRemove = if ($Component -contains 'all') {
        @('tptVMware', 'tptAD', 'tptCentreon', 'tptGLPI', 'tptOracleDB', 'tptPostgreDB')
    } else {
        $Component
    }

    $results = @()

    foreach ($comp in $componentsToRemove) {
        Write-Verbose "Procesando componente: $comp" -ForegroundColor Cyan

        $moduleInfo = Get-Module -ListAvailable $comp -ErrorAction SilentlyContinue
        if (-not $moduleInfo) {
            Write-Verbose "El módulo $comp no está instalado. Saltando..." -ForegroundColor Yellow
            $results += [PSCustomObject]@{ Component = $comp; Status = 'not_installed'; Version = $null }
            continue
        }

        $version = $moduleInfo.Version

        if ($PSCmdlet.ShouldProcess($comp, "Desinstalar módulo tpt $comp (versión $version)")) {
            try {
                Uninstall-Module -Name $comp -AllVersions -Force -ErrorAction Stop
                Write-Verbose "Desinstalado $comp versión $version" -ForegroundColor Green
                $results += [PSCustomObject]@{ Component = $comp; Status = 'removed'; Version = $version }
            } catch {
                Write-Error "Error al desinstalar ${comp}: $($_.Exception.Message)"
                $results += [PSCustomObject]@{ Component = $comp; Status = 'failed'; Version = $version; Error = $_.Exception.Message }
            }
        }
    }

    Write-Verbose "`n=== Resumen de Desinstalación ===" -ForegroundColor White
    $results | Format-Table -AutoSize
    Write-Verbose "`nDesinstalación completada." -ForegroundColor Green

    $results
} catch {
    Write-Error "Error durante la desinstalación: $($_.Exception.Message)"
    throw
}
}
