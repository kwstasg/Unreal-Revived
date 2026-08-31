#ifndef StageRoot
  #error StageRoot must point to the staged offline package
#endif

#ifndef OutputDir
  #define OutputDir AddBackslash(StageRoot) + "output"
#endif

#define ProductName "Unreal Revived"
#define ProductVersion "0.1.0"

[Setup]
AppId={{8D6614ED-8854-4D0E-9666-A891EC92713B}
AppName={#ProductName}
AppVersion={#ProductVersion}
AppPublisher=Unreal Revived
DefaultDirName=C:\Games\Unreal Revived
DefaultGroupName={#ProductName}
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=UnrealRevived-Setup-{#ProductVersion}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
CloseApplications=yes
UninstallDisplayName={#ProductName}
SetupLogging=yes

[Files]
Source: "{#StageRoot}\payload\copy-original-game.ps1"; Flags: dontcopy
Source: "{#StageRoot}\payload\*"; DestDir: "{tmp}\UnrealRevived-Payload"; Excludes: "copy-original-game.ps1"; Flags: ignoreversion recursesubdirs createallsubdirs deleteafterinstall
Source: "{#StageRoot}\patch\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#ProductName}"; Filename: "{app}\System64\Unreal.exe"; Parameters: "Unreal.unr ini=UnrealRevived.ini userini=UnrealRevivedUser.ini"; WorkingDir: "{app}\System64"
Name: "{autodesktop}\{#ProductName}"; Filename: "{app}\System64\Unreal.exe"; Parameters: "Unreal.unr ini=UnrealRevived.ini userini=UnrealRevivedUser.ini"; WorkingDir: "{app}\System64"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: checkedonce

[UninstallRun]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\UnrealRevived\backup-unreal-revived-user-data.ps1"" -InstallRoot ""{app}"""; Flags: runhidden waituntilterminated; RunOnceId: "BackupUserData"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
const
  UninstallKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{8D6614ED-8854-4D0E-9666-A891EC92713B}_is1';

var
  SourcePage: TInputDirWizardPage;

function FindExistingUninstaller(var Uninstaller: String): Boolean;
begin
  Result := RegQueryStringValue(HKLM, UninstallKey, 'UninstallString',
    Uninstaller);
  if not Result then
    Result := RegQueryStringValue(HKCU, UninstallKey, 'UninstallString',
      Uninstaller);
  if Result then
  begin
    Uninstaller := RemoveQuotes(Uninstaller);
    Result := FileExists(Uninstaller);
  end;
end;

function InitializeSetup: Boolean;
var
  Uninstaller: String;
  ResultCode: Integer;
  Choice: Integer;
begin
  Result := True;
  if not FindExistingUninstaller(Uninstaller) then
    Exit;

  Choice := SuppressibleMsgBox(
    'Unreal Revived is already installed.' + #13#10 + #13#10 +
    'Yes: uninstall the existing installation and close Setup.' + #13#10 +
    'No: continue and repair or update the existing installation.' + #13#10 +
    'Cancel: exit without making changes.',
    mbConfirmation, MB_YESNOCANCEL, IDNO);
  if Choice = IDYES then
  begin
    if not Exec(Uninstaller, '/SILENT /SUPPRESSMSGBOXES /NORESTART', '',
      SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode) then
    begin
      MsgBox('Could not start the Unreal Revived uninstaller.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
    if ResultCode <> 0 then
      MsgBox(Format('Uninstall failed with exit code %d.', [ResultCode]),
        mbError, MB_OK);
    Result := False;
  end
  else if Choice = IDCANCEL then
    Result := False;
end;

function IsOriginalGameDirectory(const Directory: String): Boolean;
begin
  Result := FileExists(AddBackslash(Directory) + 'System\Unreal.exe');
end;

function ExtractVdfValue(const Line, Key: String): String;
var
  KeyPosition: Integer;
  ValueStart: Integer;
  ValueEnd: Integer;
begin
  Result := '';
  KeyPosition := Pos('"' + Key + '"', Line);
  if KeyPosition = 0 then
    Exit;

  ValueStart := KeyPosition + Length(Key) + 2;
  while (ValueStart <= Length(Line)) and
    ((Line[ValueStart] = ' ') or (Line[ValueStart] = #9)) do
    ValueStart := ValueStart + 1;
  if (ValueStart > Length(Line)) or (Line[ValueStart] <> '"') then
    Exit;

  ValueStart := ValueStart + 1;
  ValueEnd := ValueStart;
  while (ValueEnd <= Length(Line)) and (Line[ValueEnd] <> '"') do
    ValueEnd := ValueEnd + 1;
  if ValueEnd <= Length(Line) then
    Result := Copy(Line, ValueStart, ValueEnd - ValueStart);
end;

function FindGameInSteamApps(const SteamAppsDirectory: String): String;
var
  Manifest: TArrayOfString;
  Index: Integer;
  InstallDirectory: String;
  Candidate: String;
begin
  Result := '';
  if not LoadStringsFromFile(AddBackslash(SteamAppsDirectory) +
    'appmanifest_13250.acf', Manifest) then
    Exit;

  for Index := 0 to GetArrayLength(Manifest) - 1 do
  begin
    InstallDirectory := ExtractVdfValue(Manifest[Index], 'installdir');
    if InstallDirectory <> '' then
      Break;
  end;

  if InstallDirectory = '' then
    Exit;
  Candidate := AddBackslash(SteamAppsDirectory) + 'common\' + InstallDirectory;
  if IsOriginalGameDirectory(Candidate) then
    Result := Candidate;
end;

function DetectOriginalGameDirectory: String;
var
  SteamPath: String;
  LibraryFile: String;
  LibraryLines: TArrayOfString;
  LibraryPath: String;
  Candidate: String;
  Index: Integer;
begin
  Result := '';
  if not RegQueryStringValue(HKCU, 'Software\Valve\Steam', 'SteamPath',
    SteamPath) then
    Exit;

  Candidate := FindGameInSteamApps(AddBackslash(SteamPath) + 'steamapps');
  if Candidate <> '' then
  begin
    Result := Candidate;
    Exit;
  end;

  LibraryFile := AddBackslash(SteamPath) + 'steamapps\libraryfolders.vdf';
  if not LoadStringsFromFile(LibraryFile, LibraryLines) then
    Exit;
  for Index := 0 to GetArrayLength(LibraryLines) - 1 do
  begin
    LibraryPath := ExtractVdfValue(LibraryLines[Index], 'path');
    if LibraryPath = '' then
      Continue;
    StringChangeEx(LibraryPath, '\\', '\', True);
    Candidate := FindGameInSteamApps(AddBackslash(LibraryPath) + 'steamapps');
    if Candidate <> '' then
    begin
      Result := Candidate;
      Exit;
    end;
  end;
end;

procedure InitializeWizard;
var
  DetectedDirectory: String;
begin
  SourcePage := CreateInputDirPage(wpSelectDir,
    'Original Game', 'Where is your original Unreal Gold installation?',
    'Setup will copy your existing game files into Unreal Revived. Select the ' +
    'folder containing the System directory and Unreal.exe.', False, '');
  SourcePage.Add('Original game folder:');
  DetectedDirectory := DetectOriginalGameDirectory;
  if DetectedDirectory <> '' then
    SourcePage.Values[0] := DetectedDirectory;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  SourceDirectory: String;
  DestinationDirectory: String;
begin
  Result := True;
  if CurPageID <> SourcePage.ID then
    Exit;

  if not IsOriginalGameDirectory(SourcePage.Values[0]) then
  begin
    MsgBox('Select the original Unreal Gold folder containing System\Unreal.exe.',
      mbError, MB_OK);
    Result := False;
      Exit;
    end;

    SourceDirectory := Lowercase(AddBackslash(SourcePage.Values[0]));
    DestinationDirectory := Lowercase(AddBackslash(WizardDirValue));
    if Pos(SourceDirectory, DestinationDirectory) = 1 then
    begin
      MsgBox('Unreal Revived must be installed outside the original game folder.',
        mbError, MB_OK);
      Result := False;
  end;
end;

  function UpdateReadyMemo(Space, NewLine, MemoUserInfoInfo, MemoDirInfo,
    MemoTypeInfo, MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
  begin
    Result := MemoDirInfo + NewLine + NewLine +
      'Original game files:' + NewLine + Space + SourcePage.Values[0];
    if MemoGroupInfo <> '' then
      Result := Result + NewLine + NewLine + MemoGroupInfo;
    if MemoTasksInfo <> '' then
      Result := Result + NewLine + NewLine + MemoTasksInfo;
  end;

  function PrepareToInstall(var NeedsRestart: Boolean): String;
  var
    ResultCode: Integer;
    PowerShell: String;
    Arguments: String;
  begin
    Result := '';
    ExtractTemporaryFile('copy-original-game.ps1');
    PowerShell := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
    Arguments := '-NoProfile -ExecutionPolicy Bypass -File "' +
      ExpandConstant('{tmp}\copy-original-game.ps1') +
      '" -InstallRoot "' + ExpandConstant('{app}') +
      '" -OriginalGameRoot "' + SourcePage.Values[0] + '"';

    WizardForm.StatusLabel.Caption :=
      'Copying your original game files. This may take a few minutes...';
    WizardForm.ProgressGauge.Style := npbstMarquee;
    try
      if not Exec(PowerShell, Arguments, '', SW_HIDE,
        ewWaitUntilTerminated, ResultCode) then
      begin
        Result := 'Could not start the original-game copy operation.';
        Exit;
      end;
      if ResultCode <> 0 then
        Result := Format('Copying the original game failed with exit code %d.', [ResultCode]);
    finally
      WizardForm.ProgressGauge.Style := npbstNormal;
    end;
  end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
  PowerShell: String;
  Arguments: String;
begin
  if CurStep <> ssPostInstall then
    Exit;

  PowerShell := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
  Arguments := '-NoProfile -ExecutionPolicy Bypass -File "' +
    ExpandConstant('{tmp}\UnrealRevived-Payload\install-unreal-revived.ps1') +
    '" -InstallRoot "' + ExpandConstant('{app}') +
    '" -PayloadRoot "' + ExpandConstant('{tmp}\UnrealRevived-Payload') +
    '" -OriginalGameRoot "' + SourcePage.Values[0] + '"';

  WizardForm.StatusLabel.Caption :=
    'Verifying Unreal Revived and creating its launch profiles...';
  WizardForm.ProgressGauge.Style := npbstMarquee;
  try
    if not Exec(PowerShell, Arguments, '', SW_HIDE,
      ewWaitUntilTerminated, ResultCode) then
      RaiseException('Could not start the offline installation engine.');
  finally
    WizardForm.ProgressGauge.Style := npbstNormal;
  end;
  if ResultCode <> 0 then
    RaiseException(Format('Offline installation failed with exit code %d. See the setup log for details.', [ResultCode]));
end;