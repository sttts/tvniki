USES NikiApp, Timer, Crt;

{$M 16385, 0, 655360}

VAR Niki : TNikiApplication;

VAR OldExit:Pointer;


PROCEDURE MyExitProc; FAR;
BEGIN
  ExitProc := OldExit;

  IF ExitCode<>0 THEN
  BEGIN
    ClrScr;

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

  Niki.Init; { Initialisierung }
  Niki.Run;
  Niki.Done;
END.










