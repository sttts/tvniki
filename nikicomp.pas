UNIT NikiComp;

INTERFACE
USES App, Objects, Views, Menus, Drivers, Dialogs, StdDlg, MsgBox, TvEnh;

TYPE TJustify=(jfLeft, jfRight);

     POutputLine=^TOutputLine;
     TOutputLine=OBJECT(TStaticText)
                   CONSTRUCTOR Init(VAR R:TRect; AJustify:TJustify);
                   PROCEDURE SetText(s:String);
                   PROCEDURE SetValue(v:Integer);

                  PRIVATE
                   Justify:TJustify;
                 END;


     PCompileDialog=^TCompileDialog;
     TCompileDialog=OBJECT(TDialog)
                      CONSTRUCTOR Init(ADatei:String);
                      PROCEDURE HandleEvent(VAR Event:TEvent); VIRTUAL;
                      PROCEDURE SetupWindow;

                      PROCEDURE Idle; VIRTUAL;

                      PROCEDURE Compile(ADatei:String);

                      PROCEDURE SetProgramm(ADatei:String);
                      PROCEDURE SetDatei(ADatei:String);

                      PROCEDURE CompileComplete;
                     PRIVATE
                      Programm:PParamLine;
                      Datei:PParamLine;
                      Zeilen:PParamLine;
                      GesamtZeilen:PParamLine;

                      nGesamtZeilen:Longint;
                      nZeilen : Longint;
                      strDatei : String;
                      strProgramm: String;
                      { Pointers must be fields so SetData's @Rec remains valid }
                      pDatei: PString;
                      pProgramm: PString;


                      OK:PButton;
                      Abbrechen:PButton;

                      NextFile:String;
                    END;

IMPLEMENTATION
USES Compiler, Dos, Config;

CONSTRUCTOR TOutputLine.Init(VAR R:TRect; AJustify:TJustify);
BEGIN
  INHERITED Init(R, '');
  Justify := AJustify;
END;

PROCEDURE TOutputLine.SetText(s:String);
VAR Format:String[5];
    Result:String;
BEGIN
  IF Text<>NIL THEN DisposeStr(Text);

{  Str(Size.x, Format);
  Format := '%' + Format + 's';
  Format := '%8s';
  s[length(s)+1]:=#0;
  FormatStr(Result, Format, s);}
  Text := NewStr(s);
END;

PROCEDURE TOutputLine.SetValue(v:Integer);
VAR Format:String[4];
    Result:String;
BEGIN
  IF Text<>NIL THEN DisposeStr(Text);

{  Str(Size.x, Format);
  Format := '%' + Format + 'i';
  FormatStr(Result, Format, v);}
  Str(v, Result);
  Text := NewStr(Result);
END;

{**********************************************************}

CONSTRUCTOR TCompileDialog.Init(ADatei:String);
VAR R:TRect;
BEGIN
  R.Assign(18, 5, 62, 16);
  INHERITED Init(R, 'Compilieren');

  SetupWindow;

  SetProgramm('');
  SetDatei('');

  NextFile := ADatei;
  ErrorNumber := 0;

  nGesamtZeilen := 0;
  nZeilen := 0;
END;

PROCEDURE TCompileDialog.SetupWindow;
VAR R:TRect;
BEGIN
  R.Assign(3, 2, 19, 3);
  Insert( New(PStaticText, Init(R, 'Programm      :')));
  R.Assign(19, 2, 41, 3);
  Programm := New(PParamLine, Init(R, '%22s', 1));
  Insert( Programm );

  R.Assign(3, 3, 19, 4);
  Insert( New(PStaticText, Init(R, 'Aktuelle Datei:')));
  R.Assign(19, 3, 41, 4);
  Datei := New(PParamLine, Init(R, '%22s', 1));
  Insert( Datei );

  R.Assign(3, 5, 19, 6);
  Insert( New(PStaticText, Init(R, 'Zeilen        :')));
  R.Assign(19, 5, 25, 6);
  Zeilen := New(PParamLine, Init(R, '%6d', 1));
  Zeilen^.SetData(nZeilen);
  Insert( Zeilen );

  R.Assign(3, 6, 19, 7);
  Insert( New(PStaticText, Init(R, 'Gesamte Zeilen:')));
  R.Assign(19, 6, 25, 7);
  GesamtZeilen := New(PParamLine, Init(R, '%6d', 1));
  GesamtZeilen^.SetData(nGesamtZeilen);
  Insert( GesamtZeilen );


  R.Assign(15, 8, 28, 10);
  Abbrechen := New(PButton, Init(R, '~A~bbrechen', cmCancel, bfDefault));
  Insert( Abbrechen );

  R.Assign(15, 8, 28, 10);
  OK := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
  Insert( OK );
  OK^.Hide;
END;

PROCEDURE TCompileDialog.CompileComplete;
BEGIN
  Abbrechen^.Hide;
  Ok^.Show;
END;

PROCEDURE TCompileDialog.SetProgramm(ADatei:String);
BEGIN
  strProgramm := ADatei;
  pProgramm := @strProgramm;
  Programm^.SetData(pProgramm);
END;

PROCEDURE TCompileDialog.SetDatei(ADatei:String);
BEGIN
  strDatei := ADatei;
  pDatei := @strDatei;
  Datei^.SetData(pDatei);
END;

TYPE TErrorInfo = RECORD
                    Number : Longint;
                    Line : Longint;
                    Datei : PString;
                    Desc : PString;
                  END;

PROCEDURE TCompileDialog.Compile(ADatei:String);
VAR Quelle, Ziel:String;
    Dir:DirStr;
    Name:NameStr;
    Ext:ExtStr;
BEGIN
  Quelle := ADatei;

  SetDatei(Quelle);

  FSplit(Quelle, Dir, Name, Ext);
  Ziel := Dir+Name+'.NIK';

  SetProgramm(Ziel);

  Compiler.Compile(Quelle, Ziel, GetNumOption('DEBUG', 1)=1 );
  IF ErrorNumber=0 THEN CompileComplete ELSE EndModal(cmCancel);
END;

PROCEDURE TCompileDialog.HandleEvent(VAR Event:TEvent);
BEGIN
  CASE Event.What OF
    evNothing : Idle;
{    evCommand : CASE Event.Command OF
                END;}
  END;
  INHERITED HandleEvent(Event);
END;

PROCEDURE TCompileDialog.Idle;
BEGIN
  IF (NextFile<>'') AND (ErrorNumber=0) THEN
  BEGIN
    Compile(NextFile);
    NextFile := '';
    Inc(nGesamtZeilen, Lines);
    Zeilen^.SetData(Lines);
    GesamtZeilen^.SetData(nGesamtZeilen);
  END;
END;

END.