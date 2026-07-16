@echo off
setlocal enableextensions

set "BASE_URL=https://github.com/NextGen-cgp/test-deploy/releases/download/v7.4.3"

set "WORKDIR=%ProgramData%\Clarel\InvGate\FortiClient_7.4.3"
set "INSTALLER=%WORKDIR%\Forti_Enterprise_7.4.3.msi"
set "VPN_REG=%WORKDIR%\VPNConfig.reg"

set "LOG_FILE=%WORKDIR%\install.log"
set "FORTI_LOG=%WORKDIR%\forticlient_install.log"

set "DETECTION_KEY=HKLM\SOFTWARE\Clarel\SoftwareDeployments\FortiClient_7.4.3"
set "DETECTION_VALUE=Installed"

if not exist "%WORKDIR%" mkdir "%WORKDIR%"

echo [%date% %time%] Inicio despliegue FortiClient VPN 7.4.3 > "%LOG_FILE%"

rem Comprobar si el despliegue ya se realizo
reg query "%DETECTION_KEY%" /v "%DETECTION_VALUE%" >nul 2>&1

if %errorlevel%==0 (
    echo [%date% %time%] FortiClient VPN 7.4.3 ya estaba instalado. >> "%LOG_FILE%"
    exit /b 0
)

rem Eliminar posibles descargas anteriores
if exist "%INSTALLER%" del /q "%INSTALLER%"
if exist "%VPN_REG%" del /q "%VPN_REG%"

rem Descargar el instalador MSI
echo [%date% %time%] Descargando Forti_Enterprise_7.4.3.msi... >> "%LOG_FILE%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing -Uri '%BASE_URL%/Forti_Enterprise_7.4.3.msi' -OutFile '%INSTALLER%'" >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo [%date% %time%] Error descargando Forti_Enterprise_7.4.3.msi. >> "%LOG_FILE%"
    exit /b 10
)

rem Descargar la configuracion VPN
echo [%date% %time%] Descargando VPNConfig.reg... >> "%LOG_FILE%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing -Uri '%BASE_URL%/VPNConfig.reg' -OutFile '%VPN_REG%'" >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo [%date% %time%] Error descargando VPNConfig.reg. >> "%LOG_FILE%"
    exit /b 11
)

rem Instalar FortiClient VPN silenciosamente
echo [%date% %time%] Instalando FortiClient VPN... >> "%LOG_FILE%"

msiexec.exe /i "%INSTALLER%" /qn /norestart REBOOT=ReallySuppress /L*v "%FORTI_LOG%"
set "INSTALL_RESULT=%errorlevel%"

if not "%INSTALL_RESULT%"=="0" if not "%INSTALL_RESULT%"=="3010" (
    echo [%date% %time%] Error instalando FortiClient VPN. Codigo: %INSTALL_RESULT% >> "%LOG_FILE%"
    exit /b 20
)

echo [%date% %time%] FortiClient VPN instalado correctamente. Codigo: %INSTALL_RESULT% >> "%LOG_FILE%"

rem Importar la configuracion VPN
echo [%date% %time%] Importando VPNConfig.reg... >> "%LOG_FILE%"

reg import "%VPN_REG%" >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo [%date% %time%] Error importando VPNConfig.reg. >> "%LOG_FILE%"
    exit /b 30
)

rem Crear la clave de validacion
reg add "%DETECTION_KEY%" /v "%DETECTION_VALUE%" /t REG_SZ /d "1" /f >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo [%date% %time%] Error creando la clave de validacion. >> "%LOG_FILE%"
    exit /b 40
)

echo [%date% %time%] Despliegue completado correctamente. >> "%LOG_FILE%"

exit /b 0
