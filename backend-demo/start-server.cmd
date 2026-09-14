@echo off
title HarmonyOS demo backend
cd /d "%~dp0"
echo Starting backend on port 8787 ...
d:\python.exe -u server.py
pause
