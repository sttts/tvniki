UNIT Compiler;

INTERFACE

{not $define experimental}

{$ifdef experimental}
  {$define CallableFuncs}

  {not $define UserFuncs}
    {noch nicht komplett implementiert:
     öberall innerhalb der Function mu· der Name gÅltig sein,
     um einen RÅckgabewert zu liefern

     -> die Prozedur "Befehl" mu· erweitert werden, da· Sie Konstrukte wie
     "Func := TRUE" verarbeitet

     -> Die Prozedur "Befehl" mu· durch "Anweisung ersetzt werden, die
     spÑter z.B. auch Rechnungen verarbeiten kann.
    }
{$endif}


FUNCTION Compile(ASource:String; ADest:String; Debug:Boolean):BOOLEAN;

CONST ErrSourceNotFound=1;
      ErrDestNotFound=2;
      ErrBeginWanted=3;
      ErrEndWanted=4;
      ErrPointWanted=5;
      ErrIdWanted=6;
      ErrSemikolonWanted=7;
      ErrUnClosedComment=8;
      ErrUnkownProc=9;
      ErrUsedId=10;
      ErrKeyId=11;
      ErrThenWanted=12;
      ErrUnkownFunc=13;
      ErrFuncWanted=14;
      ErrDoWanted=15;
      ErrUntilWanted=16;
      ErrRightBracket=17;

CONST ErrorLine:Integer=0;
      ErrorColumn:Integer=0;
      ErrorFile:String='';
      ErrorDescribtion:String='';
      ErrorNumber:Integer=0;
      Lines:Longint=0;

IMPLEMENTATION
USES Dos, Crt, Objects, Opcodes;

TYPE PProgram=^TProgram;
     TProgram=OBJECT(TObject)
                CONSTRUCTOR Init(ADateiName:String; VAR Fehler:Integer);
                DESTRUCTOR Done; VIRTUAL;

                FUNCTION ActPos:Word;
                FUNCTION WriteByte(b:Byte):Word;
                FUNCTION WriteWord(w:Word):Word;
                FUNCTION WriteStr(s:String):Word;

                PROCEDURE SetAdresse(adr:Word; w:Word);
                PROCEDURE SetStart(a:Word);
               PRIVATE
                Datei:File;
                Pos:Word;
              END;


     PIdentifier=^TIdentifier;
     TIdentifier=OBJECT(TObject)
                   Name:String;
                   CONSTRUCTOR Init(S:String);
                   PROCEDURE MakeCode(Prog:PProgram); VIRTUAL;
                 END;

     PProcedure=^TProcedure;
     TProcedure=OBJECT(TIdentifier)
                  Adresse:Word;
                  CONSTRUCTOR Init(S:String; a:Word);
                  PROCEDURE MakeCode(Prog:PProgram); VIRTUAL;
                END;

     PCommand=^TCommand;
     TCommand=OBJECT(TIdentifier)
                Code:Byte;
                CONSTRUCTOR Init(S:String; c:Byte);
                PROCEDURE MakeCode(Prog:PProgram); VIRTUAL;
              END;

     PFunction=^TFunction;
     TFunction=OBJECT(TCommand)
                PROCEDURE MakeCode(Prog:PProgram); VIRTUAL;
               END;

     {$ifdef UserFuncs}
     PUserFunc=^TUserFunc;
     TUserFunc=OBJECT(TProcedure)
               END;

     PVariable=^TVariable;
     TVariable=OBJECT(TIdentifier)
                 PROCEDURE StoreValue(Prog:PProgram); VIRTUAL;
                 PROCEDURE LoadValue(Prog:PProgram); VIRTUAL;
               END;

     PGlobalVar=^TGlobalVar;
     TGlobalVar=OBJECT(TVariable)
                  Adresse:Word;
                END;

     PFuncValue=^TFuncValue;
     TFuncValue=OBJECT(TVariable)
                  PROCEDURE StoreValue(Prog:PProgram); VIRTUAL;
                  PROCEDURE LoadValue(Prog:PProgram); VIRTUAL;
                END;
     {$endif}

     PIdCollection=^TIdCollection;
     TIdCollection=OBJECT(TCollection)
                     CONSTRUCTOR Init;
                     DESTRUCTOR Done; VIRTUAL;

                     PROCEDURE Add(Id:PIdentifier);
                     FUNCTION IsIn(S:String):BOOLEAN;
                     FUNCTION Search(S:String):PIdentifier;
                   END;

{*****************************************}

PROCEDURE FDelete(d:String);
VAR R:Registers;
BEGIN
  d[length(d)+1] := #0;

  R.AH := $41;
  R.DX := Ofs(d[1]);
  R.DS := Seg(d[1]);
  Intr($21, R);
END;


{*****************************************}

CONSTRUCTOR TProgram.Init;
BEGIN
  INHERITED Init;
  {$I-}
  Assign(Datei, ADateiName);
  Rewrite(Datei,1);
  WriteByte(ocJMP);
  WriteWord(0);
  Fehler := IOResult;
  {$I+}
END;

DESTRUCTOR TProgram.Done;
BEGIN
  INHERITED Done;
  Close( Datei );
END;

FUNCTION TProgram.ActPos:Word;
BEGIN
  ActPos := Pos;
END;

FUNCTION TProgram.WriteByte(b:Byte):Word;
BEGIN
  BlockWrite(Datei, b, sizeof(b));
  Inc(Pos, sizeof(b));
  WriteByte := Pos;
END;

FUNCTION TProgram.WriteWord(w:Word):Word;
BEGIN
  BlockWrite(Datei, w, sizeof(w));
  Inc(Pos, sizeof(w));
  WriteWord := Pos;
END;

FUNCTION TProgram.WriteStr(s:String):Word;
BEGIN
  BlockWrite(Datei, s[1], length(s));
  Inc(Pos, length(s));
  WriteStr := Pos;
END;

PROCEDURE TProgram.SetAdresse(adr:Word; w:Word);
BEGIN
  Seek(Datei, adr);

  BlockWrite(Datei, w, sizeof(w));

  Seek(Datei, Pos);
END;

PROCEDURE TProgram.SetStart(a:Word);
BEGIN
{  Seek(Datei, 1);
  BlockWrite(Datei, a, sizeof(a));}
  SetAdresse(1, a);
END;


{*****************************************}

CONSTRUCTOR TIdentifier.Init(S:String);
BEGIN
  INHERITED Init;
  Name := s;
END;

PROCEDURE TIdentifier.MakeCode(Prog:PProgram);
BEGIN
END;


{*****************************************}

CONSTRUCTOR TProcedure.Init(S:String; a:Word);
BEGIN
  INHERITED Init(S);
  Adresse := a;
END;

PROCEDURE TProcedure.MakeCode(Prog:PProgram);
BEGIN
  Prog^.WriteByte(ocCall);
  Prog^.WriteWord(Adresse);
END;

{*****************************************}

CONSTRUCTOR TCommand.Init(S:String; c:Byte);
BEGIN
  INHERITED Init(S);
  Code := c;
END;

PROCEDURE TCommand.MakeCode(Prog:PProgram);
BEGIN
  Prog^.WriteByte(code);
END;

{*****************************************}

PROCEDURE TFunction.MakeCode(Prog:PProgram);
BEGIN
  INHERITED MakeCode(Prog);
END;

{*****************************************}

{$ifdef UserFuncs}

PROCEDURE TVariable.StoreValue(Prog:PProgram);
BEGIN
END;

PROCEDURE TVariable.LoadValue(Prog:PProgram);
BEGIN
END;

{*****************************************}

PROCEDURE TFuncValue.StoreValue(Prog:PProgram);
BEGIN
  Prog^.WriteByte(ocSDEC);
  Prog^.WriteByte(ocPUSH);
END;

PROCEDURE TFuncValue.LoadValue(Prog:PProgram);
BEGIN
END;

{$endif}

{*****************************************}

CONSTRUCTOR TIdCollection.Init;
BEGIN
  INHERITED Init(16, 8);
END;

DESTRUCTOR TIdCollection.Done;
BEGIN
  FreeAll;
  INHERITED Done;
END;

PROCEDURE TIdCollection.Add(Id:PIdentifier);
BEGIN
  Insert(Id);
END;

FUNCTION TIdCollection.Search(S:String):PIdentifier;

  FUNCTION Matches(Item: Pointer): Boolean; FAR;
  BEGIN
    Matches:=PIdentifier(Item)^.Name = s;
  END;

BEGIN
  Search := FirstThat( @Matches );
END;


FUNCTION TIdCollection.IsIn(S:String):BOOLEAN;
BEGIN
  IsIn := Search(S) <> NIL;
END;

{*****************************************}


VAR Source:File;
    Dest:PProgram;

    Procs:PIdCollection;
    Keywords:PIdCollection;
    Funcs:PIdCollection;
    DebugMode:Boolean;

    x, y:Word;

{$ifdef UserFuncs}
CONST MaxNameAreas=16;

VAR Vars:PIdCollection;
    Locals:PIdCollection;

    NameAreas:ARRAY [0..MaxNameAreas-1] OF PIdCollection;
    ActNameArea:Integer;

{*****************************************}

FUNCTION NewNameArea:BOOLEAN;
BEGIN
END;

FUNCTION RemoveNameArea:BOOLEAN;
BEGIN
  Dec(ActNameArea);
  Dispose(NameAreas[ActNameArea], Done);
  IF ActNameArea>0 THEN
    Locals := NameAreas[ActNameArea-1]
  ELSE Locals := NIL;
END;

{$endif}

{*****************************************}

FUNCTION Programm:BOOLEAN; FORWARD;

FUNCTION Compile(ASource:String; ADest:String; Debug:Boolean):BOOLEAN;
VAR Error:Integer;
BEGIN
  DebugMode := Debug;

  New(Procs, Init);
  Procs^.Insert(New(PCommand, Init('VOR', ocGO)));
  Procs^.Insert(New(PCommand, Init('DREHE_LINKS', ocTURN)));
  Procs^.Insert(New(PCommand, Init('NIMM_AUF', ocTAKE)));
  Procs^.Insert(New(PCommand, Init('GIB_AB', ocPUT)));

  New(Funcs, Init);
  Funcs^.Insert(New(PFunction, Init('VORNE_FREI', ocCVF)));
  Funcs^.Insert(New(PFunction, Init('LINKS_FREI', ocCLF)));
  Funcs^.Insert(New(PFunction, Init('RECHTS_FREI', ocCRF)));
  Funcs^.Insert(New(PFunction, Init('PLATZ_BELEGT', ocCPB)));
  Funcs^.Insert(New(PFunction, Init('HAT_VORRAT', ocCV)));


  ErrorNumber := 0;
  ErrorLine := 0;
  ErrorFile := ASource;
  ErrorDescribtion := '';
  ErrorColumn := 0;
  Lines := 0;

  x := 0;
  y := 1;

  {$I-}
  Assign(Source, ASource);
  Reset(Source, 1);
  IF IOResult<>0 THEN
  BEGIN
    ErrorNumber := ErrSourceNotFound;
    ErrorDescribtion := 'Quelldatei nicht gefunden oder kann nicht geîffnet werden';
    Compile := FALSE;
  END ELSE
  BEGIN
    New(Dest, Init(ADest, Error));
    IF Error<>0 THEN
    BEGIN
      ErrorNumber := ErrDestNotFound;
      ErrorDescribtion := 'Zieldatei kann nicht erzeugt werden';
      Compile := False;
    END ELSE
    BEGIN
      Compile := Programm;
    END;
    Dispose(Dest, Done);
  END;
  Close(Source);
  {$I+}

  Dispose(Funcs, Done);
  Dispose(Procs, Done);

  IF ErrorNumber<>0 THEN
  BEGIN
    FDelete(ADest);
  END ELSE
  BEGIN
    Lines := y;
  END;
END;

{*********************************************}

VAR ActChar:Char;

FUNCTION NextChar:Char;
BEGIN
  IF NOT eof(Source) THEN
  BEGIN
    BlockRead(Source, ActChar, 1);

    inc(x);
    IF ActChar=#10 THEN
    BEGIN
      inc(y);
      x := 0;
    END;
  END ELSE ActChar:=#26;

  NextChar := ActChar;
END;

FUNCTION UseChar:Char;
BEGIN
  UseChar := ActChar;
END;

FUNCTION EndOfFile:BOOLEAN;
BEGIN
  EndOfFile := eof(Source);
END;

{*********************************************}

TYPE TToken=(tkNothing, tkOperator, tkId, tkUnKnown, tkBegin, tkEnd,
             tkSemikolon, tkPoint, tkLeft, tkRight);

VAR NextToken:TToken;
    NextExpression:STRING;
    NextValue:Real;

    TokenX, TokenY:Word;

PROCEDURE DebugInfo(Prog:PProgram);
BEGIN
  IF DebugMode THEN
  BEGIN
    Prog^.WriteByte(ocDebug);
    Prog^.WriteWord(y);
  END;
END;

FUNCTION GetNextToken:BOOLEAN;
VAR s:String;
    c:Char;
    Stop:Boolean;

LABEL SkipChar;

BEGIN
 SkipChar:
  GetNextToken := TRUE;

  TokenX := x;
  TokenY := y;

  NextValue := 0;
  NextExpression := '';

  c := UseChar;
  CASE c OF
      'a'..'z', 'A'..'Z' :
         BEGIN
           NextToken := tkId;
           s := Upcase(c);
           Stop := FALSE;
           WHILE NOT EndOfFile AND NOT Stop DO
           BEGIN
             c := Upcase(NextChar);
             CASE c OF
               'A'..'Z', '0'..'9', '_': s:=s+c
               ELSE Stop := TRUE;
             END;
           END;
           NextExpression := s;
         END;

      '.' : BEGIN
              NextToken := tkPoint;
              NextChar;
            END;
      ';' : BEGIN
              NextToken := tkSemikolon;
              NextChar;
            END;

      '{' : BEGIN
              WHILE (NextChar<>'}') AND (UseChar<>#26) DO;
              IF UseChar=#26 THEN
              BEGIN
                GetNextToken := FALSE;

                ErrorNumber := ErrUnClosedComment;
                ErrorLine := TokenY;
                ErrorColumn := TokenX;
                ErrorDescribtion := 'Nicht geschlossenes Kommentar';

                Exit;
              END;
              NextChar;
              Goto SkipChar;
            END;

      '(' : BEGIN
              IF NextChar='*' THEN
              BEGIN
                REPEAT
                  WHILE (NextChar<>'*') AND (UseChar<>#26) DO;
                UNTIL (NextChar=')') OR (UseChar=#26);
                IF UseChar=#26 THEN
                BEGIN
                  GetNextToken := FALSE;

                  ErrorNumber := ErrUnClosedComment;
                  ErrorLine := TokenY;
                  ErrorColumn := TokenX;
                  ErrorDescribtion := 'Nicht geschlossenes Kommentar';

                  Exit;
                END;
                NextChar;
                Goto SkipChar;
              END ELSE NextToken := tkLeft;
            END;
      ')' : BEGIN
              NextToken := tkRight;
              NextChar;
            END;

      #26 : NextToken := tkNothing;
      #0..#25,#27..#32:BEGIN
                         NextChar;
                         Goto SkipChar;
                       END;
     ELSE BEGIN
            NextToken := tkUnknown;
            NextChar;
          END;
  END;
END;

{*****************************************}

FUNCTION Kopf:BOOLEAN;
BEGIN
  Kopf := FALSE;

  { Bezeichner }
  IF NOT GetNextToken THEN Exit;
  IF (NextToken<>tkId) THEN
  BEGIN
    ErrorNumber := ErrIdWanted;
    ErrorLine := TokenY;
    ErrorColumn := TokenX;
    ErrorDescribtion := 'Bezeichner erwartet';

    Exit;
  END;

  { Bezeichner gÅltig? }
  IF Keywords^.IsIn(NextExpression) THEN
  BEGIN
    ErrorNumber := ErrKeyId;
    ErrorLine := TokenY;
    ErrorColumn := TokenX;
    ErrorDescribtion := 'SchlÅsselwort als Bezeichner nicht erlaubt (' +
      NextExpression + ')';

    Exit;
  END;

  { Bezeichner eintragen }
  Procs^.Insert( New(PIdentifier, Init(NextExpression)));
  Dest^.WriteStr( NextExpression );

  { Semikolon }
  IF NOT GetNextToken THEN Exit;
  IF NextToken<>tkSemikolon THEN
  BEGIN
    ErrorNumber := ErrSemikolonWanted;
    ErrorLine := TokenY;
    ErrorColumn := TokenX;
    ErrorDescribtion := 'Semikolon (;) erwartet';

    Exit;
  END;

  IF NOT GetNextToken THEN Exit;

  Kopf := TRUE;
END;

FUNCTION Anweisung:BOOLEAN; FORWARD;
FUNCTION IfStruct:BOOLEAN; FORWARD;


FUNCTION Block:BOOLEAN;
BEGIN
  Block := FALSE;

  { BEGIN }
  IF (NextToken=tkId) AND (NextExpression='BEGIN') THEN
  BEGIN
    DebugInfo(Dest);

    { Anweisung; Anweisung; END }
    IF NOT GetNextToken THEN Exit;
    WHILE ((NextToken=tkId) AND (NextExpression<>'END')) OR
          (NextToken=tkSemikolon) DO
    BEGIN
      { öberflÅssige Semikolons }
      WHILE NextToken=tkSemikolon DO
        IF NOT GetNextToken THEN Exit;

      { Anweisung }
      IF (NextToken=tkId) AND (NextExpression<>'END') THEN
      BEGIN
        IF NOT Anweisung THEN Exit;
      END;

      { END oder ; }
      IF (NextToken=tkId) AND (NextExpression='END') THEN Continue;

      { Kein Semikolon }
      IF NextToken<>tkSemikolon THEN
      BEGIN
        ErrorNumber := ErrEndWanted;
        ErrorLine := TokenY;
        ErrorColumn := TokenX;
        ErrorDescribtion := 'Semikolon erwartet';

        Exit;
      END;

      IF NOT GetNextToken THEN Exit;
    END;

    DebugInfo(Dest);

    { Kein END }
    IF NextExpression<>'END' THEN
    BEGIN
      ErrorNumber := ErrEndWanted;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'END oder Befehl erwartet';

      Exit;
    END;
  END ELSE
  { Kein BEGIN }
  BEGIN
    ErrorNumber := ErrBeginWanted;
    ErrorLine := TokenY;
    ErrorColumn := TokenX;
    ErrorDescribtion := 'BEGIN erwartet';

    Exit;
  END;

  IF NOT GetNextToken THEN Exit;

  Block := TRUE;
END;

FUNCTION Bool:BOOLEAN; FORWARD;
FUNCTION BoolExpression:BOOLEAN; FORWARD;

FUNCTION Sensor:BOOLEAN;
BEGIN
  Sensor := FALSE;

  IF NextToken=tkLeft THEN
  BEGIN
    IF NOT GetNextToken THEN Exit;

    IF NOT Bool THEN Exit;

    IF NextToken<>tkRight THEN
    BEGIN
      ErrorNumber := ErrRightBracket;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'Rechte Klammer erwartet';
      Exit;
    END;

    IF NOT GetNextToken THEN Exit;
  END ELSE
  BEGIN
    IF (NextToken<>tkId) THEN
    BEGIN
      ErrorNumber := ErrFuncWanted;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'Funktion erwartet';
      Exit;
    END
    ELSE
      IF NextExpression='NOT' THEN
      BEGIN
        IF NOT GetNextToken THEN Exit;
        IF NOT Sensor THEN Exit;

        Dest^.SetAdresse( Dest^.ActPos - 2, Dest^.ActPos + 3 );

        Dest^.WriteByte(ocJMP);
        Dest^.WriteWord(0);
      END
      ELSE
        IF NOT Funcs^.IsIn(NextExpression) THEN
        BEGIN
          ErrorNumber := ErrUnkownFunc;
          ErrorLine := TokenY;
          ErrorColumn := TokenX;
          ErrorDescribtion := 'Unbekannte Funktion ('+NextExpression+')';
          Exit;
        END
        ELSE
          BEGIN
            Funcs^.Search(NextExpression)^.MakeCode( Dest );

            Dest^.WriteByte(ocJNC);
            Dest^.WriteWord(0);

            IF NOT GetNextToken THEN Exit;
          END;
  END;

  Sensor := TRUE;
END;

FUNCTION Und:BOOLEAN;
VAR Neg1, Neg2:Word;
    Pos:Word;
BEGIN
  Und := FALSE;

  IF (NextToken=tkId) AND (NextExpression='AND') THEN
  BEGIN
    Neg1 := Dest^.ActPos-2;

    IF NOT GetNextToken THEN Exit;
    IF NOT BoolExpression THEN Exit;
    Neg2 := Dest^.ActPos-2;

    Dest^.WriteByte(ocJmp);
    Dest^.WriteWord(0);
    Pos := Dest^.ActPos-2;

    Dest^.SetAdresse( Neg1, Dest^.ActPos );
    Dest^.SetAdresse( Neg2, Dest^.ActPos );

    Dest^.WriteByte(ocJmp);
    Dest^.WriteWord(0);

    Dest^.SetAdresse( Pos, Dest^.ActPos );
  END;

  Und := TRUE;
END;

FUNCTION Oder:BOOLEAN;
VAR Neg1, Neg2:Word;
    Pos1, Pos2:Word;
BEGIN
  Oder := FALSE;

  IF (NextToken=tkId) AND (NextExpression='OR') THEN
  BEGIN
    Neg1 := Dest^.ActPos-2;

    Dest^.WriteByte(ocJmp);
    Dest^.WriteWord(0);
    Pos1 := Dest^.ActPos-2;

    Dest^.SetAdresse( Neg1, Dest^.ActPos );

    IF NOT GetNextToken THEN Exit;
    IF NOT BoolExpression THEN Exit;
    Neg2 := Dest^.ActPos-2;

    Dest^.WriteByte(ocJmp);
    Dest^.WriteWord(0);
    Pos2 := Dest^.ActPos-2;

    Dest^.SetAdresse( Neg2, Dest^.ActPos );

    Dest^.WriteByte(ocJmp);
    Dest^.WriteWord(0);

    Dest^.SetAdresse( Pos1, Dest^.ActPos );
    Dest^.SetAdresse( Pos2, Dest^.ActPos );
  END;

  Oder := TRUE;
END;

FUNCTION BoolExpression:BOOLEAN;
BEGIN
  BoolExpression := FALSE;

  IF NOT Sensor THEN Exit;

  IF (NextToken=tkid) AND (NextExpression='AND') THEN
    IF NOT Und THEN Exit;

  BoolExpression := TRUE;
END;


FUNCTION Bool:BOOLEAN;
BEGIN
  Bool := FALSE;

  IF NOT BoolExpression THEN Exit;

  WHILE (NextToken=tkId) AND (NextExpression='OR') DO
    IF NOT Oder THEN Exit;

  Bool := TRUE;
END;

FUNCTION IfStruct:BOOLEAN;
VAR Pos:Word;
BEGIN
  IfStruct := FALSE;

  IF (NextToken=tkId) AND (NextExpression='IF') THEN
  BEGIN
    DebugInfo(Dest);

    IF NOT GetNextToken THEN Exit;

    IF NOT Bool THEN Exit;
    Pos := Dest^.ActPos - 2;

    IF (NextToken<>tkId) OR (NextExpression<>'THEN') THEN
    BEGIN
      ErrorNumber := ErrThenWanted;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'THEN erwartet';
      Exit;
    END ELSE
    BEGIN
      IF NOT GetNextToken THEN Exit;

      IF NOT Anweisung THEN Exit;

      IF (NextToken=tkId) OR (NextExpression='ELSE') THEN
      BEGIN
        Dest^.WriteByte(ocJMP);
        Dest^.WriteWord(0);

        Dest^.SetAdresse( Pos, Dest^.ActPos );

        Pos := Dest^.ActPos;

        IF NOT GetNextToken THEN Exit;
        IF NOT Anweisung THEN Exit;

        Dest^.SetAdresse( Pos-2, Dest^.ActPos );
      END ELSE Dest^.SetAdresse( Pos, Dest^.ActPos );

      IfStruct := TRUE;
    END;
  END;
END;

FUNCTION WhileStruct:BOOLEAN;
VAR Pos:Word;
    Anfang:Word;
BEGIN
  WhileStruct := FALSE;

  IF (NextToken=tkId) AND (NextExpression='WHILE') THEN
  BEGIN
    IF NOT GetNextToken THEN Exit;

    Anfang := Dest^.ActPos;
    DebugInfo(Dest);
    IF NOT Bool THEN Exit;
    Pos := Dest^.ActPos;

    IF (NextToken<>tkId) OR (NextExpression<>'DO') THEN
    BEGIN
      ErrorNumber := ErrDoWanted;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'DO erwartet';
      Exit;
    END ELSE
    BEGIN
      IF NOT GetNextToken THEN Exit;
      IF NOT Anweisung THEN Exit;

      Dest^.WriteByte(ocJmp);
      Dest^.WriteWord( Anfang );

      Dest^.SetAdresse( Pos-2, Dest^.ActPos );

      WhileStruct := TRUE;
    END;
  END;
END;

FUNCTION RepeatStruct:BOOLEAN;
VAR Pos:Word;
    Anfang:Word;
BEGIN
  RepeatStruct := FALSE;

  Anfang := Dest^.ActPos;

  IF (NextToken=tkId) AND (NextExpression='REPEAT') THEN
  BEGIN
    { Anweisung; Anweisung; UNTIL }
    DebugInfo(Dest);

    IF NOT GetNextToken THEN Exit;

    WHILE ((NextToken=tkId) AND (NextExpression<>'UNTIL')) OR
          (NextToken=tkSemikolon) DO
    BEGIN
      { öberflÅssige Semikolons }
      WHILE NextToken=tkSemikolon DO
        IF NOT GetNextToken THEN Exit;

      { Anweisung }
      IF (NextToken=tkId) AND (NextExpression<>'UNTIL') THEN
      BEGIN
        IF NOT Anweisung THEN Exit;
      END;

      { UNTIL oder ; }
      IF (NextToken=tkId) AND (NextExpression='UNTIL') THEN Continue;

      { Kein Semikolon }
      IF NextToken<>tkSemikolon THEN
      BEGIN
        ErrorNumber := ErrSemikolonWanted;
        ErrorLine := TokenY;
        ErrorColumn := TokenX;
        ErrorDescribtion := 'Semikolon erwartet';

        Exit;
      END;

      IF NOT GetNextToken THEN Exit;
    END;

    IF (NextToken<>tkId) OR (NextExpression<>'UNTIL') THEN
    BEGIN
      ErrorNumber := ErrUntilWanted;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'UNTIL erwartet';
      Exit;
    END ELSE
    BEGIN
      DebugInfo(Dest);
      IF NOT GetNextToken THEN Exit;

      IF NOT Bool THEN Exit;

      Dest^.SetAdresse( Dest^.ActPos-2, Anfang );

      RepeatStruct := TRUE;
    END;
  END;
END;

FUNCTION Quit:BOOLEAN;
BEGIN
  Quit := FALSE;

  DebugInfo(Dest);
  Dest^.WriteByte( ocBrk );
  IF NOT GetNextToken THEN Exit;

  Quit := TRUE;
END;

FUNCTION Anweisung:BOOLEAN;
VAR Command:PIdentifier;
BEGIN
  Anweisung := FALSE;

  { Anweisung }
  IF (NextToken<>tkId) THEN
  BEGIN
    ErrorNumber := ErrEndWanted;
    ErrorLine := TokenY;
    ErrorColumn := TokenX;
    ErrorDescribtion := 'Befehl erwartet';
    Exit;
  END ELSE
  BEGIN
     { Block? }
     IF NextExpression='BEGIN' THEN
     BEGIN
       IF NOT Block THEN Exit;
     END
     ELSE
       { IF-Konstrukt? }
       IF NextExpression='IF' THEN
       BEGIN
         IF NOT IfStruct THEN Exit;
       END
       ELSE
       IF NextExpression='WHILE' THEN
       BEGIN
         IF NOT WhileStruct THEN Exit;
       END
       ELSE
       IF NextExpression='REPEAT' THEN
       BEGIN
         IF NOT RepeatStruct THEN Exit;
       END
       ELSE
       IF NextExpression='QUIT' THEN
       BEGIN
         IF NOT Quit THEN Exit;
       END
       ELSE
        BEGIN
          { gÅltiger Anweisung }
          Command := Procs^.Search(NextExpression);
          IF Command=NIL THEN
          {$ifdef CallableFuncs}
          BEGIN
            Command := Funcs^.Search(NextExpression);
            IF Command=NIL THEN
          {$endif}
            BEGIN
              ErrorNumber := ErrUnkownProc;
              ErrorLine := TokenY;
              ErrorColumn := TokenX;
              ErrorDescribtion := 'Unbekannter Befehl ('+NextExpression+')';
              Exit;
            END;
          {$ifdef CallableFuncs}
          END;
          {$endif}

          DebugInfo(Dest);
          Command^.MakeCode( Dest );

          IF NOT GetNextToken THEN Exit;
        END;
  END;

  Anweisung := TRUE;
END;

FUNCTION ProcDef:BOOLEAN;
BEGIN
  ProcDef := FALSE;

  { Bezeichner? }
  IF NOT GetNextToken THEN Exit;
  IF (NextToken<>tkId) THEN
  BEGIN
    ErrorNumber := ErrIdWanted;
    ErrorLine := TokenY;
    ErrorColumn := TokenX;
    ErrorDescribtion := 'Bezeichner erwartet';
    Exit;
  END ELSE
  BEGIN
    { Doppelter Bezeichner? }
    IF Procs^.IsIn(NextExpression) THEN
    BEGIN
      ErrorNumber := ErrUsedId;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'Doppelter Bezeichner ('+NextExpression+')';
      Exit;
    END;

    { SchlÅsselwort? }
    IF Keywords^.IsIn(NextExpression) THEN
    BEGIN
      ErrorNumber := ErrKeyId;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'SchlÅsselwort als Bezeichner nicht erlaubt ('+
        NextExpression+')';

      Exit;
    END;

    { Procedure registrieren }
    Procs^.Insert( New(PProcedure, Init(NextExpression, Dest^.ActPos)));

    DebugInfo(Dest);

    { Semikolon }
    IF NOT GetNextToken THEN Exit;
    IF NextToken<>tkSemikolon THEN
    BEGIN
      ErrorNumber := ErrSemikolonWanted;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'Semikolon erwartet';
      Exit;
    END;

    { Block }
    IF NOT GetNextToken THEN Exit;
    IF NOT Block THEN Exit;

    { Return Eintragen }
    Dest^.WriteByte( ocRET );
  END;

  ProcDef := TRUE;
END;

{$ifdef UserFuncs}
FUNCTION FuncBlock(Func:STRING):BOOLEAN;
BEGIN
  FuncBlock := FALSE;

  { BEGIN }
  IF (NextToken=tkId) AND (NextExpression='BEGIN') THEN
  BEGIN

    { Anweisung; Anweisung; END }
    IF NOT GetNextToken THEN Exit;
    WHILE ((NextToken=tkId) AND (NextExpression<>'END')) OR
          (NextToken=tkSemikolon) DO
    BEGIN
      { öberflÅssige Semikolons }
      WHILE NextToken=tkSemikolon DO
        IF NOT GetNextToken THEN Exit;

      { Anweisung }
      IF (NextToken=tkId) AND (NextExpression<>'END') THEN
      BEGIN
        IF NextExpression=Func THEN
        BEGIN
        END ELSE
          IF NOT Anweisung THEN Exit;
      END;

      { END oder ; }
      IF (NextToken=tkId) AND (NextExpression='END') THEN Continue;

      { Kein Semikolon }
      IF NextToken<>tkSemikolon THEN
      BEGIN
        ErrorNumber := ErrEndWanted;
        ErrorLine := TokenY;
        ErrorColumn := TokenX;
        ErrorDescribtion := 'Semikolon erwartet';

        Exit;
      END;

      IF NOT GetNextToken THEN Exit;
    END;

    { Kein END }
    IF NextExpression<>'END' THEN
    BEGIN
      ErrorNumber := ErrEndWanted;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'END oder Befehl erwartet';

      Exit;
    END;
  END ELSE
  { Kein BEGIN }
  BEGIN
    ErrorNumber := ErrBeginWanted;
    ErrorLine := TokenY;
    ErrorColumn := TokenX;
    ErrorDescribtion := 'BEGIN erwartet';

    Exit;
  END;

  IF NOT GetNextToken THEN Exit;

  FuncBlock := TRUE;
END;

FUNCTION FuncDef:BOOLEAN;
VAR Value:BOOLEAN;
    Name:STRING;
BEGIN
  FuncDef := FALSE;

  {Bisher noch kein RÅckgabewert}
  Value := FALSE;

  { Bezeichner? }
  IF NOT GetNextToken THEN Exit;
  IF (NextToken<>tkId) THEN
  BEGIN
    ErrorNumber := ErrIdWanted;
    ErrorLine := TokenY;
    ErrorColumn := TokenX;
    ErrorDescribtion := 'Bezeichner erwartet';
    Exit;
  END ELSE
  BEGIN
    Name := NextExpression;

    { Doppelter Bezeichner? }
    IF Funcs^.IsIn(Name) OR Procs^.IsIn(Name) THEN
    BEGIN
      ErrorNumber := ErrUsedId;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'Doppelter Bezeichner ('+Name+')';
      Exit;
    END;

    { SchlÅsselwort? }
    IF Keywords^.IsIn(Name) THEN
    BEGIN
      ErrorNumber := ErrKeyId;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'SchlÅsselwort als Bezeichner nicht erlaubt ('+
        Name+')';

      Exit;
    END;

    { Function registrieren }
    Funcs^.Insert( New(PUserFunc, Init(Name, Dest^.ActPos)));

    { Semikolon }
    IF NOT GetNextToken THEN Exit;
    IF NextToken<>tkSemikolon THEN
    BEGIN
      ErrorNumber := ErrSemikolonWanted;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'Semikolon erwartet';
      Exit;
    END;

    { Block }
    IF NOT GetNextToken THEN Exit;
    IF NOT FuncBlock(Name) THEN Exit;

    { Return Eintragen }
    Dest^.WriteByte( ocRET );
  END;

  FuncDef := TRUE;
END;
{$endif}


FUNCTION Programm:BOOLEAN;
VAR Start:Word;
BEGIN
  NextChar;
  Programm := FALSE;

  { Programmkopf? }
  IF NOT GetNextToken THEN Exit;
  IF (NextToken=tkId) AND (NextExpression='PROGRAM') THEN
    IF NOT Kopf THEN Exit;

  { Proceduren? }
  WHILE (NextToken=tkId) AND
        ( (NextExpression='PROCEDURE')
          {$ifdef UserFuncs} OR (NextExpression='FUNCTION') {$endif}
        ) DO
  BEGIN
    {$ifdef UserFuncs}
    IF NextExpression='FUNCTION' THEN
    BEGIN
      IF NOT FuncDef THEN Exit;
    END ELSE
    {$endif}
      IF NOT ProcDef THEN Exit;

    IF NextToken<>tkSemikolon THEN
    BEGIN
      ErrorNumber := ErrSemikolonWanted;
      ErrorLine := TokenY;
      ErrorColumn := TokenX;
      ErrorDescribtion := 'Semikolon erwartet';
      Exit;
    END;
    IF NOT GetNextToken THEN Exit;
  END;

  { Start = hinter den Prozeduren }
  Start := Dest^.ActPos;

  { Hauptprogramm }
  IF NOT Block THEN Exit;

  { Endpunkt }
  IF (NextToken<>tkPoint) THEN
  BEGIN
    ErrorNumber := ErrPointWanted;
    ErrorLine := TokenY;
    ErrorColumn := TokenX;
    ErrorDescribtion := 'Punkt erwartet';
  END;

  { Break }
  Dest^.WriteByte(ocBRK);

  { Start eintragen }
  Dest^.SetStart(Start);

  Programm := TRUE;
END;

BEGIN
  New(Keywords, Init);

  WITH Keywords^ DO
  BEGIN
    Insert( New(PIdentifier, Init('AND')));
    Insert( New(PIdentifier, Init('BEGIN')));
    Insert( New(PIdentifier, Init('DO')));
    Insert( New(PIdentifier, Init('ELSE')));
    Insert( New(PIdentifier, Init('END')));
    Insert( New(PIdentifier, Init('IF')));
    Insert( New(PIdentifier, Init('NOT')));
    Insert( New(PIdentifier, Init('OR')));
    Insert( New(PIdentifier, Init('PROCEDURE')));
    {$ifdef UserFuncs}Insert( New(PIdentifier, Init('FUNCTION')));{$endif}
    Insert( New(PIdentifier, Init('PROGRAM')));
    Insert( New(PIdentifier, Init('REPEAT')));
    Insert( New(PIdentifier, Init('THEN')));
    Insert( New(PIdentifier, Init('UNTIL')));
    Insert( New(PIdentifier, Init('WHILE')));
    Insert( New(PIdentifier, Init('QUIT')));
  END;
END.