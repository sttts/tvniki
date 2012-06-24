UNIT NikiHelp; {Copyright}

INTERFACE

USES Views, Drivers, Objects, TvEnh, Helpfile;

TYPE PMyHelpWindow = ^TMyHelpWindow;
     TMyHelpWindow = OBJECT(THelpWindow)
                       CONSTRUCTOR Init(Name:String; Ctx:Integer; Big:Boolean);
                       DESTRUCTOR Done; VIRTUAL;
                     END;

VAR HelpWindow:PHelpWindow;

IMPLEMENTATION
USES App, MsgBox,Strings;

CONSTRUCTOR TMyHelpWindow.Init(Name:String; Ctx:Integer; Big:Boolean);
VAR HFile:PHelpFile;
    HelpStrm:PDosStream;
    R:TRect;
BEGIN
  IF HelpWindow<>NIL THEN Dispose(HelpWindow, Done);

  HelpWindow := @Self;

  HelpStrm := New(PDosStream, Init(Name, stOpenRead));
  HFile := new(PHelpFile, Init(HelpStrm));

  INHERITED Init(HFile, Ctx);

  IF Big THEN
  BEGIN
    Desktop^.GetExtent(R);
    MoveTo(R.A.X, R.A.Y);
    GrowTo(R.B.X-R.A.X, R.B.Y-R.A.Y);
  END;
END;

DESTRUCTOR TMyHelpWindow.Done;
BEGIN
  INHERITED Done;
  IF HelpWindow = @Self THEN HelpWindow := NIL;
END;

BEGIN
  HelpWindow := NIL;
END.