@echo off
setlocal EnableDelayedExpansion
title OmniVoice - Local AI Voice Cloning

:: =============================================
:: OmniVoice Launcher
:: by sureshpydikondala
:: https://huggingface.co/k2-fsa/OmniVoice
::
:: Run this after setup.bat has been completed.
:: Gradio binds to 127.0.0.1 ONLY (local).
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
echo  +==========================================+
echo  ^|   OmniVoice - Zero-Shot Voice Cloning   ^|
echo  ^|   by sureshpydikondala                  ^|
echo  ^|   https://huggingface.co/k2-fsa/OmniVoice ^|
echo  +==========================================+
echo.

:: =============================================
:: Check installation sentinel
:: =============================================
if not exist "%SENTINEL%" (
    echo  ERROR: OmniVoice is not installed yet.
    echo.
    echo  Please run setup.bat first to install OmniVoice.
    echo.
    pause
    exit /b 1
)

for /f "tokens=2 delims==" %%T in ('findstr /b "GPU_TIER" "%SENTINEL%" 2^>nul') do set "GPU_TIER=%%T"
echo  Installation detected ^(GPU: !GPU_TIER!^)

:: =============================================
:: Find available port
:: =============================================
echo.
echo  Finding available port...
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
:: Launch Gradio (localhost only)
:: =============================================
echo.
echo  +==========================================+
echo  ^|   OmniVoice is starting...               ^|
echo  ^|   URL : http://127.0.0.1:!PORT!          ^|
echo  ^|   GPU : !GPU_TIER!                       ^|
echo  ^|                                          ^|
echo  ^|   Browser opens in ~8 seconds            ^|
echo  ^|   Press Ctrl+C to stop                  ^|
echo  +==========================================+
echo.

:: Open browser after delay (server needs ~5-8s to load model)
start "" powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Seconds 8; Start-Process 'http://127.0.0.1:!PORT!'"

:: SECURITY: --ip 127.0.0.1 binds Gradio to localhost ONLY
"%VENV_DIR%\Scripts\omnivoice-demo.exe" --ip 127.0.0.1 --port !PORT! 2>>"%LOG_FILE%"
if errorlevel 1 (
    :: Fallback if .exe wrapper missing (editable / dev install)
    "%VENV_DIR%\Scripts\python.exe" -m omnivoice.cli.demo --ip 127.0.0.1 --port !PORT! 2>>"%LOG_FILE%"
)

echo.
echo  OmniVoice stopped.
pause
exit /b 0
