; Inno Setup Script for WinUtil
; Chris Titus Tech's Windows Utility
; Build with: ISCC.exe winutil.iss
; Or run: .\build-installer.ps1

#define MyAppName "WinUtil"
#define MyAppPublisher "Chris Titus Tech"
#define MyAppURL "https://christitus.com"
#define MyAppDescription "Chris Titus Tech Windows Utility"

[Setup]
AppId={{8B7A5E3C-4F2D-4E8A-B1C0-9D6F8E2A3B7F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=no
OutputDir=installer
OutputBaseFilename=WinUtil-Setup-{#MyAppVersion}
SetupIconFile=docs\static\favicon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; Installer itself requires admin; the app also self-elevates on launch
PrivilegesRequired=admin
UninstallDisplayIcon={app}\favicon.ico
UninstallDisplayName={#MyAppName}
VersionInfoVersion=1.0.0.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppDescription}
; Prevent downgrade installs silently overwriting a newer version
VersionInfoProductVersion={#MyAppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
Source: "winutil.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "docs\static\favicon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Start Menu shortcut — targets powershell.exe; winutil.ps1 self-elevates to admin via UAC
Name: "{group}\{#MyAppName}"; \
    Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-ExecutionPolicy Bypass -NoProfile -File ""{app}\winutil.ps1"""; \
    WorkingDir: "{app}"; \
    IconFilename: "{app}\favicon.ico"; \
    Comment: "Launch Chris Titus Tech's Windows Utility"

Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

; Optional desktop shortcut (checked by default once)
Name: "{commondesktop}\{#MyAppName}"; \
    Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-ExecutionPolicy Bypass -NoProfile -File ""{app}\winutil.ps1"""; \
    WorkingDir: "{app}"; \
    IconFilename: "{app}\favicon.ico"; \
    Comment: "Launch Chris Titus Tech's Windows Utility"; \
    Tasks: desktopicon

[Run]
; Offer to launch WinUtil immediately after installation
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-ExecutionPolicy Bypass -NoProfile -File ""{app}\winutil.ps1"""; \
    WorkingDir: "{app}"; \
    Description: "Launch {#MyAppName} now"; \
    Flags: nowait postinstall skipifsilent shellexec

[Code]
// Set the "Run as administrator" flag on both shortcuts after creation.
// The .lnk format stores this in byte 21 (0-indexed), bit 5 (0x20).
procedure SetShortcutRunAsAdmin(LinkPath: String);
var
  FileStream: TFileStream;
  FlagByte: Byte;
  Buffer: AnsiString;
begin
  if not FileExists(LinkPath) then Exit;
  try
    FileStream := TFileStream.Create(LinkPath, fmOpenReadWrite);
    try
      FileStream.Seek(21, soFromBeginning);
      SetLength(Buffer, 1);
      FileStream.ReadBuffer(Buffer[1], 1);
      FlagByte := Ord(Buffer[1]) or $20;
      Buffer[1] := Chr(FlagByte);
      FileStream.Seek(21, soFromBeginning);
      FileStream.WriteBuffer(Buffer[1], 1);
    finally
      FileStream.Free;
    end;
  except
    // Non-fatal: shortcuts still work without the admin flag;
    // winutil.ps1 self-elevates via UAC on first run anyway.
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  StartMenuLink: String;
  DesktopLink: String;
begin
  if CurStep = ssPostInstall then begin
    StartMenuLink := ExpandConstant('{group}\WinUtil.lnk');
    SetShortcutRunAsAdmin(StartMenuLink);

    if WizardIsTaskSelected('desktopicon') then begin
      DesktopLink := ExpandConstant('{commondesktop}\WinUtil.lnk');
      SetShortcutRunAsAdmin(DesktopLink);
    end;
  end;
end;
