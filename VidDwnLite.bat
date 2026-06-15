@echo off
chcp 65001 >nul
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

setlocal enabledelayedexpansion

set "BIN_DIR=%~dp0bin"
set "PATH=%BIN_DIR%;%PATH%"
title Video Downloader by Dr Software (Lite)

set "DWN_DIR=Downloads"
set "A_RATE=320k"

if not exist "Logs" mkdir "Logs"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"
if not exist "!DWN_DIR!" mkdir "!DWN_DIR!"

set "MISSING_FILES=0"
if not exist "!BIN_DIR!\yt-dlp.exe" set "MISSING_FILES=1"
if not exist "!BIN_DIR!\ffmpeg.exe" set "MISSING_FILES=1"
if not exist "!BIN_DIR!\qjs.exe" set "MISSING_FILES=1"
if "!MISSING_FILES!"=="1" goto show_error
goto check_hardware

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

:check_hardware
set "NVENC_AVAIL=0"
set "AMF_AVAIL=0"
set "QSV_AVAIL=0"

"!BIN_DIR!\ffmpeg.exe" -f lavfi -i color=c=black:s=64x64:d=1 -c:v h264_nvenc -f null - >nul 2>&1 && set "NVENC_AVAIL=1"
"!BIN_DIR!\ffmpeg.exe" -f lavfi -i color=c=black:s=64x64:d=1 -c:v h264_amf -f null - >nul 2>&1 && set "AMF_AVAIL=1"
"!BIN_DIR!\ffmpeg.exe" -f lavfi -i color=c=black:s=64x64:d=1 -c:v h264_qsv -f null - >nul 2>&1 && set "QSV_AVAIL=1"

set "V_ENC=libx264"
set "HW_DEC="

if "!NVENC_AVAIL!"=="1" (
    set "V_ENC=h264_nvenc"
    set "HW_DEC=-hwaccel d3d11va"
    echo [+] Nvidia GPU Detected ^& Activated!
) else if "!AMF_AVAIL!"=="1" (
    set "V_ENC=h264_amf"
    set "HW_DEC=-hwaccel d3d11va"
    echo [+] AMD GPU Detected ^& Activated!
) else if "!QSV_AVAIL!"=="1" (
    set "V_ENC=h264_qsv"
    set "HW_DEC=-hwaccel d3d11va"
    echo [+] Intel QuickSync Detected ^& Activated!
) else (
echo [-] No Dedicated GPU Found, Using CPU (Safe Mode)
)
timeout /t 2 >nul

cls
echo ======================================================================================
echo  [+] Checking for yt-dlp core updates... Please wait...
echo ======================================================================================
"%~dp0bin\yt-dlp.exe" -U >nul 2>&1 
goto start

:start
cls
color 0B
echo ======================================================================================
echo       Dr Software Video Downloader - Ultimate Lite Edition (Powered by yt-dlp)
echo ======================================================================================
echo  !ESC![96m   To Download from Internet (YouTube, FB, etc.) !ESC![0m
echo  !ESC![92m  💡 Drag and Drop the Video URL link directly here !ESC![0m
echo ======================================================================================
echo  !ESC![95m   for Exit Type (X) and Press Enter !ESC![0m
echo ======================================================================================

set "choice="
set /p choice=" -> !ESC![91m Choice:!ESC![0m "
if not defined choice goto start
if /i "!choice!"=="x" goto exit_prog
set "choice=!choice:"=!"

:strip_main
set "choice=!choice:"=!"
echo !choice! | findstr /i "^http" >nul
if !errorlevel! == 0 (
    set "url=!choice!"
    for /f "tokens=* delims=" %%A in ("!url!") do set "url=%%A"
	goto download_menu
)
goto start

:download_menu
cls
echo ======================================================================================
echo         Link Detected !url!
echo ======================================================================================
echo  [1] Download Video or Audio
echo  [2] Download Full Playlist
echo ======================================================================================
echo  !ESC![95m  💡Go back Type (0) and Press Enter!ESC![0m
echo ======================================================================================
set "dl_opt="
set /p dl_opt=" -> Choose: "
if not defined dl_opt goto download_menu

if "!dl_opt!"=="0" goto start
if "!dl_opt!"=="1" goto choose_video_quality
if "!dl_opt!"=="2" goto choose_video_playlist_quality
goto download_menu

:choose_video_quality
set "format_str="
set "res_opt="
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
echo  [6] Audio Only - Original M4A (Fastest - No Conversion)
echo --------------------------------------------------------------------------------------
echo  !ESC![95m  💡Go back Type (0) and Press Enter!ESC![0m
echo ======================================================================================
set /p res_opt=" -> Choose an option: "

if not defined res_opt goto choose_video_quality

if "!res_opt!"=="0" goto download_menu
if "!res_opt!"=="1" set "format_str=bv*[ext=mp4][vcodec^=avc1]+ba[ext=m4a]/bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]" & goto process_video_dl
if "!res_opt!"=="2" set "format_str=bv*[height<=?1080][ext=mp4][vcodec^=avc1]+ba[ext=m4a]/bv*[height<=?1080][ext=mp4]+ba[ext=m4a]/b[height<=?1080][ext=mp4]" & goto process_video_dl
if "!res_opt!"=="3" set "format_str=bv*[height<=?720][ext=mp4][vcodec^=avc1]+ba[ext=m4a]/bv*[height<=?720][ext=mp4]+ba[ext=m4a]/b[height<=?720][ext=mp4]" & goto process_video_dl
if "!res_opt!"=="4" set "format_str=bv*[height<=?480][ext=mp4][vcodec^=avc1]+ba[ext=m4a]/bv*[height<=?480][ext=mp4]+ba[ext=m4a]/b[height<=?480][ext=mp4]" & goto process_video_dl
if "!res_opt!"=="5" goto process_mp3_dl
if "!res_opt!"=="6" goto process_m4a_dl

:process_mp3_dl
    cls
    echo ======================================================================================
    echo   Processing Audio Download (MP3)... Please wait...
    echo ======================================================================================
	if exist "!BIN_DIR!\aria2c.exe" (
    "!BIN_DIR!\yt-dlp.exe" --no-playlist --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --external-downloader aria2c --external-downloader-args "aria2c:-x 16 -s 16 -k 1M --check-certificate=false --disable-ipv6=true" --postprocessor-args "ffmpeg:-threads 0" -x --audio-format mp3 --audio-quality 0 --ffmpeg-location "!BIN_DIR!" --ignore-errors -o "!DWN_DIR!/%%(title)s.%%(ext)s" "!url!"
    ) else (
    "!BIN_DIR!\yt-dlp.exe" --no-playlist --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --postprocessor-args "ffmpeg:-threads 0" -x --audio-format mp3 --audio-quality 0 --ffmpeg-location "!BIN_DIR!" --ignore-errors -o "!DWN_DIR!/%%(title)s.%%(ext)s" "!url!"
	)
	if errorlevel 1 goto dl_error
    goto finish_dl

:process_m4a_dl
    cls
    echo ======================================================================================
    echo   Processing Original Audio Download (M4A)... Please wait...
    echo ======================================================================================
    if exist "!BIN_DIR!\aria2c.exe" (
        "!BIN_DIR!\yt-dlp.exe" --no-playlist --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --external-downloader aria2c --external-downloader-args "aria2c:-x 16 -s 16 -k 1M --check-certificate=false --disable-ipv6=true" --postprocessor-args "ffmpeg:-threads 0" -f "ba[ext=m4a]/ba" --ffmpeg-location "!BIN_DIR!" --ignore-errors -o "!DWN_DIR!/%%(title)s.%%(ext)s" "!url!"
    ) else (
        "!BIN_DIR!\yt-dlp.exe" --no-playlist --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --postprocessor-args "ffmpeg:-threads 0" -f "ba[ext=m4a]/ba" --ffmpeg-location "!BIN_DIR!" --ignore-errors -o "!DWN_DIR!/%%(title)s.%%(ext)s" "!url!"
    )
    if errorlevel 1 goto dl_error
    goto finish_dl

:process_video_dl
cls
echo.
echo ======================================================================================
echo   Processing download and fetching subtitles... Please wait...
echo ======================================================================================
if exist "!BIN_DIR!\aria2c.exe" (
"!BIN_DIR!\yt-dlp.exe" --no-playlist --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --ffmpeg-location "!BIN_DIR!" --external-downloader aria2c --external-downloader-args "aria2c:-x 16 -s 16 -k 1M --check-certificate=false --disable-ipv6=true" --concurrent-fragments 4 --postprocessor-args "ffmpeg:-threads 0" -f "!format_str!" --embed-subs --write-auto-subs --sub-langs "ar" --ignore-errors -o "!DWN_DIR!/%%(title)s [%%(height)sp].%%(ext)s" "!url!"
) else (
"!BIN_DIR!\yt-dlp.exe" --no-playlist --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --ffmpeg-location "!BIN_DIR!" --concurrent-fragments 4 --postprocessor-args "ffmpeg:-threads 0" -f "!format_str!" --embed-subs --write-auto-subs --sub-langs "ar" --ignore-errors -o "!DWN_DIR!/%%(title)s [%%(height)sp].%%(ext)s" "!url!"
)
if errorlevel 1 goto dl_error
goto finish_dl

:choose_video_playlist_quality
set "format_str="
set "res_opt="
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
echo  [6] Audio Only - Original M4A (Fastest - No Conversion)
echo --------------------------------------------------------------------------------------
echo  !ESC![95m  💡Go back Type (0) and Press Enter!ESC![0m
echo ======================================================================================
set /p res_opt=" -> Choose an option: "

if not defined res_opt goto choose_video_playlist_quality

if "!res_opt!"=="0" goto download_menu
if "!res_opt!"=="1" set "format_str=bv*[ext=mp4][vcodec^=avc1]+ba[ext=m4a]/bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]" & goto process_video_playlist_dl
if "!res_opt!"=="2" set "format_str=bv*[height<=?1080][ext=mp4][vcodec^=avc1]+ba[ext=m4a]/bv*[height<=?1080][ext=mp4]+ba[ext=m4a]/b[height<=?1080][ext=mp4]" & goto process_video_playlist_dl
if "!res_opt!"=="3" set "format_str=bv*[height<=?720][ext=mp4][vcodec^=avc1]+ba[ext=m4a]/bv*[height<=?720][ext=mp4]+ba[ext=m4a]/b[height<=?720][ext=mp4]" & goto process_video_playlist_dl
if "!res_opt!"=="4" set "format_str=bv*[height<=?480][ext=mp4][vcodec^=avc1]+ba[ext=m4a]/bv*[height<=?480][ext=mp4]+ba[ext=m4a]/b[height<=?480][ext=mp4]" & goto process_video_playlist_dl
if "!res_opt!"=="5" goto process_mp3_playlist_dl
if "!res_opt!"=="6" goto process_m4a_playlist_dl

:process_mp3_playlist_dl
    cls
    echo ======================================================================================
    echo   Processing Playlist Audio Download (MP3)... Please wait...
    echo ======================================================================================
	if exist "!BIN_DIR!\aria2c.exe" (
    "!BIN_DIR!\yt-dlp.exe" --yes-playlist --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --external-downloader aria2c --external-downloader-args "aria2c:-x 16 -s 16 -k 1M --check-certificate=false --disable-ipv6=true" --postprocessor-args "ffmpeg:-threads 0" -x --audio-format mp3 --audio-quality 0 --ffmpeg-location "!BIN_DIR!" --ignore-errors -o "!DWN_DIR!\\%%(playlist_title)s\\%%(playlist_index)s - %%(title)s.%%(ext)s" "!url!"
    ) else (
    "!BIN_DIR!\yt-dlp.exe" --yes-playlist --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --postprocessor-args "ffmpeg:-threads 0" -x --audio-format mp3 --audio-quality 0 --ffmpeg-location "!BIN_DIR!" --ignore-errors -o "!DWN_DIR!\\%%(playlist_title)s\\%%(playlist_index)s - %%(title)s.%%(ext)s" "!url!"
	)
	if errorlevel 1 goto dl_error
    goto finish_dl

:process_m4a_playlist_dl
    cls
    echo ======================================================================================
    echo   Processing Original Playlist Audio Download (M4A)... Please wait...
    echo ======================================================================================
    if exist "!BIN_DIR!\aria2c.exe" (
        "!BIN_DIR!\yt-dlp.exe" --yes-playlist --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --external-downloader aria2c --external-downloader-args "aria2c:-x 16 -s 16 -k 1M --check-certificate=false --disable-ipv6=true" --postprocessor-args "ffmpeg:-threads 0" -f "ba[ext=m4a]/ba" --ffmpeg-location "!BIN_DIR!" --ignore-errors -o "!DWN_DIR!\\%%(playlist_title)s\\%%(playlist_index)s - %%(title)s.%%(ext)s" "!url!"
    ) else (
        "!BIN_DIR!\yt-dlp.exe" --yes-playlist --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --postprocessor-args "ffmpeg:-threads 0" -f "ba[ext=m4a]/ba" --ffmpeg-location "!BIN_DIR!" --ignore-errors -o "!DWN_DIR!\\%%(playlist_title)s\\%%(playlist_index)s - %%(title)s.%%(ext)s" "!url!"
    )
    if errorlevel 1 goto dl_error
    goto finish_dl

:process_video_playlist_dl
cls
echo.
echo ======================================================================================
echo   Processing Playlist download and fetching subtitles... Please wait...
echo ======================================================================================
if exist "%~dp0bin\aria2c.exe" (
"%~dp0bin\yt-dlp.exe" --yes-playlist --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --ffmpeg-location "!BIN_DIR!" --external-downloader aria2c --external-downloader-args "aria2c:-x 16 -s 16 -k 1M --check-certificate=false --disable-ipv6=true" --concurrent-fragments 4 --postprocessor-args "ffmpeg:-threads 0" -f "!format_str!" --embed-subs --write-auto-subs --sub-langs "ar" --ignore-errors -o "!DWN_DIR!\\%%(playlist_title)s\\%%(playlist_index)s - %%(title)s [%%(height)sp].%%(ext)s" "!url!"
) else (
"%~dp0bin\yt-dlp.exe" --yes-playlist --js-runtimes quickjs --windows-filenames --retries 3 --fragment-retries 3 --cache-dir "!BIN_DIR!\cache" --ffmpeg-location "!BIN_DIR!" --concurrent-fragments 4 --postprocessor-args "ffmpeg:-threads 0" -f "!format_str!" --embed-subs --write-auto-subs --sub-langs "ar" --ignore-errors -o "!DWN_DIR!\\%%(playlist_title)s\\%%(playlist_index)s - %%(title)s [%%(height)sp].%%(ext)s" "!url!"
)
if errorlevel 1 goto dl_error
goto finish_dl

:dl_error
    echo.
    echo   Error: Download failed. Please check your internet connection or URL.
	    echo  
    pause
    goto download_menu

:finish_dl
echo.
echo --------------------------------------------------------------------------------------
echo   Download Completed Successfully [✓] Check your "!DWN_DIR!" folder.
    echo  
	powershell -Command "(New-Object -ComObject SAPI.SpVoice).Speak('Process Completed successfully')"
goto download_menu

:exit_prog
if exist "!BIN_DIR!\cache" rmdir /s /q "!BIN_DIR!\cache"
endlocal
exit /b
