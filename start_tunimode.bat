\
@echo off
title TuniMode - Lancement automatique

set BACKEND_PATH=%~dp0backend
set FRONTEND_PATH=%~dp0frontend

echo Lancement backend...
start "TuniMode Backend" cmd /k "cd /d %BACKEND_PATH% && npm install && npm run dev"

echo Lancement frontend...
start "TuniMode Frontend" cmd /k "cd /d %FRONTEND_PATH% && flutter pub get && flutter run -d chrome"

pause
