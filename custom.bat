@echo off
setlocal enabledelayedexpansion

set "_CACHE=%~dp0\cache"
set "_DIR=!_CACHE!\custom"

if not exist "!_DIR!\*" mkdir !_DIR!
pushd !_DIR!

:: Custom Lists
curl -z a.dove.txt -o a.dove.txt -R https://a.dove.isdumb.one/list.txt -s 2>nul

:: Merge all custom
set "_MERGE=!_CACHE!\custom.txt"
set _RUN=cmd /c "copy *.txt !_MERGE! /y >nul"

pwsh -c "$f = (gci -af *.txt); $d = ($f | sort LastWriteTime | select -Last 1).LastWriteTime; !_RUN!; (gi !_MERGE!).LastWriteTime = $d"

exit /b
