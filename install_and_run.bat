@echo off
setlocal EnableDelayedExpansion
title OmniVoice - Local AI Voice Cloning

:: =============================================
:: OmniVoice Single-Click Installer & Launcher
:: https://huggingface.co/k2-fsa/OmniVoice
::
:: - Auto-detects NVIDIA / AMD / Intel GPU
:: - Gradio binds to 127.0.0.1 ONLY (local)
:: - Re-run anytime: install is skipped if done
:: =============================================

:: Capture script directory - handles spaces in path
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "VENV_DIR=%SCRIPT_DIR%\.venv"
set "SENTINEL=%SCRIPT_DIR%\.installed"
set "LOG_FILE=%SCRIPT_DIR%\install_log.txt"
set "GPU_TIER=CPU"
set "PORT=7860"

echo.
echo  =============================================
echo   OmniVoice - Zero-Shot Voice Cloning
echo   https://huggingface.co/k2-fsa/OmniVoice
echo  =============================================
echo.

:: =============================================
:: SECTION 1: Python Version Check
:: =============================================
echo [1/8] Checking Python installation...

python --version >nul 2>&1
if errorlevel 1 goto :NO_PYTHON

for /f "tokens=2 delims= " %%V in ('python --version 2^>^&1') do set "PY_VER=%%V"
for /f "tokens=1 delims=." %%A in ("!PY_VER!") do set "PY_MAJOR=%%A"
for /f "tokens=2 delims=." %%B in ("!PY_VER!") do set "PY_MINOR=%%B"

if !PY_MAJOR! LSS 3 goto :WRONG_PYTHON
if !PY_MAJOR! EQU 3 if !PY_MINOR! LSS 10 goto :WRONG_PYTHON
echo    Python !PY_VER! - OK

:: =============================================
:: SECTION 2: Sentinel Check (Skip Reinstall)
:: =============================================
if exist "%SENTINEL%" (
    echo.
    echo  [INFO] OmniVoice already installed - skipping to launch.
    echo         Delete "%SENTINEL%" to force reinstallation.
    echo.
    for /f "tokens=2 delims==" %%T in ('findstr /b "GPU_TIER" "%SENTINEL%" 2^>nul') do set "GPU_TIER=%%T"
    goto :FIND_PORT
)
echo    First-time installation - proceeding with setup.

:: =============================================
:: SECTION 3: Virtual Environment Setup
:: =============================================
echo.
echo [2/8] Setting up virtual environment...
if exist "%VENV_DIR%\Scripts\python.exe" (
    echo    Existing .venv found - reusing.
) else (
    python -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo.
        echo  ERROR: Failed to create virtual environment.
        echo  Try: python -m pip install --upgrade virtualenv
        pause
        exit /b 1
    )
    echo    Created .venv in: %VENV_DIR%
)

echo.
echo [3/8] Upgrading pip...
"%VENV_DIR%\Scripts\python.exe" -m pip install --upgrade pip --quiet >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo    WARNING: pip upgrade skipped - continuing with existing version.
) else (
    echo    pip is up to date.
)

:: =============================================
:: SECTION 4: GPU Detection (3-tier)
:: =============================================
echo.
echo [4/8] Detecting GPU hardware...
set "DRV_MAJOR=0"
set "NVIDIA_SMI_CMD="

:: --- NVIDIA: check nvidia-smi ---
where nvidia-smi >nul 2>&1
if not errorlevel 1 set "NVIDIA_SMI_CMD=nvidia-smi"
if not defined NVIDIA_SMI_CMD (
    if exist "%SystemRoot%\System32\nvidia-smi.exe" set "NVIDIA_SMI_CMD=%SystemRoot%\System32\nvidia-smi.exe"
)

if defined NVIDIA_SMI_CMD (
    :: Query driver version - output is e.g. "570.86.15"
    :: tokens=1 delims=. extracts the major part (570)
    for /f "usebackq tokens=1 delims=." %%D in (`"!NVIDIA_SMI_CMD!" --query-gpu=driver_version --format=csv^,noheader 2^>nul`) do (
        set "DRV_MAJOR=%%D"
        goto :CHECK_NVIDIA_VER
    )
)
goto :CHECK_DX12

:CHECK_NVIDIA_VER
echo    NVIDIA GPU detected ^(driver: !DRV_MAJOR!.x^)
:: CUDA 12.8 requires driver >= 570 (Blackwell/Ada Lovelace)
if !DRV_MAJOR! GEQ 570 (
    set "GPU_TIER=NVIDIA"
    echo    Driver supports CUDA 12.8 - using NVIDIA CUDA acceleration.
    goto :INSTALL_TORCH
)
echo    Driver !DRV_MAJOR! is below 570 - CUDA 12.8 not supported.
echo    Update drivers at: https://www.nvidia.com/drivers
echo    Checking DirectX 12 fallback...

:CHECK_DX12
:: Use PowerShell Win32_VideoController (wmic deprecated in Win11 24H2+)
:: Exclude NVIDIA (handled above), Microsoft (Basic Display), VMware/VirtualBox (VMs)
set "NON_NVIDIA_GPU="
for /f "usebackq tokens=*" %%G in (`powershell -NoProfile -Command "try { $g = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -notmatch 'NVIDIA|Microsoft|VMware|VirtualBox|Basic Display' } | Select-Object -First 1 -ExpandProperty Name; if ($g) { $g } } catch {}" 2^>nul`) do (
    set "NON_NVIDIA_GPU=%%G"
)

if defined NON_NVIDIA_GPU (
    set "GPU_TIER=DX12"
    echo    GPU detected: !NON_NVIDIA_GPU!
    echo    Using torch-directml for DirectX 12 acceleration.
    goto :INSTALL_TORCH
)

echo    No compatible GPU found - using CPU mode.

:: =============================================
:: SECTION 5: PyTorch Installation
:: =============================================
:INSTALL_TORCH
echo.
echo [5/8] Installing PyTorch ^(!GPU_TIER! mode^)...

if "!GPU_TIER!"=="NVIDIA" (
    echo    Fetching PyTorch 2.8.0 + CUDA 12.8 build ^(~2.5 GB download^)...
    "%VENV_DIR%\Scripts\pip.exe" install torch==2.8.0+cu128 torchaudio==2.8.0+cu128 --extra-index-url https://download.pytorch.org/whl/cu128 --no-warn-script-location >> "%LOG_FILE%" 2>&1
    if not errorlevel 1 (
        echo    PyTorch CUDA installed.
        goto :INSTALL_OMNIVOICE
    )
    echo    CUDA install failed - falling back to CPU build. See install_log.txt
    set "GPU_TIER=CPU"
)

if "!GPU_TIER!"=="DX12" (
    echo    Installing PyTorch CPU base + torch-directml...
    "%VENV_DIR%\Scripts\pip.exe" install torch==2.8.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cpu --no-warn-script-location >> "%LOG_FILE%" 2>&1
    if errorlevel 1 goto :TORCH_FAIL
    "%VENV_DIR%\Scripts\pip.exe" install torch-directml --no-warn-script-location >> "%LOG_FILE%" 2>&1
    if errorlevel 1 (
        echo    torch-directml unavailable - running in CPU mode.
        set "GPU_TIER=CPU"
    ) else (
        echo    DirectX 12 GPU acceleration enabled.
    )
    goto :INSTALL_OMNIVOICE
)

:: CPU fallback (GPU_TIER=CPU from detection or after failed NVIDIA/DX12)
echo    Installing PyTorch 2.8.0 CPU build...
"%VENV_DIR%\Scripts\pip.exe" install torch==2.8.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cpu --no-warn-script-location >> "%LOG_FILE%" 2>&1
if errorlevel 1 goto :TORCH_FAIL
echo    PyTorch CPU installed.

:: =============================================
:: SECTION 6: OmniVoice Package
:: =============================================
:INSTALL_OMNIVOICE
echo.
echo [6/8] Installing OmniVoice...
"%VENV_DIR%\Scripts\pip.exe" install omnivoice --no-warn-script-location >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo.
    echo  ERROR: OmniVoice installation failed.
    echo  Check your internet connection.
    echo  Details: "%LOG_FILE%"
    pause
    exit /b 1
)
echo    OmniVoice installed.

:: =============================================
:: SECTION 7: Model Pre-download
:: =============================================
:PRELOAD_MODEL
echo.
echo [7/8] Downloading OmniVoice model weights...
echo    First run: approx. 3-4 GB - may take 10-30 minutes.
echo    Subsequent runs skip this step automatically.
echo    Cache: %USERPROFILE%\.cache\huggingface\hub
echo.

"%VENV_DIR%\Scripts\python.exe" "%SCRIPT_DIR%\_preload_model.py"
if errorlevel 1 (
    echo.
    echo  ERROR: Model download failed.
    echo  Common causes:
    echo    - No internet connection
    echo    - Insufficient disk space ^(need ~4 GB free^)
    echo    - HuggingFace temporarily unreachable
    echo.
    echo  Re-run this file to resume - downloads are resumable.
    echo  If HuggingFace is blocked in your region, run this first:
    echo    set HF_ENDPOINT=https://hf-mirror.com
    echo.
    pause
    exit /b 1
)
echo    Model ready.

:: =============================================
:: SECTION 8: Write Sentinel + Find Free Port
:: =============================================
> "%SENTINEL%" echo GPU_TIER=!GPU_TIER!
>> "%SENTINEL%" echo INSTALLED_DATE=%DATE% %TIME%
>> "%SENTINEL%" echo PYTHON_VER=!PY_VER!
echo.
echo    Installation complete.

:FIND_PORT
echo [8/8] Finding available port...
set "PORT=7860"

:PORT_LOOP
netstat -an 2>nul | findstr "LISTENING" | findstr ":!PORT! " >nul 2>&1
if not errorlevel 1 (
    echo    Port !PORT! in use - trying next...
    set /a PORT+=1
    if !PORT! GTR 7869 (
        echo.
        echo  ERROR: Ports 7860-7869 are all in use.
        echo  Close other applications and try again.
        pause
        exit /b 1
    )
    goto :PORT_LOOP
)
echo    Port !PORT! available.

:: =============================================
:: SECTION 9: Launch Gradio (localhost only)
:: =============================================
:LAUNCH
echo.
echo  =============================================
echo   Starting OmniVoice on port !PORT!
echo   URL:  http://127.0.0.1:!PORT!
echo   GPU:  !GPU_TIER!
echo.
echo   Browser opens automatically in ~8 seconds.
echo   Press Ctrl+C to stop the server.
echo  =============================================
echo.

:: Open browser after delay (server needs ~5-8s to load model)
start "" powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Seconds 8; Start-Process 'http://127.0.0.1:!PORT!'"

:: SECURITY: --ip 127.0.0.1 binds Gradio to localhost ONLY
:: This prevents ANY exposure to LAN or internet
"%VENV_DIR%\Scripts\omnivoice-demo.exe" --ip 127.0.0.1 --port !PORT! 2>>"%LOG_FILE%"
if errorlevel 1 (
    :: Fallback if .exe wrapper missing (editable / dev install)
    "%VENV_DIR%\Scripts\python.exe" -m omnivoice.cli.demo --ip 127.0.0.1 --port !PORT! 2>>"%LOG_FILE%"
)

echo.
echo  OmniVoice stopped.
pause
exit /b 0

:: =============================================
:: ERROR HANDLERS (only reached via goto)
:: =============================================

:NO_PYTHON
echo.
echo  ERROR: Python was not found in PATH.
echo.
echo  Install Python 3.10 or higher from:
echo    https://www.python.org/downloads/
echo.
echo  IMPORTANT: During installation, check:
echo    [x] Add Python to PATH
echo.
pause
exit /b 1

:WRONG_PYTHON
echo.
echo  ERROR: Python !PY_VER! is too old.
echo  OmniVoice requires Python 3.10 or higher.
echo.
echo  Install Python 3.10+ from:
echo    https://www.python.org/downloads/
echo.
pause
exit /b 1

:TORCH_FAIL
echo.
echo  ERROR: PyTorch installation failed.
echo  Check your internet connection.
echo  Details: "%LOG_FILE%"
echo.
pause
exit /b 1
