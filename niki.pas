USES NikiApp, Timer, Mouse;

{$M 16385, 0, 655360}

VAR Niki : TNikiApplication;

VAR OldExit:Pointer;


PROCEDURE MyExitProc; FAR;
BEGIN
  ExitProc := OldExit;
  DoneMouse;

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
  InitMouse;

  Niki.Init; { Initialisierung }
  Niki.Run;
  Niki.Done;
END.










