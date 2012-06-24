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
USES Dos, NikiCnst, NikiEdit, NikiInfo, Crt, NikiGlob, NikiCopy,
     NikiHelp, HelpFile, Hilfe, Config;

CONST HeapSize = (128 * 1024) DIV 16;

CONSTRUCTOR TNikiApplication.Init;
VAR z:Integer;
    P:TPoint;
    sMode:String;
    Mode:Integer;
BEGIN
  MaxHeapSize := HeapSize;
  LoadConfig('NIKI.CFG');

  INHERITED Init;

  RegisterObjects;
  RegisterViews;
  RegisterMenus;
  RegisterApp;
  RegisterHelpFile;

  IF MemAvail<64*1024 THEN
    MessageBox(
    'Sie haben nur sehr wenig Speicher zur VerfÅgung, so da· es vorkommen kann, da· einige Funktionen nicht funtionieren',
    NIL, mfError+mfOkButton);

  FeldWindow:=NIL;

  CreateClipboard;

  P.X:=80-17;
  P.Y:=0;

  InfoWindow := New(PInfoDialog, Init(P));
  InsertWindow(InfoWindow);

  FeldNeu;

  IF ParamCount=0 THEN
    Neu
  ELSE
    FOR z:=1 TO ParamCount DO OpenEditor(ParamStr(z), TRUE);

  Mode := smCO80;
  sMode := GetStrOption('VIDMODE', 'COLOR');
  IF sMode='BW' THEN Mode := smBW80 ELSE
    IF sMode='MONO' THEN
      Mode := smMono;

  IF GetNumOption('LINES', 25)=50 THEN
    Mode := Mode OR smFont8x8;

  SetScreenMode(Mode);
  Redraw;

  Info;
END;

PROCEDURE TNikiApplication.SwitchVideoMode;
BEGIN
  SetScreenMode(ScreenMode XOR smFont8x8);
END;

PROCEDURE TNikiApplication.CreateClipboard;
VAR
  R: TRect;
BEGIN
  DeskTop^.GetExtent(R);
  ClipWindow := New( PEditWindow, Init(R, '', wnNoNumber));
  IF ClipWindow <> NIL THEN
  BEGIN
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
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      StdStatusKeys(nil)), nil)));
END;

PROCEDURE TNikiApplication.InitMenuBar;
VAR R : TRect;
BEGIN
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New (PMenuBar, Init(R, NewMenu(
    NewSubMenu('~D~atei', hcNoContext, NewMenu(
      NewItem('~N~eu', '', 0, cmNew, hcNoContext,
      NewItem('ô~f~fnen...', 'F3', kbF3, cmOpen, hcNoContext,
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
      NewItem('~U~ndo', 'Alt-RÅck', kbAltBack, cmUndo, hcNoContext,
      NewLine(
      NewItem('~A~usschneiden', 'Shift-Entf', kbShiftDel, cmCut, hcNoContext,
      NewItem('~K~opieren', 'Strg-Einfg', kbCtrlIns, cmCopy, hcNoContext,
      NewItem('~E~infÅgen', 'Shift-Einfg', kbShiftIns, cmPaste, hcNoContext,
      NewItem('~L~îschen', 'Strg-Entf', kbCtrlDel, cmClear, hcNoContext,
      NewLine(
      NewItem('~Z~eige Clipboard', '', 0, cmShowClip, hcNoContext,
      NIL))))))))),
    NewSubMenu('~S~uchen', hcNoContext, NewMenu(
      NewItem('~S~uchen...', '', kbNoKey, cmFind, hcNoContext,
      NewItem('~E~rsetzen...', '', kbNoKey, cmReplace, hcNoContext,
      NewItem('~W~eitersuchen', 'Alt-W', kbAltW, cmSearchAgain, hcNoContext,
      NIL)))),
    NewSubMenu('~C~ompiler', hcNoContext, NewMenu(
      NewItem('~A~usfÅhren', 'Strg-F9', kbCtrlF9, cmRun, hcNoContext,
      NewItem('~C~ompilieren', 'Alt-F9', kbAltF9, cmCompile, hcNoContext,
      NewItem('~E~inzelschritt', 'Strg-F8', kbCtrlF8, cmDebug, hcNoContext,
      NewItem('Programm ~z~urÅcksetzen', 'Strg-F2', kbCtrlF2, cmReset, hcNoContext,
      NewLine(
      NewItem('~T~each in', '', 0, cmTeachIn, hcNoContext,
      NIL))))))),
    NewSubMenu('~F~eld', hcNoContext, NewMenu(
      NewItem('~N~eu', '', 0, cmNewFeld, hcNoContext,
      NewItem('ô~f~fnen...', '', 0, cmOpenFeld, hcNoContext,
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
      NewItem('Alle ~s~chlie·en', '', kbNoKey, cmCloseAll, hcNoContext,
      NewLine(
      NewItem('~G~rî·e/Position','Ctrl+F5', kbCtrlF5, cmResize, hcNoContext,
      NewItem('~V~ergrî·ern', 'F5', kbF5, cmZoom, hcNoContext,
      NewItem('NÑ~c~hstes', 'F6', kbF6, cmNext, hcNoContext,
      NewItem('V~o~rheriges', 'Shift+F6', kbShiftF6, cmPrev, hcNoContext,
      NewItem('~S~chlie·en...', 'Alt+F3', kbAltF3, cmClose, hcNoContext,
      NewLine(
      NewItem('~V~ideomodus Ñndern', '', 0, cmVidMode, hcNoContext,
      NewItem('~I~nfo-Fenster An/Aus', '', 0, cmInfoWin, hcNoContext,
      NIL))))))))))))),
    NewSubMenu('~H~ilfe', hcNoContext, NewMenu(
      NewItem('I~n~halt', 'F1', kbF1, cmHelp, hcNoContext,
      NewItem('~P~ASCAL-Hilfe', 'Strg-F1', kbCtrlF1, cmPascalHelp, hcNoContext,
      NewLine(
      NewItem('~I~nfo', '', 0, cmInfo, hcNoContext,
      NIL))))),
    NIL))))))))));


END;

PROCEDURE TNikiApplication.HandleEvent(VAR Event:TEvent);
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
VAR x,y:Integer;
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
  IF ExecuteDialog(New(PFileDialog, Init('*.PAS', 'Datei îffnen',
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
  E: TEvent;
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
    DeskTop^.GetExtent(R);
    P := New(PFeldWindow, Init(R, FileName));
    FeldWindow := PFeldWindow(InsertWindow(P));
  END;
END;

PROCEDURE TNikiApplication.FeldNeu;
BEGIN
  OpenFeld('');
END;

PROCEDURE TNikiApplication.FeldOeffnen;
VAR DateiName:String[100];
BEGIN
  DateiName := '*.ROB';
  IF ExecuteDialog(New(PFileDialog, Init('*.ROB', 'Feld îffnen',
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


PROCEDURE TNikiApplication.Hilfe;
VAR Name:String;
    h:PHelpWindow;
BEGIN
  name := CalcHelpName;
  IF Name='' THEN
  BEGIN
    MessageBox('Die Hilfedatei kann nicht geîffnet werden',
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