# OSDBuilder

[OSDBuilder](https://osdbuilder.osdeploy.com/) es un módulo PowerShell creado por [David Segura](https://twitter.com/SeguraOSD) que permite hacer *offline servicing* de la imagen WIM de un sistema operativo Windows (Windows 10, Windows 2016, Windows 2019).

La principal ventaja de OSDBuilder respecto a otros métodos existentes para actualizar una imagen WIM es el uso de tareas (**Tasks**) que se pueden ejecutar de forma desatendida cuando sea necesario (por ejemplo cada *Patch Tuesday*).

Estas tareas permiten instalar actualizaciones (CU, SSU, .NET, etc.), habilitar y deshabilitar características de Windows, eliminar aplicaciones universales que no se necesiten, agregar múltiples paquetes de lenguajes, etc.

La imagen WIM resultante se puede utilizar en multiples escenarios:

* Crear un fichero ISO para instalar el SO en una máquina virtual
* Crear un USB para instalar el SO en un equipo físico
* Importarla en [Microsoft Deployment Toolkit (MDT)](https://docs.microsoft.com/en-us/mem/configmgr/mdt/) para [desplegarla](https://docs.microsoft.com/en-us/windows/deployment/deploy-windows-mdt/prepare-for-windows-deployment-with-mdt) de forma automatizada usando LTI, ZTI o UDI
* Importarla en [Microsoft Endpoint Manager: Configuration Manager (MEMCM)](https://docs.microsoft.com/en-us/mem/configmgr/), el antiguo SCCM o Config Manager, para lo mismo
* Etc.

## Instalación de OSDBuilder

La instalación de OSDBuilder se realiza de la siguiente manera:

* Ejecutar PowerShell desde una cuenta con permisos de Administrador
* Ejecutar el _cmdlet_ `Install-Module` para instalar desde la [PowerShell Gallery](https://www.powershellgallery.com/):

```PowerShell
Install-Module -Name OSDBuilder -Force
```

> **Nota**:  Si hubiese algún problema para descargar el módulo es recomendable revisar la configuración del **cifrado TLS 1.2 en PowerShell** (ver Anexo).

* Cerrar y abrir PowerShell para que cargue los nuevos módulos instalados

OSDBuilder también instalará dos módulos complementarios:
* **[OSDSUS](https://osdsus.osdeploy.com/)**, el módulo que contiene el catálogo de actualizaciones de WSUS (también usado por [OSDUpdate](https://osdupdate.osdeploy.com/) y por [WIMWitch](https://msendpointmgr.com/wim-witch/) de [Donna Ryan](https://twitter.com/TheNotoriousDRR))
* **[OSD](https://osd.osdeploy.com/)**, un módulo con funciones auxiliares que pueden ser de utilidad durante el despliegue de un sistema operativo

## Configuración del entorno

### Directorio raíz

Antes de comenzar a utilizar OSDBuilder, es recomendable configurar el entorno de trabajo para indicarle dónde se crearán los directorios para el contenido, las actualizaciones, los sistemas operativos, etc.

En esta documentación se cambiará el directorio por defecto de OSDBuilder (`C:\OSDBuilder`) a otro disco con más espacio y más rápido (`V:\OSDBuilder`) mediante el siguiente comando:

```PowerShell
# Cambiar el directorio raíz de OSDBuilder sin crearlo todavía
OSDBuilder -SetPath V:\OSDBuilder
```

Al ejecutar el comando anterior se puede observar que OSDBuilder indica los directorios para cada tipo de contenido:

```
PS C:\WINDOWS\system32> OSDBuilder -SetPath V:\OSDBuilder
VERBOSE: Initializing OSDBuilder ...
OSDBuilder 20.7.6.1 | OSDSUS 20.9.8.1 | OSD 20.8.19.1
Home            V:\OSDBuilder
-Content        V:\OSDBuilder\Content
-ContentPacks   V:\OSDBuilder\ContentPacks
-FeatureUpdates V:\OSDBuilder\FeatureUpdates
-OSImport       V:\OSDBuilder\OSImport
-OSMedia        V:\OSDBuilder\OSMedia
-OSBuilds       V:\OSDBuilder\OSBuilds
-PEBuilds       V:\OSDBuilder\PEBuilds
-Mount          V:\OSDBuilder\Mount
-Tasks          V:\OSDBuilder\Tasks
-Templates      V:\OSDBuilder\Templates
-Updates        V:\OSDBuilder\Updates
```

### Entornos Dev, Prod y Share

Aunque ahora ya se podría comenzar a trabajar con OSDBuilder, se puede afinar aún más la configuración para tener diferentes entornos (**Dev** y **Prod**) que compartan contenido (**Share**) y así minimizar el espacio en disco.

Esto se consigue creando un fichero de configuración global `OSDBuilder.json` en el directorio `C:\ProgramData\OSDeploy`. El contenido de este fichero es el siguiente:

```
{
    "PathContent":  "V:\\OSDBuilder\\Share\\Content",
    "PathContentPacks":  "V:\\OSDBuilder\\Share\\ContentPacks",
    "PathFeatureUpdates":  "V:\\OSDBuilder\\Share\\FeatureUpdates",
    "PathOSImport":  "V:\\OSDBuilder\\Share\\OSImport",
    "PathOSMedia":  "V:\\OSDBuilder\\Share\\OSMedia",
    "PathMount":  "V:\\OSDBuilder\\Share\\Mount",
    "PathUpdates":  "V:\\OSDBuilder\\Share\\Updates"
}
```

Si se inicializa OSDBuilder se puede observar que algunos directorios (los indicados en el fichero `OSDBuilder.json`) han cambiado su ubicación:

```
PS C:\WINDOWS\system32> Get-OSDBuilder -Initialize
VERBOSE: Initializing OSDBuilder ...
OSDBuilder 20.7.6.1 | OSDSUS 20.9.8.1 | OSD 20.8.19.1
Home            V:\OSDBuilder
-Content        V:\OSDBuilder\Share\Content
-ContentPacks   V:\OSDBuilder\Share\ContentPacks
-FeatureUpdates V:\OSDBuilder\Share\FeatureUpdates
-OSImport       V:\OSDBuilder\Share\OSImport
-OSMedia        V:\OSDBuilder\Share\OSMedia
-OSBuilds       V:\OSDBuilder\OSBuilds
-PEBuilds       V:\OSDBuilder\PEBuilds
-Mount          V:\OSDBuilder\Share\Mount
-Tasks          V:\OSDBuilder\Tasks
-Templates      V:\OSDBuilder\Templates
-Updates        V:\OSDBuilder\Share\Updates
```

> **Nota**: El fichero `OSDBuilder.json` se puede utilizar no solo para indicar los directorios de trabajo sino para fijar cualquier valor del entorno indicado en la variable `$SetOSDBuilder`.

### Creación de directorios

A continuación se procede a crear los directorios correspondientes a los diferentes entornos (**Dev** y **Prod**) y unos *scripts* auxiliares para cambiar a cada uno de ellos.

* Crear los directorios correspondientes a los diferentes entornos:

```PowerShell
New-Item -Force -ItemType Directory -Path V:\OSDBuilder
New-Item -Force -ItemType Directory -Path V:\OSDBuilder\Share
New-Item -Force -ItemType Directory -Path V:\OSDBuilder\Dev
New-Item -Force -ItemType Directory -Path V:\OSDBuilder\Prod
```

* Crear un fichero `SetHome.ps1` en los directorios `Dev` y `Prod` con el siguiente contenido:

```PowerShell
OSDBuilder -SetHome $PSScriptRoot
Pause
```

## Selección del entorno

Cada vez que se quiera cambiar de entorno de trabajo (**Dev** y **Prod**) será necesario:

* Ejecutar el *script* `SetHome.ps1` del entorno con el que se quiere trabajar usando la opción _Run with PowerShell_ del Explorador de archivos

Por ejemplo, después de ejecutar el *script* del directorio `Prod`, el entorno queda preparado de la siguiente manera:

```
PS C:\WINDOWS\system32> Get-OSDBuilder
VERBOSE: Initializing OSDBuilder ...
OSDBuilder 20.7.6.1 | OSDSUS 20.9.8.1 | OSD 20.8.19.1
Home            V:\OSDBuilder\Prod
-Content        V:\OSDBuilder\Share\Content
-ContentPacks   V:\OSDBuilder\Share\ContentPacks
-FeatureUpdates V:\OSDBuilder\Share\FeatureUpdates
-OSImport       V:\OSDBuilder\Share\OSImport
-OSMedia        V:\OSDBuilder\Share\OSMedia
-OSBuilds       V:\OSDBuilder\Prod\OSBuilds
-PEBuilds       V:\OSDBuilder\Prod\PEBuilds
-Mount          V:\OSDBuilder\Share\Mount
-Tasks          V:\OSDBuilder\Prod\Tasks
-Templates      V:\OSDBuilder\Prod\Templates
-Updates        V:\OSDBuilder\Share\Updates
```

A continuación ya se puede abrir PowerShell como Administrador y ejecutar [`Get-OSDBuilder`](https://osdbuilder.osdeploy.com/docs/basics/get-osdbuilder) para crear la estructura interna de los directorios:

```PowerShell
Get-OSDBuilder -CreatePaths
```

> **Nota**: Si se observa la estructura de directorios interna mediante el comando `tree.exe V:\OSDBuilder` se pueden ver los directorios para las tareas, las plantillas, los SO importados, los scripts, los paquetes de lenguaje, etc.

```
V:\OSDBuilder>tree
Folder PATH listing for volume DISK_V
Volume serial number is XXXXXXXX XXXX:XXXX
V:.
├───Dev
├───Prod
│   ├───OSBuilds
│   ├───PEBuilds
│   ├───Tasks
│   └───Templates
└───Share
    ├───Content
    │   ├───ADK
    │   │   ├───Windows 10 1903
    │   │   │   └───Windows Preinstallation Environment
    │   │   └───Windows 10 2004
    │   │       └───Windows Preinstallation Environment
    │   ├───DaRT
    │   │   └───DaRT 10
    │   ├───Drivers
    │   ├───ExtraFiles
    │   ├───IsoExtract
    │   │   ├───Windows 10 1903 FOD x64
    │   │   ├───Windows 10 1903 Language
    │   │   ├───Windows 10 2004 FOD x64
    │   │   ├───Windows 10 2004 Language
    │   │   ├───Windows Server 2019 1809 FOD x64
    │   │   └───Windows Server 2019 1809 Language
    │   ├───OneDrive
    │   ├───Packages
    │   ├───Scripts
    │   ├───StartLayout
    │   └───Unattend
    ├───ContentPacks
    │   └───_Global
    │       ├───Media
    │       │   ├───ALL
    │       │   └───x64
    │       ├───OSCapability
    │       │   ├───1903 x64
    │       │   ├───1903 x64 RSAT
    │       │   ├───1909 x64
    │       │   ├───1909 x64 RSAT
    │       │   ├───2004 x64
    │       │   └───2004 x64 RSAT
    │       ├───OSDrivers
    │       │   ├───ALL
    │       │   └───x64
    │       ├───OSExtraFiles
    │       │   ├───ALL
    │       │   ├───ALL Subdirs
    │       │   ├───x64
    │       │   └───x64 Subdirs
    │       ├───OSLanguageFeatures
    │       │   ├───1903 x64
    │       │   ├───1909 x64
    │       │   └───2004 x64
    │       ├───OSLanguagePacks
    │       │   ├───1903 x64
    │       │   ├───1909 x64
    │       │   └───2004 x64
    │       ├───OSLocalExperiencePacks
    │       │   ├───1903 x64
    │       │   ├───1909 x64
    │       │   └───2004 x64
    │       ├───OSPackages
    │       │   ├───1903 x64
    │       │   ├───1909 x64
    │       │   └───2004 x64
    │       ├───OSPoshMods
    │       │   ├───ProgramFiles
    │       │   └───System
    │       ├───OSRegistry
    │       │   ├───ALL
    │       │   └───x64
    │       ├───OSScripts
    │       │   ├───ALL
    │       │   └───x64
    │       ├───OSStartLayout
    │       │   ├───ALL
    │       │   └───x64
    │       ├───PEADK
    │       │   ├───1903 x64
    │       │   ├───1909 x64
    │       │   └───2004 x64
    │       ├───PEADKLang
    │       │   ├───1903 x64
    │       │   ├───1909 x64
    │       │   └───2004 x64
    │       ├───PEDaRT
    │       ├───PEDrivers
    │       │   ├───ALL
    │       │   └───x64
    │       ├───PEExtraFiles
    │       │   ├───ALL
    │       │   ├───ALL Subdirs
    │       │   ├───x64
    │       │   └───x64 Subdirs
    │       ├───PEPoshMods
    │       │   ├───ProgramFiles
    │       │   └───System
    │       ├───PERegistry
    │       │   ├───ALL
    │       │   └───x64
    │       └───PEScripts
    │           ├───ALL
    │           └───x64
    ├───FeatureUpdates
    ├───Mount
    ├───OSImport
    ├───OSMedia
    └───Updates
```

## Importar Sistemas Operativos

Para comenzar a trabajar con OSDBuilder es esencial [importar los Sistemas Operativos](https://osdbuilder.osdeploy.com/docs/osimport/import-osmedia) (**OSMedia**) a los que se aplicarán las tareas de configuración y actualización.

### Montar ISO

Antes de importar un Sistema Operativo es necesario montar el ISO que lo contiene utilizando el *cmdlet* `Mount-DiskImage`:

```PowerShell
# Directorio que contiene los ISO de Windows 10
$WindowsISO = "E:\EQUIPS\ISOs\Win10"

# Windows 10 1903
Mount-DiskImage -ImagePath "$WindowsISO\1903\SW_DVD9_Win_Pro_10_1903_64BIT_Spanish_Pro_Ent_EDU_N_MLF_X22-02936.iso"

# Windows 10 1909
Mount-DiskImage -ImagePath "$WindowsISO\1909\SW_DVD9_Win_Pro_10_1909_64BIT_Spanish_Pro_Ent_EDU_N_MLF_X22-17418.iso"

# Windows 10 2004
Mount-DiskImage -ImagePath "$WindowsISO\2004\SW_DVD9_Win_Pro_10_2004.1_64BIT_Spanish_Pro_Ent_EDU_N_MLF_-2_X22-31428.iso"

# Directorio que contiene los ISO
$ISOs = "E:\EQUIPS\ISOs"

# Windows Server 2016
Mount-DiskImage -ImagePath "$ISOs\Win2016\SW_DVD9_Win_Server_STD_CORE_2016_64Bit_English_-4_DC_STD_MLF_X21-70526.iso"

# Windows Server 2019
Mount-DiskImage -ImagePath "$ISOs\Win2019\SW_DVD9_Win_Server_STD_CORE_2019_64Bit_English_DC_STD_MLF_X21-96581.iso"
```

> **Nota**: Si tenemos más de un ISO en un directorio concreto y queremos montarlos todos al mismo tiempo se puede usar el *cmdlet* `Get-ChildItem` de PowerShell:

```PowerShell
# Directorio que contiene los ISO de Windows 10
$WindowsISO = "E:\EQUIPS\ISOs\Win10"

# Montar todos los ISO que se encuentren por debajo
Get-ChildItem -Path "$WindowsISO" *.iso -Recurse | ForEach-Object {Mount-DiskImage -ImagePath $_.FullName}
```

### Importar un SO

Para importar un sistema operativo (**OSMedia**) se utiliza el *cmdlet* `Import-OSMedia`:

```PowerShell
Import-OSMedia
```

Este comando analiza las unidades montadas desde los ISO en búsqueda de sistemas operativos Windows. A continuación los muestra en una *GridView* desde la que se pueden seleccionar aquellos que se quieren importar.

> **Nota**: Desde hace unos años, los ISO de Windows 10 incorporan diferentes ediciones del Sistema Operativo. En nuestro caso hay que importar la edición **Education** (equivale a la versión Enterprise en entornos educativos) o la **Pro Education** (necesaria para las activaciones nominales de Windows).

```
PS C:\WINDOWS\system32> Import-OSMedia
2020-09-24-131406 Validating OSDBuilder Content
2020-09-24-131406 Validating Administrator Rights and Elevation
========================================================================================
2020-09-24-131406 Media: Scan F:\Sources\install.wim
ImageIndex 1: Windows 10 Education
ImageIndex 2: Windows 10 Education N
ImageIndex 3: Windows 10 Enterprise
ImageIndex 4: Windows 10 Enterprise N
ImageIndex 5: Windows 10 Pro
ImageIndex 6: Windows 10 Pro N
ImageIndex 7: Windows 10 Pro Education
ImageIndex 8: Windows 10 Pro Education N
ImageIndex 9: Windows 10 Pro for Workstations
ImageIndex 10: Windows 10 Pro N for Workstations
(...)
```

También es posible importar una **EditionId** concreta sin necesidad de seleccionarla de una lista, por ejemplo:

```PowerShell
# Ediciones 'Education' de Windows 10
Import-OSMedia -EditionId Education -SkipGrid

# Ediciones 'Pro Education' de Windows 10
Import-OSMedia -EditionId ProfessionalEducation -SkipGrid

# Ediciones 'Standard' de Windows Server 2016/2019 (Core y Desktop Experience)
Import-OSMedia -EditionId ServerStandard -SkipGrid

# Ediciones 'Standard' de Windows Server 2016/2019 (Desktop Experience)
Import-OSMedia -EditionId ServerStandard -InstallationType Server -SkipGrid
```

De forma similar, se puede epecificar una **imagen concreta** del Sistema Operativo usando el parámetro `-ImageName`:

```PowerShell
Import-OSMedia -ImageName 'Windows 10 Education' -SkipGrid
Import-OSMedia -ImageName 'Windows 10 Pro Education' -SkipGrid
Import-OSMedia -ImageName 'Windows Server 2016 Standard (Desktop Experience)' -SkipGrid
Import-OSMedia -ImageName 'Windows Server 2019 Standard (Desktop Experience)' -SkipGrid
```

Los sistemas operativos importados se copian en subdirectorios de la carpeta `V:\OSDBuilder\Share\OSImport`(formados por el nombre del Sistema Operativo, su edición, su _build_ y su idioma principal si es diferente de en-US):

```
Windows 10 Education x64 1909 18363.418 es-ES
Windows 10 Education x64 2004 19041.329 es-ES
Windows Server 2016 Standard Desktop Experience x64 1607 14393.447
Windows Server 2019 Standard Desktop Experience x64 1809 17763.107
```

### Importar y actualizar un SO

También es posible **importar** el SO y **actualizarlo** con la última actualización acumulativa disponible en ese momento usando el parámetro `-Update`, por ejemplo:

```PowerShell
Import-OSMedia -ImageName 'Windows 10 Education' -SkipGrid -Update
```

### Desmontar ISO

Para desmontar la ISO se utiliza el *cmdlet* `Dismount-DiskImage` sobre el mismo fichero ISO utilizado para montar:

```PowerShell
# Directorio que contiene los ISO de Windows 10
$WindowsISO = "E:\EQUIPS\ISOs\Win10"

# Windows 10 1903
Dismount-DiskImage -ImagePath "$WindowsISO\1903\SW_DVD9_Win_Pro_10_1903_64BIT_Spanish_Pro_Ent_EDU_N_MLF_X22-02936.iso"

# Windows 10 1909
Dismount-DiskImage -ImagePath "$WindowsISO\1909\SW_DVD9_Win_Pro_10_1909_64BIT_Spanish_Pro_Ent_EDU_N_MLF_X22-17418.iso"

# Windows 10 2004
Dismount-DiskImage -ImagePath "$WindowsISO\2004\SW_DVD9_Win_Pro_10_2004.1_64BIT_Spanish_Pro_Ent_EDU_N_MLF_-2_X22-31428.iso"

# Directorio que contiene los ISO
$ISOs = "E:\EQUIPS\ISOs"

# Windows Server 2016
Dismount-DiskImage -ImagePath "$ISOs\Win2016\SW_DVD9_Win_Server_STD_CORE_2016_64Bit_English_-4_DC_STD_MLF_X21-70526.iso"

# Windows Server 2019
Dismount-DiskImage -ImagePath "$ISOs\Win2019\SW_DVD9_Win_Server_STD_CORE_2019_64Bit_English_DC_STD_MLF_X21-96581.iso"
```

> **Nota**: Si tenemos más de un ISO en un directorio concreto y queremos desmontarlos todos al mismo tiempo se puede usar el *cmdlet* `Get-ChildItem` de PowerShell:

```PowerShell
# Directorio que contiene los ISO de Windows 10
$WindowsISO = "E:\EQUIPS\ISOs\Win10"

# Desmontar todos los ISO que se encuentren por debajo
Get-ChildItem -Path "$WindowsISO" *.iso -Recurse | ForEach-Object {Dismount-DiskImage -ImagePath $_.FullName}
```

## Actualizar un SO (OSMedia)

El segundo martes de cada mes o _**Patch Tuesday**_, Microsoft publica los paquetes de actualización para sus sistemas operativos.

La página [Windows 10 Update history](https://support.microsoft.com/en-us/help/4498140/windows-10-update-history) recoge la información sobre cada *build* de las diferentes versiones de Windows 10 disponibles.

La página [Windows lifecycle fact sheet](https://support.microsoft.com/en-us/help/13853/windows-lifecycle-fact-sheet) recoge las fechas de publicación de una versión de Windows 10 así como la fecha final de soporte (es decir, la fecha a partir de la cual ya no tiene actualizaciones).

A fecha 25 de Septiembre de 2020 las últimas compilaciones disponibles son:

| Version | Disponibilidad | Final de servicio (Pro) | Final de servicio (Education) | Última *build* | Fecha *build* |
| --- | --- | --- | --- | --- | --- |
| Windows 10 1909 | 12 Nov 2019 | 11 May 2021 | 10 May 2022 | 18363.1082 | 8 Sep 2020 |
| Windows 10 2004 | 27 May 2020 | 14 Dic 2021 | 14 Dic 2021 | 19041.508 | 8 Sep 2020 |

> **Nota**: Es recomendable utilizar las versiones **Education** de **Septiembre** (xx09 o xxH2) ya que tienen un periodo de actualizaciones de **30 meses** en lugar de los 18 meses habituales.

### Actualizar OSDSUS

David Segura publica actualizaciones del módulo **OSDSUS** cada *Patch Tuesday* que incluyen las URL de las actualizaciones de Windows publicadas por Microsoft.

Por tanto, habría que actualizarlo para que OSDBuilder pueda descargarlas correctamente:

```PowerShell
# Actualización necesaria cada Patch Tuesday
Update-OSDSUS
```

> **Nota**: Al ejecutar `Get-OSDBuilder` se informará de la necesidad de actualizar este módulo ya que comprueba la versión instalada con la disponible en la web:

```
PS C:\WINDOWS\system32> Get-OSDBuilder                                                                                  VERBOSE: Initializing OSDBuilder ...
OSDBuilder 20.9.29.1 | OSDSUS 20.9.8.1 | OSD 20.8.19.1
Home            V:\OSDBuilder\Prod
-Content        V:\OSDBuilder\Share\Content
-ContentPacks   V:\OSDBuilder\Share\ContentPacks
-FeatureUpdates V:\OSDBuilder\Share\FeatureUpdates
-OSImport       V:\OSDBuilder\Share\OSImport
-OSMedia        V:\OSDBuilder\Share\OSMedia
-OSBuilds       V:\OSDBuilder\Prod\OSBuilds
-PEBuilds       V:\OSDBuilder\Prod\PEBuilds
-Mount          V:\OSDBuilder\Share\Mount
-Tasks          V:\OSDBuilder\Prod\Tasks
-Templates      V:\OSDBuilder\Prod\Templates
-Updates        V:\OSDBuilder\Share\Updates

WARNING: OSDSUS can be updated to 20.9.29.1
Update-OSDSUS
```

### Descargar OneDrive

Es recomendable actualizar el instalador de [OneDrive](https://support.microsoft.com/en-us/office/onedrive-release-notes-845dcf18-f921-435e-bf28-4e24b95e5fc0) incluído en las OSMedia con la última versión disponible.

Para descargarlo hay que usar el *cmdlet* `Get-DownOSDBuilder` especificando el canal de actualización que se desee (Enterprise o Production).

```PowerShell
# Enterprise (deferred)
# Get-DownOSDBuilder -ContentDownload 'OneDriveSetup Enterprise'

# Production
Get-DownOSDBuilder -ContentDownload 'OneDriveSetup Production'
```

> **Nota**: El instalador se dejará en `V:\OSDBuilder\Share\Content\OneDrive\OneDriveSetup.exe` preparado para ser usado cuando se actualice una OSMedia.

```
PS C:\WINDOWS\system32> Get-DownOSDBuilder -ContentDownload 'OneDriveSetup Production'
VERBOSE: DownloadUrl: https://go.microsoft.com/fwlink/p/?LinkId=248256
VERBOSE: DownloadPath: V:\OSDBuilder\Share\Content\OneDrive
VERBOSE: DownloadFile: OneDriveSetup.exe
VERBOSE: DownloadVersion: 20.143.0716.0003
VERBOSE: Complete
```

### Descargar e instalar actualizaciones

A continuación se utiliza el *cmdlet* `Update-OSMedia` para descargar las actualizaciones de las OSMedia que se seleccionen en la *Grid View*:

```PowerShell
# Descarga de actualizaciones 
# Update-OSMedia -Download

# Descarga e instalación de actualizaciones
Update-OSMedia -Download -Execute
```

Los sistemas operativos actualizados se generan en subdirectorios de la carpeta `V:\OSDBuilder\Share\OSMedia`.

A fecha 25 de Septiembre de 2020 las versiones actualizadas son las siguientes (nótese la diferencia con las versiones importadas desde los ficheros ISO):

```
Windows 10 Education x64 1909 18363.1082 es-ES
Windows 10 Education x64 2004 19041.508 es-ES
Windows Server 2016 Standard Desktop Experience x64 1607 14393.3930
Windows Server 2019 Standard Desktop Experience x64 1809 17763.1457
```

## Crear una OSBuild

Tal como se ha comentado anteriormente, OSDBuilder permite hacer muchas más cosas que la simple actualización de una OSMedia.

Se puede utilizar una **Task** para crear una **OSBuild** de forma repetitiva después de cada *Patch Tuesday*.

Una OSBuild no es más que una OSMedia (habitualmente un sistema operativo actulizado) al que se le aplican una serie de operaciones para:

* Eliminar las Aplicaciones Universales no necesarias para que no se aprovisionen al instalar el SO
* Habilitar o deshabilitar Características de Windows
* Modificar el registro de máquina (HKLM) o del usuario por defecto
* Añadir paquetes de lenguajes para hacer una instalación multi-lenguaje
* Etc.

En las versiones iniciales de OSDBuilder se trabajaba usando **[Templates](https://osdbuilder.osdeploy.com/docs/osbuild/new-osbuildtask/templates)** para definir en cada uno ellos las operaciones necesarias para construir la OSBuild.

En las versiones más recientes, se han añadido la posibilidad de trabajar con **ContentPacks** (explicados más adelante) para agrupar los contenidos que se incluirán en la OSBuild.

### Crear una Tarea vacía

El primer paso para crear una OSBuild de **Windows 10 Education x64 1909** es la creación de una tarea vacía seleccionando una OSMedia de Windows 10 1909 mediante el siguiente comando:

```PowerShell
# Crear una Task vacía a partir de una OSMedia de Windows 10 1909
New-OSBuildTask -SaveAs Task -TaskName "Windows 10 Education x64 1909 BLANK" -CustomName "Windows 10 Education x64 1909"
```

Este comando genera un fichero `OSBuild Windows 10 Education x64 1909 BLANK.json` en el directorio `V:\OSDBuilder\Prod\Tasks` con un contenido similar al mostrado a continuación:

```
{
    "TaskType":  "OSBuild",
    "TaskVersion":  "20.9.29.1",
    "TaskGuid":  "2ccd2b6c-c228-4509-9685-db20d71134d0",
    "TaskName":  "Windows 10 Education x64 1909 BLANK",
    "CustomName":  "Windows 10 Education x64 1909",
    "OSMFamily":  "Client Education x64 18363 es-ES",
    "OSMGuid":  "5508ba52-1949-4e21-a568-bd0452920197",
    "Name":  "Windows 10 Education x64 1909 18363.1082 es-ES",
    "ImageName":  "Windows 10 Education",
    "Arch":  "x64",
    "ReleaseId":  "1909",
    "UBR":  "18363.1082",
    "Languages":  [
                      "es-ES"
                  ],
    "EditionId":  "Education",
    "InstallationType":  "Client",
    "MajorVersion":  "10",
    "Build":  "18362",
    "CreatedTime":  "\/Date(1570418099992)\/",
    "ModifiedTime":  "\/Date(1600955724409)\/",
    "ContentPacks":  null,
    "EnableNetFX3":  "False",
    "WinPEAutoExtraFiles":  "False",
    "RemoveAppxProvisionedPackage":  null,
    "RemoveWindowsCapability":  null,
    "RemoveWindowsPackage":  null,
    "DisableWindowsOptionalFeature":  null,
    "EnableWindowsOptionalFeature":  null,
    "Drivers":  null,
    "ExtraFiles":  null,
    "Scripts":  null,
    "StartLayoutXML":  "",
    "UnattendXML":  "",
    "AddWindowsPackage":  null,
    "AddFeatureOnDemand":  null,
    "WinPEADKPE":  null,
    "WinPEADKRE":  null,
    "WinPEADKSE":  null,
    "WinPEDaRT":  "",
    "WinPEDrivers":  null,
    "WinPEExtraFilesPE":  null,
    "WinPEExtraFilesRE":  null,
    "WinPEExtraFilesSE":  null,
    "WinPEScriptsPE":  null,
    "WinPEScriptsRE":  null,
    "WinPEScriptsSE":  null,
    "LangSetAllIntl":  "",
    "LangSetInputLocale":  "",
    "LangSetSKUIntlDefaults":  "",
    "LangSetSetupUILang":  "",
    "LangSetSysLocale":  "",
    "LangSetUILang":  "",
    "LangSetUILangFallback":  "",
    "LangSetUserLocale":  "",
    "LanguagePack":  null,
    "LanguageInterfacePack":  null,
    "LocalExperiencePacks":  null,
    "LanguageFeature":  null,
    "LanguageCopySources":  null
}
```

### Aplicaciones Universales

A continuación se crea una plantilla en la que se especificará qué aplicaciones universales hay que eliminar de la OSMedia (y que, por tanto, no se aprovisionarán cuando se instale el Sistema Operativo a partir de ella):

```PowerShell
# Crear un Template para eliminar las AppX que no se necesitan
New-OSBuildTask -SaveAs Template -TaskName 'Windows 10 Education x64 1909 Appx' -RemoveAppx
```

El comando anterior crea el fichero `OSBuild Windows 10 Education x64 1909 Appx.json` en el directorio `V:\OSDBuilder\Prod\Templates`.

Este fichero tiene la misma estructura que el fichero BLANK pero el campo **RemoveAppxProvisionedPackage** contendrá los nombres de los paquetes correspondientes a las aplicaciones universales que se hayan seleccionado para borrar.

> **Nota**: Ver en el Anexo de estas notas un listado de aplicaciones universales que es recomendable mantener en la instalación.

### Características de Windows

Las características de Windows se pueden deshabilitar y habilitar en la imagen WIM mediante el siguiente comando:

```PowerShell
# Crear un Template para habilitar/deshabilitar las Features que se consideren
New-OSBuildTask -SaveAs Template -TaskName "Windows 10 Education x64 1909 Features" -EnableFeature -DisableFeature
```

En nuestro entorno se suelen deshabilitar las siguientes características:

* FaxServicesClientPackage
* MicrosoftWindowsPowerShellV2
* MicrosoftWindowsPowerShellV2Root
* Printing-XPSServices-Features

Y habilitar éstas:

* Containers-DisposableClientVM (Windows Sandbox)
* Microsoft-Windows-Subsystem-Linux (WSL 1)
* TelnetClient
* VirtualMachinePlatform (WSL 2)

> **Nota**: La [característica **VirtualMachinePlatform**](https://docs.microsoft.com/en-us/windows/wsl/install-win10) es necesaria para poder instalar el [kernel de Linux WSL2](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi).

### Ejecución de scripts

OSDBuilder es capaz de ejecutar _scripts_ para modificar la imagen WIM (por ejemplo, el registro HKLM de la máquina una vez instalada).

```PowerShell
# (Opcional) Crear un Template para añadir scripts
New-OSBuildTask -SaveAs Template -TaskName "Windows 10 Education x64 1909 Scripts" -ContentScripts
```

Los scripts que se pueden seleccionar mediante el comando anterior son los ficheros `*.ps1` que estén en el directorio `V:\OSDBuilder\Share\Content\Scripts`.

En nuestro entorno se suelen incluir los siguientes scripts:

```
Global Add-DesktopIcons.ps1
Global Set-ConsoleOptions.ps1
Global Set-ControlPanelConfiguration.ps1
Global Set-FileExplorerOptions.ps1
Global Set-FirstDayOfWeek.ps1
Global Set-TimeZoneRomance.ps1
Windows 10 Disable-ConsumerApps.ps1
Windows 10 Disable-CortanaSearch.ps1
Windows 10 Disable-DriversFromWindowsUpdate.ps1
Windows 10 Disable-EdgeShortcut.ps1
Windows 10 Disable-WebSearch.ps1
```

### Paquetes de lenguajes

```PowerShell
# (Opcional) Crear un Template para añadir los lenguajes
# New-OSBuildTask -SaveAs Template -TaskName "Windows 10 Education x64 1909 Languages" -ContentLanguagePackages -SetAllIntl es-ES

# Crear un Template para añadir los lenguajes usando un ContentPack
New-OSBuildTask -SaveAs Template -TaskName "Windows 10 Education x64 1909 Languages" -AddContentPacks -SetAllIntl es-ES
```

Los lenguajes que se pueden seleccionar mediante el comando anterior son **ContentPack** que estén en el directorio `V:\OSDBuilder\Share\ContentPacks`.

En nuestro entorno se suelen incluir los siguientes paquetes:

* MultiLang ca-es
* MultiLang en-us

> **Nota**: Antes de poder seleccionar los lenguajes, es necesario crear los **ContentPack** tal como se explica más adelante (ver apartados **OSLanguagePacks** y **OSLanguageFeatures**).

### (Opcional) Test de una OSBuild

Para comprobar una **OSBuild** de forma rápida se puede ejecutar el siguiente comando:

```PowerShell
# Generar ISO de la OSBuild para probarla en una VM
New-OSBuild -SkipTask -Execute -SkipComponentCleanup -SkipUpdates -CreateISO
```

### Construir la OSBuild

Finalmente, se puede generar la **OSBuild** a partir de la tarea inicial que usará las plantillas creadas en los pasos anteriores:

```PowerShell
# Ejecutar la construcción de la OSBuild
New-OSBuild -ByTaskName "Windows 10 Education x64 1909 BLANK" -Execute -Download
```

### Ejemplo de OSBuildTask

Un ejemplo con los pasos completos para la versión **2004** de Windows 10 (quitar AppX, habilitar/deshabilitar Features, añadir ContentPAcks y descargar OneDrive) sería el siguiente:

```PowerShell
# Crear una Task vacía seleccionando el ISO correspondiente
New-OSBuildTask -SaveAs Task -TaskName "Windows 10 Education x64 2004 BLANK" -CustomName "Windows 10 Education x64 2004"

# Crear un Template para eliminar las AppX que se considere
# 1) Seleccionar todas las aplicaciones de la lista
# 2) Editar el fichero JSON
# 3) Borrar las que se conservan según la tabla del Anexo
New-OSBuildTask -SaveAs Template -TaskName 'Windows 10 Education x64 2004 Appx' -RemoveAppx

# Crear un Template para habilitar/deshabilitar las Features que se consideren
# - MicrosoftWindowsPowerShellV2
# - MicrosoftWindowsPowerShellV2Root
# - Printing-XPSServices-Features
# + Containers-DisposableClientVM (Windows Sandbox)
# + Microsoft-Windows-Subsystem-Linux (WSL1)
# + TelnetClient
# + VirtualMachinePlatform (WSL2)
New-OSBuildTask -SaveAs Template -TaskName "Windows 10 Education x64 2004 Features" -EnableFeature -DisableFeature

# (Opcional) Crear un Template para añadir scripts
New-OSBuildTask -SaveAs Template -TaskName "Windows 10 Education x64 2004 Scripts" -ContentScripts

# Crear un Template para añadir los lenguajes usando ContentPacks que se hayan creado con anterioridad
New-OSBuildTask -SaveAs Template -TaskName "Windows 10 Education x64 2004 Languages" -AddContentPacks -SetAllIntl es-ES

# Descargar OneDrive
Get-DownOSDBuilder -ContentDownload 'OneDriveSetup Production'

# Se actualiza la OSMedia con los últimos parches
Update-OSMedia

# (Opcional) Test rápido de la OSBuild creando un ISO
New-OSBuild -ByTaskName "Windows 10 Education x64 2004 BLANK" -Execute -SkipComponentCleanup -SkipUpdates -SkipUpdatesPE -CreateISO

# Se ejecuta la construcción de la OSBuild
New-OSBuild -ByTaskName "Windows 10 Education x64 2004 BLANK" -Execute -Download
```

## Content Packs

Los [ContentPacks](https://osdbuilder.osdeploy.com/docs/contentpacks) (`V:\OSDBuilder\Share\ContentPacks`) permiten agrupar todo el contenido individual que se puede añadir a una OSBuildTask (por ejemplo *drivers*, *scripts*, ficheros de registro, etc.).

Existe un ContentPack llamado **_Global** que se añade a cualquier OSBuild a no ser que se deshabilite.

Para crear un ContentPack se utiliza el *cmdlet* `New-OSDBuilderContentPack`. Si no se especifica un tipo de contenido concreto, se creará la estructura de directorios para todos los tipos de contenido disponibles:

```PowerShell
# Crear un ContentPack con todos los tipos de contenido disponibles
New-OSDBuilderContentPack -Name 'My Content Pack'

# Crear un ContentPack con los contenidos relacionados con el Sistema Operativo
New-OSDBuilderContentPack -Name 'My OS Content Pack' -ContentType OS

# Crear un ContentPack con los contenidos relacionados con WinPE
New-OSDBuilderContentPack -Name 'My WinPE Content Pack' -ContentType WinPE

# Crear un ContentPack con los contenidos relaciones con lenguajes múltiples
New-OSDBuilderContentPack -Name 'My LP Content Pack' -ContentType MultiLang
```

Los tipos de contenido disponibles para añadir a un ContentPack son los siguientes:

```
Sistema Operativo
=================
Media
OSCapability
OSDrivers
OSExtraFiles
OSPackages
OSPoshMods
OSRegistry
OSScripts
OSStartLayout

Lenguajes
=========
OSLanguageFeatures
OSLanguagePacks
OSLocalExperiencePacks

WinPE
=====
PEADK
PEADKLang
PEDaRT
PEDrivers
PEExtraFiles
PEPoshMods
PERegistry
PEScripts
```

> **Nota**: Los directorios de un ContentPack correspondientes a tipos de contenido no utilizados se pueden borrar.

### Media

[Media](https://osdbuilder.osdeploy.com/docs/contentpacks/content/media) sirve para añadir contenido a la raíz de todas las **Media** o **ISO** que se generen.

El típico ejemplo es añadir un fichero `AutoUnattend.xml` para automatizar la instalación de Windows y el OOBE de usuario.

* `<ContentPackDir>\Media\ALL`: Contenido para cualquier arquitectura
* `<ContentPackDir>\Media\x64`: Contenido para arquitecturas x64

### OSCapability

[OSCapability](https://osdbuilder.osdeploy.com/docs/contentpacks/content/oscapability) sirve para añadir **FOD** (Features on Demand) de Windows a las OSBuild que la incluyan.

* `<ContentPackDir>\OSCapability\1909 x64 RSAT`: Contenido para Windows 10 1909
* `<ContentPackDir>\OSCapability\2004 x64 RSAT`: Contenido para Windows 10 2004

Las Feature on Demand se distribuyen en dos ISO. Una vez descargados y montados, se pueden copiar las características que se necesiten.

> **Nota**: Además de los ficheros `*.cab` de las características, es necesario copiar el directorio `metadata` y el fichero `FoDMetadata_Client.cab` para que todo funcione correctamente.

El típico ejemplo es añadir las **RSAT** (Remote Server Administration Tools) para administrar el AD o el DNS:

```PowerShell
# Crear un ContentPack de tipo OS
New-OSDBuilderContentPack -Name "RSAT" -ContentType OS
```

* Borrar todos los directorios excepto `OSCapability`
* Copiar los ficheros de **RSAT** desde el ISO 1 de las Features on Demand
* Borrar los ficheros de las herramientas que no se necesiten (a excepción del directorio `metadata` y el fichero `FoDMetadata_Client.cab`)

> **Nota**: Aunque se pueden copiar a mano, el script `Copy-RSAT.ps1` permite importar FOD RSAT desde los DVDs de FOD.

```PowerShell
.\Z-Extra\Copy-RSAT.ps1 1909
.\Z-Extra\Copy-RSAT.ps1 2004
```

### OSDrivers/PEDrivers

[OSDrivers/PEDrivers](https://osdbuilder.osdeploy.com/docs/contentpacks/content/osdrivers-pedrivers) sirve para añadir drivers al SO y a Windows PE.

> **Nota**: Se recomienda no volverse loco y copiar *Driver Packs* completos. Es mejor copiar únicamente lo necesario.

### OSExtraFiles/PEExtraFiles

[OSExtraFiles/PEExtraFiles](https://osdbuilder.osdeploy.com/docs/contentpacks/content/osextrafiles-peextrafiles) sirve para añadir contenido extra en la raíz del SO y de Windows PE.

### OSPackages

[OSPackages](https://osdbuilder.osdeploy.com/docs/contentpacks/content/ospackages) no está explicado para qué sirve.

### OSPoshMods/PEPoshMods

[OSPoshMods/PEPoshMods](https://osdbuilder.osdeploy.com/docs/contentpacks/content/osposhmods-peposhmods) sirve para añadir módulos PowerShell al SO y a Windows PE. Se pueden añadir en el directorio `ProgramFiles` y en el directorio `System`.

* `<ContentPackDir>\OSPoshMods\ProgramFiles`: Añadir contenido en `\Program Files\WindowsPowerShell\Modules`
* `<ContentPackDir>\OSPoshMods\System`: Añadir contenido en `\Windows\System32\WindowsPowerShell\v1.0\Modules`

Por ejemplo, para instalar algunos módulos de la PowerShell Gallery, se podría ejecutar el siguiente script:

```PowerShell
# Módulo OSD de David Segura
Save-Module -Name OSD -Path V:\\OSDBuilder\\Share\\ContentPacks\_Global\OSPoshMods\ProgramFiles
Save-Module -Name OSD -Path V:\\OSDBuilder\\Share\\ContentPacks\_Global\PEPoshMods\ProgramFiles

# Módulo PackageManagement
Save-Module -Name PackageManagement -Path V:\OSDBuilder\Share\ContentPacks\_Global\OSPoshMods\ProgramFiles
Save-Module -Name PackageManagement -Path V:\OSDBuilder\Share\ContentPacks\_Global\PEPoshMods\ProgramFiles
```

### OSRegistry/PERegistry

[OSRegistry/PERegistry](https://osdbuilder.osdeploy.com/docs/contentpacks/content/osregistry-peregistry) sirve para añadir ficheros `*.reg` al SO y a Windows PE.

### OSScripts/PEScripts

[OSScripts/PEScripts](https://osdbuilder.osdeploy.com/docs/contentpacks/content/osscripts-pescripts) sirve para ejecutar scripts en el SO y en Windows PE.

### OSStartLayout

[OSStartLayout](https://osdbuilder.osdeploy.com/docs/contentpacks/content/osstartlayout) sirve para añadir un layout del *Menú de Inicio* en formato XML.

La documentación de Microsoft [Customize and export Start layout](https://docs.microsoft.com/en-us/windows/configuration/customize-and-export-start-layout) explica como configurar un menú en un equipo y exportarlo a formato XML y así poder usarlo en este ContentPack.

### PEADK

[PEADK](https://osdbuilder.osdeploy.com/docs/contentpacks/content/peadk) sirve para añadir los **WinPE OC** (componentes opcionales) y sus correspondientes lenguajes al entorno WinPE.

Hay que intentar que sean los mínimos posibles para que las imágenes WinPE, WinRE y WinSE sean lo más pequeñas posible.

Se consiguen desde el directorio `C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs` después de haber instalado [Windows ADK](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install).

Después hay que añadir los **LP** correspondientes (están en el ISO de LP, por ejemplo `F:\Windows Preinstallation Environment\x64\WinPE_OCs`):

```
WinPE-WMI (*)
WinPE-NetFX (*)
WinPE-Scripting (*)
WinPE-PowerShell (*)
WinPE-DismCmdlets (*)

WinPE-Dot3Svc.cab
WinPE-SecureStartup
WinPE-PlatformID
WinPE-SecureBootCmdlets
WinPE-StorageWMI
WinPE-WinReCfg
WinPE-Scripting
WinPE-SecureStartup
WinPE-EnhancedStorage
WinPE-FMAPI
WinPE-WDS-Tools
WinPE-HTA
WinPE-MDAC
```

La documentación de Microsoft tiene la [referencia completa de los paquetes WinPE disponibles](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-add-packages--optional-components-reference) para poder decidir cuáles se necesitan.

Aunque se pueden copiar a mano, el script `Copy-WinPEADK.ps1` permite copiar los ficheros desde el directorio de Windows ADK y el DVD de los LP:

```PowerShell
.\Z-Extra\Copy-WinPEADK.ps1 1909
.\Z-Extra\Copy-WinPEADK.ps1 2004
```

> **Nota**: Los ficheros copiados desde `C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment` correponderán a la versión de [Windows ADK](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install) instalada en el sistema, independientemente de la versión indicada como parámetro de los scripts anteriores.

### PEDaRT

Para añadir DaRT a Windows PE (añadir ficheros CAB de DaRT y el fichero `DartConfig.dat`).

## Multiple Languages

### OSLanguagePacks

Para copiar los [paquetes de lenguajes](https://osdbuilder.osdeploy.com/docs/contentpacks/multilang-content/oslanguagepacks) desde el ISO de los Language Packs, primero hay que crear la estructura correspondiente:

```PowerShell
New-OSDBuilderContentPack -Name "MultiLang ca-es" -ContentType MultiLang
New-OSDBuilderContentPack -Name "MultiLang fr-fr" -ContentType MultiLang
New-OSDBuilderContentPack -Name "MultiLang es-es" -ContentType MultiLang
New-OSDBuilderContentPack -Name "MultiLang en-us" -ContentType MultiLang
```

> **Nota**: Aunque se pueden copiar a mano, el script `Copy-Languages.ps1` permite copiar los ficheros desde el DVD de los LP.

```PowerShell
.\Z-Extra\Copy-Languages.ps1 1909
.\Z-Extra\Copy-Languages.ps1 2004
```

> **Nota**: Se han añadido los LXP según el artículo sobre las listas de lenguajes para "Display" y "Preferred" de [Patrick van den Born](http://patrickvandenborn.blogspot.com/2019/10/wvd-and-vdi-automation-change-in.html).

### OSLanguageFeatures

Para copiar las [FOD relacionados con los lenguajes](https://osdbuilder.osdeploy.com/docs/contentpacks/multilang-content/oslanguagefeatures) desde los ISO de los FOD, primero hay que crear la estructura correspondiente:

```PowerShell
New-OSDBuilderContentPack -Name "MultiLang ca-es" -ContentType MultiLang
New-OSDBuilderContentPack -Name "MultiLang fr-fr" -ContentType MultiLang
New-OSDBuilderContentPack -Name "MultiLang es-es" -ContentType MultiLang
New-OSDBuilderContentPack -Name "MultiLang en-us" -ContentType MultiLang
```

> **Nota**: Aunque se pueden copiar a mano, el script `Copy-LanguagesFOD.ps1` permite copiar los ficheros desde el DVD de los FOD.

```PowerShell
.\Z-Extra\Copy-LanguagesFOD.ps1 1909
.\Z-Extra\Copy-LanguagesFOD.ps1 2004
```

## Desinstalar OSDBuilder

Si por algún motivo es necesario desinstalar OSDBuilder y los módulos relacionados, se pueden ejecutar los siguientes comandos:

```PowerShell
Uninstall-Module -Name OSD -AllVersions -Force
Uninstall-Module -Name OSDSUS -AllVersions -Force
Uninstall-Module -Name OSDBuilder -AllVersions -Force
Uninstall-Module -Name OSDUpdate -AllVersions -Force
```

## Actualizar OSDBuilder

Durante la ejecución de OSDBuider, éste comprueba si existe una versión más actualizada de él mismo y de los módulos auxiliares.

En el siguiente ejemplo se está ejecutando OSDBuilder 20.7.6.1 y OSDSUS 20.9.8.1 cuando ya se había publicado la [versión 20.9.29.1 para soportar Windows 10 2009 (20H2)](https://twitter.com/SeguraOSD/status/1311012490910797824). OSDBuilder lo indica con unos mensajes de _warning_:

```
PS C:\WINDOWS\system32> Get-OSDBuilder                                                                                  VERBOSE: Initializing OSDBuilder ...
OSDBuilder 20.7.6.1 | OSDSUS 20.9.8.1 | OSD 20.8.19.1
Home            V:\OSDBuilder\Prod
-Content        V:\OSDBuilder\Share\Content
-ContentPacks   V:\OSDBuilder\Share\ContentPacks
-FeatureUpdates V:\OSDBuilder\Share\FeatureUpdates
-OSImport       V:\OSDBuilder\Share\OSImport
-OSMedia        V:\OSDBuilder\Share\OSMedia
-OSBuilds       V:\OSDBuilder\Prod\OSBuilds
-PEBuilds       V:\OSDBuilder\Prod\PEBuilds
-Mount          V:\OSDBuilder\Share\Mount
-Tasks          V:\OSDBuilder\Prod\Tasks
-Templates      V:\OSDBuilder\Prod\Templates
-Updates        V:\OSDBuilder\Share\Updates

WARNING: OSDBuilder can be updated to 20.9.29.1
OSDBuilder -Update

WARNING: OSDSUS can be updated to 20.9.29.1
Update-OSDSUS
```

En este caso hay que actualizar el módulo principal (OSDBuilder):

```PowerShell
OSDBuilder -Update
```

Este comando se encarga de desinstalar todos los módulos y de instalar los nuevos desde la PowerShell Gallery. Una vez finalizado el proceso es necesario reiniciar las sesiones de PowerShell para usar las nuevas versiones:

```
[...]
WARNING: Uninstall-Module -Name OSDSUS -AllVersions -Force
WARNING: Install-Module -Name OSDSUS -Force
WARNING: Import-Module -Name OSDSUS -Force
WARNING: Uninstall-Module -Name OSDBuilder -AllVersions -Force
WARNING: Remove-Module -Name OSDBuilder -Force
WARNING: Install-Module -Name OSDBuilder -Force
WARNING: Update-Module -Name -Force OSDSUS
WARNING: Import-Module -Name OSDSUS -Force
WARNING: Import-Module -Name OSDBuilder -Force
WARNING: Close all open PowerShell sessions before using OSDBuilder
```

> **Nota**: En otras ocasiones (como por ejemplo los _Patch Tuesday_) suele actualizarse únicamente el módulo OSD mediante el _cmdlet_ `Update-OSDSUS`.

Una vez reiniciado PowerShell se comprueba que las nuevas versiones ya están en uso:

```
PS C:\WINDOWS\system32> Get-OSDBuilder                                                                                  VERBOSE: Initializing OSDBuilder ...
OSDBuilder 20.9.29.1 | OSDSUS 20.9.29.1 | OSD 20.8.19.1
Home            V:\OSDBuilder\Prod
-Content        V:\OSDBuilder\Share\Content
-ContentPacks   V:\OSDBuilder\Share\ContentPacks
-FeatureUpdates V:\OSDBuilder\Share\FeatureUpdates
-OSImport       V:\OSDBuilder\Share\OSImport
-OSMedia        V:\OSDBuilder\Share\OSMedia
-OSBuilds       V:\OSDBuilder\Prod\OSBuilds
-PEBuilds       V:\OSDBuilder\Prod\PEBuilds
-Mount          V:\OSDBuilder\Share\Mount
-Tasks          V:\OSDBuilder\Prod\Tasks
-Templates      V:\OSDBuilder\Prod\Templates
-Updates        V:\OSDBuilder\Share\Updates
```

## Anexo

### Variables de OSDBuilder

Para obtener las variables de OSDBuilder en un fichero `*.json` que después se pueda utilizar en la configuración local se puede usar el siguiente comando:

```PowerShell
$SetOSDBuilder | ConvertTo-Json | Out-File 'V:\OSDBuilder\AllSettings.json'
```

### Desmontar imágenes WIM

Si en algún momento hay algún problema con las imágenes WIM y éstas se quedan montadas, impidiendo borrar algún directorio, se puede usar el siguiente comando:

```PowerShell
Get-WindowsImage -Mounted | Dismount-WindowsImage -Discard
```

### <a name="TLS12"></a>Usar TLS1.2 en PowerShell

Desde abril de 2020, [PowerShell Gallery únicamente soporta TLS 1.2](https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/) (TLS 1.0 y TLS 1.1 son obsoletos).

Por ese motivo, al intentar descargar módulos puede haber problemas (_Install-Package : No match was found..._) si no se especifica el protocolo correcto:

```PowerShell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

Si se quiere que [TLS 1.2 sea el cifrado por defecto en el SO,](https://twitter.com/manelrodero/status/1305409972759560198) se pueden cambiar estas claves del registro:

```PowerShell
# set strong cryptography on 64 bit .Net Framework (version 4 and above)
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord

# set strong cryptography on 32 bit .Net Framework (version 4 and above)
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord 
```

### Eliminar Aplicaciones Universales (AppX)

A la hora de decidir qué [aplicaciones universales AppX](https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10) se eliminan de las OSBuild pueden ser útiles las tablas de los artículos de [Anton Romanyuk (Vacuum Breather)](https://www.vacuumbreather.com/index.php/blog/item/87-windows-10-1903-built-in-apps-what-to-keep) y de [Mike Galvin](https://gal.vin/2017/04/06/removing-uwp-apps-mdt/).

En nuestro entorno se suelen eliminar las aplicaciones indicadas en la siguiente tabla:

| Paquete | Aplicación | Decisión | Notas |
| --- | --- | :---: | --- |
| Microsoft.549981C3F5F10 | Cortana | Conservar | Nueva en 2004|
| Microsoft.BingWeather | El Tiempo | Eliminar | |
| Microsoft.DesktopAppInstaller | Instalador de aplicación | Conservar | |
| Microsoft.GetHelp | Obtener ayuda | Eliminar | |
| Microsoft.Getstarted | Recomendaciones | Eliminar | |
| Microsoft.HEIFImageExtension | Extensiones de imagen HEIF | Conservar | |
| Microsoft.Messaging | Mensajes | Eliminar | Eliminada en 2004 |
| Microsoft.Microsoft3DViewer | Visor 3D | Eliminar | |
| Microsoft.MicrosoftOfficeHub | Office | Eliminar | |
| Microsoft.MicrosoftSolitaireCollection | Microsoft Solitaire Collection | Eliminar | |
| Microsoft.MicrosoftStickyNotes | Sticky Notes | Conservar | |
| Microsoft.MixedReality.Portal | Portal de realidad mixta | Eliminar | |
| Microsoft.MSPaint | Paint 3D | Eliminar | |
| Microsoft.Office.OneNote | OneNote | Eliminar | |
| Microsoft.OneConnect | Planes móviles | Eliminar | Eliminada en 2004 |
| Microsoft.People | Contactos | Eliminar | |
| Microsoft.Print3D | Print 3D | Eliminar | Eliminada en 2004 |
| Microsoft.ScreenSketch | Recorte y anotación | Conservar | |
| Microsoft.SkypeApp | Skype | Eliminar | |
| Microsoft.StorePurchaseApp | Store Purchase App | Conservar | |
| Microsoft.VCLibs.140.00 | C++ Runtime for Desktop Bridge | Conservar | Nueva en 2004 |
| Microsoft.VP9VideoExtensions | VP9 Video Extensions | Conservar | |
| Microsoft.Wallet | Microsoft Pay | Eliminar | |
| Microsoft.WebMediaExtensions | Extensiones de multimedia web | Conservar | |
| Microsoft.WebpImageExtension | Extensiones de imagen Webp | Conservar | |
| Microsoft.Windows.Photos | Fotos | Conservar | |
| Microsoft.WindowsAlarms | Alarmas y reloj | Conservar | |
| Microsoft.WindowsCalculator | Calculadora | Conservar | |
| Microsoft.WindowsCamera | Cámara | Conservar | |
| microsoft.windowscommunicationsapps | Correo y Calendario | Eliminar | |
| Microsoft.WindowsFeedbackHub | Centro de opiniones | Eliminar | Opcional |
| Microsoft.WindowsMaps | Mapas | Eliminar | |
| Microsoft.WindowsSoundRecorder | Grabadora de voz | Conservar | |
| Microsoft.WindowsStore | Microsoft Store | Conservar | |
| Microsoft.Xbox.TCUI | Experiencia de Xbox Live en el juego | Eliminar | |
| Microsoft.XboxApp | Xbox Console Companion | Eliminar | |
| Microsoft.XboxGameOverlay | Complemento de la barra de juego Xbox | Eliminar | |
| Microsoft.XboxGamingOverlay | Barra de juego de Xbox | Eliminar | |
| Microsoft.XboxIdentityProvider | Proveedor de identidades de Xbox | Eliminar | |
| Microsoft.XboxSpeechToTextOverlay | n/a | Eliminar | |
| Microsoft.YourPhone | Tu Teléfono | Eliminar | |
| Microsoft.ZuneMusic | Groove Música | Eliminar | |
| Microsoft.ZuneVideo | Películas y TV | Eliminar | |

## Opciones a explorar

A la hora de habilitar/deshabilitar características de Windows se podrían explorar las siguientes opciones:

* Deshabilitar [Internet Explorer](https://support.microsoft.com/en-us/help/4013567/how-to-disable-internet-explorer-on-windows)
* Habilitar [Windows Defender Application Guard (WDAG)](https://docs.microsoft.com/es-es/windows/security/threat-protection/microsoft-defender-application-guard/reqs-md-app-guard)
