UNIT NikiEdit;

INTERFACE
USES Objects, App, Views, Drivers, Editors, Dialogs, TVEnh, NikiGlob, Printer;

TYPE PNikiEditor=^TNikiEditor;
     TNikiEditor=OBJECT(TEditWindow)
                   Compiled:Boolean;
                   CONSTRUCTOR Init(VAR Bounds: TRect;
                       FileName: FNameStr; ANumber: Integer);
                   DESTRUCTOR Done; VIRTUAL;

                   PROCEDURE SetState(AState: Word; Enable: Boolean); VIRTUAL;
                   PROCEDURE HandleEvent(VAR Event:TEvent); VIRTUAL;

                   PROCEDURE UpdateCommands; VIRTUAL;

                   FUNCTION Compile:BOOLEAN;
                   PROCEDURE Run(Debug:BOOLEAN);
                   PROCEDURE Print;
                   PROCEDURE ShowError; VIRTUAL;
                 END;

IMPLEMENTATION
USES NikiCnst, NikiComp, Compiler, MsgBox, NikiFeld, Dos, NikiInfo,
     StdDlg, Hilfe, NikiPrnt, Config;

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
      MyEditorDialog := MessageBox('%s wurde verändert. Speichern?',
        @Info, mfInformation + mfYesNoCancel);
    edSaveUntitled:
      MyEditorDialog := MessageBox('Unbenannte Datei speichern?',
        nil, mfInformation + mfYesNoCancel);
    edSaveAs:
      MyEditorDialog :=
        Application^.ExecuteDialog(New(PFileDialog, Init('*.PAS',
        'Speichern als', '~N~ame', fdOkButton, 101)), Info);
    edFind:
      MyEditorDialog :=
        Application^.ExecuteDialog(CreateFindDialog, Info);
    edSearchFailed:
      MyEditorDialog := MessageBox('Suchtext nicht gefunden.',
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
        MyEditorDialog := MessageBoxRect(R, 'Dieses Vorkommen ersetzen?',
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

  Editor^.Modified := FALSE;
  Compiled := FALSE;
  HelpCtx := hcEditor;
END;

DESTRUCTOR TNikiEditor.Done;
BEGIN
  IF EditWindow = @Self THEN EditWindow := NIL;
  INHERITED Done;
END;

PROCEDURE TNikiEditor.HandleEvent(VAR Event:TEvent);
BEGIN
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
                              MessageBox('Der Debug-Modus wurde über den Schalter DEBUG in NIKI.CFG deaktiviert.',
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
  END;
  INHERITED HandleEvent(Event);

  Compiled := Compiled AND NOT Editor^.Modified;
END;

PROCEDURE TNikiEditor.SetState(AState: Word; Enable: Boolean);
BEGIN
  INHERITED SetState(AState, Enable);
  IF (AState=sfSelected) THEN UpdateCommands;
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

FUNCTION TNikiEditor.Compile:BOOLEAN;
BEGIN
  Compile := FALSE;

  IF Editor^.Save AND (GetTitle(255)<>'Untitled') THEN
  BEGIN
    IF Application^.ExecView(
           New(PCompileDialog, Init(GetTitle(255)))
       )=cmOk THEN
    BEGIN
      Compile := TRUE;
      Compiled := TRUE;
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
    MessageBox('Sie müssen erst ein Roboterfeld laden, um das Programm zu starten',
        NIL, mfOkButton+mfInformation);
  END;

  IF FeldWindow<>NIL THEN
  BEGIN
    Error := FALSE;

    { NIK-Datei muá noch gesucht werden und die Zeit der letzten nderung
      mit der Zeit der PAS-Datei verglichen werden, um zu ermitteln, ob
      die Datei neu compiliert werden muá }

    IF (Editor^.Modified OR (GetTitle(255)='Untitled')) OR NOT Compiled THEN
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

  Error := New(PErrorLine, Init(R, 'Fehler #%d in Zeile %d: %s', 3));

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

