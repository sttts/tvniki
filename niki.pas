{$MODE OBJFPC}
{$M 16385, 0, 655360}

USES NikiApp, Timer, Mouse, SysUtils;

VAR Niki : TNikiApplication;

VAR OldExit:Pointer;
VAR AltScreenActive: Boolean = False;
VAR CrashLog: Text;

{ Switch from alternate screen back to main screen and disable mouse }
PROCEDURE LeaveAltScreen;
BEGIN
  IF AltScreenActive THEN
  BEGIN
    AltScreenActive := False;
    { Disable mouse modes first so terminal is usable }
    Write(#27'[?1006l');
    Write(#27'[?1000l');
    { Switch back to main screen }
    Write(#27'[?1049l');
    Writeln;
    Flush(Output);
  END;
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

  { Switch to alternate screen }
  Write(#27'[?1049h');
  AltScreenActive := True;

  Install_Timer;

  { Force xterm mouse mode for terminals not recognized by fv_utf8 }
  { (alacritty, kitty, wezterm, iterm, etc.) }
  Write(#27'[?1000h');  { Enable mouse button tracking }
  Write(#27'[?1006h');  { Enable SGR extended mouse mode }

  InitMouse;

  TRY
    Niki.Init;
    Niki.Run;
    Niki.Done;
  EXCEPT
    ON E: Exception DO
    BEGIN
      { Write to crash.log for debugging }
      Assign(CrashLog, 'crash.log');
      Rewrite(CrashLog);
      Writeln(CrashLog, 'Exception: ', E.ClassName, ': ', E.Message);
      Writeln(CrashLog, 'Backtrace:');
      DumpExceptionBackTrace(CrashLog);
      Close(CrashLog);

      LeaveAltScreen;
      Writeln(StdErr, 'Exception: ', E.ClassName, ': ', E.Message);
      Writeln(StdErr, 'Backtrace:');
      DumpExceptionBackTrace(StdErr);
      Writeln(StdErr);
      Writeln(StdErr, 'To decode: lldb ', ParamStr(0), ' -o "image lookup -a <addr>" -o quit');
      Writeln(StdErr);
      Writeln(StdErr, '(also saved to crash.log)');
      Halt(1);
    END;
  END;
END.
