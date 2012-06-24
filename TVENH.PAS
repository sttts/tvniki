UNIT TvEnh;

INTERFACE
USES Dialogs, Views, Drivers, Objects, Timer;

FUNCTION Max(a,b:Integer):Integer;
FUNCTION Min(a,b:Integer):Integer;
PROCEDURE Beep;
PROCEDURE FDelete(d:String);
FUNCTION GetTemp:String;

CONST CErrorLine    = #4;

CONST Balken:String='|/-\';

TYPE PParamLine=^TParamLine;
     TParamLine=OBJECT(TParamText)
                  CONSTRUCTOR Init(VAR Bounds: TRect; CONST AText: String;
                      AParamCount: Integer);
                  PROCEDURE GetText(VAR S: String); VIRTUAL;

                  PROCEDURE HandleEvent(VAR Event:TEvent); VIRTUAL;
                  FUNCTION Execute: WORD; VIRTUAL;
                  PROCEDURE EndModal(Command:WORD); VIRTUAL;

                 PRIVATE
                  EndState:WORD;
                END;

     PErrorLine=^TErrorLine;
     TErrorLine=OBJECT(TParamLine)
                  FUNCTION GetPalette: PPalette; VIRTUAL;
                END;

     PProcess = ^TProcess;
     TProcess = OBJECT(TView)
                  Pos:Byte;
                  MyTimer:Integer;

                  CONSTRUCTOR Init(p:TPoint);
                  DESTRUCTOR Done; VIRTUAL;

                  PROCEDURE Idle; VIRTUAL;
                  PROCEDURE Draw; VIRTUAL;
                END;

     PScrollerLine=^TScrollerLine;
     TScrollerLine=OBJECT(TView)
                     ScrollText:String;
                     Len:Integer;
                     Pos:Integer;

                     MyTimer:Integer;

                     CONSTRUCTOR Init(var Bounds: TRect; AText: String);
                     DESTRUCTOR Done; VIRTUAL;

                     PROCEDURE Draw; VIRTUAL;
                     PROCEDURE Idle; VIRTUAL;
                   END;


IMPLEMENTATION
USES Crt, Dos;

FUNCTION Max(a,b:Integer):Integer;
BEGIN
  IF a>b THEN Max := a ELSE Max := b;
END;

FUNCTION Min(a,b:Integer):Integer;
BEGIN
  IF a>b THEN Min := a ELSE Min := b;
END;

PROCEDURE Beep;
BEGIN
  Sound(1000);
  Delay(200);
  nosound;
END;

PROCEDURE FDelete(d:String);
VAR R:Registers;
BEGIN
  d[length(d)+1] := #0;

  R.AH := $41;
  R.DX := Ofs(d[1]);
  R.DS := Seg(d[1]);
  Intr($21, R);
END;

FUNCTION GetTemp:String;
VAR d:String;
BEGIN
  d := GetEnv('TEMP');
  IF d = '' THEN d := GetEnv('TMP');
  GetTemp := d;
END;

{*******************************}

CONSTRUCTOR TProcess.Init;
VAR r:TRect;
BEGIN
  R.Assign(p.x, p.y, p.x+1, p.y+1);
  INHERITED Init(r);

  GrowMode := gfGrowLoY + gfGrowHiX + gfGrowHiY;
  Pos := 1;

  MyTimer := NewCounter;
  IF MyTimer<0 THEN Done;
END;

DESTRUCTOR TProcess.Done;
BEGIN
  ReleaseCounter( MyTimer );

  INHERITED Done;
END;

PROCEDURE TProcess.Idle;
BEGIN
  IF Counter(MyTimer) > 1 THEN
  BEGIN
    SetCounter(MyTimer, 0);

    Inc(Pos);
    IF Pos>Length(Balken) THEN Pos := 1;

    Draw;
  END;
END;

PROCEDURE TProcess.Draw;
VAR Buf:TDrawBuffer;
BEGIN
  MoveChar(Buf, Balken[Pos], GetColor(37), 1);
  WriteLine(0,0,1,1,Buf);
{  WriteChar(0, 0, Balken[Pos], GetColor(37), 1);}
END;


{*******************************}

CONSTRUCTOR TParamLine.Init(var Bounds: TRect; const AText: String;
  AParamCount: Integer);
BEGIN
  INHERITED Init(Bounds, AText, AParamCount);
  ParamList := NIL;
END;

procedure TParamLine.GetText(var S: String);
begin
  if (Text <> nil) then
  BEGIN
    IF (ParamCount>0) AND (ParamList<>NIL) then FormatStr(S, Text^, ParamList^)
    ELSE S := Text^;
  END
  else S := '';
end;

PROCEDURE TParamLine.HandleEvent(VAR Event:TEvent);
BEGIN
  IF GetState(sfModal) THEN
    CASE Event.What OF
      evKeyDown, evMouseDown: EndModal(cmOk);
    END;
  INHERITED HandleEvent(Event);
END;

FUNCTION TParamLine.Execute: WORD;
VAR
  E: TEvent;
BEGIN
  REPEAT
    EndState := 0;
    REPEAT
      GetEvent(E);
      HandleEvent(E);
    UNTIL EndState <> 0;
  UNTIL Valid(EndState);
  Execute := EndState;
END;

PROCEDURE TParamLine.EndModal;
BEGIN
  EndState := Command;
END;

FUNCTION TErrorLine.GetPalette: PPalette;
CONST P: String[Length(CErrorLine)] = CErrorLine;
BEGIN
  GetPalette := @P;
END;

{**********************************}

CONSTRUCTOR TScrollerLine.Init(var Bounds: TRect; AText: String);
BEGIN
  INHERITED Init(Bounds);

  ScrollText := AText;
  Len := Length(AText);
  Pos := 1;

  MyTimer := NewCounter;
  IF MyTimer<0 THEN Done;
END;

DESTRUCTOR TScrollerLine.Done;
BEGIN
  ReleaseCounter( MyTimer );

  INHERITED Done;
END;

PROCEDURE TScrollerLine.Idle;
BEGIN
  IF Counter(MyTimer)>1 THEN
  BEGIN
    SetCounter( MyTimer,0 );

    Inc(Pos);
    IF Pos>Len THEN Pos:=1;

    Draw;
  END;
END;

PROCEDURE TScrollerLine.Draw;
VAR p:Integer;
    Von,Bis:Integer;
    Color: Byte;
    Center: Boolean;
    Buf: TDrawBuffer;
    BufPos:Integer;
BEGIN
  Color := GetColor(4);
  MoveChar(Buf, ' ', Color, Size.X);

  BufPos:=0;

  Bis := Pos+Size.X;
  IF Bis>Len THEN Bis := Len;
  FOR p:=Pos TO Bis DO
  BEGIN
    Byte(Buf[BufPos]) := Byte(ScrollText[p]);
    inc(BufPos);
  END;

  Bis := Size.X-(Bis-Pos);
  FOR p:=1 TO Bis DO
  BEGIN
    Byte(Buf[BufPos]) := Byte(ScrollText[p]);
    inc(BufPos);
  END;

  WriteLine(0, 0, Size.X, 1, Buf);
end;


END.