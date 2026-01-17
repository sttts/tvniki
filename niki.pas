USES NikiApp, Timer, Mouse;

{$M 16385, 0, 655360}

VAR Niki : TNikiApplication;

VAR OldExit:Pointer;


PROCEDURE MyExitProc; FAR;
BEGIN
  ExitProc := OldExit;
  DoneMouse;

  { Disable xterm mouse mode }
  Write(#27'[?1006l');  { Disable SGR extended mouse mode }
  Write(#27'[?1000l');  { Disable mouse button tracking }

  IF ExitCode<>0 THEN
  BEGIN
    Write(#27'[2J'#27'[H');  { ANSI: clear screen and home cursor }

    Writeln('>>>>>>>>> Fehler <<<<<<<<<');
    Writeln;
    Writeln('Es ist ein nicht bekannter Fehler aufgetreten.');
    Writeln('tvNiki wurde beendet, um einen Absturz zu verhindern.');
    Writeln;
  END;
END;

BEGIN
  OldExit := ExitProc;
  ExitProc := @MyExitProc;

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










