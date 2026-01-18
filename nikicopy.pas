UNIT NikiCopy; {Copyright}

INTERFACE

USES Views, Dialogs, Drivers, Objects, TvEnh;

TYPE PCopyRightDialog=^TCopyrightDialog;
     TCopyRightDialog=OBJECT(TDialog)
                   CONSTRUCTOR Init;
                   DESTRUCTOR Done; VIRTUAL;
                   PROCEDURE SetupWindow; VIRTUAL;
                   PROCEDURE Idle; VIRTUAL;

                   FUNCTION GetPalette: PPalette; VIRTUAL;

                   PROCEDURE HandleEvent(VAR Event:TEvent); VIRTUAL;

                  PRIVATE
                   Scroller:PScrollerLine;
                 END;

IMPLEMENTATION
USES App, Strings, Timer, Hilfe, Version;

CONST Height=9;
      MinWidth=36;


{************************************}

FUNCTION CalcWidth: Integer;
VAR Ver: String;
BEGIN
  Ver := 'tvNiki ' + VersionString;
  IF Length(Ver) + 4 > MinWidth THEN
    CalcWidth := Length(Ver) + 4
  ELSE
    CalcWidth := MinWidth;
END;

CONSTRUCTOR TCopyrightDialog.Init;
VAR R:TRect;
    Width: Integer;
BEGIN
  Width := CalcWidth;
  Desktop^.GetExtent(R);
  R.A.X := (R.B.X-Width) DIV 2;
  R.A.Y := (R.B.Y-Height) DIV 2;
  R.B.X := R.A.X + Width;
  R.B.Y := R.A.Y + Height;

  INHERITED Init(R, 'Info');

  Scroller := NIL;
  HelpCtx := hcCopyright;

  SetupWindow;
END;

DESTRUCTOR TCopyrightDialog.Done;
BEGIN
  INHERITED Done;
END;

PROCEDURE TCopyrightDialog.SetupWindow;
VAR R:TRect;
    Ver:String;
    Width: Integer;
BEGIN
  Width := CalcWidth;
  Ver := 'tvNiki ' + VersionString;

  { Centered version string }
  R.Assign((Width - Length(Ver)) DIV 2, 2, (Width + Length(Ver)) DIV 2, 3);
  Insert( New(PStaticText, Init(R, Ver)));

  { Centered OK button }
  R.Assign((Width - 12) DIV 2, 4, (Width + 12) DIV 2, 6);
  Insert( New(PButton, Init(R, '~O~K', cmOk, bfDefault)));

  { Scrolling copyright }
  R.Assign(1, 7, Width - 1, 8);
  New(Scroller, Init(R,
    'tvNiki (c) 1996-2026 Stefan Schimanski, all rights reserved - '));
  Insert(Scroller);
END;

FUNCTION TCopyrightDialog.GetPalette: PPalette;
BEGIN
  GetPalette := Inherited GetPalette;
END;

PROCEDURE TCopyrightDialog.HandleEvent(VAR Event:TEvent);
BEGIN
  IF Event.What=evNothing THEN Idle;
  INHERITED HandleEvent(Event);
END;

PROCEDURE TCopyrightDialog.Idle;
BEGIN
  IF Scroller<>NIL THEN Scroller^.Idle;
END;

END.