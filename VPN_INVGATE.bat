@echo off
setlocal enableextensions

set "PS_EXE=%windir%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%windir%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PS_EXE=%windir%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

set "REG_EXE=%windir%\System32\reg.exe"
if exist "%windir%\Sysnative\reg.exe" set "REG_EXE=%windir%\Sysnative\reg.exe"

set "BASE_URL=https://raw.githubusercontent.com/NextGen-cgp/test-deploy/main"
set "WORKDIR=%ProgramData%\Clarel\InvGate\02VPN"
set "CONF_FILE=%WORKDIR%\FortiClient_02_VPN_USERS_CLAREL.xml"
set "LOG_FILE=%WORKDIR%\install.log"

set "DETECTION_KEY=HKLM\SOFTWARE\Dia-SCCM\02_VPN_USERS_CLAREL_VDF"
set "DETECTION_VALUE=Installed"

set "FCCONFIG=%ProgramFiles%\Fortinet\FortiClient\FCConfig.exe"
if not exist "%FCCONFIG%" set "FCCONFIG=%ProgramFiles(x86)%\Fortinet\FortiClient\FCConfig.exe"

if not exist "%WORKDIR%" mkdir "%WORKDIR%"

echo [%date% %time%] Inicio despliegue VPN > "%LOG_FILE%"

"%REG_EXE%" query "%DETECTION_KEY%" /v "%DETECTION_VALUE%" >> "%LOG_FILE%" 2>&1
if %errorlevel%==0 (
    echo [%date% %time%] Ya estaba aplicada. >> "%LOG_FILE%"
    exit /b 0
)

if not exist "%FCCONFIG%" (
    echo [%date% %time%] No se encontro FCConfig.exe >> "%LOG_FILE%"
    exit /b 20
)

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
  "Invoke-WebRequest -UseBasicParsing -Uri '%BASE_URL%/FortiClient_02_VPN_USERS_CLAREL.xml' -OutFile '%CONF_FILE%'" >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo [%date% %time%] Error descargando XML desde GitHub >> "%LOG_FILE%"
    exit /b 10
)

"%FCCONFIG%" -m all -f "%CONF_FILE%" -o import -i 1 -p "12345678" >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo [%date% %time%] Error importando VPN con FCConfig >> "%LOG_FILE%"
    exit /b 30
)

"%REG_EXE%" add "%DETECTION_KEY%" /v "%DETECTION_VALUE%" /t REG_SZ /d "1" /f >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo [%date% %time%] Error creando clave de deteccion >> "%LOG_FILE%"
    exit /b 40
)

echo [%date% %time%] VPN importada correctamente >> "%LOG_FILE%"
exit /b 0
exit /b 0
