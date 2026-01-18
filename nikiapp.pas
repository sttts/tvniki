UNIT NikiApp;

INTERFACE

{not $define debug}

USES App, Memory, Objects, Views, Menus, Drivers, Editors, StdDlg, MsgBox, NikiFeld, TvEnh;

TYPE  TNikiApplication = OBJECT(TApplication)
                           CONSTRUCTOR Init;
                           PROCEDURE InitMenuBar; VIRTUAL;
                           PROCEDURE InitStatusLine; VIRTUAL;
                           PROCEDURE HandleEvent(VAR Event:TEvent); VIRTUAL;
                           PROCEDURE CreateClipboard;

                           FUNCTION GetPalette:ppalette; VIRTUAL;
                           PROCEDURE GetEvent(var Event: TEvent); virtual;

                           FUNCTION OpenEditor(FileName: FNameStr; Visible: Boolean): PEditWindow;
                           FUNCTION OpenFeld(FileName:FNameStr):PFeldWindow;

                           PROCEDURE Idle; VIRTUAL;

                           PROCEDURE Neu;
                           PROCEDURE Oeffnen;
                           PROCEDURE ZeigeClipboard;
                           PROCEDURE Info;
                           PROCEDURE ChangeDir;

                           PROCEDURE FeldNeu;
                           PROCEDURE FeldOeffnen;

                           PROCEDURE ShowInfo;
                           PROCEDURE HideInfo;

                           PROCEDURE Hilfe(Ctx:Integer; Modal:BOOLEAN);
                          PRIVATE
                           ClipWindow:PEditWindow;
                           Balken:PProcess;
                         END;


IMPLEMENTATION
USES Dos, FVConsts, NikiCnst, NikiEdit, NikiInfo, NikiGlob, NikiCopy,
     NikiHelp, HelpFile, Hilfe, Config, SysUtils, NikiStrings, NikiDasm;

CONST HeapSize = (128 * 1024) DIV 16;
      { Editor commands from original TV Editors unit }
      cmFind        = 82;
      cmReplace     = 83;
      cmSearchAgain = 84;

PROCEDURE ArrangeWindows;
VAR R: TRect;
    DeskW, DeskH: Integer;
    FieldW, FieldH: Integer;
    EditorW: Integer;
CONST
    { Field window size = content (61x21) + frame (2x2) }
    { But field content already includes border at row 0 and 20, so visible area is smaller }
    MaxFieldW = 63;  { SizeX + 2 }
    MaxFieldH = 21;  { Actual visible height needed }
BEGIN
  { Get desktop size }
  Desktop^.GetExtent(R);
  DeskW := R.B.X - R.A.X;
  DeskH := R.B.Y - R.A.Y;

  { Field window: sized to show all content + frame }
  FieldW := MaxFieldW;
  IF FieldW > DeskW DIV 2 THEN FieldW := DeskW DIV 2;
  { Use exact size needed for content + frame, or full height if desktop is too small }
  IF DeskH >= MaxFieldH + 6 THEN
    FieldH := MaxFieldH  { Exact fit with room for info below }
  ELSE IF DeskH >= MaxFieldH THEN
    FieldH := MaxFieldH  { Exact fit, no room for info }
  ELSE
    FieldH := DeskH;  { Desktop too small, use all available }

  { Editor gets left side }
  EditorW := DeskW - FieldW;

  { Position editor on left }
  IF EditWindow <> NIL THEN
  BEGIN
    R.A.X := 0;
    R.A.Y := 0;
    R.B.X := EditorW;
    R.B.Y := DeskH;
    EditWindow^.Locate(R);
  END;

  { Position field on right }
  IF FeldWindow <> NIL THEN
  BEGIN
    R.A.X := EditorW;
    R.A.Y := 0;
    R.B.X := DeskW;
    R.B.Y := FieldH;
    FeldWindow^.Locate(R);
  END;

  { Position info to the right of editor, below field }
  IF InfoWindow <> NIL THEN
  BEGIN
    R.A.X := EditorW;
    R.A.Y := FieldH;
    R.B.X := EditorW + 38;  { Width for horizontal layout }
    IF R.B.X > DeskW THEN R.B.X := DeskW;
    R.B.Y := FieldH + 3;
    IF R.B.Y > DeskH THEN R.B.Y := DeskH;
    InfoWindow^.Locate(R);
  END;

  { Position disasm window below info window }
  IF DisasmWindow <> NIL THEN
  BEGIN
    R.A.X := EditorW;
    R.A.Y := FieldH + 3;
    R.B.X := DeskW;
    R.B.Y := DeskH;
    IF R.B.Y > R.A.Y + 3 THEN
      DisasmWindow^.Locate(R);
  END;
END;

CONSTRUCTOR TNikiApplication.Init;
VAR z:Integer;
    P:TPoint;
    R:TRect;
    sMode:String;
    Mode:Integer;
BEGIN
  { MaxHeapSize and MemAvail removed - not needed on modern systems }
  LoadConfig('NIKI.CFG');

  INHERITED Init;

  RegisterObjects;
  RegisterViews;
  RegisterMenus;
  RegisterApp;
  RegisterHelpFile;

  FeldWindow:=NIL;

  CreateClipboard;

  { Info window - will be repositioned later }
  P.X := 0;
  P.Y := 0;
  InfoWindow := New(PInfoDialog, Init(P));
  InsertWindow(InfoWindow);

  { Disassemble window - initially hidden }
  Desktop^.GetExtent(R);
  R.A.X := R.B.X - 30;
  R.B.Y := R.A.Y + 15;
  DisasmWindow := New(PDisasmWindow, Init(R));
  DisasmWindow^.Hide;
  InsertWindow(DisasmWindow);

  FeldNeu;

  IF ParamCount=0 THEN
    EditWindow := OpenEditor('', TRUE)
  ELSE
    FOR z:=1 TO ParamCount DO
    BEGIN
      IF UpCase(ExtractFileExt(ParamStr(z))) = '.ROB' THEN
        OpenFeld(ParamStr(z))
      ELSE
        EditWindow := OpenEditor(ParamStr(z), TRUE);
    END;

  Mode := smCO80;
  sMode := GetStrOption('VIDMODE', 'COLOR');
  IF sMode='BW' THEN Mode := smBW80 ELSE
    IF sMode='MONO' THEN
      Mode := smMono;

  IF GetNumOption('LINES', 25)=50 THEN
    Mode := Mode OR smFont8x8;

  SetScreenMode(Mode);

  { Arrange windows after screen mode is set }
  ArrangeWindows;
  Redraw;

  Info;
END;

PROCEDURE TNikiApplication.CreateClipboard;
VAR
  R: TRect;
BEGIN
  DeskTop^.GetExtent(R);
  ClipWindow := New( PEditWindow, Init(R, '', wnNoNumber));
  IF ClipWindow <> NIL THEN
  BEGIN
    ClipWindow^.State := ClipWindow^.State AND NOT sfShadow;
    ClipWindow^.Hide;
    Clipboard := ClipWindow^.Editor;
    Clipboard^.CanUndo := False;
    InsertWindow(ClipWindow);
  END;
END;

PROCEDURE TNikiApplication.InitStatusLine;
VAR R:TRect;
    P:TPoint;
BEGIN
  GetExtent(R);

  IF GetNumOption('PROCESS', 1)=1 THEN
  BEGIN
    P.X := R.B.X-1;
    P.Y := R.B.Y-1;
    New(Balken, Init(P));
    Insert( Balken );

    R.B.X := R.B.X - 1;
  END;

  R.A.Y := R.B.Y - 1;
  New(StatusLine, Init(R,
    NewStatusDef(hcFeldeditor, hcFeldeditor,
      NewStatusKey('~Space~=' + tr('Wall'), kbNoKey, cmIdle,
      NewStatusKey('~P~=' + tr('Niki/turn'), kbNoKey, cmIdle,
      NewStatusKey('~+/-~=' + tr('Supply'), kbNoKey, cmIdle,
      NewStatusKey('~Ctrl-F9~=' + tr('Run'), kbCtrlF9, cmRun,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      nil))))),
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Ctrl-F9~ ' + tr('Run'), kbCtrlF9, cmRun,
      NewStatusKey('~Alt-X~/~Ctrl-Q~ Exit', kbAltX, cmQuit,
      NewStatusKey('', kbCtrlQ, cmQuit,
      StdStatusKeys(nil)))), nil))));
END;

PROCEDURE TNikiApplication.InitMenuBar;
VAR R : TRect;
BEGIN
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New (PMenuBar, Init(R, NewMenu(
    NewSubMenu(tr('~F~ile'), hcNoContext, NewMenu(
      NewItem(tr('~N~ew'), '', 0, cmNew, hcNoContext,
      NewItem(tr('~O~pen...'), 'F3', kbF3, cmOpen, hcNoContext,
      NewLine(
      NewItem(tr('~S~ave'), 'F2', kbF2, cmSave, hcNoContext,
      NewItem(tr('Save ~a~s...'), '', 0, cmSaveAs, hcNoContext,
      NewItem(tr('~P~rint...'), '', kbNoKey, cmPrint, hcNoContext,
      NewLine(
      NewItem(tr('~C~hange directory...'), '', kbNoKey, cmChangeDir, hcNoContext,
{      NewItem('~D~OS aufrufen', '', kbNoKey, cmDosShell, hcNoContext,}
      NewLine(
      NewItem(tr('~Q~uit'), 'Alt-X', kbAltX, cmQuit, hcNoContext,
      NIL))))))))))),
    NewSubMenu(tr('~E~dit'), hcNoContext, NewMenu(
      NewItem(tr('~U~ndo'), 'Alt-Back', kbAltBack, cmUndo, hcNoContext,
      NewLine(
      NewItem(tr('Cu~t~'), 'Shift-Del', kbShiftDel, cmCut, hcNoContext,
      NewItem(tr('~C~opy'), 'Ctrl-Ins', kbCtrlIns, cmCopy, hcNoContext,
      NewItem(tr('~P~aste'), 'Shift-Ins', kbShiftIns, cmPaste, hcNoContext,
      NewItem(tr('C~l~ear'), 'Ctrl-Del', kbCtrlDel, cmClear, hcNoContext,
      NewLine(
      NewItem(tr('~S~how clipboard'), '', 0, cmShowClip, hcNoContext,
      NIL))))))))),
    NewSubMenu(tr('~S~earch'), hcNoContext, NewMenu(
      NewItem(tr('~F~ind...'), '', kbNoKey, cmFind, hcNoContext,
      NewItem(tr('~R~eplace...'), '', kbNoKey, cmReplace, hcNoContext,
      NewItem(tr('Search ~a~gain'), 'Alt-W', kbAltW, cmSearchAgain, hcNoContext,
      NIL)))),
    NewSubMenu(tr('~C~ompiler'), hcNoContext, NewMenu(
      NewItem(tr('~R~un'), 'Ctrl-F9', kbCtrlF9, cmRun, hcNoContext,
      NewItem(tr('C~o~mpile'), 'Alt-F9', kbAltF9, cmCompile, hcNoContext,
      NewItem(tr('~S~ingle step'), 'Ctrl-F8', kbCtrlF8, cmDebug, hcNoContext,
      NewItem(tr('~R~eset program'), 'Ctrl-F2', kbCtrlF2, cmReset, hcNoContext,
      NewLine(
      NewItem(tr('~T~each in'), '', 0, cmTeachIn, hcNoContext,
      NIL))))))),
    NewSubMenu(tr('F~i~eld'), hcNoContext, NewMenu(
      NewItem(tr('~N~ew'), '', 0, cmNewFeld, hcNoContext,
      NewItem(tr('~O~pen...'), '', 0, cmOpenFeld, hcNoContext,
      NewLine(
      NewItem(tr('~S~ave'), '', 0, cmSaveFeld, hcNoContext,
      NewItem(tr('Save ~a~s...'), '', 0, cmSaveAsFeld, hcNoContext,
      NewItem(tr('~P~rint...'), '', 0, cmPrintFeld, hcNoContext,
      NewLine(
      NewItem(tr('S~u~pply...'), '', 0, cmVorrat, hcNoContext,
      NewItem(tr('Sp~e~ed...'), '', 0, cmSpeed, hcNoContext,
      NIL)))))))))),
    NewSubMenu(tr('~W~indow'), hcNoContext, NewMenu(
      NewItem(tr('~T~ile'), '', kbNoKey, cmTile, hcNoContext,
      NewItem(tr('~C~ascade'), '', kbNoKey, cmCascade, hcNoContext,
      NewItem(tr('Cl~o~se all'), '', kbNoKey, cmCloseAll, hcNoContext,
      NewLine(
      NewItem(tr('Si~z~e/move'),'Ctrl+F5', kbCtrlF5, cmResize, hcNoContext,
      NewItem(tr('~Z~oom'), 'F5', kbF5, cmZoom, hcNoContext,
      NewItem(tr('~N~ext'), 'F6', kbF6, cmNext, hcNoContext,
      NewItem(tr('~P~revious'), 'Shift+F6', kbShiftF6, cmPrev, hcNoContext,
      NewItem(tr('C~l~ose...'), 'Alt+F3', kbAltF3, cmClose, hcNoContext,
      NewLine(
      NewItem(tr('~I~nfo window on/off'), '', 0, cmInfoWin, hcNoContext,
      NewItem(tr('~D~isassemble'), '', 0, cmDisasmWin, hcNoContext,
      NIL))))))))))))),
    NewSubMenu(tr('~H~elp'), hcNoContext, NewMenu(
      NewItem(tr('~C~ontents'), 'F1', kbF1, cmHelp, hcNoContext,
      NewItem(tr('~P~ASCAL help'), 'Ctrl-F1', kbCtrlF1, cmPascalHelp, hcNoContext,
      NewLine(
      NewItem(tr('~A~bout'), '', 0, cmInfo, hcNoContext,
      NIL))))),
    NIL))))))))));


END;

PROCEDURE TNikiApplication.HandleEvent(VAR Event:TEvent);
VAR NewMode: TVideoMode;
BEGIN
  CASE Event.What OF
    evCommand : CASE Event.Command OF
                  cmNew : Neu;
                  cmOpen : Oeffnen;
                  cmShowClip: ZeigeClipboard;
                  cmInfo : Info;

                  cmNewFeld : FeldNeu;
                  cmOpenFeld: FeldOeffnen;

                  cmInfoWin:BEGIN
                              IF InfoWindow^.GetState(sfVisible) THEN
                                HideInfo
                              ELSE ShowInfo;
                            END;
                  cmDisasmWin:
                            IF DisasmWindow <> NIL THEN
                            BEGIN
                              IF DisasmWindow^.GetState(sfVisible) THEN
                                DisasmWindow^.Hide
                              ELSE BEGIN
                                DisasmWindow^.Show;
                                DisasmWindow^.Select;
                              END;
                            END;
                  cmRun:  IF (TypeOf(Desktop^.Current^)<>TypeOf(TNikiEditor)) THEN
                            IF EditWindow<>NIL THEN
                            BEGIN
                              PNikiEditor(EditWindow)^.Run(FALSE);
                              ClearEvent(Event);
                            END;
                  cmDebug:IF (TypeOf(Desktop^.Current^)<>TypeOf(TNikiEditor)) THEN
                            IF EditWindow<>NIL THEN
                            BEGIN
                              PNikiEditor(EditWindow)^.Run(TRUE);
                              ClearEvent(Event);
                            END;
                  cmCompile, cmPrint:
                          IF TypeOf(Desktop^.Current^)<>TypeOf(TNikiEditor) THEN
                            IF EditWindow<>NIL THEN EditWindow^.Select;
                  cmVorrat, cmSpeed, cmTeachIn, cmPrintFeld:
                          IF TypeOf(Desktop^.Current^)<>TypeOf(TFeldWindow) THEN
                            IF FeldWindow<>NIL THEN
                            BEGIN
                              IF InfoWindow<>NIL THEN InfoWindow^.Select;
                              FeldWindow^.Select;
                            END;
                  cmChangeDir: ChangeDir;
                  cmHelp: Hilfe(hcNoContext, FALSE);
                  cmPascalHelp: Hilfe(hcPascal, FALSE);
                  cmResizeApp: BEGIN
                    { Handle terminal resize - use new size from event }
                    NewMode.Col := Event.Id;
                    NewMode.Row := Event.InfoWord;
                    NewMode.Color := True;
                    SetScreenVideoMode(NewMode);
                    ArrangeWindows;
                    Redraw;
                    ClearEvent(Event);
                  END;
                END;
  END;
  INHERITED HandleEvent(Event);
END;

PROCEDURE TNikiApplication.GetEvent(var Event: TEvent);
BEGIN
  INHERITED GetEvent(Event);

  IF (Event.What=evKeyDown) AND (Event.KeyCode=kbF1) THEN
  BEGIN
    Event.What := evNothing;
    Hilfe(GetHelpCtx, TopView <> @Self);
  END;

  { Global quit shortcut - Ctrl-Q works regardless of focused view }
  IF (Event.What=evKeyDown) AND (Event.KeyCode=kbCtrlQ) THEN
  BEGIN
    Event.What := evCommand;
    Event.Command := cmQuit;
  END;
END;

FUNCTION TNikiApplication.OpenEditor(FileName: FNameStr; Visible: Boolean): PEditWindow;
VAR
  P: PWindow;
  R: TRect;
BEGIN
  { Inherit size and position from current editor if one exists }
  IF EditWindow <> NIL THEN
    EditWindow^.GetBounds(R)
  ELSE
    DeskTop^.GetExtent(R);
  P := New(PNikiEditor, Init(R, FileName, wnNoNumber));
  IF NOT Visible THEN P^.Hide;
  OpenEditor := PNikiEditor(InsertWindow(P));
END;

PROCEDURE TNikiApplication.Idle;
{$ifdef Debug}
VAR x,y:Integer;
{$endif}
BEGIN
  INHERITED Idle;

  IF FeldWindow<>NIL THEN FeldWindow^.Idle;

  { Only animate spinner when a program is running }
  IF Balken<>NIL THEN
  BEGIN
    IF (FeldWindow<>NIL) AND FeldWindow^.IsRunning THEN
    BEGIN
      Balken^.SetActive(TRUE);
      Balken^.Idle;
    END
    ELSE
      Balken^.SetActive(FALSE);
  END;

  {$ifdef Debug}
  x := WhereX;
  y := WhereY;
  GotoXY(70,25);
  Write(MemAvail);
  GotoXY(x,y);
  {$endif}
END;

PROCEDURE TNikiApplication.Neu;
BEGIN
   OpenEditor('', TRUE);
END;

PROCEDURE TNikiApplication.Oeffnen;
VAR DateiName:String[100];
    OldWindow: PEditWindow;
BEGIN
  DateiName := '*.PAS';
  IF ExecuteDialog(New(PFileDialog, Init('*.PAS', tr('Open File'),
         tr('~N~ame'), fdOpenButton, 100)), @DateiName) <> cmCancel
  THEN BEGIN
    { Remember untitled unmodified window to close after opening new file }
    OldWindow := NIL;
    IF (EditWindow <> NIL) AND (EditWindow^.Editor <> NIL) THEN
      IF (EditWindow^.Editor^.FileName = '') AND NOT EditWindow^.Editor^.Modified THEN
        OldWindow := EditWindow;
    OpenEditor(DateiName, TRUE);
    IF OldWindow <> NIL THEN OldWindow^.Close;
  END;
END;

PROCEDURE TNikiApplication.ZeigeClipboard;
BEGIN
  ClipWindow^.Select;
  ClipWindow^.Show;
END;

PROCEDURE TNikiApplication.Info;
BEGIN
  ExecuteDialog( New( PCopyrightDialog, Init), NIL);
END;

FUNCTION TNikiApplication.OpenFeld(FileName: FNameStr): PFeldWindow;
VAR
  P: PWindow;
  R: TRect;
  OldOrigin: TPoint;
  HadWindow: Boolean;
CONST
  { Window size = field content (61x21) + frame (2x2) }
  FieldWindowW = 63;  { SizeX + 2 }
  FieldWindowH = 23;  { SizeY + 2 }
BEGIN
  HadWindow := FALSE;
  IF FeldWindow<>NIL THEN
  BEGIN
    IF FeldWindow^.CanClose THEN
    BEGIN
      { Remember position before disposing }
      OldOrigin := FeldWindow^.Origin;
      HadWindow := TRUE;
      Dispose(FeldWindow, Done);
      FeldWindow:=NIL;
    END;
  END;

  IF FeldWindow=NIL THEN
  BEGIN
    { Create window with exact size needed for content + frame }
    IF HadWindow THEN
      R.Assign(OldOrigin.X, OldOrigin.Y, OldOrigin.X + FieldWindowW, OldOrigin.Y + FieldWindowH)
    ELSE
      R.Assign(0, 0, FieldWindowW, FieldWindowH);
    P := New(PFeldWindow, Init(R, FileName));
    FeldWindow := PFeldWindow(InsertWindow(P));
  END;

  OpenFeld := FeldWindow;
END;

PROCEDURE TNikiApplication.FeldNeu;
BEGIN
  OpenFeld('');
END;

PROCEDURE TNikiApplication.FeldOeffnen;
VAR DateiName:String[100];
BEGIN
  DateiName := '*.ROB';
  IF ExecuteDialog(New(PFileDialog, Init('*.ROB', tr('Open Field'),
         tr('~N~ame'), fdOpenButton, 100)), @DateiName) <> cmCancel
  THEN OpenFeld(DateiName);
END;

FUNCTION TNikiApplication.GetPalette:ppalette;
CONST CNeuColor=CAppColor+CHelpColor+CFeldColor;
      CNeuBW=CAppBlackwhite+CHelpBlackWhite+CFeldBlackWhite;
      CNeuMono=CAppMonochrome+CHelpMonochrome+CFeldMonochrome;

      P:ARRAY[apcolor..apmonochrome] OF string[length(CNeuColor)]
        =(CNeuColor,CNeuBW,CNeuMono);
BEGIN
  GetPalette:=@P[apppalette];
END;

PROCEDURE TNikiApplication.ShowInfo;
BEGIN
  InfoWindow^.Show;
  InfoWindow^.Select;
END;

PROCEDURE TNikiApplication.HideInfo;
BEGIN
  InfoWindow^.Hide;
END;

PROCEDURE TNikiApplication.ChangeDir;
BEGIN
  Desktop^.ExecView (New(PChDirDialog, Init(cdNormal, 0)));
END;

FUNCTION CalcHelpName: PathStr;
VAR
  EXEName: PathStr;
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
  Lang: String;
  Result: PathStr;
BEGIN
  EXEName := ParamStr(0);
  FSplit(EXEName, Dir, Name, Ext);
  { Remove trailing path separator }
  if (Length(Dir) > 0) and (Dir[Length(Dir)] in ['/', '\']) then
    Dec(Dir[0]);

  { Try language-specific help file first (e.g., hilfe.en.hlp) }
  Lang := GetCurrentLang;
  Result := FSearch('hilfe.' + Lang + '.hlp', Dir);
  IF Result <> '' THEN
  BEGIN
    CalcHelpName := Result;
    Exit;
  END;

  { Fall back to default help file }
  CalcHelpName := FSearch('hilfe.hlp', Dir);
END;


PROCEDURE TNikiApplication.Hilfe(Ctx:Integer; Modal:BOOLEAN);
VAR Name:String;
    h:PHelpWindow;
BEGIN
  name := CalcHelpName;
  IF Name='' THEN
  BEGIN
    MessageBox(tr('Cannot open help file'),
      NIL, mfError+mfOkButton);
  END ELSE
  BEGIN
    IF Modal THEN
    BEGIN
      IF (HelpWindow=NIL)
         { OR
         ((HelpWindow<>NIL) AND (NOT HelpWindow^.GetState(sfModal)))} THEN
      BEGIN
        h := New( PMyHelpWindow, Init(Name, Ctx,
               GetNumOption('BIGHELP', 0)=1));
        ExecView(h);
        Dispose(h, Done);
      END;
    END
    ELSE
    BEGIN
      InsertWindow( New( PMyHelpWindow, Init(Name, Ctx,
        GetNumOption('BIGHELP', 0)=1)));
    END;
  END;
END;


END.