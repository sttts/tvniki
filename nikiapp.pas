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

                           PROCEDURE SwitchVideoMode;

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
     NikiHelp, HelpFile, Hilfe, Config;

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

  { Position info below field on right }
  IF InfoWindow <> NIL THEN
  BEGIN
    R.A.X := DeskW - 17;
    R.A.Y := FieldH;
    R.B.X := DeskW;
    R.B.Y := FieldH + 6;
    IF R.B.Y > DeskH THEN R.B.Y := DeskH;
    InfoWindow^.Locate(R);
  END;
END;

CONSTRUCTOR TNikiApplication.Init;
VAR z:Integer;
    P:TPoint;
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

  FeldNeu;

  IF ParamCount=0 THEN
    EditWindow := OpenEditor('', TRUE)
  ELSE
    FOR z:=1 TO ParamCount DO EditWindow := OpenEditor(ParamStr(z), TRUE);

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

PROCEDURE TNikiApplication.SwitchVideoMode;
BEGIN
  { Toggle 25/50 line mode - simplified for Free Vision }
  { In Free Vision, ScreenMode is a TVideoMode record, not a simple Word }
  { This function is a placeholder - line mode switching may need terminal support }
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
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt-X~/~Ctrl-Q~ Exit', kbAltX, cmQuit,
      NewStatusKey('', kbCtrlQ, cmQuit,
      StdStatusKeys(nil))), nil)));
END;

PROCEDURE TNikiApplication.InitMenuBar;
VAR R : TRect;
BEGIN
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New (PMenuBar, Init(R, NewMenu(
    NewSubMenu('~D~atei', hcNoContext, NewMenu(
      NewItem('~N~eu', '', 0, cmNew, hcNoContext,
      NewItem('~Ö~ffnen...', 'F3', kbF3, cmOpen, hcNoContext,
      NewLine(
      NewItem('~S~peichern', 'F2', kbF2, cmSave, hcNoContext,
      NewItem('Speichern ~a~ls...', '', 0, cmSaveAs, hcNoContext,
      NewItem('~D~rucken...', '', kbNoKey, cmPrint, hcNoContext,
      NewLine(
      NewItem('~V~erzeichnis wechseln...', '', kbNoKey, cmChangeDir, hcNoContext,
{      NewItem('~D~OS aufrufen', '', kbNoKey, cmDosShell, hcNoContext,}
      NewLine(
      NewItem('~B~eenden', 'Alt-X', kbAltX, cmQuit, hcNoContext,
      NIL))))))))))),
    NewSubMenu('~B~earbeiten', hcNoContext, NewMenu(
      NewItem('~U~ndo', 'Alt-Back', kbAltBack, cmUndo, hcNoContext,
      NewLine(
      NewItem('~A~usschneiden', 'Shift-Del', kbShiftDel, cmCut, hcNoContext,
      NewItem('~K~opieren', 'Ctrl-Ins', kbCtrlIns, cmCopy, hcNoContext,
      NewItem('~E~infügen', 'Shift-Ins', kbShiftIns, cmPaste, hcNoContext,
      NewItem('~L~öschen', 'Ctrl-Del', kbCtrlDel, cmClear, hcNoContext,
      NewLine(
      NewItem('~Z~eige Clipboard', '', 0, cmShowClip, hcNoContext,
      NIL))))))))),
    NewSubMenu('~S~uchen', hcNoContext, NewMenu(
      NewItem('~S~uchen...', '', kbNoKey, cmFind, hcNoContext,
      NewItem('~E~rsetzen...', '', kbNoKey, cmReplace, hcNoContext,
      NewItem('~W~eitersuchen', 'Alt-W', kbAltW, cmSearchAgain, hcNoContext,
      NIL)))),
    NewSubMenu('~C~ompiler', hcNoContext, NewMenu(
      NewItem('~A~usführen', 'Ctrl-F9', kbCtrlF9, cmRun, hcNoContext,
      NewItem('~C~ompilieren', 'Alt-F9', kbAltF9, cmCompile, hcNoContext,
      NewItem('~E~inzelschritt', 'Ctrl-F8', kbCtrlF8, cmDebug, hcNoContext,
      NewItem('Programm ~z~urücksetzen', 'Ctrl-F2', kbCtrlF2, cmReset, hcNoContext,
      NewLine(
      NewItem('~T~each in', '', 0, cmTeachIn, hcNoContext,
      NIL))))))),
    NewSubMenu('~F~eld', hcNoContext, NewMenu(
      NewItem('~N~eu', '', 0, cmNewFeld, hcNoContext,
      NewItem('~Ö~ffnen...', '', 0, cmOpenFeld, hcNoContext,
      NewLine(
      NewItem('~S~peichern', '', 0, cmSaveFeld, hcNoContext,
      NewItem('Speichern ~a~ls...', '', 0, cmSaveAsFeld, hcNoContext,
      NewItem('~D~rucken...', '', 0, cmPrintFeld, hcNoContext,
      NewLine(
      NewItem('~V~orrat...', '', 0, cmVorrat, hcNoContext,
      NewItem('~G~eschwindigkeit...', '', 0, cmSpeed, hcNoContext,
      NIL)))))))))),
    NewSubMenu('Fe~n~ster', hcNoContext, NewMenu(
      NewItem('~N~ebeneinander', '', kbNoKey, cmTile, hcNoContext,
      NewItem('~H~intereinander', '', kbNoKey, cmCascade, hcNoContext,
      NewItem('Alle ~s~chließen', '', kbNoKey, cmCloseAll, hcNoContext,
      NewLine(
      NewItem('~G~röße/Position','Ctrl+F5', kbCtrlF5, cmResize, hcNoContext,
      NewItem('~V~ergrößern', 'F5', kbF5, cmZoom, hcNoContext,
      NewItem('Nä~c~hstes', 'F6', kbF6, cmNext, hcNoContext,
      NewItem('V~o~rheriges', 'Shift+F6', kbShiftF6, cmPrev, hcNoContext,
      NewItem('~S~chließen...', 'Alt+F3', kbAltF3, cmClose, hcNoContext,
      NewLine(
      NewItem('~V~ideomodus ändern', '', 0, cmVidMode, hcNoContext,
      NewItem('~I~nfo-Fenster An/Aus', '', 0, cmInfoWin, hcNoContext,
      NIL))))))))))))),
    NewSubMenu('~H~ilfe', hcNoContext, NewMenu(
      NewItem('I~n~halt', 'F1', kbF1, cmHelp, hcNoContext,
      NewItem('~P~ASCAL-Hilfe', 'Ctrl-F1', kbCtrlF1, cmPascalHelp, hcNoContext,
      NewLine(
      NewItem('~I~nfo', '', 0, cmInfo, hcNoContext,
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
                  cmRun, cmCompile, cmPrint, cmDebug:
                          IF TypeOf(Desktop^.Current^)<>TypeOf(TNikiEditor) THEN
                            IF EditWindow<>NIL THEN EditWindow^.Select;
                  cmVorrat, cmSpeed, cmTeachIn, cmPrintFeld:
                          IF TypeOf(Desktop^.Current^)<>TypeOf(TFeldWindow) THEN
                            IF FeldWindow<>NIL THEN
                            BEGIN
                              IF InfoWindow<>NIL THEN InfoWindow^.Select;
                              FeldWindow^.Select;
                            END;
                  cmVidMode: SwitchVideoMode;
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
END;

FUNCTION TNikiApplication.OpenEditor(FileName: FNameStr; Visible: Boolean): PEditWindow;
VAR
  P: PWindow;
  R: TRect;
BEGIN
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
  IF Balken<>NIL THEN Balken^.Idle;

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
BEGIN
  DateiName := '*.PAS';
  IF ExecuteDialog(New(PFileDialog, Init('*.PAS', 'Datei Öffnen',
         '~N~ame', fdOpenButton, 100)), @DateiName) <> cmCancel
  THEN OpenEditor(DateiName, TRUE);
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
CONST
  { Window size = field content (61x21) + frame (2x2) }
  FieldWindowW = 63;  { SizeX + 2 }
  FieldWindowH = 23;  { SizeY + 2 }
BEGIN
  IF FeldWindow<>NIL THEN
  BEGIN
    IF FeldWindow^.CanClose THEN
    BEGIN
      Dispose(FeldWindow, Done);
      FeldWindow:=NIL;
    END;
  END;

  IF FeldWindow=NIL THEN
  BEGIN
    { Create window with exact size needed for content + frame }
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
  IF ExecuteDialog(New(PFileDialog, Init('*.ROB', 'Feld Öffnen',
         '~N~ame', fdOpenButton, 100)), @DateiName) <> cmCancel
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
BEGIN
  if Lo(DosVersion) >= 3 then EXEName := ParamStr(0)
  else EXEName := FSearch('TVDEMO.EXE', GetEnv('PATH'));
  FSplit(EXEName, Dir, Name, Ext);
  if Dir[Length(Dir)] = '\' then Dec(Dir[0]);
  CalcHelpName := FSearch('HILFE.HLP', Dir);
END;


PROCEDURE TNikiApplication.Hilfe(Ctx:Integer; Modal:BOOLEAN);
VAR Name:String;
    h:PHelpWindow;
BEGIN
  name := CalcHelpName;
  IF Name='' THEN
  BEGIN
    MessageBox('Die Hilfedatei kann nicht geöffnet werden',
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