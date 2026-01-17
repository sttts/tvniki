UNIT NikiInfo;
INTERFACE
USES Dialogs, Objects, Views, Drivers, TVEnh;

TYPE TStatus=(stEdit, stRunning, stTeachIn, stPaused, stDebug);

     PInfoDialog=^TInfoDialog;
     TInfoDialog=OBJECT(TDialog)
                   CONSTRUCTOR Init(VAR P: TPoint);
                   DESTRUCTOR Done; VIRTUAL;
                   PROCEDURE SetupWindow; VIRTUAL;

                   FUNCTION GetPalette: PPalette; VIRTUAL;

                   PROCEDURE HandleEvent(VAR Event:TEvent); VIRTUAL;

                   PROCEDURE SetPosition(x,y:Integer);
                   PROCEDURE SetVorrat(v:Integer);
                   PROCEDURE SetMode(s:TStatus);
                  PRIVATE
                   Position:PParamLine;
                   Vorrat:PParamLine;
                   Mode:PParamLine;
                 END;

VAR InfoWindow:PInfoDialog;

IMPLEMENTATION


CONSTRUCTOR TInfoDialog.Init(VAR P: TPoint);
VAR R:TRect;
BEGIN
  R.A.X := P.X;
  R.A.Y := P.Y;
  R.B.X := R.A.X + 17;
  R.B.Y := R.A.Y + 6;

  INHERITED Init(R, 'Info');
  State := State AND NOT sfShadow;

  SetupWindow;
END;

DESTRUCTOR TInfoDialog.Done;
BEGIN
  IF InfoWindow=@Self THEN InfoWindow := NIL;
  INHERITED Done;
END;

PROCEDURE TInfoDialog.SetupWindow;
VAR R:TRect;
BEGIN
  R.Assign(2,1,16,2);
  New(Position, Init(R, 'Pos.:   %2d:%-2d', 2));
  SetPosition(0,0);
  Insert(Position);

  R.Assign(2,2,15,3);
  New(Vorrat, Init(R,   'Vorrat: %2d', 1));
  SetVorrat(0);
  Insert(Vorrat);

  R.Assign(4,4,15,5);
  New(Mode, Init(R,   '%s', 1));
  SetMode(stTeachIn);
  Insert(Mode);
END;

FUNCTION TInfoDialog.GetPalette: PPalette;
CONST P: String[Length(CCyanWindow)] = CCyanWindow;
BEGIN
  GetPalette := @P;
END;

TYPE TPosInfo = RECORD
                  x:Longint;
                  y:Longint;
                END;

VAR Pos:TPosInfo;

PROCEDURE TInfoDialog.HandleEvent(VAR Event:TEvent);
BEGIN
  CASE Event.What OF
    evCommand : CASE Event.Command OF
                  cmClose : BEGIN
                              ClearEvent(Event);
                              Hide;
                            END;
                END;
  END;

  INHERITED HandleEvent(Event);
END;


PROCEDURE TInfoDialog.SetPosition(x,y:Integer);
BEGIN
  Pos.X := x;
  Pos.Y := y;

  Position^.SetData(Pos);
END;

VAR i:Longint;

PROCEDURE TInfoDialog.SetVorrat(v:Integer);
BEGIN
  i := v;
  Vorrat^.SetData(i);
END;

VAR Str:PString;

PROCEDURE TInfoDialog.SetMode(s:TStatus);
BEGIN
  CASE s OF
    stEdit : Str^:=  '  Edit';
    stRunning: Str^:=' Running';
    stTeachIn: Str^:='Teach In';
    stPaused: Str^:='Pause';
    stDebug: Str^:='Debugging';
  END;
  Mode^.SetData(Str);
END;

BEGIN
  Getmem(Str, 256);
END.
