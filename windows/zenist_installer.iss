; Inno Setup Script for Zenist
; 此腳本會將 Flutter 編譯好的 Release 資料夾打包成 Windows 安裝檔

#define MyAppName "Zenist"
#define MyAppPublisher "Zenist"
#define MyAppURL "https://github.com/ChiesiMario/Zenist"
#define MyAppExeName "zenist.exe"
#define MyBuildDir "..\build\windows\x64\runner\Release"
#define MyAppVersion GetStringFileInfo(MyBuildDir + "\" + MyAppExeName, "ProductVersion")

[Setup]
; 應用程式的基本資訊
AppId={{5A18C3B4-9F2B-4A92-A2D0-2B3E11C4F7D3}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; 安裝路徑預設為 C:\Program Files\Zenist
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}

; 輸出的安裝檔名稱與存放位置
OutputDir=..\build\windows\x64\installer
OutputBaseFilename=Zenist-Setup-v{#MyAppVersion}

; 安裝圖示與介面設定
SetupIconFile=runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DisableWelcomePage=no

[Languages]
; 支援預設語言安裝精靈
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; 載入 Release 目錄下的所有檔案
Source: "{#MyBuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.pdb"

[Icons]
; 在開始菜單與桌面建立捷徑
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; 安裝完成後提供立即執行的選項
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Registry]
; 解除安裝時自動清理開機自啟動登錄檔
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueName: "zenist"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueName: "Zenist"; Flags: uninsdeletevalue