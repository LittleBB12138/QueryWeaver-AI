@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

echo.
echo ========================================
echo   Push project to GitHub
echo ========================================
echo.

echo [1/4] Checking Git status...
git status

echo.
echo [2/4] Adding files...
git add .

echo.
echo [3/4] Committing changes...
git diff --cached --quiet

if errorlevel 1 (
    git commit -m "Update project"
) else (
    echo No new changes to commit.
)

echo.
echo [4/4] Pushing to GitHub...
git push

if errorlevel 1 (
    echo.
    echo [ERROR] Push failed.
) else (
    echo.
    echo [SUCCESS] Push completed.
)

echo.
pause