#ifndef StageRoot
  #error StageRoot must point to the staged offline package
#endif

#ifndef OutputDir
  #define OutputDir AddBackslash(StageRoot) + "output"
#endif

#define ProductName "Unreal Revived"
#define ProductVersion "0.2.0"
#ifndef ProductIconName
  #error ProductIconName must identify the staged content-addressed icon
#endif

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
UninstallDisplayIcon={app}\UnrealRevived\{#ProductIconName}

[Files]
Source: "{#StageRoot}\payload\copy-original-game.ps1"; Flags: dontcopy
Source: "{#StageRoot}\payload\unreal-revived-install-content-v1.json"; Flags: dontcopy
Source: "{#StageRoot}\payload\*"; DestDir: "{tmp}\UnrealRevived-Payload"; Excludes: "copy-original-game.ps1"; Flags: ignoreversion recursesubdirs createallsubdirs deleteafterinstall
Source: "{#StageRoot}\patch\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#ProductName}"; Filename: "{app}\System64\Unreal.exe"; WorkingDir: "{app}\System64"; IconFilename: "{app}\UnrealRevived\{#ProductIconName}"
Name: "{autodesktop}\{#ProductName}"; Filename: "{app}\System64\Unreal.exe"; WorkingDir: "{app}\System64"; IconFilename: "{app}\UnrealRevived\{#ProductIconName}"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
const
  UninstallKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{8D6614ED-8854-4D0E-9666-A891EC92713B}_is1';
  OldUnrealInstallerUrl = 'https://www.oldunreal.com/downloads/unreal/full-game-installers/';

var
  SourcePage: TInputDirWizardPage;
  SourceHelpLabel: TNewStaticText;
  GetOriginalGameButton: TNewButton;
  DetectOriginalGameButton: TNewButton;
  KeepSaveGames: Boolean;
  UninstallOptionsAccepted: Boolean;
  PreservedSaveDirectory: String;

function InitializeUninstall: Boolean;
begin
  KeepSaveGames := True;
  UninstallOptionsAccepted := True;
  Result := True;
end;

procedure InitializeUninstallProgressForm;
var
  OptionsPanel: TPanel;
  DescriptionLabel: TNewStaticText;
  KeepSavesCheck: TNewCheckBox;
  UninstallButton: TNewButton;
  CancelButton: TNewButton;
  ButtonWidth: Integer;
begin
  if UninstallSilent then
    Exit;

  UninstallProgressForm.Caption := 'Uninstall Unreal Revived';

  OptionsPanel := TPanel.Create(UninstallProgressForm);
  OptionsPanel.Parent := UninstallProgressForm;
  OptionsPanel.SetBounds(0, 0, UninstallProgressForm.ClientWidth,
    UninstallProgressForm.ClientHeight);
  OptionsPanel.BevelOuter := bvNone;
  OptionsPanel.Color := clWindow;
  OptionsPanel.Anchors := [akLeft, akTop, akRight, akBottom];

  DescriptionLabel := TNewStaticText.Create(OptionsPanel);
  DescriptionLabel.Parent := OptionsPanel;
  DescriptionLabel.SetBounds(ScaleX(12), ScaleY(12),
    OptionsPanel.ClientWidth - ScaleX(24), ScaleY(64));
  DescriptionLabel.AutoSize := False;
  DescriptionLabel.WordWrap := True;
  DescriptionLabel.Caption :=
    'This removes Unreal Revived only. Your original Unreal Gold installation ' +
    'and OldUnreal downloads will not be changed. Choose whether save games ' +
    'remain for a future installation; a Documents backup is created either way.';

  KeepSavesCheck := TNewCheckBox.Create(OptionsPanel);
  KeepSavesCheck.Parent := OptionsPanel;
  KeepSavesCheck.SetBounds(ScaleX(12), ScaleY(84),
    OptionsPanel.ClientWidth - ScaleX(24), ScaleY(20));
  KeepSavesCheck.Caption := 'Keep save games';
  KeepSavesCheck.Checked := True;

  UninstallButton := TNewButton.Create(OptionsPanel);
  UninstallButton.Parent := OptionsPanel;
  UninstallButton.Caption := 'Uninstall';
  UninstallButton.ModalResult := mrOk;
  UninstallButton.Default := True;

  CancelButton := TNewButton.Create(OptionsPanel);
  CancelButton.Parent := OptionsPanel;
  CancelButton.Caption := 'Cancel';
  CancelButton.ModalResult := mrCancel;
  CancelButton.Cancel := True;

  ButtonWidth := UninstallProgressForm.CalculateButtonWidth([UninstallButton.Caption,
    CancelButton.Caption]);
  UninstallButton.SetBounds(
    OptionsPanel.ClientWidth - ScaleX(12) - (ButtonWidth * 2) - ScaleX(8),
    OptionsPanel.ClientHeight - ScaleY(35), ButtonWidth, ScaleY(23));
  CancelButton.SetBounds(OptionsPanel.ClientWidth - ScaleX(12) - ButtonWidth,
    OptionsPanel.ClientHeight - ScaleY(35), ButtonWidth, ScaleY(23));
  UninstallProgressForm.ActiveControl := KeepSavesCheck;
  OptionsPanel.BringToFront;

  UninstallOptionsAccepted := UninstallProgressForm.ShowModal() = mrOk;
  if UninstallOptionsAccepted then
    KeepSaveGames := KeepSavesCheck.Checked;
  OptionsPanel.Hide;
end;

procedure BackupUninstallUserData;
var
  ResultCode: Integer;
  PowerShell: String;
  Arguments: String;
begin
  PowerShell := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
  Arguments := '-NoProfile -ExecutionPolicy Bypass -File "' +
    ExpandConstant('{app}\UnrealRevived\backup-unreal-revived-user-data.ps1') +
    '" -InstallRoot "' + ExpandConstant('{app}') + '"';
  if not Exec(PowerShell, Arguments, '', SW_HIDE,
    ewWaitUntilTerminated, ResultCode) then
    RaiseException('Could not start the user-data backup.');
  if ResultCode <> 0 then
    RaiseException(Format('User-data backup failed with exit code %d.', [ResultCode]));
end;

procedure PreserveInstalledSaveGames;
var
  SaveDirectory: String;
begin
  if not KeepSaveGames then
    Exit;

  SaveDirectory := AddBackslash(ExpandConstant('{app}')) + 'Save';
  if not DirExists(SaveDirectory) then
    Exit;

  PreservedSaveDirectory := ExpandConstant('{app}') +
    '.UnrealRevived-Save-' +
    GetDateTimeString('yyyymmdd-hhnnss', '-', '-');
  if not RenameFile(SaveDirectory, PreservedSaveDirectory) then
    RaiseException('Could not preserve the save-game directory.');
end;

procedure RestoreInstalledSaveGames;
var
  SaveDirectory: String;
begin
  if (PreservedSaveDirectory = '') or
    (not DirExists(PreservedSaveDirectory)) then
    Exit;

  SaveDirectory := AddBackslash(ExpandConstant('{app}')) + 'Save';
  if (not ForceDirectories(ExpandConstant('{app}'))) or
    (not RenameFile(PreservedSaveDirectory, SaveDirectory)) then
    MsgBox('Save games could not be restored automatically. They remain at:' + #13#10 +
      PreservedSaveDirectory, mbError, MB_OK);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    if not UninstallOptionsAccepted then
      Abort;
    BackupUninstallUserData;
    PreserveInstalledSaveGames;
  end
  else if CurUninstallStep = usPostUninstall then
    RestoreInstalledSaveGames;
end;

function ExtractUninstallerExecutable(const Command: String): String;
var
  ClosingQuote: Integer;
begin
  Result := Trim(Command);
  if (Length(Result) > 0) and (Result[1] = '"') then
  begin
    Delete(Result, 1, 1);
    ClosingQuote := Pos('"', Result);
    if ClosingQuote > 0 then
      Result := Copy(Result, 1, ClosingQuote - 1);
  end
  else
    Result := RemoveQuotes(Result);
end;

function FindExistingUninstaller(var Uninstaller: String): Boolean;
begin
  Result := RegQueryStringValue(HKLM, UninstallKey, 'UninstallString',
    Uninstaller);
  if not Result then
    Result := RegQueryStringValue(HKCU, UninstallKey, 'UninstallString',
      Uninstaller);
  if Result then
  begin
    Uninstaller := ExtractUninstallerExecutable(Uninstaller);
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
    if not Exec(Uninstaller, '/SUPPRESSMSGBOXES /NORESTART', '',
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
  Candidate := 'C:\Unreal';
  if IsOriginalGameDirectory(Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

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

procedure DetectOriginalGameButtonClick(Sender: TObject);
var
  DetectedDirectory: String;
begin
  DetectedDirectory := DetectOriginalGameDirectory;
  if DetectedDirectory <> '' then
  begin
    SourcePage.Values[0] := DetectedDirectory;
    SourceHelpLabel.Caption := 'Unreal Gold detected. You can continue Setup.';
  end
  else
    MsgBox('Unreal Gold was not detected yet. Finish the OldUnreal installer, ' +
      'then click Detect Again, or browse to the folder containing System\Unreal.exe.',
      mbInformation, MB_OK);
end;

procedure GetOriginalGameButtonClick(Sender: TObject);
var
  ErrorCode: Integer;
begin
  if not ShellExec('open', OldUnrealInstallerUrl, '', '', SW_SHOWNORMAL,
    ewNoWait, ErrorCode) then
    MsgBox('Could not open the OldUnreal installer page. Visit:' + #13#10 +
      OldUnrealInstallerUrl, mbError, MB_OK);
end;

procedure InitializeWizard;
var
  DetectedDirectory: String;
  ButtonWidth: Integer;
begin
  SourcePage := CreateInputDirPage(wpSelectDir,
    'Original Game', 'Where is your original Unreal Gold installation?',
    'Setup will copy your existing game files into Unreal Revived. Select the ' +
    'folder containing the System directory and Unreal.exe.', False, '');
  SourcePage.Add('Original game folder:');
  DetectedDirectory := DetectOriginalGameDirectory;
  if DetectedDirectory <> '' then
    SourcePage.Values[0] := DetectedDirectory;

  SourceHelpLabel := TNewStaticText.Create(SourcePage);
  SourceHelpLabel.Parent := SourcePage.Surface;
  SourceHelpLabel.SetBounds(0, ScaleY(92), SourcePage.SurfaceWidth,
    ScaleY(42));
  SourceHelpLabel.AutoSize := False;
  SourceHelpLabel.WordWrap := True;
  if DetectedDirectory <> '' then
    SourceHelpLabel.Caption := 'Unreal Gold was detected. You can continue Setup.'
  else
    SourceHelpLabel.Caption := 'No installation was detected. Install Unreal Gold ' +
      'using OldUnreal, then return here and detect it again.';

  ButtonWidth := ScaleX(190);
  GetOriginalGameButton := TNewButton.Create(SourcePage);
  GetOriginalGameButton.Parent := SourcePage.Surface;
  GetOriginalGameButton.SetBounds(0, ScaleY(140), ButtonWidth, ScaleY(23));
  GetOriginalGameButton.Caption := 'Install via OldUnreal...';
  GetOriginalGameButton.OnClick := @GetOriginalGameButtonClick;

  DetectOriginalGameButton := TNewButton.Create(SourcePage);
  DetectOriginalGameButton.Parent := SourcePage.Surface;
  DetectOriginalGameButton.SetBounds(ButtonWidth + ScaleX(8), ScaleY(140),
    ScaleX(100), ScaleY(23));
  DetectOriginalGameButton.Caption := 'Detect Again';
  DetectOriginalGameButton.OnClick := @DetectOriginalGameButtonClick;
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
    ExtractTemporaryFile('unreal-revived-install-content-v1.json');
    PowerShell := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
    Arguments := '-NoProfile -ExecutionPolicy Bypass -File "' +
      ExpandConstant('{tmp}\copy-original-game.ps1') +
      '" -InstallRoot "' + ExpandConstant('{app}') +
      '" -OriginalGameRoot "' + SourcePage.Values[0] +
      '" -ContentManifest "' +
      ExpandConstant('{tmp}\unreal-revived-install-content-v1.json') + '"';

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

  if not RegWriteStringValue(HKCU, UninstallKey, 'UninstallString',
    '"' + ExpandConstant('{uninstallexe}') + '" /SUPPRESSMSGBOXES') then
    RaiseException('Could not configure the registered uninstaller.');
end;
