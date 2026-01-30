@echo off
echo ==========================================
echo 1. PREPARACION
echo ==========================================
echo Asegurate de haber copiado el archivo JSON de Firebase en:
echo supabase\functions\push-notification\service-account.json
echo.
echo Presiona enter si ya lo hiciste...
pause

echo.
echo ==========================================
echo 2. INICIAR SESION
echo ==========================================
echo Se abrira el navegador. Por favor confirma el acceso.
.\supabase.exe login
echo.

echo.
echo ==========================================
echo 3. DESPLEGAR FUNCION
echo ==========================================
.\supabase.exe functions deploy push-notification --project-ref fmreitafxucwejvwzjvp --no-verify-jwt

echo.
echo ==========================================
echo LISTO!
echo ==========================================
pause
