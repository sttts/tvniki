UNIT Timer;
INTERFACE

{not $define debug}

PROCEDURE Install_Timer;
PROCEDURE UnInstall_Timer;

FUNCTION NewCounter:Integer;
PROCEDURE ReleaseCounter(Num:Integer);

PROCEDURE SetCounter(Num:Integer; v:Longint);
FUNCTION Counter(Num:Integer):Longint;

IMPLEMENTATION
USES Dos;

CONST MaxTimer=10;

TYPE PPROCEDURE=^PROC;
     PROC=PROCEDURE;

VAR Old:PPROCEDURE;
    Installed:BOOLEAN;
    OldExit:PPROCEDURE;

    counters:ARRAY[0..MaxTimer-1] OF Longint;
    UseList:ARRAY[0..MaxTimer-1] OF Boolean;

    TimerAvailable:Word;

PROCEDURE NewExit; FAR;
BEGIN
  ExitProc := OldExit;

  UnInstall_Timer;
END;

FUNCTION NewCounter:Integer;
VAR z:Byte;
BEGIN
  NewCounter := -1;

  FOR z := 0 TO MaxTimer-1 DO
    IF UseList[z] = FALSE THEN
    BEGIN
      UseList[z] := TRUE;
      SetCounter( z,0 );
      NewCounter := z;

      dec(TimerAvailable);

      break;
    END;
END;

PROCEDURE ReleaseCounter(Num:Integer);
BEGIN
  IF (Num<MaxTimer) AND (Num>=0) AND (UseList[Num] = TRUE) THEN
  BEGIN
    Inc(TimerAvailable);
    UseList[Num] := FALSE;
  END;
END;

PROCEDURE SetCounter(Num:Integer; v:Longint);
BEGIN
  IF (Num<MaxTimer) AND (Num>=0) THEN
    Counters[Num] := v;
END;

FUNCTION Counter(Num:Integer):Longint;
BEGIN
  Counter := 0;

  IF (Num<MaxTimer) AND (Num>=0) THEN
    Counter := Counters[Num];
END;

PROCEDURE TimerInt; INTERRUPT;
VAR z:Byte;
BEGIN
  FOR z:=0 TO MaxTimer-1 DO Inc(Counters[z]);

  {$ifdef debug}
  Mem[SegB800:0] := TimerAvailable + 48;
  {$endif}

  ASM
    pushf
    call Old
  END;
END;

PROCEDURE Install_Timer;
BEGIN
  IF NOT Installed THEN
  BEGIN
    GetIntVec($1c, Pointer(Old));
    SetIntVec($1c, @TimerInt);

    Installed := TRUE;
  END;
END;

PROCEDURE UnInstall_Timer;
BEGIN
  IF Installed THEN
  BEGIN
    SetIntVec($1c, Old);
    Installed := FALSE;
  END;
END;

VAR z:Byte;

BEGIN
  OldExit := ExitProc;
  ExitProc := @NewExit;

  TimerAvailable := MaxTimer;

  FOR z:=0 TO MaxTimer-1 DO
  BEGIN
    SetCounter( z, 0 );
    UseList[z] := FALSE;
  END;
  Installed:=FALSE;
END.