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
USES App, Strings, Timer, Hilfe;

CONST Width=36;
      Height=11;


{************************************}

CONSTRUCTOR TCopyrightDialog.Init;
VAR R:TRect;
BEGIN
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
BEGIN
  R.Assign(13,2,27,3);
  Insert( New(PStaticText, Init(R, 'tvNiki 1.11')));

  R.Assign(9,4,27,5);
  Insert( New(PStaticText, Init(R,   'by 1Stein Software')));

  R.Assign(12,7,24,9);
  Insert( New(PButton, Init(R, '~O~K', cmOk, bfDefault)));

  R.Assign(1,9,35,10);
  New(Scroller, Init(R,
    'tvNiki (c) by Stefan Schimanski 1996, all rights reserved - '));
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