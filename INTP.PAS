UNIT Intp;
INTERFACE


CONST stOk       = 0;
      stNoMemory = 1;
      stBreak    = 2;
      stStackErr = 3;
      stUnknownOpcode = 4;
      stFileError = 5;
      stNoVorrat = 6;
      stNoPalette = 7;
      stHitWall = 8;

      StackSize = 4092;

TYPE PProgramArray=^TProgramArray;
     TProgramArray=ARRAY[0..8191] OF Byte;

     PStackArray=^TStackArray;
     TStackArray=ARRAY[0..StackSize-1] OF Word;

     PInterpreter=^TInterpreter;
     TInterpreter=OBJECT
                    Status:Integer;
                    Prog:PProgramArray;
                    Stack:PStackArray;

                    IP:Word;
                    SP:Word;
                    Carry:BOOLEAN;

                    BreakPoint:BOOLEAN;

                    CONSTRUCTOR Init(ADatei:STRING);
                    DESTRUCTOR Done; VIRTUAL;

                    PROCEDURE LoadFile(ADatei:STRING);

                    PROCEDURE Error(e:Integer); VIRTUAL;

                    FUNCTION RunStep:BOOLEAN;

                    PROCEDURE Call;
                    PROCEDURE Return;
                    PROCEDURE Debug(p:Word); VIRTUAL;

                    FUNCTION Vor:BOOLEAN; VIRTUAL;
                    PROCEDURE Links; VIRTUAL;
                    FUNCTION Nimm_Auf:BOOLEAN; VIRTUAL;
                    FUNCTION Leg_Ab:BOOLEAN; VIRTUAL;

                    FUNCTION Vorne_Frei:BOOLEAN; VIRTUAL;
                    FUNCTION Links_Frei:BOOLEAN; VIRTUAL;
                    FUNCTION Rechts_Frei:BOOLEAN; VIRTUAL;
                    FUNCTION hat_Vorrat:BOOLEAN; VIRTUAL;
                    FUNCTION Platz_belegt:BOOLEAN; VIRTUAL;
                  END;

IMPLEMENTATION
USES Objects, Opcodes;


CONSTRUCTOR TInterpreter.Init(ADatei:STRING);
BEGIN
  Status := stOk;
  BreakPoint := FALSE;

  IP := 0;
  SP := 0;
  Carry := FALSE;

  Prog := NIL;
  Stack := NIL;

  { Modern systems have plenty of memory - just allocate directly }
  New(Prog);
  IF Prog = NIL THEN Status := stNoMemory;

  New(Stack);
  IF Stack = NIL THEN Status := stNoMemory;

  IF Status=stOk THEN LoadFile(ADatei);
END;

PROCEDURE TInterpreter.LoadFile(ADatei:STRING);
VAR s:TBufStream;
BEGIN
  IF Status=stOk THEN
  BEGIN
    S.Init(ADatei, stOpen, 2048);

    S.Read(Prog^, S.GetSize);

    IF S.Status<>stOk THEN Status:=stFileError;

    S.Done;
  END;
END;

DESTRUCTOR TInterpreter.Done;
BEGIN
  IF Stack<>NIL THEN Dispose(Stack);
  IF Prog<>NIL THEN Dispose(Prog);
END;

PROCEDURE TInterpreter.Call;
BEGIN
  IF Sp>=StackSize THEN Status := stStackErr ELSE
  BEGIN
    Stack^[SP] := IP + 2;
    Inc(Sp);
    IP := Prog^[IP]+Prog^[IP+1]*256;
  END;
END;

PROCEDURE TInterpreter.Return;
BEGIN
  IF Sp=0 THEN Status := stStackErr ELSE
  BEGIN
    Dec(Sp);
    IP := Stack^[SP];
  END;
END;

PROCEDURE TInterpreter.Debug(p:Word);
BEGIN
  Breakpoint := TRUE;
END;

PROCEDURE TInterpreter.Error(e:Integer);
BEGIN
  Status := e;
END;

{VAR Info:RECORD
           c : Byte;
           ip, sp:Longint;
        END;}

FUNCTION TInterpreter.RunStep:BOOLEAN;
VAR c:Byte;
BEGIN
  IF Status=stOk THEN
  BEGIN
    IP := IP AND 8191;

    c:=Prog^[IP];
    Inc(IP);
    CASE c OF
      ocJMP : IP := Prog^[IP]+Prog^[IP+1]*256;
      ocGO  : IF NOT Vor THEN Status := stHitWall;
      ocTURN: Links;
      ocTAKE: IF NOT Nimm_Auf THEN Status := stNoPalette;
      ocPUT : IF NOT Leg_Ab THEN Status := stNoVorrat;
      ocCALL: Call;
      ocRET : Return;
      ocCVF : Carry := Vorne_Frei;
      ocCLF : Carry := Links_Frei;
      ocCRF : Carry := Rechts_Frei;
      ocCPB : Carry := Platz_Belegt;
      ocCV  : Carry := hat_Vorrat;
      ocJC  : IF Carry THEN IP := Prog^[IP]+Prog^[IP+1]*256 ELSE Inc(IP, 2);
      ocJNC : IF NOT Carry THEN IP := Prog^[IP]+Prog^[IP+1]*256 ELSE Inc(IP, 2);
      ocDEBUG:BEGIN
                Debug(Prog^[IP]+Prog^[IP+1]*256);
                Inc(IP,2);
              END;
      ocBRK : Status:=stBreak;
      ELSE Status := stUnknownOpcode;
    END;

    CASE c OF
     ocTURN, ocGO, ocTAKE, ocPUT : RunStep := TRUE;
     ELSE RunStep := FALSE;
    END;
  END;
END;

FUNCTION TInterpreter.Vor:BOOLEAN;
BEGIN
END;

PROCEDURE TInterpreter.Links;
BEGIN
END;

FUNCTION TInterpreter.Nimm_Auf:BOOLEAN;
BEGIN
END;

FUNCTION TInterpreter.Leg_Ab:BOOLEAN;
BEGIN
END;

FUNCTION TInterpreter.Vorne_Frei:BOOLEAN;
BEGIN
END;

FUNCTION TInterpreter.Links_Frei:BOOLEAN;
BEGIN
END;

FUNCTION TInterpreter.Rechts_Frei:BOOLEAN;
BEGIN
END;

FUNCTION TInterpreter.hat_Vorrat:BOOLEAN;
BEGIN
END;

FUNCTION TInterpreter.Platz_belegt:BOOLEAN;
BEGIN
END;





END.