; Instagram Koleksiyon Yöneticisi - Inno Setup kurulum betiği
; Kaynak: dist\InstagramKoleksiyonYoneticisi\ (build_exe.bat ile PyInstaller'dan üretilir)

#define MyAppName "Instagram Koleksiyon Yöneticisi"
#define MyAppVersion "1.0.0"
#define MyAppExeName "InstagramKoleksiyonYoneticisi.exe"
#define MyAppDir "dist\InstagramKoleksiyonYoneticisi"

[Setup]
AppId={{6F1B7C0E-6D9E-4E3E-9C3B-6C4B3B5A9F21}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=installer_output
OutputBaseFilename=InstagramKoleksiyonYoneticisi_Setup
SetupIconFile=assets\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Tasks]
Name: "desktopicon"; Description: "Masaüstü kısayolu oluştur"; GroupDescription: "Ek simgeler:"

[Files]
Source: "{#MyAppDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
var
  DepsPage: TWizardPage;
  DepsInfoLabel: TNewStaticText;
  CBTesseract, CBFFmpeg: TNewCheckBox;

function IsWinGetAvailable(): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec('cmd.exe', '/c where winget >nul 2>nul', '', SW_HIDE,
    ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

procedure InitializeWizard;
begin
  DepsPage := CreateCustomPage(wpSelectTasks, 'Ek Bileşenler (İsteğe Bağlı)',
    'Metin tanıma (OCR) özelliği için gerekli programlar');

  DepsInfoLabel := TNewStaticText.Create(DepsPage);
  DepsInfoLabel.Parent := DepsPage.Surface;
  DepsInfoLabel.AutoSize := False;
  DepsInfoLabel.WordWrap := True;
  DepsInfoLabel.Width := DepsPage.SurfaceWidth;
  DepsInfoLabel.Height := ScaleY(70);
  DepsInfoLabel.Caption :=
    'Uygulama bu ikisi olmadan da tam çalışır; yalnızca gönderi/video ' +
    'içindeki yazıyı tanıma (OCR) özelliği için gereklidirler. ' +
    'winget üzerinden otomatik kurulmalarını isteyebilir ya da daha sonra ' +
    'kendiniz kurabilirsiniz.';

  CBTesseract := TNewCheckBox.Create(DepsPage);
  CBTesseract.Parent := DepsPage.Surface;
  CBTesseract.Caption := 'Tesseract OCR''i şimdi kur (görsellerden metin tanımak için)';
  CBTesseract.Top := DepsInfoLabel.Top + DepsInfoLabel.Height + ScaleY(8);
  CBTesseract.Width := DepsPage.SurfaceWidth;
  CBTesseract.Checked := True;

  CBFFmpeg := TNewCheckBox.Create(DepsPage);
  CBFFmpeg.Parent := DepsPage.Surface;
  CBFFmpeg.Caption := 'ffmpeg''i şimdi kur (videodan kare yakalamak için)';
  CBFFmpeg.Top := CBTesseract.Top + CBTesseract.Height + ScaleY(8);
  CBFFmpeg.Width := DepsPage.SurfaceWidth;
  CBFFmpeg.Checked := True;

  if not IsWinGetAvailable() then
  begin
    CBTesseract.Enabled := False;
    CBFFmpeg.Enabled := False;
    CBTesseract.Caption := CBTesseract.Caption + ' (winget bulunamadı)';
    CBFFmpeg.Caption := CBFFmpeg.Caption + ' (winget bulunamadı)';
  end;
end;

procedure InstallOptionalDependency(const PackageId, DisplayName: String);
var
  ResultCode: Integer;
begin
  if not Exec('winget',
    'install --id ' + PackageId + ' -e --accept-package-agreements --accept-source-agreements',
    '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode) or (ResultCode <> 0) then
    MsgBox(DisplayName + ' kurulumu tamamlanamadı. Daha sonra elle kurabilirsiniz.',
      mbInformation, MB_OK);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if CBTesseract.Enabled and CBTesseract.Checked then
      InstallOptionalDependency('UB-Mannheim.TesseractOCR', 'Tesseract OCR');
    if CBFFmpeg.Enabled and CBFFmpeg.Checked then
      InstallOptionalDependency('Gyan.FFmpeg', 'ffmpeg');
  end;
end;
