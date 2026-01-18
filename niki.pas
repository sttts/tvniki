{$MODE OBJFPC}
{$M 16385, 0, 655360}

USES NikiApp, Timer, Mouse, SysUtils, Process, Classes;

VAR Niki : TNikiApplication;

VAR OldExit:Pointer;
VAR AltScreenActive: Boolean = False;
VAR CrashLog: Text;

VAR DecodedBacktrace: TStringList;

{ Decode stack addresses using platform-specific tool }
PROCEDURE DecodeBacktrace;
VAR
  P: TProcess;
  J: Integer;
  LoadAddr, FileAddr: PtrUInt;
BEGIN
  DecodedBacktrace := TStringList.Create;

  { Calculate load address from PASCALMAIN's runtime address }
  { PASCALMAIN is at file offset ~0xe20, so round down to page boundary }
  LoadAddr := PtrUInt(@PASCALMAIN) AND $FFFFFFFFFFFFF000;

  P := TProcess.Create(NIL);
  TRY
    {$IFDEF DARWIN}
    P.Executable := 'atos';
    P.Parameters.Add('-o');
    P.Parameters.Add(ParamStr(0));
    P.Parameters.Add('-l');
    P.Parameters.Add('0x' + HexStr(Pointer(LoadAddr)));
    FOR J := 0 TO ExceptFrameCount - 1 DO
      P.Parameters.Add('0x' + HexStr(ExceptFrames[J]));
    {$ELSE}
    { On Linux, convert runtime addresses to file addresses }
    P.Executable := 'addr2line';
    P.Parameters.Add('-e');
    P.Parameters.Add(ParamStr(0));
    P.Parameters.Add('-f');
    P.Parameters.Add('-C');
    P.Parameters.Add('-p');
    FOR J := 0 TO ExceptFrameCount - 1 DO
    BEGIN
      { Subtract load address to get file offset }
      FileAddr := PtrUInt(ExceptFrames[J]) - LoadAddr;
      P.Parameters.Add('0x' + HexStr(Pointer(FileAddr)));
    END;
    {$ENDIF}
    P.Options := [poWaitOnExit, poUsePipes];
    P.Execute;
    DecodedBacktrace.LoadFromStream(P.Output);
  EXCEPT
    { Decoding failed, leave empty }
  END;
  P.Free;
END;

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
      { Decode backtrace first while we're still running }
      DecodeBacktrace;

      LeaveAltScreen;

      { Write to crash.log }
      Assign(CrashLog, 'crash.log');
      Rewrite(CrashLog);
      Writeln(CrashLog, 'Exception: ', E.ClassName, ': ', E.Message);
      Writeln(CrashLog, 'Backtrace:');
      IF DecodedBacktrace.Count > 0 THEN
        Writeln(CrashLog, DecodedBacktrace.Text)
      ELSE
        DumpExceptionBackTrace(CrashLog);
      Close(CrashLog);

      { Write to stderr }
      Writeln(StdErr, 'Exception: ', E.ClassName, ': ', E.Message);
      Writeln(StdErr, 'Backtrace:');
      IF DecodedBacktrace.Count > 0 THEN
        Write(StdErr, DecodedBacktrace.Text)
      ELSE
        DumpExceptionBackTrace(StdErr);
      Writeln(StdErr);
      Writeln(StdErr, '(also saved to crash.log)');

      DecodedBacktrace.Free;
      Halt(1);
    END;
  END;
END.
