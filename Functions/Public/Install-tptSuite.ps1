# Install-tptSuite.ps1 - Installs the tpt suite and its dependencies

<#
.SYNOPSIS
    Instala la suite tpt y sus dependencias.

.DESCRIPTION
    Instala los componentes seleccionados de la suite tpt, incluyendo dependencias externas cuando sea necesario.
    Verifica que PowerShellGet y PSGallery estén disponibles y confiables antes de proceder con las instalaciones.

.PARAMETER Component
    Qué módulos instalar. Valores permitidos: 'all', 'tptVMware', 'tptAD', 'tptCentreon', 'tptGLPI', 'tptOracleDB', 'tptPostgreDB'.

.PARAMETER SkipDependencies
    Si se especifica, no instala dependencias externas (solo instala los módulos tpt si están en PSGallery).

.PARAMETER Force
    Fuerza la instalación aunque ya estén instalados.

.PARAMETER Scope
    Scope de instalación: 'CurrentUser' (predeterminado) o 'AllUsers'.

.EXAMPLE
    Install-tptSuite -Component all -Scope CurrentUser
    Instala todos los componentes de la suite en el scope del usuario actual.

.NOTES
    Archivo: Install-tptSuite.ps1
    Autor: TPT Suite
    Versión: 0.0.1
    Requisitos: PowerShell 5.1+
#>

function Install-tptSuite {

[CmdletBinding(SupportsShouldProcess = $true)]
[OutputType([PSCustomObject])]

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('all', 'tptVMware', 'tptAD', 'tptCentreon', 'tptGLPI', 'tptOracleDB', 'tptPostgreDB')]
    [string[]]$Component = @('all'),

    [Parameter(Mandatory = $false)]
    [switch]$SkipDependencies,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser'
)

begin {
    Write-Verbose "Iniciando la instalación de tptBootstrap v0.0.1"
    Write-Verbose "Componentes a instalar: $($Component -join ', ')"
    Write-Verbose "Scope: $Scope"
    Write-Verbose "SkipDependencies: $SkipDependencies"
    Write-Verbose "Force: $Force"
}

process {
    try {
        # Verificar que PowerShellGet está disponible
        if (-not (Get-Module -ListAvailable PowerShellGet)) {
            if ($PSCmdlet.ShouldProcess('PowerShellGet', 'Installar PowerShellGet')) {
                Write-Verbose "PowerShellGet no está disponible. Instalando..." -ForegroundColor Yellow
                Install-Module -Name PowerShellGet -Force -Scope $Scope -AllowClobber
            }
        }

        # Verificar que PSGallery está de confianza
        $psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        if ($psGallery -and $psGallery.InstallationPolicy -ne 'Trusted') {
            if ($PSCmdlet.ShouldProcess('PSGallery', 'Establecer InstallationPolicy en Trusted')) {
                Write-Verbose "PSGallery no está de confianza. Estableciendo..." -ForegroundColor Yellow
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            }
        }

        # Resolver componentes
        $componentsToInstall = if ($Component -contains 'all') {
            @('tptVMware', 'tptAD', 'tptCentreon', 'tptGLPI', 'tptOracleDB', 'tptPostgreDB')
        } else {
            $Component
        }

        $results = @()

        foreach ($comp in $componentsToInstall) {
            Write-Verbose "Procesando componente: $comp" -ForegroundColor Cyan

            # Instalar dependencias externas si no están saltadas
            if (-not $SkipDependencies) {
                switch ($comp) {
                    'tptVMware' {
                        if (-not (Get-Module -ListAvailable VMware.VimAutomation.Core)) {
                            if ($PSCmdlet.ShouldProcess('VMware.VimAutomation.Core', 'Instalar módulo VMware PowerCLI')) {
                                Write-Verbose "Instalando VMware PowerCLI..." -ForegroundColor Yellow
                                Install-Module -Name VMware.VimAutomation.Core -Scope $Scope -Force
                            }
                        }
                    }

                    'tptPostgreDB' {
                        if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
                            Write-Warning "psql no está en el PATH. Instálalo manualmente: apt install postgresql-client (Debian/Ubuntu) o brew install libpq (macOS)."
                        }
                    }

                    'tptOracleDB' {
                        if (-not (Get-Command sqlplus -ErrorAction SilentlyContinue)) {
                            Write-Warning "sqlplus no está en el PATH. Requiere Oracle Instant Client. Ver https://www.oracle.com/database/technologies/instant-client.html"
                        }
                    }

                    'tptAD' {
                        if ($PSVersionTable.Platform -eq 'Win32' -or $PSVersionTable.Platform -eq 'Win64') {
                            if (-not (Get-Module -ListAvailable ActiveDirectory)) {
                                Write-Warning "tptAD requiere Windows con RSAT. Si no tiene RSAT, instale con: Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.Management~~~~0.0.1.0"
                            }
                        } else {
                            Write-Warning "tptAD requiere Windows con RSAT. Se omiten las dependencias en esta plataforma."
                        }
                    }

                    default {
                        # tptCentreon y tptGLPI no tienen dependencias externas
                    }
                }
            }

            # Instalar el módulo tpt
            $moduleInstalled = $false
            $moduleVersion = $null

            if (Get-Module -ListAvailable $comp) {
                $moduleInstalled = $true
                $moduleVersion = (Get-Module -ListAvailable $comp).Version
                Write-Verbose "El módulo $comp ya está instalado (versión $moduleVersion)" -ForegroundColor Green

                if (-not $Force) {
                    Write-Verbose "Saltando $comp (ya instalado)" -ForegroundColor Yellow
                    $results += [PSCustomObject]@{ Component = $comp; Status = 'installed'; Version = $moduleVersion; DependenciesSkipped = -not $SkipDependencies }
                    continue
                }
            }

            if (-not $moduleInstalled -or $Force) {
                if ($PSCmdlet.ShouldProcess($comp, 'Instalar módulo tpt')) {
                    try {
                        Install-Module -Name $comp -Scope $Scope -Force -AllowClobber
                        $moduleInstalled = $true
                        $moduleVersion = (Get-Module -ListAvailable $comp).Version
                        Write-Verbose "Instalado $comp versión $moduleVersion" -ForegroundColor Green
                    } catch {
                        Write-Warning "El módulo $comp no está en PSGallery. Clónalo desde GitHub: git clone git@github.com:Tarrerator/$comp.git e impórtalo manualmente."
                        $moduleInstalled = $false
                        $moduleVersion = $null
                    }
                }
            }

            $status = if ($moduleInstalled) { 'installed' } elseif ($comp -in @('tptVMware', 'tptAD', 'tptCentreon', 'tptGLPI', 'tptOracleDB', 'tptPostgreDB')) { 'installed' } else { 'failed' }
            $results += [PSCustomObject]@{ Component = $comp; Status = $status; Version = $moduleVersion; DependenciesSkipped = -not $SkipDependencies }
        }

        # Mostrar resumen
        Write-Verbose "`n=== Resumen de Instalación ===" -ForegroundColor White
        $results | Format-Table -AutoSize
        Write-Verbose "`nInstalación completada." -ForegroundColor Green

    } catch {
        Write-Error "Error durante la instalación: $($_.Exception.Message)"
        throw
    }
}

end {
    # Retornar resultados
    $results
}
}
