UNIT Config;

INTERFACE

FUNCTION LoadConfig(Name:String):BOOLEAN;
FUNCTION SaveConfig(Name:String):BOOLEAN;

FUNCTION GetNumOption(S:String; Default:Integer):INTEGER;
FUNCTION GetStrOption(S:String; Default:String):String;

IMPLEMENTATION
USES Dos, Objects;

TYPE POption=^TOption;
     TOption=OBJECT(TObject)
               CONSTRUCTOR Init(aName, aValue:String);
               FUNCTION NumValue:Integer; VIRTUAL;
               FUNCTION StrValue:String; VIRTUAL;

              PRIVATE
               Name:String;
               Value:String;
               Num:Integer;
             END;

     POptionsCollection=^TOptionsCollection;
     TOptionsCollection=OBJECT(TCollection)
                         CONSTRUCTOR Init;
                         DESTRUCTOR Done; VIRTUAL;

                         PROCEDURE Add(Opt:POption);
                         PROCEDURE Remove(S:String);
                         FUNCTION IsIn(S:String):BOOLEAN;
                         FUNCTION Search(S:String):POption;
                       END;

{*****************************************}

CONSTRUCTOR TOption.Init(aName, aValue:String);
VAR err:Integer;
BEGIN
  INHERITED Init;

  Name := aName;
  Value := aValue;

  val(Value, Num, Err);
  IF Err<>0 THEN Err:=0;
END;

FUNCTION TOption.NumValue:Integer;
BEGIN
  NumValue := Num;
END;

FUNCTION TOption.StrValue:String;
BEGIN
  StrValue := Value;
END;

{*****************************************}

CONSTRUCTOR TOptionsCollection.Init;
BEGIN
  INHERITED Init(16, 8);
END;

DESTRUCTOR TOptionsCollection.Done;
BEGIN
  FreeAll;
  INHERITED Done;
END;

PROCEDURE TOptionsCollection.Add(Opt:POption);
BEGIN
  Insert(Opt);
END;

PROCEDURE TOptionsCollection.Remove(S:String);
VAR o:POption;
BEGIN
  o := Search(S);
  IF o<>NIL THEN Delete(o);
END;

FUNCTION TOptionsCollection.Search(S:String):POption;

  FUNCTION Matches(Item: Pointer): Boolean; FAR;
  BEGIN
    Matches:=POption(Item)^.Name = s;
  END;

BEGIN
  Search := FirstThat( @Matches );
END;


FUNCTION TOptionsCollection.IsIn(S:String):BOOLEAN;
BEGIN
  IsIn := Search(S) <> NIL;
END;

{*****************************************}

VAR Options:POptionsCollection;

{*****************************************}

FUNCTION LoadConfig(Name:String):BOOLEAN;
VAR f:Text;
    Line:String;
    P:Byte;
    n,v:STRING;
    Path: DirStr;
    FName: NameStr;
    FExt: ExtStr;
BEGIN
  IF Options<>NIL THEN Dispose(Options, Done);

  New(Options, Init);

  {$i-}
  Assign(f, Name);
  Reset(f);

  IF IOResult<>0 THEN
  BEGIN
    FSplit(ParamStr(0), Path, FName, FExt);

    Assign(f, Path+Name);
    Reset(f);
  END;

  WHILE (NOT EoF(f)) AND (IOResult=0) DO
  BEGIN
    Readln(f, Line);
    IF (Line<>'') AND (Line[1]<>';') AND (Line[1]<>' ') THEN
    BEGIN
      FOR p:=1 TO Length(Line) DO Line[p]:=UpCase(Line[p]);

      p := Pos('=', Line);
      IF p<>0 THEN
      BEGIN
        n := Copy(Line,1,p-1);
        v := Copy(Line,p+1,Length(Line)-p);

        {Writeln('''', n,''' = ''',v,'''');}

        Options^.Remove('n');
        Options^.Add( New(POption, Init(n, v)) );
      END;
    END;
  END;

  Close(f);

  LoadConfig := IOResult=0;
  {$i+}
END;

FUNCTION SaveConfig(Name:String):BOOLEAN;
VAR f:Text;
BEGIN
END;

FUNCTION GetNumOption(S:String; Default:Integer):INTEGER;
VAR o:POption;
BEGIN
  GetNumOption := Default;

  IF Options=NIL THEN Exit;

  o := Options^.Search(S);
  IF o<>NIL THEN
    GetNumOption := o^.NumValue
END;

FUNCTION GetStrOption(S:String; Default:String):String;
VAR o:POption;
BEGIN
  GetStrOption := Default;

  IF Options=NIL THEN Exit;

  o := Options^.Search(S);
  IF o<>NIL THEN
    GetStrOption := o^.StrValue
END;

BEGIN
  Options := NIL;
END.