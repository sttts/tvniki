UNIT NikiPrnt; {Print}

INTERFACE

USES Views, Dialogs, Drivers, Objects, TvEnh, Editors, NikiFeld, NikiFlWn;

CONST mdFeld=1;
      mdEdit=2;

TYPE PPrintDialog=^TPrintDialog;
     TPrintDialog=OBJECT(TDialog)
                   CONSTRUCTOR Init(aMode:Integer);
                   DESTRUCTOR Done; VIRTUAL;
                   PROCEDURE SetupWindow; VIRTUAL;

                   PROCEDURE HandleEvent(VAR Event:TEvent); VIRTUAL;

                  PRIVATE
                   Mode:Integer;
                 END;



     PPrintProcess=^TPrintProcess;
     TPrintProcess=OBJECT(TDialog)
                   CONSTRUCTOR Init;
                   DESTRUCTOR Done; VIRTUAL;
                   PROCEDURE SetupWindow; VIRTUAL;

                   PROCEDURE HandleEvent(VAR Event:TEvent); VIRTUAL;

                   PROCEDURE Print; VIRTUAL;
                  PRIVATE
                   Status:Integer;
                 END;

     PEditPrint=^TEditPrint;
     TEditPrint=OBJECT(TPrintProcess)
                   CONSTRUCTOR Init(aEditor:PEditor);

                   PROCEDURE Print; VIRTUAL;

                  PRIVATE
                   LineNumbers:Boolean;
                   FileName:Boolean;

                   Editor:PEditor;
                   Line:Longint;
                   Position:Word;
                 END;

     PFeldPrint=^TFeldPrint;
     TFeldPrint=OBJECT(TPrintProcess)
                   CONSTRUCTOR Init(aEditor:PFeldEditor);

                   PROCEDURE Print; VIRTUAL;

                  PRIVATE
                   FileName:Boolean;
                   Vorrat:BOOLEAN;

                   Editor:PFeldEditor;
                   XPos:Longint;
                   YPos:Longint;
                 END;


     DPrintDialog=RECORD
                    Options:Word;
                  END;

CONST opZeilenNummern=1;
      opVorrat=1;
      opDateiName=2;

      PrintOptions:DPrintDialog=
      (
        Options:opZeilenNummern OR opDateiName
      );

IMPLEMENTATION
USES App, Strings, Hilfe, Dos, MsgBox, Printer;

CONST Width=29;
      Height=8;


{$i-}

{************************************}

CONSTRUCTOR TPrintDialog.Init(aMode:Integer);
VAR R:TRect;
BEGIN
  Desktop^.GetExtent(R);
  R.A.X := (R.B.X-Width) DIV 2;
  R.A.Y := (R.B.Y-Height) DIV 2;
  R.B.X := R.A.X + Width;
  R.B.Y := R.A.Y + Height;

  INHERITED Init(R, 'Drucken');

  Mode := aMode;

  SetupWindow;
END;

DESTRUCTOR TPrintDialog.Done;
BEGIN
  INHERITED Done;
END;

PROCEDURE TPrintDialog.SetupWindow;
VAR R:TRect;
BEGIN
  R.Assign(2,1,27,4);
  CASE Mode OF
   mdEdit : Insert( New(PCheckBoxes, Init(R,
              NewSItem('~Z~eilennummern',
              NewSItem('Datei~n~ame',
              NIL)))));
   mdFeld : Insert( New(PCheckBoxes, Init(R,
              NewSItem('~V~orrat',
              NewSItem('Datei~n~ame',
              NIL)))));
  END;

  R.Assign(14,5,26,7);
  Insert( New(PButton, Init(R, 'A~b~bruch', cmCancel, bfNormal)));

  R.Assign(2,5,14,7);
  Insert( New(PButton, Init(R, '~O~K', cmOk, bfDefault)));
END;

PROCEDURE TPrintDialog.HandleEvent(VAR Event:TEvent);
BEGIN
  INHERITED HandleEvent(Event);
END;

{************************************}

CONSTRUCTOR TPrintProcess.Init;
VAR R:TRect;
BEGIN
  Desktop^.GetExtent(R);
  R.A.X := (R.B.X-20) DIV 2;
  R.A.Y := (R.B.Y-7) DIV 2;
  R.B.X := R.A.X + 20;
  R.B.Y := R.A.Y + 7;

  INHERITED Init(R, 'Drucken');

{  HelpCtx := hcPrint;}

  SetupWindow;
  Status := 0;
END;

DESTRUCTOR TPrintProcess.Done;
BEGIN
  INHERITED Done;
END;

PROCEDURE TPrintProcess.SetupWindow;
VAR R:TRect;
BEGIN
  R.Assign(5,2,18,4);
  Insert( New(PStaticText, Init(R, 'Drucke...')));

  R.Assign(2,4,17,6);
  Insert( New(PButton, Init(R, 'A~b~bruch', cmCancel, bfDefault)));
END;

PROCEDURE TPrintProcess.HandleEvent(VAR Event:TEvent);
BEGIN
  IF Event.What = evNothing THEN Print;
  INHERITED HandleEvent(Event);
END;

PROCEDURE TPrintProcess.Print;
BEGIN
END;

{************************************}

CONSTRUCTOR TEditPrint.Init(aEditor:PEditor);
BEGIN
  INHERITED Init;

  LineNumbers := (PrintOptions.Options AND opZeilenNummern)<>0;
  FileName := (PrintOptions.Options AND opDateiName)<>0;

  Editor := aEditor;

  Position := 0;
  Line := 1;
END;

PROCEDURE TEditPrint.Print;
VAR c:Char;
BEGIN
  CASE Status OF
   0 : BEGIN
         IF Filename THEN
         BEGIN
           Writeln(Lst, 'Dateiname: ', PFileEditor(Editor)^.FileName);
           Writeln(Lst);
         END;

         Status := 1;
       END;
   1 : BEGIN
         IF Position<Editor^.BufLen THEN
         BEGIN
           IF (Position=0) AND LineNumbers THEN Write(Lst, Line:3, ' ');

           c := Editor^.BufChar(Position);
           Inc(Position);

           Write(Lst, c);

           IF LineNumbers AND (c=#10) THEN
           BEGIN
             inc(Line);
             Write(Lst, Line:3, ' ');
           END;

           IF IOResult<>0 THEN Message(@Self, evCommand, cmClose, NIL);

         END ELSE
         BEGIN
           Status := 2;
         END;
       END;
   2: BEGIN
        Writeln(Lst,'');
        Status := 3;
      END;
   ELSE Message(@Self, evCommand, cmClose, NIL);
  END;
END;

{************************************}

CONSTRUCTOR TFeldPrint.Init(aEditor:PFeldEditor);
BEGIN
  INHERITED Init;

  Editor := aEditor;

  XPos := 0;
  YPos := 0;

  FileName := (PrintOptions.Options AND opDateiName)<>0;
  Vorrat   := (PrintOptions.Options AND opVorrat)<>0;
END;

PROCEDURE TFeldPrint.Print;
VAR c:String[4];
    c1:Char;
BEGIN
  CASE Status OF
   0 : BEGIN
         IF Vorrat AND FileName THEN
           Writeln(Lst, 'Vorrat: ', Editor^.GetVorrat:2,'   Dateiname: ', Editor^.Datei)
         ELSE IF Filename THEN
           Writeln(Lst, '':12, 'Dateiname: ', Editor^.Datei)
         ELSE IF Vorrat THEN
           Writeln(Lst, 'Dateiname: ', Editor^.Datei);



         Writeln(Lst);

         Status := 1;
       END;
   1 : BEGIN
         IF (XPos<SizeX) AND (YPos<SizeY) THEN
         BEGIN
           c := Editor^.Feld[YPos, XPos].z;
           { Convert special characters for printing }
           IF Length(c) = 1 THEN
           BEGIN
             c1 := c[1];
             CASE c1 OF
               #16 : c := '>';
               #17 : c := '<';
               #30 : c := '^';
               #31 : c := 'v';
             END;
           END;

           Write(Lst, c);
           inc(XPos);
           IF XPos>=SizeX THEN
           BEGIN
             Writeln(Lst);
             XPos := 0;
             inc(YPos);
           END;

           IF IOResult<>0 THEN Message(@Self, evCommand, cmClose, NIL);
         END ELSE
           Status := 2;
       END;
   2: BEGIN
        Writeln(Lst,'');
        Status := 3;
      END;
   ELSE Message(@Self, evCommand, cmClose, NIL);
  END;
END;


END.