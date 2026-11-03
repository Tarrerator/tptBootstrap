# tptBootstrap

Módulo PowerShell que instala, actualiza y gestiona los demás módulos de la suite `tpt` y sus dependencias externas.

## Función

Actúa como punto de entrada para desplegar la suite completa: verifica PowerShellGet, confía en PSGallery, instala las dependencias externas de cada componente (PowerCLI, clientes de base de datos, RSAT de Active Directory) y clona o instala los módulos `tpt`.

## Tabla de funciones

| Función | Parámetros | Descripción |
|---------|-----------|-------------|
| `Install-tptSuite` | `-Component`, `-SkipDependencies`, `-Force`, `-Scope` | Instala los módulos seleccionados y sus dependencias |
| `Get-tptSuiteStatus` | — | Muestra el estado de instalación de cada módulo y dependencia |
| `Remove-tptSuite` | `-Component` | Desinstala los módulos `tpt` seleccionados |

## Requisitos

- PowerShell 7.2+ (o Windows PowerShell 5.1 en Windows)
- Conexión a internet (PSGallery y GitHub)
- Para componentes con dependencias externas:
  - `tptVMware` → módulo `VMware.VimAutomation.Core` (PowerCLI) desde PSGallery
  - `tptPostgreDB` → `psql` en el PATH (`apt install postgresql-client` / `brew install libpq`)
  - `tptOracleDB` → `sqlplus` en el PATH (Oracle Instant Client)
  - `tptAD` → solo Windows, con RSAT instalado

## Ejemplo de uso

```powershell
# Instalar toda la suite
Install-tptSuite -Component all

# Instalar solo VMware y PostgreSQL
Install-tptSuite -Component tptVMware, tptPostgreDB

# Ver estado de la suite
Get-tptSuiteStatus

# Desinstalar todo
Remove-tptSuite -Component all
```

## Nota sobre los módulos tpt

Los módulos `tpt` aún no están publicados en PSGallery. Si `Install-Module` no los encuentra,
`Install-tptSuite` muestra la orden `git clone` correspondiente desde
`github.com/Tarrerator/<modulo>`.

## Licencia

GPL-3.0
