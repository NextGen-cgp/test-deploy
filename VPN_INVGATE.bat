@echo off
setlocal enableextensions

REM 1. URL base de GitHub RAW
set "BASE_URL=https://raw.githubusercontent.com/NextGen-cgp/test-deploy/main"

REM 2. Carpeta local de trabajo
set "WORKDIR=%ProgramData%\Clarel\InvGate\02VPN"

REM 3. Ruta local donde se guardara el .reg descargado
set "REG_FILE=%WORKDIR%\VPN_USERS_CLAREL_FORTI.reg"

REM 4. Crear carpeta local si no existe
if not exist "%WORKDIR%" mkdir "%WORKDIR%"

REM 5. Descargar el .reg desde GitHub a la carpeta local
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
  "Invoke-WebRequest -UseBasicParsing -Uri '%BASE_URL%/VPN_USERS_CLAREL_FORTI.reg' -OutFile '%REG_FILE%'"

if errorlevel 1 (
    echo Error descargando VPN_USERS_CLAREL_FORTI.reg desde GitHub
    exit /b 10
)

REM 6. Importar el .reg ya descargado
reg.exe import "%REG_FILE%"

if errorlevel 1 (
    echo Error importando VPN_USERS_CLAREL_FORTI.reg
    exit /b 20
)

REM 7. Crear clave de deteccion
reg.exe add "HKLM\SOFTWARE\Dia-SCCM\02_VPN_USERS_CLAREL_VDF" /v Installed /t REG_SZ /d "1" /f

if errorlevel 1 (
    echo Error creando clave de deteccion
    exit /b 30
)

echo Configuracion VPN importada correctamente
exit /b 0