UNIT NikiFlWn;
INTERFACE
USES Objects, Views, Drivers, Dialogs, TvEnh, NikiInfo, Editors;

CONST cmUpdateTitle = 523;
      SizeX=61;
      SizeY=21;

      CFeld=#137#136#138#27#28#29#30#31;
      {#83#82#84#27#28#29#30#31;}

      wPoint= 0;
      wL   = 1;
      wU   = 2;
      wLU  = wL+wU;
      wR   = 4;
      wRL  = wR+wL;
      wRU  = wR+wU;
      wRLU = wR+wL+wU;
      wD   = 8;
      wLD  = wL+wD;
      wDU  = wD+wU;
      wLDU = wL+wD+wU;
      wRD  = wR+wD;
      wRLD = wR+wL+wD;
      wRDU = wR+wD+wU;
      wLRDU= wR+wL+wD+wU;

      wHor = wRL;
      wVert= wDU;

      wMid = 16;
      wNo  = 17;

      Walls:String='Ä³ÙÄÄÀÁ³¿³´ÚÂÃÅ  ';
     {Walls:String='úúÙúÄÀÁú¿³´ÚÂÃÅ  ';}
     {Walls:String='úú¼úÍÈÊú»º¹ÉËÌÎ  ';}

      cFeld1 = 15 + 0*16;
      cFeld2 = 7 + 0*16;


TYPE TChar=RECORD
             z:CHAR;
             f:BYTE;
           END;



TYPE PFeld=^TFeld;
     TFeld=OBJECT(TScroller)
             Feld:ARRAY[0..SizeY-1, 0..SizeX-1] OF TChar;

             Datei:String;

             Status:TStatus;

             Modified : BOOLEAN;
             IsValid : BOOLEAN;

             CONSTRUCTOR Init(R:TRect; ADatei:String;
                 AHScrollBar, AVScrollBar:PScrollBar);
             DESTRUCTOR Done; VIRTUAL;

             PROCEDURE HandleEvent(VAR Event:TEvent); VIRTUAL;

             FUNCTION CanClose:BOOLEAN; VIRTUAL;

             PROCEDURE UpdateScrollbars;

             PROCEDURE SizeLimits(VAR Min, Max: TPoint); VIRTUAL;
             PROCEDURE ChangeBounds(VAR Bounds: TRect); VIRTUAL;

             FUNCTION GetTitle:String;
             FUNCTION GetPalette:PPalette; VIRTUAL;

             PROCEDURE ResetMode; VIRTUAL;
             FUNCTION Valid(Command: Word): Boolean; VIRTUAL;

             PROCEDURE Draw; VIRTUAL;
             PROCEDURE DrawLine(y:Integer); VIRTUAL;

             PROCEDURE MakeLogical(VAR x,y:Integer);
             PROCEDURE MakePhysical(VAR x,y:Integer);

             PROCEDURE ClearFeld;

             FUNCTION LoadFile(ADatei:STRING):BOOLEAN;
             FUNCTION SaveFile(ADatei:STRING):BOOLEAN;

             PROCEDURE WriteFile(VAR S:TStream); VIRTUAL;
             PROCEDURE ReadFile(VAR S:TStream); VIRTUAL;

             PROCEDURE Save;
             PROCEDURE SaveAs;
           END;

IMPLEMENTATION
USES Crt, Dos, NikiCnst, MsgBox, App, StdDlg, Timer, Hilfe;

CONSTRUCTOR TFeld.Init;
BEGIN
  INHERITED Init(R, AHScrollBar, AVScrollBar);
  IsValid := TRUE;

  GrowMode := gfGrowHiX + gfGrowHiY;
  Options := Options or ofSelectable;
  EventMask := evMouseDown + evMouseAuto + evKeyDown + evCommand + evBroadcast;
  Modified := FALSE;
  SetLimit(SizeX-1, SizeY-1);
  Datei := ADatei;
  HelpCtx := hcFeldEditor;

  ClearFeld;

  IF ADatei<>'' THEN
  BEGIN
    IF NOT LoadFile( ADatei ) THEN
    BEGIN
      IsValid := FALSE;
      MessageBox('Error while reading file', NIL, mfError+mfOkButton);
    END;
  END;
END;

DESTRUCTOR TFeld.Done;
BEGIN
  INHERITED Done;
END;

FUNCTION TFeld.LoadFile(ADatei:STRING):BOOLEAN;
VAR S:TBufStream;
    Id:PString;
    x,y:Byte;
BEGIN
  LoadFile := FALSE;

  S.Init(ADatei, stOpen, 2048);
  IF S.Status=stOk THEN
  BEGIN
     Id := S.ReadStr;
     IF Id^='FELD' THEN
     BEGIN
       ReadFile(S);

       IF S.Status>=stOk THEN LoadFile := TRUE;
     END;

     DisposeStr(Id);
  END;
  S.Done;
END;

FUNCTION TFeld.SaveFile(ADatei:STRING):BOOLEAN;
VAR S:TBufStream;
    Id:String;
BEGIN
  SaveFile := FALSE;

  S.Init(ADatei, stCreate, 2048);
  IF S.Status>=stOK THEN
  BEGIN
    Id := 'FELD';
    S.WriteStr(@Id);

    WriteFile(S);
  END;

  IF S.Status=stOk THEN SaveFile := TRUE;

  S.Done;
END;

PROCEDURE TFeld.WriteFile(VAR S:TStream);
VAR x,y:Byte;
BEGIN
  FOR Y:=0 TO SizeY-1 DO
    FOR X:=0 TO SizeX-1 DO
      S.Write(Feld[y,x].z, 1);
END;

PROCEDURE TFeld.ReadFile(VAR S:TStream);
VAR x,y:Byte;
BEGIN
  FOR Y:=0 TO SizeY-1 DO
    FOR X:=0 TO SizeX-1 DO
      S.Read(Feld[y,x].z, 1);
END;

PROCEDURE TFeld.Save;
BEGIN
  IF (Datei<>'') THEN
  BEGIN
    ResetMode;
    IF NOT SaveFile(Datei) THEN
      MessageBox('Error while saving file', NIL, mfError+mfOkButton)
    ELSE Modified:=FALSE;
  END ELSE SaveAs;
END;

PROCEDURE TFeld.SaveAs;
VAR DateiName:String[100];
BEGIN
  DateiName := '*.ROB';
  IF Application^.ExecuteDialog(New(PFileDialog, Init('*.ROB',
         'Datei speichern', '~N~ame', fdOkButton, 100)), @DateiName)
     <> cmCancel
  THEN
    BEGIN
      ResetMode;
      Datei := DateiName;
      IF Owner<>NIL THEN
        Message(Owner, evBroadcast, cmUpdateTitle, nil);

      IF SaveFile(Datei) THEN Modified := FALSE ELSE
        MessageBox('Error while saving file', NIL, mfError+mfOkButton);
    END;
END;

FUNCTION TFeld.Valid(Command: Word): Boolean;
BEGIN
  IF Command=cmValid THEN
    Valid:=INHERITED Valid(Command) AND IsValid
  ELSE
    BEGIN
      ResetMode;
      Valid := CanClose;
    END;
END;

PROCEDURE TFeld.ResetMode;
BEGIN
END;

PROCEDURE TFeld.SizeLimits(var Min, Max: TPoint);
BEGIN
  Min.X := 10;
  Min.Y := 2;
  Max.X := SizeX;
  Max.Y := SizeY;
END;

PROCEDURE TFeld.ChangeBounds(VAR Bounds: TRect);
BEGIN
  SetBounds(Bounds);
  UpdateScrollbars;
END;

PROCEDURE TFeld.UpdateScrollbars;
BEGIN
  Draw;

  IF HScrollBar <> NIL THEN
      HScrollBar^.SetParams(Delta.X, 0, Limit.X - Size.X + 1, Size.X DIV 2, 1);
  IF VScrollBar <> NIL THEN
      VScrollBar^.SetParams(Delta.Y, 0, Limit.Y - Size.Y + 1, Size.Y - 1, 1);
END;

VAR Str:PString;

FUNCTION TFeld.CanClose:BOOLEAN;
VAR Result:Integer;
BEGIN
  IF Modified THEN
  BEGIN
    Str^:=GetTitle;
    Result := MessageBox('Das Feld %s vor dem Schlieáen speichern?', @Str, mfYesButton+mfNoButton+mfCancelButton+
      mfConfirmation);

    CASE Result OF
      cmYes: Save;
      cmNo: Modified:=FALSE;
    END;
  END;
  CanClose := NOT Modified;
END;

PROCEDURE TFeld.HandleEvent(VAR Event:TEvent);
VAR Klick:TPoint;
BEGIN
  CASE Event.What OF
    evCommand:CASE Event.Command OF
                cmSaveFeld : Save;
                cmSaveAsFeld: SaveAs;
                cmClose:IF NOT CanClose THEN ClearEvent(Event);
              END;
  END;

  INHERITED HandleEvent(Event);
END;

PROCEDURE TFeld.MakeLogical(VAR x,y:Integer);
BEGIN
  x := x + Delta.X;
  y := y + Delta.Y;
END;

PROCEDURE TFeld.MakePhysical(VAR x,y:Integer);
BEGIN
  x := x - Delta.X;
  y := y - Delta.Y;
END;

PROCEDURE TFeld.ClearFeld;
VAR x,y:Word;
BEGIN
  FOR y:=0 TO SizeY-1 DO
  BEGIN
    FOR x:=0 TO SizeX-1 DO
    BEGIN
      Feld[y, x].z := Walls[wNo];
      Feld[y, x].f := cFeld1;
    END;
  END;

  FOR y:=0 TO SizeY DIV 2 DO
    FOR x:=0 TO SizeX DIV 4 DO
      Feld[y*2, x*4].z := Walls[wPoint];

  FOR x:=1 TO SizeX-2 DO
  BEGIN
    Feld[0, x].z := Walls[wHor];
    Feld[SizeY-1, x].z := Walls[wHor];
  END;

  FOR y:=1 TO SizeY-2 DO
  BEGIN
    Feld[y, 0].z := Walls[wVert];
    Feld[y, SizeX-1].z := Walls[wVert];
  END;

  Feld[0, 0].z := Walls[wRD];
  Feld[0,SizeX-1].z := Walls[wLD];
  Feld[SizeY-1, 0].z := Walls[wRU];
  Feld[SizeY-1,SizeX-1].z := Walls[wLU];

  FOR y:=0 TO (SizeY-2) div 2 DO
    FOR x:=0 TO (SizeX-4) div 4 DO
    BEGIN
      Feld[y*2+1, x*4+1].z := Walls[wMid];
      Feld[y*2+1, x*4+2].z := Walls[wMid];
      Feld[y*2+1, x*4+3].z := Walls[wMid];

      Feld[y*2+1, x*4+1].f := cFeld2;
      Feld[y*2+1, x*4+2].f := cFeld2;
      Feld[y*2+1, x*4+3].f := cFeld2;
    END;
END;

FUNCTION TFeld.GetTitle:String;
BEGIN
  IF Datei<>'' THEN
    GetTitle := Datei
  ELSE GetTitle:='Untitled';
END;

FUNCTION TFeld.GetPalette: PPalette;
CONST P: String[Length(CGrayWindow)] = CGrayWindow;
BEGIN
  GetPalette := @P;
END;

PROCEDURE TFeld.Draw;
VAR y:Integer;
BEGIN
  FOR y:=Delta.Y TO Delta.Y+Size.Y-1 DO
    DrawLine( y );
END;

PROCEDURE TFeld.DrawLine(y:Integer);
VAR Width:Byte;
    Color:Byte;
BEGIN
  IF (y>=Delta.Y) AND (y<Delta.Y+Size.Y) THEN
  BEGIN
    Width := SizeX-Delta.X;
    IF Width > Size.X THEN Width := Size.X;
    WriteLine(0, y-Delta.Y, Width, 1, Feld[y, Delta.X]);
  END;
END;

BEGIN
  Walls[0] := 'ú';
  GetMem(Str, 256);
END.