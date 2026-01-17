UNIT Timer;

{ Cross-platform timer unit for Free Pascal }
{ Replaces DOS INT 1Ch timer with SysUtils timing }

INTERFACE

PROCEDURE Install_Timer;
PROCEDURE UnInstall_Timer;

FUNCTION NewCounter: Integer;
PROCEDURE ReleaseCounter(Num: Integer);

PROCEDURE SetCounter(Num: Integer; v: Longint);
FUNCTION Counter(Num: Integer): Longint;

IMPLEMENTATION

USES SysUtils;

CONST
  MaxTimer = 10;
  { DOS timer ticked at ~18.2 Hz (54.9ms per tick) }
  TicksPerSecond = 18.2;
  MsPerTick = 1000.0 / TicksPerSecond;

VAR
  Installed: Boolean;

  { Base values set when SetCounter is called }
  CounterBase: ARRAY[0..MaxTimer-1] OF Longint;

  { Timestamp when counter was last set (milliseconds since midnight) }
  StartTimes: ARRAY[0..MaxTimer-1] OF Int64;
  UseList: ARRAY[0..MaxTimer-1] OF Boolean;
  TimerAvailable: Word;

{ Get current time in milliseconds }
FUNCTION GetCurrentMs: Int64;
VAR
  Hour, Min, Sec, MSec: Word;
BEGIN
  DecodeTime(Now, Hour, Min, Sec, MSec);
  GetCurrentMs := Int64(Hour) * 3600000 + Int64(Min) * 60000 +
                  Int64(Sec) * 1000 + MSec;
END;

FUNCTION NewCounter: Integer;
VAR
  z: Byte;
BEGIN
  NewCounter := -1;

  FOR z := 0 TO MaxTimer-1 DO
    IF UseList[z] = FALSE THEN
    BEGIN
      UseList[z] := TRUE;
      SetCounter(z, 0);
      NewCounter := z;
      Dec(TimerAvailable);
      Break;
    END;
END;

PROCEDURE ReleaseCounter(Num: Integer);
BEGIN
  IF (Num < MaxTimer) AND (Num >= 0) AND (UseList[Num] = TRUE) THEN
  BEGIN
    Inc(TimerAvailable);
    UseList[Num] := FALSE;
  END;
END;

PROCEDURE SetCounter(Num: Integer; v: Longint);
BEGIN
  IF (Num < MaxTimer) AND (Num >= 0) THEN
  BEGIN
    CounterBase[Num] := v;
    StartTimes[Num] := GetCurrentMs;
  END;
END;

FUNCTION Counter(Num: Integer): Longint;
VAR
  ElapsedMs: Int64;
  Ticks: Longint;
BEGIN
  Counter := 0;

  IF (Num < MaxTimer) AND (Num >= 0) AND UseList[Num] THEN
  BEGIN
    ElapsedMs := GetCurrentMs - StartTimes[Num];

    { Handle midnight rollover }
    IF ElapsedMs < 0 THEN
      ElapsedMs := ElapsedMs + 86400000;

    { Convert milliseconds to DOS-style ticks (~18.2 Hz) }
    Ticks := Round(ElapsedMs / MsPerTick);
    Counter := CounterBase[Num] + Ticks;
  END;
END;

PROCEDURE Install_Timer;
BEGIN
  { No-op on modern systems - timing is always available }
  Installed := TRUE;
END;

PROCEDURE UnInstall_Timer;
BEGIN
  { No-op on modern systems }
  Installed := FALSE;
END;

VAR
  z: Byte;

BEGIN
  TimerAvailable := MaxTimer;

  FOR z := 0 TO MaxTimer-1 DO
  BEGIN
    CounterBase[z] := 0;
    StartTimes[z] := 0;
    UseList[z] := FALSE;
  END;

  Installed := FALSE;
END.
