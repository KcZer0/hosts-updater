@echo off
setlocal enabledelayedexpansion
pushd %~dp0

set "_COMPRESS=hostscompress"
where !_COMPRESS! 2>nul >nul || (
    set "_COMPRESS=hostscompress-x64"
    where !_COMPRESS! 2>nul >nul || goto :no_compress
)

set "_CACHE=%~dp0\cache"
if not exist "!_CACHE!\backup\*" mkdir !_CACHE!\backup

set _SHOST="%SYSTEMROOT%\System32\drivers\etc\hosts"
set _CHOST="!_CACHE!\hosts"

:: Copy hosts
copy !_SHOST! !_CHOST! /y >nul
pwsh -c "$d = (date).toString('yyyy-MM-dd_HHmmss'); copy !_CHOST! !_CACHE!\backup\hosts-$d"

:: Download Files
set "_SBH=!_CACHE!\unified.txt"
set "_CST=!_CACHE!\custom.txt"

REM https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
curl -z !_SBH! -o !_SBH! -R http://sbc.io/hosts/hosts -s 2>nul
call custom.bat

:: Check dates
for /f "delims=" %%d in ('findstr /c:"# Date" !_CHOST!') do set "_OLDDATE=%%d"
for /f "delims=" %%d in ('findstr /c:"# Date" !_SBH!') do set "_NEWDATE=%%d"

if "!_OLDDATE!" == "!_NEWDATE!" (
    echo. Already up to date: !_NEWDATE!
    timeout /t 2 /nobreak > nul
    exit /b
)
echo. Updating Hosts...

:: Compress
set "_FULL=!_CACHE!\full.txt"
set "_COMP=!_CACHE!\compress.txt"

copy !_SBH! + !_CST! !_FULL! /y >nul
hostscompress /q /i !_FULL! /o !_COMP! 

:: Finalize
set "_PTSTR=#### BEGIN UNIFIED HOSTS ####"
set "_PTEND=#### END UNIFIED HOSTS ####"
set "_RGX=(?s)(!_PTSTR!).*?(!_PTEND!)"

pwsh -c "$f='!_CHOST!'; $c='!_COMP!'; $ci=[IO.File]::ReadAllText($c); $t=[IO.File]::ReadAllText($f); $r='!_RGX!'; $nl=[Environment]::NewLine; if($t -match $r){[regex]::Replace($t, $r, '$1' + $nl + $ci + $nl + '$2') | Set-Content $f} else {Add-Content $f ($nl + '!_PTSTR!' + $nl + $ci + $nl + '!_PTEND!')}"

timeout /t 1 /nobreak > nul
attrib -R "!_SHOST!"

timeout /t 2 /nobreak > nul
copy "!_CHOST!" "!_SHOST!" /y >nul

timeout /t 1 /nobreak > nul
attrib +R "!_SHOST!"


:: Done
echo. Hosts Updated: !_NEWDATE!
timeout /t 3 /nobreak >nul
exit /b

:no_compress
echo. Missing hostscompress binary...
echo. Please add hostscompress binary to PATH
exit /b
