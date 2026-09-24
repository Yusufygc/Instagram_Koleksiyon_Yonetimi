@echo off
REM Uygulamayi PyInstaller ile paketler (dist\InstagramKoleksiyonYoneticisi\).
REM Inno Setup betigi (installer.iss) bu klasoru kaynak alir.
cd /d "%~dp0"

venv\Scripts\pyinstaller.exe main.py ^
  --name "InstagramKoleksiyonYoneticisi" ^
  --windowed ^
  --icon assets\app_icon.ico ^
  --add-data "qml;qml" ^
  --add-data "assets;assets" ^
  --hidden-import PySide6.QtQml ^
  --hidden-import PySide6.QtQuick ^
  --hidden-import PySide6.QtQuickControls2 ^
  --hidden-import PySide6.QtMultimedia ^
  --hidden-import PySide6.QtNetwork ^
  --hidden-import keyring.backends.Windows ^
  --noconfirm

echo.
echo Bitti: dist\InstagramKoleksiyonYoneticisi\InstagramKoleksiyonYoneticisi.exe
