; Unreal Revived
; Author: Kwstasg - Kostas Giannakakis
; Project: https://github.com/kwstasg/Unreal-Revived

#ifndef StageRoot
  #error StageRoot must point to the staged offline package
#endif

#ifndef OutputDir
  #define OutputDir AddBackslash(StageRoot) + "output"
#endif

#ifdef ValidationBuild
  #define ProductName "Unreal Revived Validation"
  #define ProductGuid "2ECFF5AD-A39A-469F-906C-6D842DF3D310"
#else
  #define ProductName "Unreal Revived"
  #define ProductGuid "8D6614ED-8854-4D0E-9666-A891EC92713B"
#endif
#define ProductVersion "0.8.0"
#define ProductFileVersion "0.8.0.0"
#define ProductAuthor "Kwstasg - Kostas Giannakakis"
#define ProjectUrl "https://github.com/kwstasg/Unreal-Revived"
#ifndef ProductIconName
  #error ProductIconName must identify the staged content-addressed icon
#endif

[Setup]
AppId={{{#ProductGuid}}
AppName={#ProductName}
AppVersion={#ProductVersion}
AppVerName={#ProductName} {#ProductVersion}
AppPublisher={#ProductAuthor}
AppPublisherURL={#ProjectUrl}
AppSupportURL={#ProjectUrl}/issues
AppUpdatesURL={#ProjectUrl}/releases
DefaultDirName=C:\Games\Unreal Revived
DefaultGroupName={#ProductName}
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=UnrealRevived-Setup-{#ProductVersion}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
WizardSizePercent=120,150
WizardImageFile={#StageRoot}\payload\InstallerWizard.png
DisableWelcomePage=no
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
CloseApplications=yes
UninstallDisplayName={#ProductName}
SetupLogging=yes
UninstallDisplayIcon={app}\UnrealRevived\{#ProductIconName}
VersionInfoCompany={#ProductAuthor}
VersionInfoDescription={#ProductName} Installer
VersionInfoProductName={#ProductName}
VersionInfoProductVersion={#ProductVersion}
VersionInfoVersion={#ProductFileVersion}
VersionInfoCopyright=Copyright (C) 2026 {#ProductAuthor}

[Files]
Source: "{#StageRoot}\payload\copy-original-game.ps1"; Flags: dontcopy
Source: "{#StageRoot}\payload\unreal-revived-install-content-v1.json"; Flags: dontcopy
Source: "{#StageRoot}\payload\InstallerWizard.png"; DestDir: "{app}\UnrealRevived"; Flags: ignoreversion
Source: "{#StageRoot}\payload\*"; DestDir: "{tmp}\UnrealRevived-Payload"; Excludes: "copy-original-game.ps1,InstallerWizard.png"; Flags: ignoreversion recursesubdirs createallsubdirs deleteafterinstall
Source: "{#StageRoot}\patch\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#ProductName}"; Filename: "{app}\System64\UnrealRevived.exe"; WorkingDir: "{app}\System64"; IconFilename: "{app}\UnrealRevived\{#ProductIconName}"
Name: "{autoprograms}\{#ProductName} VR"; Filename: "{app}\System64\UnrealRevivedVR.exe"; WorkingDir: "{app}\System64"; IconFilename: "{app}\UnrealRevived\{#ProductIconName}"
Name: "{autodesktop}\{#ProductName}"; Filename: "{app}\System64\UnrealRevived.exe"; WorkingDir: "{app}\System64"; IconFilename: "{app}\UnrealRevived\{#ProductIconName}"; Tasks: desktopicon
Name: "{autodesktop}\{#ProductName} VR"; Filename: "{app}\System64\UnrealRevivedVR.exe"; WorkingDir: "{app}\System64"; IconFilename: "{app}\UnrealRevived\{#ProductIconName}"; Tasks: vrdesktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &normal game desktop shortcut"; GroupDescription: "Desktop shortcuts:"
Name: "vrdesktopicon"; Description: "Create a &VR desktop shortcut"; GroupDescription: "Desktop shortcuts:"; Flags: unchecked

[Run]
Filename: "{app}\System64\UnrealRevived.exe"; WorkingDir: "{app}\System64"; Description: "Launch {#ProductName}"; Flags: postinstall nowait skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
const
  UninstallKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{{#ProductGuid}}_is1';
  OldUnrealInstallerUrl = 'https://www.oldunreal.com/downloads/unreal/full-game-installers/';

var
  SourcePage: TInputDirWizardPage;
  SourceHelpLabel: TNewStaticText;
  GetOriginalGameButton: TNewButton;
  DetectOriginalGameButton: TNewButton;
  ProjectLinkLabel: TNewLinkLabel;
  KeepSaveGames: Boolean;
  UninstallOptionsAccepted: Boolean;
  PreservedSaveDirectory: String;

function HasCommandLineParameter(const Parameter: String): Boolean;
var
  Index: Integer;
begin
  Result := False;
  for Index := 1 to ParamCount do
    if CompareText(ParamStr(Index), Parameter) = 0 then
    begin
      Result := True;
      Exit;
    end;
end;

procedure ProjectLinkLabelClick(Sender: TObject; const Link: String;
  LinkType: TSysLinkType);
var
  ErrorCode: Integer;
begin
  if LinkType = sltURL then
    if not ShellExec('open', Link, '', '', SW_SHOWNORMAL,
      ewNoWait, ErrorCode) then
      MsgBox('Could not open the project page. Visit:' + #13#10 +
        '{#ProjectUrl}', mbError, MB_OK);
end;

function ShowUninstallOptions: Boolean;
var
  OptionsForm: TSetupForm;
  OptionsPanel: TPanel;
  PortraitImage: TBitmapImage;
  HeadingLabel: TNewStaticText;
  DescriptionLabel: TNewStaticText;
  KeepSavesCheck: TNewCheckBox;
  LinkLabel: TNewLinkLabel;
  UninstallButton: TNewButton;
  CancelButton: TNewButton;
  ButtonWidth: Integer;
  ContentLeft: Integer;
begin
  OptionsForm := CreateCustomForm(ScaleX(600), ScaleY(320), False, True);
  OptionsForm.Caption := 'Uninstall Unreal Revived {#ProductVersion}';
  OptionsForm.Position := poScreenCenter;

  OptionsPanel := TPanel.Create(OptionsForm);
  OptionsPanel.Parent := OptionsForm;
  OptionsPanel.SetBounds(0, 0, OptionsForm.ClientWidth,
    OptionsForm.ClientHeight);
  OptionsPanel.BevelOuter := bvNone;
  OptionsPanel.Color := OptionsForm.Color;
  OptionsPanel.Anchors := [akLeft, akTop, akRight, akBottom];

  PortraitImage := TBitmapImage.Create(OptionsPanel);
  PortraitImage.Parent := OptionsPanel;
  PortraitImage.SetBounds(ScaleX(12), ScaleY(10), ScaleX(150), ScaleY(287));
  PortraitImage.Stretch := True;
  if FileExists(ExpandConstant('{app}\UnrealRevived\InstallerWizard.png')) then
    PortraitImage.PngImage.LoadFromFile(
      ExpandConstant('{app}\UnrealRevived\InstallerWizard.png'));

  ContentLeft := PortraitImage.Left + PortraitImage.Width + ScaleX(14);
  HeadingLabel := TNewStaticText.Create(OptionsPanel);
  HeadingLabel.Parent := OptionsPanel;
  HeadingLabel.SetBounds(ContentLeft, ScaleY(16),
    OptionsPanel.ClientWidth - ContentLeft - ScaleX(12), ScaleY(28));
  HeadingLabel.AutoSize := False;
  HeadingLabel.Color := OptionsPanel.Color;
  HeadingLabel.Font.Style := [fsBold];
  HeadingLabel.Font.Size := 12;
  HeadingLabel.Caption := 'Uninstall Unreal Revived';

  DescriptionLabel := TNewStaticText.Create(OptionsPanel);
  DescriptionLabel.Parent := OptionsPanel;
  DescriptionLabel.SetBounds(ContentLeft, HeadingLabel.Top + HeadingLabel.Height + ScaleY(8),
    OptionsPanel.ClientWidth - ContentLeft - ScaleX(12), ScaleY(92));
  DescriptionLabel.AutoSize := False;
  DescriptionLabel.WordWrap := True;
  DescriptionLabel.Color := OptionsPanel.Color;
  DescriptionLabel.Caption :=
    'This removes Unreal Revived only. Your original Unreal Gold installation ' +
    'and OldUnreal downloads will not be changed. Choose whether save games ' +
    'remain for a future installation; a Documents backup is created either way.';

  KeepSavesCheck := TNewCheckBox.Create(OptionsPanel);
  KeepSavesCheck.Parent := OptionsPanel;
  KeepSavesCheck.SetBounds(ContentLeft,
    DescriptionLabel.Top + DescriptionLabel.Height + ScaleY(6),
    OptionsPanel.ClientWidth - ContentLeft - ScaleX(12), ScaleY(20));
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

  LinkLabel := TNewLinkLabel.Create(OptionsPanel);
  LinkLabel.Parent := OptionsPanel;
  LinkLabel.Left := ContentLeft;
  LinkLabel.Top := OptionsPanel.ClientHeight - ScaleY(61);
  LinkLabel.Width := OptionsPanel.ClientWidth - ContentLeft - ScaleX(12);
  LinkLabel.Caption := 'GitHub: <a href="{#ProjectUrl}">{#ProjectUrl}</a>';
  LinkLabel.UseVisualStyle := True;
  LinkLabel.OnLinkClick := @ProjectLinkLabelClick;

  ButtonWidth := OptionsForm.CalculateButtonWidth([UninstallButton.Caption,
    CancelButton.Caption]);
  UninstallButton.SetBounds(
    OptionsPanel.ClientWidth - ScaleX(12) - (ButtonWidth * 2) - ScaleX(8),
    OptionsPanel.ClientHeight - ScaleY(35), ButtonWidth, ScaleY(23));
  CancelButton.SetBounds(OptionsPanel.ClientWidth - ScaleX(12) - ButtonWidth,
    OptionsPanel.ClientHeight - ScaleY(35), ButtonWidth, ScaleY(23));
  OptionsForm.ActiveControl := KeepSavesCheck;
  OptionsPanel.BringToFront;

  Result := OptionsForm.ShowModal() = mrOk;
  if Result then
    KeepSaveGames := KeepSavesCheck.Checked;
  OptionsForm.Free;
end;

function InitializeUninstall: Boolean;
var
  ResultCode: Integer;
begin
  KeepSaveGames := not HasCommandLineParameter('/REMOVESAVES');
  UninstallOptionsAccepted := True;

  if HasCommandLineParameter('/VERYSILENT') then
  begin
    Result := True;
    Exit;
  end;

  if UninstallSilent then
  begin
    UninstallOptionsAccepted := ShowUninstallOptions;
    Result := UninstallOptionsAccepted;
    Exit;
  end;

  { Suppress Inno's native confirmation and show our single options dialog. }
  Result := False;
  if not Exec(ExpandConstant('{uninstallexe}'),
    '/SILENT /SUPPRESSMSGBOXES /NORESTART', ExpandConstant('{app}'),
    SW_SHOWNORMAL, ewNoWait, ResultCode) then
    MsgBox('Could not start the Unreal Revived uninstaller.', mbError, MB_OK);
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
begin
  Result := True;
  if not FindExistingUninstaller(Uninstaller) then
    Exit;

  { Older builds do not contain the branded uninstall form. Let Setup upgrade
    them first instead of invoking their uninstaller silently. }
  if not FileExists(AddBackslash(ExtractFileDir(Uninstaller)) +
    'UnrealRevived\InstallerWizard.png') then
    Exit;

  { Use the same single branded uninstall/options dialog as a direct launch. }
  if not Exec(Uninstaller,
    '/SILENT /SUPPRESSMSGBOXES /NORESTART', '',
    SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode) then
  begin
    MsgBox('Could not start the Unreal Revived uninstaller.', mbError, MB_OK);
    Result := False;
    Exit;
  end
  else if ResultCode = 0 then
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
  RequestedDirectory: String;
  ButtonWidth: Integer;
begin
  WizardForm.WelcomeLabel2.Height := WizardForm.WelcomePage.ClientHeight -
    WizardForm.WelcomeLabel2.Top - ScaleY(16);
  WizardForm.WelcomeLabel1.Caption :=
    'Welcome to Unreal Revived {#ProductVersion}';
  WizardForm.WelcomeLabel2.Caption :=
    'Rediscover Unreal and Return to Na Pali on modern Windows, ' +
    'on your screen or in seated VR.' + #13#10 + #13#10 +
    '- Modern graphics: Direct3D 12, HD lightmaps, up to 8x MSAA, ' +
    'and customizable visual effects' + #13#10 +
    '- Modern displays: widescreen, 4K rendering, borderless windows, ' +
    'and high-refresh support' + #13#10 +
    '- Seated VR: stereo depth, head tracking, and your choice of ' +
    'head-gaze or motion-controller aiming' + #13#10 +
    '- Adjustable VR comfort: height and world-size controls, ' +
    'wall-collision fade, and a stable, adjustable HUD' + #13#10 +
    '- Flexible controls: keyboard, mouse, and gamepads, with up to ' +
    'three bindings per action' + #13#10 +
    '- Both classic campaigns: refreshed menus, OpenAL audio, and ' +
    'separate desktop and VR launch options' + #13#10 + #13#10 +
    'Ready-to-use defaults, with optional settings to make the ' +
    'experience your own.' + #13#10 + #13#10 +
    'Requires your original game files. Setup installs separately ' +
    'and leaves your original game untouched.';

  ProjectLinkLabel := TNewLinkLabel.Create(WizardForm);
  ProjectLinkLabel.Parent := WizardForm;
  ProjectLinkLabel.AutoSize := False;
  ProjectLinkLabel.SetBounds(ScaleX(12),
    WizardForm.CancelButton.Top + ScaleY(3),
    WizardForm.BackButton.Left - ScaleX(24), ScaleY(18));
  ProjectLinkLabel.Caption := 'Unreal Revived  |  ' +
    '<a href="{#ProjectUrl}">GitHub</a>';
  ProjectLinkLabel.UseVisualStyle := True;
  ProjectLinkLabel.OnLinkClick := @ProjectLinkLabelClick;

  SourcePage := CreateInputDirPage(wpSelectDir,
    'Original Game', 'Where is your original Unreal Gold installation?',
    'Setup will copy your existing game files into Unreal Revived. Select the ' +
    'folder containing the System directory and Unreal.exe.', False, '');
  SourcePage.Add('Original game folder:');
  RequestedDirectory := ExpandConstant('{param:OriginalGameRoot|}');
  if RequestedDirectory <> '' then
    DetectedDirectory := RequestedDirectory
  else
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
    CopyErrorPath: String;
    CopyError: AnsiString;
  begin
    Result := '';
    ExtractTemporaryFile('copy-original-game.ps1');
    ExtractTemporaryFile('unreal-revived-install-content-v1.json');
    PowerShell := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
    CopyErrorPath := ExpandConstant('{tmp}\original-game-copy-error.txt');
    DeleteFile(CopyErrorPath);
    Arguments := '-NoProfile -ExecutionPolicy Bypass -File "' +
      ExpandConstant('{tmp}\copy-original-game.ps1') +
      '" -InstallRoot "' + ExpandConstant('{app}') +
      '" -OriginalGameRoot "' + SourcePage.Values[0] +
      '" -ContentManifest "' +
      ExpandConstant('{tmp}\unreal-revived-install-content-v1.json') +
      '" -ErrorLog "' + CopyErrorPath + '"';

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
      begin
        Result := Format('Copying the original game failed with exit code %d.', [ResultCode]);
        if LoadStringFromFile(CopyErrorPath, CopyError) then
          Result := Result + #13#10 + Trim(UTF8Decode(CopyError));
        Log(Result);
      end;
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
    '"' + ExpandConstant('{uninstallexe}') +
    '" /SILENT /SUPPRESSMSGBOXES /NORESTART') then
    RaiseException('Could not configure the registered uninstaller.');
  if not RegWriteStringValue(HKCU, UninstallKey, 'QuietUninstallString',
    '"' + ExpandConstant('{uninstallexe}') +
    '" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART') then
    RaiseException('Could not configure the quiet uninstaller.');
end;
