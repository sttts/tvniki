UNIT NikiEdit;

INTERFACE
USES Objects, App, Views, Drivers, Editors, Dialogs, TVEnh, NikiGlob, Printer;

TYPE PNikiEditor=^TNikiEditor;
     TNikiEditor=OBJECT(TEditWindow)
                   Compiled:Boolean;
                   LastCursorLine:Word;
                   CONSTRUCTOR Init(VAR Bounds: TRect;
                       FileName: FNameStr; ANumber: Integer);
                   DESTRUCTOR Done; VIRTUAL;

                   PROCEDURE SetState(AState: Word; Enable: Boolean); VIRTUAL;
                   PROCEDURE HandleEvent(VAR Event:TEvent); VIRTUAL;

                   PROCEDURE UpdateCommands; VIRTUAL;
                   PROCEDURE CheckCursorSync;

                   FUNCTION GetTitle(MaxLen: Sw_Integer): TTitleStr; VIRTUAL;
                   FUNCTION Compile:BOOLEAN;
                   PROCEDURE Run(Debug:BOOLEAN);
                   PROCEDURE Print;
                   PROCEDURE ShowError; VIRTUAL;
                 END;

IMPLEMENTATION
USES NikiCnst, NikiComp, Compiler, MsgBox, NikiFeld, Dos, NikiInfo,
     StdDlg, Hilfe, NikiPrnt, Config, SysUtils, NikiStrings, NikiDasm;

{$F+}
FUNCTION MyEditorDialog(Dialog: Integer; Info: Pointer): Word;
VAR
  R: TRect;
  T: TPoint;
BEGIN
  CASE Dialog OF
    edOutOfMemory:
      MyEditorDialog := MessageBox('Not enough memory for this operation.',
        nil, mfError + mfOkButton);
    edReadError:
      MyEditorDialog := MessageBox('Error reading file %s.',
        @Info, mfError + mfOkButton);
    edWriteError:
      MyEditorDialog := MessageBox('Error writing file %s.',
        @Info, mfError + mfOkButton);
    edCreateError:
      MyEditorDialog := MessageBox('Error creating file %s.',
        @Info, mfError + mfOkButton);
    edSaveModify:
      MyEditorDialog := MessageBox(tr('%s has been modified. Save?'),
        @Info, mfInformation + mfYesNoCancel);
    edSaveUntitled:
      MyEditorDialog := MessageBox(tr('Save untitled file?'),
        nil, mfInformation + mfYesNoCancel);
    edSaveAs:
      MyEditorDialog :=
        Application^.ExecuteDialog(New(PFileDialog, Init('*.PAS',
        tr('Save as'), tr('~N~ame'), fdOkButton, 101)), Info);
    edFind:
      MyEditorDialog :=
        Application^.ExecuteDialog(CreateFindDialog, Info);
    edSearchFailed:
      MyEditorDialog := MessageBox(tr('Search string not found.'),
        nil, mfError + mfOkButton);
    edReplace:
      MyEditorDialog :=
        Application^.ExecuteDialog(CreateReplaceDialog, Info);
    edReplacePrompt:
      begin
        { Avoid placing the dialog on the same line as the cursor }
        R.Assign(0, 1, 40, 8);
        R.Move((Desktop^.Size.X - R.B.X) div 2, 0);
        Desktop^.MakeGlobal(R.B, T);
        Inc(T.Y);
        if TPoint(Info).Y <= T.Y then
          R.Move(0, Desktop^.Size.Y - R.B.Y - 2);
        MyEditorDialog := MessageBoxRect(R, tr('Replace this occurrence?'),
          nil, mfYesNoCancel + mfInformation);
      end;
  end;
end;

{$F-}

{***********************************************}

CONSTRUCTOR TNikiEditor.Init(VAR Bounds: TRect;
    FileName: FNameStr; ANumber: Integer);
BEGIN
  INHERITED Init(Bounds, FileName, ANumber);
  State := State AND NOT sfShadow;

  Editor^.Modified := FALSE;
  Compiled := FALSE;
  LastCursorLine := 0;
  HelpCtx := hcEditor;
END;

DESTRUCTOR TNikiEditor.Done;
BEGIN
  IF EditWindow = @Self THEN EditWindow := NIL;
  INHERITED Done;
END;

FUNCTION TNikiEditor.GetTitle(MaxLen: Sw_Integer): TTitleStr;
VAR
  FileName, RelPath: String;
BEGIN
  IF Editor = NIL THEN
    GetTitle := ''
  ELSE BEGIN
    FileName := Editor^.FileName;
    IF FileName = '' THEN
      GetTitle := tr('Untitled')
    ELSE BEGIN
      RelPath := ExtractRelativePath(GetCurrentDir + PathDelim, FileName);
      IF Length(RelPath) < Length(FileName) THEN
        GetTitle := Copy(RelPath, 1, MaxLen)
      ELSE
        GetTitle := Copy(FileName, 1, MaxLen);
    END;
  END;
END;

PROCEDURE TNikiEditor.HandleEvent(VAR Event:TEvent);
VAR
  TargetLine: Word;
  LineNum: Word;
  i: LongInt;
  p: LongInt;
BEGIN
  { Handle Ctrl-A/Ctrl-E for line navigation before inherited }
  IF (Event.What = evKeyDown) AND (Editor <> NIL) THEN
  BEGIN
    CASE Event.CharCode OF
      #1: BEGIN { Ctrl-A - go to beginning of line }
        p := Editor^.CurPtr;
        WHILE (p > 0) AND (Editor^.BufChar(p - 1) <> #10) DO
          Dec(p);
        Editor^.SetCurPtr(p, 0);
        ClearEvent(Event);
        Exit;
      END;
      #5: BEGIN { Ctrl-E - go to end of line }
        p := Editor^.CurPtr;
        WHILE (p < Editor^.BufLen) AND (Editor^.BufChar(p) <> #10) DO
          Inc(p);
        Editor^.SetCurPtr(p, 0);
        ClearEvent(Event);
        Exit;
      END;
    END;
  END;

  CASE Event.What OF
    evCommand : CASE Event.Command OF
                  cmCompile : BEGIN
                                EditWindow := @Self;
                                Compile;
                              END;
                  cmRun : BEGIN
                            EditWindow := @Self;
                            Run(FALSE);
                          END;
                  cmDebug:BEGIN
                            IF GetNumOption('DEBUG', 1)=0 THEN
                            BEGIN
                              MessageBox(tr('Debug mode has been disabled via the DEBUG switch in NIKI.CFG.'),
                                NIL, mfOkButton);
                            END;

                            EditWindow := @Self;
                            Run(TRUE);
                          END;

                  cmPrint : BEGIN
                              EditWindow := @Self;
                              Print;
                            END;
                END;
    evBroadcast: CASE Event.Command OF
                   cmGotoEditorLine: BEGIN
                     TargetLine := Word(PtrUInt(Event.InfoPtr));
                     IF (Editor <> NIL) AND (TargetLine > 0) THEN
                     BEGIN
                       { Find character position of target line }
                       LineNum := 1;
                       i := 0;
                       WHILE (i < Editor^.BufLen) AND (LineNum < TargetLine) DO
                       BEGIN
                         IF Editor^.BufChar(i) = #10 THEN Inc(LineNum);
                         Inc(i);
                       END;
                       { Move cursor (invisible when not focused) }
                       Editor^.SetCurPtr(i, 0);
                       { Set highlight line and scroll to show it }
                       EditorHighlightLine := TargetLine;
                       Editor^.ScrollTo(0, TargetLine - 1 - Editor^.Size.Y DIV 2);
                       DrawView;
                     END;
                     ClearEvent(Event);
                     Exit;
                   END;
                 END;
  END;
  INHERITED HandleEvent(Event);

  { Clear disasm when editor becomes dirty after compile }
  IF Compiled AND Editor^.Modified THEN
  BEGIN
    DisasmFileName := '';
    IF (DisasmWindow <> NIL) AND (DisasmWindow^.Viewer <> NIL) THEN
    BEGIN
      DisasmWindow^.Viewer^.Clear;
      DisasmWindow^.DrawView;
    END;
  END;
  Compiled := Compiled AND NOT Editor^.Modified;
  CheckCursorSync;
END;

PROCEDURE TNikiEditor.SetState(AState: Word; Enable: Boolean);
BEGIN
  INHERITED SetState(AState, Enable);
  IF (AState=sfSelected) THEN
  BEGIN
    UpdateCommands;
    { Remember this editor as the active one for running from field }
    IF Enable THEN EditWindow := @Self;
  END;
END;

PROCEDURE TNikiEditor.UpdateCommands;
VAR m:BOOLEAN;
BEGIN
  m := GetState(sfSelected);

{  SetCmdState( cmCompile, m );
  SetCmdState( cmRun, m );
  SetCmdState( cmSave, m );
  SetCmdState( cmSaveAs, m );
  SetCmdState( cmOpen, m );}
END;

PROCEDURE TNikiEditor.CheckCursorSync;
VAR
  Line: Word;
  p: LongInt;
BEGIN
  IF Editor = NIL THEN Exit;
  { Only sync when editor has focus }
  IF NOT GetState(sfSelected) THEN Exit;

  { Count lines up to cursor position }
  Line := 1;
  FOR p := 0 TO Editor^.CurPtr - 1 DO
    IF Editor^.BufChar(p) = #10 THEN Inc(Line);

  IF Line <> LastCursorLine THEN
  BEGIN
    LastCursorLine := Line;
    IF Desktop <> NIL THEN
      Message(Desktop, evBroadcast, cmSyncDisasm, Pointer(PtrUInt(Line)));
  END;
END;

FUNCTION TNikiEditor.Compile:BOOLEAN;
VAR
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
BEGIN
  Compile := FALSE;

  IF Editor^.Save AND (Editor^.FileName<>'') THEN
  BEGIN
    IF Application^.ExecView(
           New(PCompileDialog, Init(GetTitle(255)))
       )=cmOk THEN
    BEGIN
      Compile := TRUE;
      Compiled := TRUE;

      { Broadcast update to disasm window }
      FSplit(Editor^.FileName, Dir, Name, Ext);
      DisasmFileName := Dir + Name + '.NIK';
      IF Desktop <> NIL THEN
        Message(Desktop, evBroadcast, cmUpdateDisasm, NIL);

      { Force cursor sync on recompile }
      LastCursorLine := 0;
    END ELSE
    BEGIN
      IF ErrorNumber<>0 THEN
      BEGIN
        ShowError;
        Editor^.Modified := TRUE;
      END;
    END;
  END;
END;

PROCEDURE TNikiEditor.Run(Debug:BOOLEAN);
VAR Quelle, Ziel:String;
    Dir:DirStr;
    Name:NameStr;
    Ext:ExtStr;

    Error : BOOLEAN;
BEGIN
  Compiled := Compiled AND NOT Editor^.Modified;

  IF FeldWindow=NIL THEN
  BEGIN
    MessageBox(tr('You must load a robot field first to run the program'),
        NIL, mfOkButton+mfInformation);
  END;

  IF FeldWindow<>NIL THEN
  BEGIN
    Error := FALSE;

    { NIK-Datei muá noch gesucht werden und die Zeit der letzten nderung
      mit der Zeit der PAS-Datei verglichen werden, um zu ermitteln, ob
      die Datei neu compiliert werden muá }

    IF (Editor^.Modified OR (Editor^.FileName='')) OR NOT Compiled THEN
      Error := NOT Compile;

    IF NOT Error THEN
    BEGIN
      FSplit(Editor^.FileName, Dir, Name, Ext);
      Ziel := Dir+Name+'.NIK';
      IF InfoWindow<>NIL THEN
      BEGIN
        InfoWindow^.Show;
        InfoWindow^.Select;
      END;
      FeldWindow^.Select;
      FeldWindow^.Run(Ziel, Debug);
    END;
  END;
END;

PROCEDURE TNikiEditor.Print;
BEGIN
  IF Application^.ExecuteDialog(
       New(PPrintDialog, Init(mdEdit)), @PrintOptions)=cmOk THEN
  BEGIN
    Application^.ExecuteDialog(
       New(PEditPrint,
         Init(Editor)), @PrintOptions)
  END;
END;

TYPE TErrorInfo = RECORD
                    Number : Longint;
                    Line : Longint;
                    Desc : PString;
                  END;

PROCEDURE TNikiEditor.ShowError;
VAR ErrorInfo:TErrorInfo;
    Event:TEvent;
    R:TRect;
    Error:PErrorLine;
    p:Word;
    x,y:Word;
BEGIN

  IF ErrorLine<>0 THEN
  BEGIN
    x := 1;
    y := 1;
    FOR p := 0 TO Editor^.BufLen DO
    BEGIN
      IF (y = ErrorLine) AND (x = ErrorColumn) THEN
      BEGIN
        Editor^.SetCurPtr(p, 0);
        Break;
      END;

      inc(x);
      IF Editor^.BufChar(p)=#10 THEN
      BEGIN
        x := 1;
        inc(y);
      END;
    END;

    Editor^.ScrollTo(ErrorColumn-40, ErrorLine-2);
  END;

  GetExtent(R);
  inc(R.A.Y);
  inc(R.A.X);
  dec(R.B.X);
  R.B.Y:=R.A.Y+1;

  Error := New(PErrorLine, Init(R, tr('Error #%d at line %d: %s'), 3));

  ErrorInfo.Number := ErrorNumber;
  ErrorInfo.Desc := @ErrorDescribtion;
  ErrorInfo.Line := ErrorLine;
  Error^.SetData( ErrorInfo );
  Error^.HelpCtx := hcFehler + ErrorNumber;

  ExecView( Error );

  Dispose( Error, Done );
END;

BEGIN
  EditorDialog := @MyEditorDialog;
  EditWindow := NIL;
END.

