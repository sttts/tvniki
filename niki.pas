USES NikiApp, Timer, Mouse, BaseUnix;

{$M 16385, 0, 655360}

VAR Niki : TNikiApplication;

VAR OldExit:Pointer;
VAR AltScreenActive: Boolean = False;

{ Switch from alternate screen back to main screen }
PROCEDURE LeaveAltScreen;
BEGIN
  IF AltScreenActive THEN
  BEGIN
    Write(#27'[?1049l');
    AltScreenActive := False;
  END;
END;

{ Signal handler for crashes - switch to main screen before backtrace prints }
PROCEDURE CrashHandler(Sig: CInt); cdecl;
BEGIN
  LeaveAltScreen;

  { Disable mouse modes so terminal is usable }
  Write(#27'[?1006l');
  Write(#27'[?1000l');

  { Re-raise signal with default handler to get backtrace }
  FpSignal(Sig, SignalHandler(SIG_DFL));
  FpKill(FpGetpid, Sig);
END;

PROCEDURE MyExitProc; FAR;
BEGIN
  ExitProc := OldExit;
  DoneMouse;

  { Switch back to main screen }
  LeaveAltScreen;

  { Disable xterm mouse mode }
  Write(#27'[?1006l');  { Disable SGR extended mouse mode }
  Write(#27'[?1000l');  { Disable mouse button tracking }
END;

BEGIN
  OldExit := ExitProc;
  ExitProc := @MyExitProc;

  { Install signal handlers before switching screens, so crashes show backtrace }
  FpSignal(SIGSEGV, SignalHandler(@CrashHandler));
  FpSignal(SIGBUS, SignalHandler(@CrashHandler));
  FpSignal(SIGFPE, SignalHandler(@CrashHandler));
  FpSignal(SIGILL, SignalHandler(@CrashHandler));

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










