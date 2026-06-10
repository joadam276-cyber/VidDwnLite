@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "BIN_DIR=%~dp0bin"
set "PATH=%BIN_DIR%;%PATH%"
title Video Downloader by Dr Software (Lite)

set "OUT_DIR=Downloads"
if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"

set "MISSING_FILES=0"
if not exist "!BIN_DIR!\yt-dlp.exe" set "MISSING_FILES=1"
if not exist "!BIN_DIR!\ffmpeg.exe" set "MISSING_FILES=1"
if not exist "!BIN_DIR!\qjs.exe" set "MISSING_FILES=1"
if "!MISSING_FILES!"=="1" goto show_error
cls
color 0E
echo ======================================================================================
echo   Checking for updates... Please wait...
echo ======================================================================================
"!BIN_DIR!\yt-dlp.exe" -U
goto download_menu

:show_error
cls
color 0C
echo ======================================================================================
echo  [ CRITICAL ERROR: REQUIRED CORE FILES NOT FOUND ]
echo ======================================================================================
echo  Please download the missing dependencies and place them inside the 'bin' folder:
echo.
echo  1. Downloader Core (yt-dlp.exe):
echo     https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe
echo     (Move 'yt-dlp.exe' directly into the 'bin' folder)
echo.
echo  2. Video Processing Tools (ffmpeg.exe ^& ffprobe.exe):
echo     https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n8.1-latest-win64-gpl-8.1.zip
echo     (Extract and move 'ffmpeg.exe' and 'ffprobe.exe' into the 'bin' folder)
echo.
echo  3. JavaScript Runtime Core (qjs.exe ^& DLL):
echo     https://bellard.org/quickjs/binary_releases/quickjs-win-x86_64-2026-06-04.zip
echo     (Extract and move 'qjs.exe' and 'libwinpthread-1.dll' into the 'bin' folder)
echo --------------------------------------------------------------------------------------
echo  Target Path: "!BIN_DIR!"
echo ======================================================================================
echo.
pause
exit /b

:download_menu
set "url="
cls
color 0B
echo ======================================================================================
echo        Dr Software Video Downloader - Ultimate Lite Edition (Powered by yt-dlp)
echo ======================================================================================
echo.
echo  [Tip: You can paste the link or drag-and-drop the URL here directly]
echo.
set /p url=" -> Enter Video URL (or type 'X' to exit): "

if not defined url goto download_menu
set "url=!url:"=!"
if /i "!url!"=="x" exit /b

echo !url! | findstr /i "^http" >nul
if errorlevel 1 goto download_menu

:choose_video_quality
cls
color 0E
echo ======================================================================================
echo                            Select Video Resolution
echo ======================================================================================
echo  URL: !url!
echo --------------------------------------------------------------------------------------
echo  [1] Best Available Quality (Up to 4K / 8K)
echo  [2] 1080p FHD (High Quality)
echo  [3] 720p HD (Balanced - Optimized for space)
echo  [4] 480p SD (Optimized for data and space)
echo  [5] Best Quality Audio Only (MP3 320k)

echo --------------------------------------------------------------------------------------
set "res_opt="
set /p res_opt=" -> Choose an option: "

if not defined res_opt goto choose_video_quality

if "!res_opt!"=="5" (
    cls
    echo ======================================================================================
    echo   Processing Audio Download... Please wait...
    echo ======================================================================================
    "!BIN_DIR!\yt-dlp.exe" --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" -x --audio-format mp3 --audio-quality 0 --ffmpeg-location "!BIN_DIR!" --downloader-args "ffmpeg:-hwaccel d3d11va" -o "!OUT_DIR!/%%(title)s.%%(ext)s" "!url!"
    if errorlevel 1 goto dl_error
    goto finish_dl
)

if "!res_opt!"=="1" set "format_str=bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]"
if "!res_opt!"=="2" set "format_str=bv*[height<=?1080][ext=mp4][vcodec^=avc1]+ba[ext=m4a]/b[height<=?1080][ext=mp4][vcodec^=avc1]"
if "!res_opt!"=="3" set "format_str=bv*[height<=?720][ext=mp4][vcodec^=avc1]+ba[ext=m4a]/b[height<=?720][ext=mp4][vcodec^=avc1]"
if "!res_opt!"=="4" set "format_str=bv*[height<=?480][ext=mp4][vcodec^=avc1]+ba[ext=m4a]/b[height<=?480][ext=mp4][vcodec^=avc1]"
if not defined format_str goto choose_video_quality

cls
echo.
echo ======================================================================================
echo   Processing download and fetching subtitles... Please wait...
echo ======================================================================================

"!BIN_DIR!\yt-dlp.exe" --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --ffmpeg-location "!BIN_DIR!" --concurrent-fragments 4 --downloader-args "ffmpeg:-hwaccel d3d11va -threads 4" -f "!format_str!" --embed-subs --write-auto-subs --sub-langs "ar" --ignore-errors -o "!OUT_DIR!/%%(title)s [%%(height)sp].%%(ext)s" "!url!"
if errorlevel 1 goto dl_error
goto finish_dl

:dl_error
    echo.
    echo   Error: Download failed. Please check your internet connection or URL.
    pause
    goto download_menu

:finish_dl
echo.
echo --------------------------------------------------------------------------------------
echo   Download Completed Successfully [✓] Check your "!OUT_DIR!" folder.
powershell -Command "[System.Media.SystemSounds]::Asterisk.Play()" >nul 2>&1
pause
goto download_menu