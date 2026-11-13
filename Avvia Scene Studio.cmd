@echo off
setlocal
set "runner=%~dp0build\windows\x64\runner"
if exist "%runner%\Profile\scene_studio.exe" (
    start "" "%runner%\Profile\scene_studio.exe"
) else (
    start "" "%runner%\Release\scene_studio.exe"
)
