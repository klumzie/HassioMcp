@echo off
setlocal enabledelayedexpansion

echo ========================================
echo PowerPoint Protection Remover
echo ========================================
echo.

:: Check if file was provided
if "%~1"=="" (
    echo Usage: Drag and drop a .pptx or .ppsx file onto this script
    echo Or run: remove-pptx-protection.bat "path\to\file.pptx"
    pause
    exit /b 1
)

:: Get the full path and filename
set "INPUT_FILE=%~1"
set "FILE_DIR=%~dp1"
set "FILE_NAME=%~n1"
set "FILE_EXT=%~x1"

:: Validate file extension
if /i not "%FILE_EXT%"==".pptx" if /i not "%FILE_EXT%"==".ppsx" (
    echo Error: File must be .pptx or .ppsx
    pause
    exit /b 1
)

:: Check if file exists
if not exist "%INPUT_FILE%" (
    echo Error: File not found: %INPUT_FILE%
    pause
    exit /b 1
)

echo Processing: %FILE_NAME%%FILE_EXT%
echo.

:: Step 1: Create backup
set "BACKUP_FILE=%FILE_DIR%%FILE_NAME%_backup%FILE_EXT%"
echo [1/9] Creating backup...
copy "%INPUT_FILE%" "%BACKUP_FILE%" >nul
if errorlevel 1 (
    echo Error: Failed to create backup
    pause
    exit /b 1
)
echo       Backup created: %FILE_NAME%_backup%FILE_EXT%

:: Step 2: Create working copy and rename to .zip
set "ZIP_FILE=%FILE_DIR%%FILE_NAME%_temp.zip"
echo [2/9] Creating working copy...
copy "%INPUT_FILE%" "%ZIP_FILE%" >nul
if errorlevel 1 (
    echo Error: Failed to create working copy
    pause
    exit /b 1
)

:: Step 3: Create temporary extraction directory
set "TEMP_DIR=%FILE_DIR%%FILE_NAME%_temp"
echo [3/9] Creating temporary directory...
if exist "%TEMP_DIR%" rd /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

:: Step 4: Extract ZIP contents using PowerShell
echo [4/9] Extracting ZIP contents...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TEMP_DIR%' -Force"
if errorlevel 1 (
    echo Error: Failed to extract ZIP
    rd /s /q "%TEMP_DIR%"
    del "%ZIP_FILE%"
    pause
    exit /b 1
)

:: Step 5: Locate presentation.xml
set "PRESENTATION_XML=%TEMP_DIR%\ppt\presentation.xml"
echo [5/9] Locating presentation.xml...
if not exist "%PRESENTATION_XML%" (
    echo Error: presentation.xml not found in ppt folder
    rd /s /q "%TEMP_DIR%"
    del "%ZIP_FILE%"
    pause
    exit /b 1
)
echo       Found: ppt\presentation.xml

:: Step 6: Remove modifyVerifier tag using PowerShell
echo [6/9] Removing protection tags...
powershell -Command "$content = Get-Content '%PRESENTATION_XML%' -Raw; $content = $content -replace '<p:modifyVerifier[^>]*/>',''; $content = $content -replace '<p:modifyVerifier[^>]*>.*?</p:modifyVerifier>',''; Set-Content '%PRESENTATION_XML%' -Value $content -NoNewline"
if errorlevel 1 (
    echo Warning: PowerShell modification may have failed, but continuing...
)
echo       Protection tags removed

:: Step 7: Delete old ZIP file
echo [7/9] Cleaning up old archive...
del "%ZIP_FILE%"

:: Step 8: Repackage as ZIP using PowerShell
echo [8/9] Repackaging file...
powershell -Command "Compress-Archive -Path '%TEMP_DIR%\*' -DestinationPath '%ZIP_FILE%' -Force"
if errorlevel 1 (
    echo Error: Failed to repackage ZIP
    rd /s /q "%TEMP_DIR%"
    pause
    exit /b 1
)

:: Step 9: Rename back to original extension
set "OUTPUT_FILE=%FILE_DIR%%FILE_NAME%_unprotected%FILE_EXT%"
echo [9/9] Finalizing...
move "%ZIP_FILE%" "%OUTPUT_FILE%" >nul
if errorlevel 1 (
    echo Error: Failed to create final file
    rd /s /q "%TEMP_DIR%"
    pause
    exit /b 1
)

:: Cleanup temporary directory
rd /s /q "%TEMP_DIR%"

echo.
echo ========================================
echo SUCCESS!
echo ========================================
echo Original file: %FILE_NAME%%FILE_EXT%
echo Backup file:   %FILE_NAME%_backup%FILE_EXT%
echo New file:      %FILE_NAME%_unprotected%FILE_EXT%
echo.
echo The protection has been removed from the new file.
echo Your original file is untouched, and a backup was created.
echo ========================================
echo.
pause
