USES NikiApp, Timer, Mouse, SysUtils;

{$M 16385, 0, 655360}

VAR Niki : TNikiApplication;

VAR OldExit:Pointer;
VAR OldErrorProc: TErrorProc;
VAR AltScreenActive: Boolean = False;

{ Switch from alternate screen back to main screen and disable mouse }
PROCEDURE LeaveAltScreen;
BEGIN
  IF AltScreenActive THEN
  BEGIN
    { Disable mouse modes first so terminal is usable }
    Write(#27'[?1006l');
    Write(#27'[?1000l');
    { Switch back to main screen }
    Write(#27'[?1049l');
    AltScreenActive := False;
  END;
END;

{ Called on runtime errors before the error message is printed }
PROCEDURE MyErrorProc(ErrNo: Longint; Address, Frame: CodePointer);
BEGIN
  LeaveAltScreen;
  { Call old handler if any }
  IF OldErrorProc <> NIL THEN
    OldErrorProc(ErrNo, Address, Frame);
END;

PROCEDURE MyExitProc; FAR;
BEGIN
  ExitProc := OldExit;
  DoneMouse;

  { Switch back to main screen (for normal exits) }
  LeaveAltScreen;

  { Disable xterm mouse mode (in case LeaveAltScreen didn't run) }
  Write(#27'[?1006l');  { Disable SGR extended mouse mode }
  Write(#27'[?1000l');  { Disable mouse button tracking }
END;

BEGIN
  OldExit := ExitProc;
  ExitProc := @MyExitProc;

  { Install error handler to switch screens before backtrace prints }
  OldErrorProc := ErrorProc;
  ErrorProc := @MyErrorProc;

  { Switch to alternate screen }
  Write(#27'[?1049h');
  AltScreenActive := True;

  Install_Timer;

  { Force xterm mouse mode for terminals not recognized by fv_utf8 }
  { (alacritty, kitty, wezterm, iterm, etc.) }
  Write(#27'[?1000h');  { Enable mouse button tracking }
  Write(#27'[?1006h');  { Enable SGR extended mouse mode }

  InitMouse;

  Niki.Init; { Initialisierung }
  Niki.Run;
  Niki.Done;
END.










