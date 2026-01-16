@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Office Protection Remover
echo (Word/Excel/PowerPoint)
echo ========================================
echo.

:: Check if file was provided
if "%~1"=="" (
    echo Usage: Drag and drop an Office file onto this script
    echo.
    echo Supported formats:
    echo   - PowerPoint: .pptx, .pptm, .ppsx, .potx, .potm
    echo   - Excel: .xlsx, .xlsm, .xltx, .xltm
    echo   - Word: .docx, .docm, .dotx, .dotm
    echo.
    echo Or run: remove-office-protection.bat "path\to\file.docx"
    pause
    exit /b 1
)

:: Get the full path and filename
set "INPUT_FILE=%~1"
set "FILE_DIR=%~dp1"
set "FILE_NAME=%~n1"
set "FILE_EXT=%~x1"

:: Detect file type
set "FILE_TYPE="
if /i "%FILE_EXT%"==".pptx" set "FILE_TYPE=POWERPOINT"
if /i "%FILE_EXT%"==".pptm" set "FILE_TYPE=POWERPOINT"
if /i "%FILE_EXT%"==".ppsx" set "FILE_TYPE=POWERPOINT"
if /i "%FILE_EXT%"==".potx" set "FILE_TYPE=POWERPOINT"
if /i "%FILE_EXT%"==".potm" set "FILE_TYPE=POWERPOINT"
if /i "%FILE_EXT%"==".xlsx" set "FILE_TYPE=EXCEL"
if /i "%FILE_EXT%"==".xlsm" set "FILE_TYPE=EXCEL"
if /i "%FILE_EXT%"==".xltx" set "FILE_TYPE=EXCEL"
if /i "%FILE_EXT%"==".xltm" set "FILE_TYPE=EXCEL"
if /i "%FILE_EXT%"==".docx" set "FILE_TYPE=WORD"
if /i "%FILE_EXT%"==".docm" set "FILE_TYPE=WORD"
if /i "%FILE_EXT%"==".dotx" set "FILE_TYPE=WORD"
if /i "%FILE_EXT%"==".dotm" set "FILE_TYPE=WORD"

:: Validate file extension
if "%FILE_TYPE%"=="" (
    echo Error: Unsupported file type: %FILE_EXT%
    echo.
    echo Supported formats:
    echo   PowerPoint: .pptx, .pptm, .ppsx, .potx, .potm
    echo   Excel: .xlsx, .xlsm, .xltx, .xltm
    echo   Word: .docx, .docm, .dotx, .dotm
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
echo File type: %FILE_TYPE%
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

:: Step 5-6: Remove protection based on file type
echo [5/9] Locating protection files...
echo [6/9] Removing protection tags...

if "%FILE_TYPE%"=="POWERPOINT" (
    set "PRESENTATION_XML=%TEMP_DIR%\ppt\presentation.xml"
    if not exist "!PRESENTATION_XML!" (
        echo Error: presentation.xml not found in ppt folder
        rd /s /q "%TEMP_DIR%"
        del "%ZIP_FILE%"
        pause
        exit /b 1
    )
    echo       Found: ppt\presentation.xml
    powershell -Command "$content = Get-Content '!PRESENTATION_XML!' -Raw; $content = $content -replace '<p:modifyVerifier[^>]*/>',''; $content = $content -replace '<p:modifyVerifier[^>]*>.*?</p:modifyVerifier>',''; Set-Content '!PRESENTATION_XML!' -Value $content -NoNewline"
    if errorlevel 1 (
        echo Warning: PowerShell modification may have failed, but continuing...
    )
    echo       Protection tags removed
)

if "%FILE_TYPE%"=="EXCEL" (
    set "WORKBOOK_FILE=%TEMP_DIR%\xl\workbook.xml"
    if not exist "!WORKBOOK_FILE!" (
        echo Error: workbook.xml not found in xl folder
        rd /s /q "%TEMP_DIR%"
        del "%ZIP_FILE%"
        pause
        exit /b 1
    )
    echo       Found: xl\workbook.xml
    powershell -Command "$c=Get-Content '!WORKBOOK_FILE!' -Raw;$c=$c -replace '<workbookProtection[^>]*/>','';$c=$c -replace '<workbookProtection[^>]*>.*?</workbookProtection>','';Set-Content '!WORKBOOK_FILE!' -Value $c -NoNewline"
    powershell -Command "$c=Get-Content '!WORKBOOK_FILE!' -Raw;$c=$c -replace '<fileSharing[^>]*/>','';$c=$c -replace '<fileSharing[^>]*>.*?</fileSharing>','';Set-Content '!WORKBOOK_FILE!' -Value $c -NoNewline"
    echo       Workbook protection removed
    if exist "%TEMP_DIR%\xl\worksheets\" (
        powershell -Command "Get-ChildItem '%TEMP_DIR%\xl\worksheets\*.xml' | ForEach-Object { $c = Get-Content $_.FullName -Raw; $c = $c -replace '<sheetProtection[^>]*/>',''; $c = $c -replace '<sheetProtection[^>]*>.*?</sheetProtection>',''; Set-Content $_.FullName -Value $c -NoNewline }"
        echo       Worksheet protection removed
    )
)

if "%FILE_TYPE%"=="WORD" (
    set "DOCUMENT_FILE=%TEMP_DIR%\word\document.xml"
    if not exist "!DOCUMENT_FILE!" (
        echo Error: document.xml not found in word folder
        rd /s /q "%TEMP_DIR%"
        del "%ZIP_FILE%"
        pause
        exit /b 1
    )
    echo       Found: word\document.xml
    powershell -Command "$content = Get-Content '!DOCUMENT_FILE!' -Raw; $content = $content -replace '<w:documentProtection[^>]*/>',''; $content = $content -replace '<w:documentProtection[^>]*>.*?</w:documentProtection>',''; Set-Content '!DOCUMENT_FILE!' -Value $content -NoNewline"
    echo       Document protection removed
    set "SETTINGS_FILE=%TEMP_DIR%\word\settings.xml"
    if exist "!SETTINGS_FILE!" (
        powershell -Command "$c=Get-Content '!SETTINGS_FILE!' -Raw;$c=$c -replace '<w:documentProtection[^>]*/>','';$c=$c -replace '<w:documentProtection[^>]*>.*?</w:documentProtection>','';Set-Content '!SETTINGS_FILE!' -Value $c -NoNewline"
        powershell -Command "$c=Get-Content '!SETTINGS_FILE!' -Raw;$c=$c -replace '<w:writeProtection[^>]*/>','';$c=$c -replace '<w:writeProtection[^>]*>.*?</w:writeProtection>','';Set-Content '!SETTINGS_FILE!' -Value $c -NoNewline"
        echo       Settings protection removed
    )
)

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
echo File type:     %FILE_TYPE%
echo Original file: %FILE_NAME%%FILE_EXT%
echo Backup file:   %FILE_NAME%_backup%FILE_EXT%
echo New file:      %FILE_NAME%_unprotected%FILE_EXT%
echo.
echo The protection has been removed from the new file.
echo Your original file is untouched, and a backup was created.
echo ========================================
echo.
pause
