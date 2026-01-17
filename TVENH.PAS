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
                  PROCEDURE GetText(VAR S: ShortString); VIRTUAL;

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
USES SysUtils;

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
  { Use terminal bell instead of DOS sound }
  Write(#7);
END;

PROCEDURE FDelete(d:String);
BEGIN
  { Use SysUtils instead of DOS INT 21h }
  SysUtils.DeleteFile(d);
END;

FUNCTION GetTemp:String;
VAR d:String;
BEGIN
  {$IFDEF UNIX}
  d := GetEnvironmentVariable('TMPDIR');
  IF d = '' THEN d := '/tmp';
  {$ELSE}
  d := GetEnvironmentVariable('TEMP');
  IF d = '' THEN d := GetEnvironmentVariable('TMP');
  {$ENDIF}
  GetTemp := d;
END;

{*******************************}

CONSTRUCTOR TProcess.Init(p:TPoint);
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

procedure TParamLine.GetText(var S: ShortString);
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

PROCEDURE TParamLine.EndModal(Command:WORD);
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
VAR
    Von,Bis:Integer;
    Color: Byte;
    Buf: TDrawBuffer;
    DisplayStr: String;
BEGIN
  Color := GetColor(4);
  MoveChar(Buf, ' ', Color, Size.X);

  { Build display string from scroll position }
  Bis := Pos + Size.X;
  IF Bis > Len THEN Bis := Len;

  DisplayStr := Copy(ScrollText, Pos, Bis - Pos + 1);
  { Wrap around if needed }
  IF Length(DisplayStr) < Size.X THEN
    DisplayStr := DisplayStr + Copy(ScrollText, 1, Size.X - Length(DisplayStr));

  MoveStr(Buf, DisplayStr, Color);
  WriteLine(0, 0, Size.X, 1, Buf);
end;


END.