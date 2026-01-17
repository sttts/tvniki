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

CONST cFeld1 = 15 + 0*16;
      cFeld2 = 7 + 0*16;

VAR   Walls: ARRAY[0..17] OF String[4];  { UTF-8 box-drawing characters }


TYPE TChar=RECORD
             z:String[4];  { UTF-8 character (up to 4 bytes) }
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
USES Dos, SysUtils, NikiCnst, MsgBox, App, StdDlg, Timer, Hilfe;

CONSTRUCTOR TFeld.Init(R:TRect; ADatei:String;
    AHScrollBar, AVScrollBar:PScrollBar);
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
    Id:PShortString;
BEGIN
  LoadFile := FALSE;

  S.Init(ADatei, stOpen, 2048);
  IF S.Status=stOk THEN
  BEGIN
     Id := S.ReadStr;
     IF (Id <> NIL) AND (Id^='FELD') THEN
     BEGIN
       ReadFile(S);
       IF S.Status>=stOk THEN LoadFile := TRUE;
     END;

     IF Id <> NIL THEN DisposeStr(Id);
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

{ Convert CP437 byte to UTF-8 string for box-drawing characters }
FUNCTION CP437toUTF8(c: Byte): String;
BEGIN
  CASE c OF
    $B3: CP437toUTF8 := '│';  { vertical line }
    $C4: CP437toUTF8 := '─';  { horizontal line }
    $DA: CP437toUTF8 := '┌';  { top-left corner }
    $BF: CP437toUTF8 := '┐';  { top-right corner }
    $C0: CP437toUTF8 := '└';  { bottom-left corner }
    $D9: CP437toUTF8 := '┘';  { bottom-right corner }
    $C3: CP437toUTF8 := '├';  { T left }
    $B4: CP437toUTF8 := '┤';  { T right }
    $C2: CP437toUTF8 := '┬';  { T down }
    $C1: CP437toUTF8 := '┴';  { T up }
    $C5: CP437toUTF8 := '┼';  { cross }
    $FA: CP437toUTF8 := '·';  { middle dot (field point) }
    $F9: CP437toUTF8 := '·';  { alternate dot }
    $10: CP437toUTF8 := '►';  { right arrow (robot) }
    $11: CP437toUTF8 := '◄';  { left arrow (robot) }
    $1E: CP437toUTF8 := '▲';  { up arrow (robot) }
    $1F: CP437toUTF8 := '▼';  { down arrow (robot) }
  ELSE
    CP437toUTF8 := Chr(c);    { ASCII or pass through }
  END;
END;

{ Convert UTF-8 string back to CP437 byte for file saving }
FUNCTION UTF8toCP437(s: String): Byte;
BEGIN
  IF s = '│' THEN UTF8toCP437 := $B3
  ELSE IF s = '─' THEN UTF8toCP437 := $C4
  ELSE IF s = '┌' THEN UTF8toCP437 := $DA
  ELSE IF s = '┐' THEN UTF8toCP437 := $BF
  ELSE IF s = '└' THEN UTF8toCP437 := $C0
  ELSE IF s = '┘' THEN UTF8toCP437 := $D9
  ELSE IF s = '├' THEN UTF8toCP437 := $C3
  ELSE IF s = '┤' THEN UTF8toCP437 := $B4
  ELSE IF s = '┬' THEN UTF8toCP437 := $C2
  ELSE IF s = '┴' THEN UTF8toCP437 := $C1
  ELSE IF s = '┼' THEN UTF8toCP437 := $C5
  ELSE IF s = '·' THEN UTF8toCP437 := $FA
  ELSE IF s = '►' THEN UTF8toCP437 := $10
  ELSE IF s = '◄' THEN UTF8toCP437 := $11
  ELSE IF s = '▲' THEN UTF8toCP437 := $1E
  ELSE IF s = '▼' THEN UTF8toCP437 := $1F
  ELSE IF Length(s) > 0 THEN UTF8toCP437 := Ord(s[1])
  ELSE UTF8toCP437 := Ord(' ');
END;

PROCEDURE TFeld.WriteFile(VAR S:TStream);
VAR x,y:Byte;
    c:Byte;
BEGIN
  FOR Y:=0 TO SizeY-1 DO
    FOR X:=0 TO SizeX-1 DO
    BEGIN
      c := UTF8toCP437(Feld[y,x].z);
      S.Write(c, 1);
    END;
END;

PROCEDURE TFeld.ReadFile(VAR S:TStream);
VAR x,y:Byte;
    c:Byte;
BEGIN
  FOR Y:=0 TO SizeY-1 DO
    FOR X:=0 TO SizeX-1 DO
    BEGIN
      S.Read(c, 1);
      Feld[y,x].z := CP437toUTF8(c);
    END;
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

VAR Str:PShortString;

FUNCTION TFeld.CanClose:BOOLEAN;
VAR Result:Integer;
BEGIN
  IF Modified THEN
  BEGIN
    Str^:=GetTitle;
    Result := MessageBox('Das Feld %s vor dem Schließen speichern?', @Str, mfYesButton+mfNoButton+mfCancelButton+
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
    B:TDrawBuffer;
    i,j:Integer;
    s:String[4];
BEGIN
  IF (y>=Delta.Y) AND (y<Delta.Y+Size.Y) THEN
  BEGIN
    Width := SizeX-Delta.X;
    IF Width > Size.X THEN Width := Size.X;
    { Convert TChar array to TDrawBuffer (Int64 format with UTF-8 support) }
    FOR i := 0 TO Width-1 DO
    BEGIN
      s := Feld[y, Delta.X+i].z;
      Int64Rec(B[i]).Lo := 0;  { Clear character bytes }
      FOR j := 1 TO Length(s) DO
        Int64Rec(B[i]).Bytes[j-1] := Ord(s[j]);
      Int64Rec(B[i]).Hi := Feld[y, Delta.X+i].f;
    END;
    WriteLine(0, y-Delta.Y, Width, 1, B);
  END;
END;

BEGIN
  { Initialize box-drawing characters for walls using UTF-8 Unicode }
  { Index: 0=point, 1=L, 2=U, 3=LU, 4=R, 5=RL, 6=RU, 7=RLU }
  {        8=D, 9=LD, 10=DU, 11=LDU, 12=RD, 13=RLD, 14=RDU, 15=LRDU }
  {        16=mid, 17=no }
  Walls[0]  := '·';  { centered dot for field points }
  Walls[1]  := '─';  { left }
  Walls[2]  := '│';  { up }
  Walls[3]  := '┘';  { LU corner }
  Walls[4]  := '─';  { right }
  Walls[5]  := '─';  { horizontal }
  Walls[6]  := '└';  { RU corner }
  Walls[7]  := '┴';  { RLU T-junction }
  Walls[8]  := '│';  { down }
  Walls[9]  := '┐';  { LD corner }
  Walls[10] := '│';  { vertical }
  Walls[11] := '┤';  { LDU T-junction }
  Walls[12] := '┌';  { RD corner }
  Walls[13] := '┬';  { RLD T-junction }
  Walls[14] := '├';  { RDU T-junction }
  Walls[15] := '┼';  { LRDU cross }
  Walls[16] := ' ';  { mid (field) }
  Walls[17] := ' ';  { no wall }

  GetMem(Str, 256);
END.