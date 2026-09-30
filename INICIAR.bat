@echo off
setlocal
cd /d "%~dp0"
title JARC'S EYE View

echo ============================================
echo    JARC'S EYE View - iniciando...
echo ============================================
echo.

REM 1) Crear entorno virtual e instalar dependencias si no existe
if not exist ".venv\Scripts\python.exe" (
    echo [1/4] Creando entorno virtual e instalando dependencias...
    py -m venv .venv
    ".venv\Scripts\python.exe" -m pip install --upgrade pip
    ".venv\Scripts\python.exe" -m pip install -r "backend\requirements.txt"
    echo.
)

REM 2) Crear .env desde la plantilla si no existe
if not exist ".env" (
    if exist ".env.example" copy ".env.example" ".env" >nul
    echo [AVISO] Se creo .env desde la plantilla. Edita .env y pon tus claves antes de usar todo.
    echo.
)

REM 3) Liberar el puerto 8000 SOLO si lo ocupa una instancia previa de esta app (backend.main:app).
REM    Si es otro programa, no se toca: se avisa y uvicorn fallara al arrancar.
echo [2/4] Comprobando el puerto 8000...
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $own = { param($id) $p = Get-CimInstance Win32_Process -Filter ('ProcessId=' + $id); if (-not $p) { return $false }; if ($p.CommandLine -like '*backend.main:app*') { return $true }; $pp = Get-CimInstance Win32_Process -Filter ('ProcessId=' + $p.ParentProcessId); return [bool]($pp -and $pp.CommandLine -like '*backend.main:app*') }; Get-NetTCPConnection -LocalPort 8000 -State Listen | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { if (& $own $_) { Stop-Process -Id $_ -Force; Write-Host ('  Cerrada instancia previa (PID ' + $_ + ')') } else { Write-Host ('  [AVISO] El puerto 8000 lo usa otro programa (PID ' + $_ + '). No se cierra.') } }"

REM 4) Abrir el navegador tras 3s (mientras arranca el servidor)
echo [3/4] Abriendo http://localhost:8000 en el navegador...
start "" /min cmd /c "timeout /t 3 /nobreak >nul && explorer http://localhost:8000"

echo [4/4] Iniciando servidor (auto-recarga activada). Cierra esta ventana o pulsa Ctrl+C para detener.
echo.
".venv\Scripts\python.exe" -m uvicorn backend.main:app --port 8000 --reload --reload-dir backend

echo.
echo El servidor se detuvo.
pause
