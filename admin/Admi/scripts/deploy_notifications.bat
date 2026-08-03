@echo off
chcp 65001 >nul
echo ========================================
echo  نشر إشعارات الحجوزات - تطبيق الإدمن
echo ========================================
powershell -ExecutionPolicy Bypass -File "%~dp0setup_push_notifications.ps1"
pause
