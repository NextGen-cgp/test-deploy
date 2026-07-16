@echo off
setlocal enableextensions

set "PS_EXE=%windir%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%windir%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PS_EXE=%windir%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

set "REG_EXE=%windir%\System32\reg.exe"
if exist "%windir%\Sysnative\reg.exe" set "REG_EXE=%windir%\Sysnative\reg.exe"

set "BASE_URL=https://raw.githubusercontent.com/NextGen-cgp/test-deploy/main"
set "WORKDIR=%ProgramData%\Clarel\InvGate\FortiClient_7.4.3"

set "INSTALLER=%WORKDIR%\FortiClientVPN_7.4.3.msi"
set "VPN_REG=%WORKDIR%\VPNConfig.reg"

set "LOG_FILE=%WORKDIR%\install.log"
set "FORTI_LOG=%WORKDIR%\forticlient_install.log"

set "DETECTION_KEY=HKLM\SOFTWARE\Clarel\SoftwareDeployments\FortiClient_7.4.3"
set "DETECTION_VALUE=Installed"

if not exist "%WORKDIR%" mkdir "%WORKDIR%"

echo [%date% %time%] Inicio despliegue FortiClient VPN 7.4.3 > "%LOG_FILE%"

"%REG_EXE%" query "%DETECTION_KEY%" /v "%DETECTION_VALUE%" >nul 2>&1

if %errorlevel%==0 (
    echo [%date% %time%] FortiClient VPN 7.4.3 ya estaba instalado. >> "%LOG_FILE%"
    exit /b 0
)

echo [%date% %time%] Descargando FortiClientVPN_7.4.3.msi... >> "%LOG_FILE%"

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
  "Invoke-WebRequest -UseBasicParsing -Uri '%BASE_URL%/FortiClientVPN_7.4.3.msi' -OutFile '%INSTALLER%'" >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo [%date% %time%] Error descargando FortiClientVPN_7.4.3.msi. >> "%LOG_FILE%"
    exit /b 10
)

echo [%date% %time%] Descargando VPNConfig.reg... >> "%LOG_FILE%"

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
  "Invoke-WebRequest -UseBasicParsing -Uri '%BASE_URL%/VPNConfig.reg' -OutFile '%VPN_REG%'" >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo [%date% %time%] Error descargando VPNConfig.reg. >> "%LOG_FILE%"
    exit /b 11
)

echo [%date% %time%] Instalando FortiClient VPN... >> "%LOG_FILE%"

msiexec.exe /i "%INSTALLER%" /qn /norestart REBOOT=ReallySuppress /L*v "%FORTI_LOG%"
set "INSTALL_RESULT=%errorlevel%"

if not "%INSTALL_RESULT%"=="0" if not "%INSTALL_RESULT%"=="3010" (
    echo [%date% %time%] Error instalando FortiClient VPN. Codigo: %INSTALL_RESULT% >> "%LOG_FILE%"
    exit /b 20
)

echo [%date% %time%] Importando configuracion VPN... >> "%LOG_FILE%"

"%REG_EXE%" import "%VPN_REG%" >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo [%date% %time%] Error importando VPNConfig.reg. >> "%LOG_FILE%"
    exit /b 30
)

"%REG_EXE%" add "%DETECTION_KEY%" /v "%DETECTION_VALUE%" /t REG_SZ /d "1" /f >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo [%date% %time%] Error creando la clave de deteccion. >> "%LOG_FILE%"
    exit /b 40
)

echo [%date% %time%] FortiClient VPN 7.4.3 instalado y configurado correctamente. >> "%LOG_FILE%"

exit /b 0
