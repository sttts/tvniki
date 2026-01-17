UNIT NikiFeld;
INTERFACE
USES Objects, Views, Drivers, Dialogs, TvEnh, Intp, NikiInfo, Editors, NikiFlWn;

CONST CFeldColor=#$0F#$07#$0A;
      cmTextEnd = 511;  { Editor command from original TV Editors unit }
      CFeldBlackWhite=#$0F#$07#15;
      CFeldMonochrome=#$0F#$07#10;

TYPE PRobot=^TRobot;
     PFeldEditor=^TFeldEditor;

     TRichtung=(rDummy, rLinks, rOben, rRechts, rUnten);

     TRobot=OBJECT(TObject)
              x,y:Integer;
              Vorrat:Integer;

              Feld:PFeldEditor;

              FarbeAlt:Byte;
              ZeichenAlt:Char;

              Richtung:TRichtung;

              Visible:BOOLEAN;

              CONSTRUCTOR Init(ax,ay:Integer;ARichtung:TRichtung;AFeld:PFeldEditor);
              DESTRUCTOR Done; VIRTUAL;

              PROCEDURE Store(VAR S:TStream); VIRTUAL;
              CONSTRUCTOR Load(VAR S:TStream; AFeld:PFeldEditor);

              FUNCTION VornFrei:BOOLEAN;
              FUNCTION HintenFrei:BOOLEAN;
              FUNCTION LinksFrei:BOOLEAN;
              FUNCTION RechtsFrei:BOOLEAN;
              FUNCTION PlatzBelegt:BOOLEAN;
              FUNCTION hatVorrat:BOOLEAN;

              FUNCTION Go(Walls:BOOLEAN):BOOLEAN; VIRTUAL;
              PROCEDURE Left; VIRTUAL;
              FUNCTION Take:BOOLEAN; VIRTUAL;
              FUNCTION Put:BOOLEAN; VIRTUAL;

              PROCEDURE Draw; VIRTUAL;
              PROCEDURE RestoreBackground; VIRTUAL;
              PROCEDURE SaveBackground; VIRTUAL;

              PROCEDURE Move(ax,ay:Integer);
              PROCEDURE MoveTo(ax,ay:Integer);

              PROCEDURE Turn(ARichtung:Integer);
              PROCEDURE TurnTo(ARichtung:TRichtung);

              PROCEDURE VPos(VAR ax,ay:Integer);

              PROCEDURE Hide;
              PROCEDURE Show;
             PRIVATE
              dx, dy:Integer;
            END;

     PProgInterpreter = ^TProgInterpreter;

     TFeldEditor=OBJECT(TFeld)
             CONSTRUCTOR Init(R:TRect; ADatei:String;
                 AHScrollBar, AVScrollBar:PScrollBar);
             DESTRUCTOR Done; VIRTUAL;

             PROCEDURE WriteFile(VAR S:TStream); VIRTUAL;
             PROCEDURE ReadFile(VAR S:TStream); VIRTUAL;

             PROCEDURE HandleEvent(VAR Event:TEvent); VIRTUAL;
             PROCEDURE Idle; VIRTUAL;
             PROCEDURE Draw; VIRTUAL;

             PROCEDURE MoveCursor(x,y:Integer);
             PROCEDURE MoveCursorTo(x,y:Integer);
             PROCEDURE TrackCursor; VIRTUAL;
             PROCEDURE UpdateCursor;

             FUNCTION IsWall(x,y:Integer):BOOLEAN;
             PROCEDURE SetWall(x,y:Integer; Mode:BOOLEAN);
             PROCEDURE ChangeVorrat(x,y:Integer; Mode:BOOLEAN);
             PROCEDURE MoveNikiTo(x,y:Integer);
             PROCEDURE UpdateCorner(x,y:Integer);

             PROCEDURE UpdateInfoWindow;
             PROCEDURE ShowError;
             PROCEDURE ShowLine;
             PROCEDURE Finished;
             PROCEDURE ResetMode; VIRTUAL;

             PROCEDURE Edit;
             PROCEDURE Run(ADatei:STRING; Debug:BOOLEAN);
             PROCEDURE StopRun;

             PROCEDURE TeachIn;
             PROCEDURE StopTeachIn;
             PROCEDURE RecordAction(Event:TEvent);
             PROCEDURE TeachLine(s:String);

             PROCEDURE Vorrat;
             PROCEDURE SetSpeed;
             FUNCTION GetVorrat:Word;

             PROCEDURE Print;
            PRIVATE
             Prog:PProgInterpreter;
             Niki:PRobot;
             Pos:TPoint;
             Speed:Longint;
             Paused:Boolean;
             TeachInBuf:PFileEditor;
             MyTimer:Integer;
             ExecCommand:BOOLEAN;
           END;

     PFeldWindow=^TFeldWindow;
     TFeldWindow=OBJECT(TWindow)
                   CONSTRUCTOR Init(R:TRect; ADatei:STRING);
                   DESTRUCTOR Done; VIRTUAL;

                   FUNCTION CanClose:BOOLEAN;

                   PROCEDURE HandleEvent(VAR Event:TEvent); VIRTUAL;

                   PROCEDURE Idle; VIRTUAL;

                   PROCEDURE SizeLimits(var Min, Max: TPoint); VIRTUAL;
                   FUNCTION GetPalette: PPalette; VIRTUAL;

                   PROCEDURE UpdateTitle;
                   FUNCTION GetTitle(MaxLen: LongInt): ShortString;

                   PROCEDURE Run(ADatei:STRING; Debug:BOOLEAN);
                  PRIVATE
                   Feld : PFeldEditor;
                 END;

     TProgInterpreter = OBJECT(TInterpreter)
                          CONSTRUCTOR Init(ADatei:STRING; ARobot:PRobot);

                          PROCEDURE Debug(p:Word); VIRTUAL;

                          FUNCTION Vor:BOOLEAN; VIRTUAL;
                          PROCEDURE Links; VIRTUAL;
                          FUNCTION Nimm_Auf:BOOLEAN; VIRTUAL;
                          FUNCTION Leg_Ab:BOOLEAN; VIRTUAL;

                          FUNCTION Vorne_Frei:BOOLEAN; VIRTUAL;
                          FUNCTION Links_Frei:BOOLEAN; VIRTUAL;
                          FUNCTION Rechts_Frei:BOOLEAN; VIRTUAL;
                          FUNCTION hat_Vorrat:BOOLEAN; VIRTUAL;
                          FUNCTION Platz_Belegt:BOOLEAN; VIRTUAL;
                         PRIVATE
                          Robot:PRobot;
                          ActLine:Integer;
                        END;

VAR FeldWindow:PFeldWindow;

IMPLEMENTATION
USES Dos, Config, NikiCnst, MsgBox, App, StdDlg, Timer, NikiGlob, NikiPrnt;


{******************************************************
 *                                                    *
 * Implementierung des Interpreters                   *
 *                                                    *
 ******************************************************}

CONSTRUCTOR TProgInterpreter.Init(ADatei:STRING; ARobot:PRobot);
BEGIN
  INHERITED Init(ADatei);
  Robot := ARobot;
  ActLine := -1;
END;

PROCEDURE TProgInterpreter.Debug(p:Word);
BEGIN
  INHERITED Debug(p);
  ActLine := p;
END;

FUNCTION TProgInterpreter.Vor:BOOLEAN;
BEGIN
  IF (Status=stOk) AND (Robot<>NIL) THEN Vor := Robot^.Go(TRUE);
END;

PROCEDURE TProgInterpreter.Links;
BEGIN
  IF (Status=stOk) AND (Robot<>NIL) THEN
  BEGIN
    Robot^.Left;
  END;
END;

FUNCTION TProgInterpreter.Nimm_Auf:BOOLEAN;
BEGIN
  IF (Status=stOk) AND (Robot<>NIL) THEN
    Nimm_Auf := Robot^.Take;
END;

FUNCTION TProgInterpreter.Leg_Ab:BOOLEAN;
BEGIN
  IF (Status=stOk) AND (Robot<>NIL) THEN
    Leg_Ab :=  Robot^.Put;
END;

FUNCTION TProgInterpreter.Vorne_Frei:BOOLEAN;
BEGIN
  Vorne_Frei := Robot^.VornFrei;
END;

FUNCTION TProgInterpreter.Links_Frei:BOOLEAN;
BEGIN
  Links_Frei := Robot^.LinksFrei;
END;

FUNCTION TProgInterpreter.Rechts_Frei:BOOLEAN;
BEGIN
  Rechts_Frei := Robot^.RechtsFrei;
END;

FUNCTION TProgInterpreter.Platz_Belegt:BOOLEAN;
BEGIN
  Platz_Belegt := Robot^.PlatzBelegt;
END;

FUNCTION TProgInterpreter.hat_Vorrat:BOOLEAN;
BEGIN
  hat_Vorrat := Robot^.hatVorrat;
END;


{******************************************************
 *                                                    *
 * Implementierung vom Robotor                        *
 *                                                    *
 ******************************************************}

CONST {Robots:String='<^>v';}
      Robots:String=#17#30#16#31;

      cRobot = 14 + 0*16;

CONSTRUCTOR TRobot.Init(ax,ay:Integer;ARichtung:TRichtung;AFeld:PFeldEditor);
BEGIN
  INHERITED Init;

  MoveTo(ax, ay);
  TurnTo(ARichtung);

  Vorrat := 0;

  Feld := AFeld;

  Show;
END;

DESTRUCTOR TRobot.Done;
BEGIN
  Hide;
  INHERITED Done;
END;

PROCEDURE TRobot.Store(VAR S:TStream);
BEGIN
  S.Write(x, Sizeof(x));
  S.Write(y, Sizeof(y));
  S.Write(Vorrat, Sizeof(Vorrat));
  S.Write(Richtung, Sizeof(Richtung));
END;

CONSTRUCTOR TRobot.Load(VAR S:TStream; AFeld:PFeldEditor);
BEGIN
  Feld := AFeld;

  S.Read(x, Sizeof(x));
  S.Read(y, Sizeof(y));
  S.Read(Vorrat, Sizeof(Vorrat));
  S.Read(Richtung, Sizeof(Richtung));

  Turn(0);

  Visible := FALSE;
  Show;
END;

PROCEDURE TRobot.Draw;
BEGIN
  IF Visible AND (Feld<>NIL) THEN
  BEGIN
    Feld^.Feld[y,x].z := Robots[byte(Richtung)];
    Feld^.Feld[y,x].f := cRobot;
  END;
END;

PROCEDURE TRobot.RestoreBackground;
BEGIN
  IF (Feld<>NIL) AND Visible THEN
  BEGIN
    Feld^.Feld[y,x].z := ZeichenAlt;
    Feld^.Feld[y,x].f := FarbeAlt;
  END;
END;

PROCEDURE TRobot.SaveBackground;
BEGIN
  IF (Feld<>NIL) AND Visible THEN
  BEGIN
    ZeichenAlt := Feld^.Feld[y,x].z;
    FarbeAlt := Feld^.Feld[y,x].f;
  END;
END;

FUNCTION TRobot.VornFrei:BOOLEAN;
BEGIN
  IF (Feld<>NIL) THEN
    Vornfrei := Feld^.Feld[y+dy*1, x+dx*2].z = Walls[wNo]
  ELSE VornFrei:=FALSE;
END;

FUNCTION TRobot.HintenFrei:BOOLEAN;
BEGIN
  IF (Feld<>NIL) THEN
    Hintenfrei := Feld^.Feld[y-dy*1, x-dx*2].z = Walls[wNo]
  ELSE HintenFrei:=FALSE;
END;

FUNCTION TRobot.LinksFrei:BOOLEAN;
BEGIN
  IF (Feld<>NIL) THEN
    Linksfrei := Feld^.Feld[y-dx*1, x+dy*2].z = Walls[wNo]
  ELSE LinksFrei:=FALSE;
END;

FUNCTIOn TRobot.RechtsFrei:BOOLEAN;
BEGIN
  IF (Feld<>NIL) THEN
    Rechtsfrei := Feld^.Feld[y+dx*1, x-dy*2].z = Walls[wNo]
  ELSE RechtsFrei:=FALSE;
END;

FUNCTION TRobot.PlatzBelegt:BOOLEAN;
BEGIN
  CASE ZeichenAlt OF
    '1'..'9': PlatzBelegt := TRUE;
   ELSE PlatzBelegt := FALSE;
  END;
END;

FUNCTION TRobot.hatVorrat:BOOLEAN;
BEGIN
  hatVorrat := Vorrat>0;
END;

FUNCTION TRobot.Go(Walls:BOOLEAN):BOOLEAN;
BEGIN
  IF Walls AND VornFrei THEN
  BEGIN
    RestoreBackground;
    CASE Richtung OF
      rLinks : Move(-4, 0);
      rRechts: Move( 4, 0);
      rOben  : Move( 0,-2);
      rUnten : Move( 0, 2);
    END;
    SaveBackground;
    Draw;
    Go := TRUE;
  END ELSE Go := FALSE;
END;

PROCEDURE TRobot.Left;
BEGIN
  Turn(-1);
  Draw;
END;

FUNCTION TRobot.Take:BOOLEAN;
BEGIN
  Take := TRUE;

  CASE ZeichenAlt OF
    '2'..'9':BEGIN
               Dec(ZeichenAlt);
               Inc(Vorrat);
             END;
    '1':BEGIN
          ZeichenAlt := ' ';
          Inc(Vorrat);
        END;
    ELSE Take := FALSE;
  END;
END;

FUNCTION TRobot.Put:BOOLEAN;
BEGIN
  Put := TRUE;

  IF (ZeichenAlt<>'9') AND (Vorrat>0) THEN
  BEGIN
    IF ZeichenAlt=' ' THEN ZeichenAlt:='1'
      ELSE Inc(ZeichenAlt);
    Dec(Vorrat);
  END ELSE Put := FALSE;
END;

PROCEDURE TRobot.Move(ax,ay:Integer);
BEGIN
  Moveto(x+ax, y+ay);
END;

PROCEDURE TRobot.MoveTo(ax,ay:Integer);
BEGIN
  IF ax<0 THEN ax := 0 ELSE
    IF ax>SizeX-2 THEN ax := SizeX-2;

  IF ay<0 THEN ay := 0 ELSE
    IF ay>SizeY-2 THEN ay := SizeY-2;

  x := (ax AND NOT 3) + 2;
  y := (ay AND NOT 1) + 1;
END;

PROCEDURE TRobot.Turn(ARichtung:Integer);
VAR r:Integer;
BEGIN
  r := Integer(Richtung) + ARichtung;
  WHILE r<1 DO inc(r, 4);
  WHILE r>4 DO dec(r, 4);

  TurnTo(TRichtung(r));
END;

PROCEDURE TRobot.TurnTo(ARichtung:TRichtung);
BEGIN
  Richtung := ARichtung;

  CASE Richtung OF
    rLinks: BEGIN
              dx := -1;
              dy := 0;
            END;
    rRechts:BEGIN
              dx := 1;
              dy := 0;
            END;
    rOben : BEGIN
              dx := 0;
              dy := -1;
            END;
    rUnten: BEGIN
              dx := 0;
              dy := 1;
            END;
  END;
END;

PROCEDURE TRobot.VPos(VAR ax,ay:Integer);
BEGIN
  ax := x DIV 4 + 1;
  ay := y DIV 2 + 1;
END;

PROCEDURE TRobot.Hide;
BEGIN
  RestoreBackground;
  Visible := FALSE;
END;

PROCEDURE TRobot.Show;
BEGIN
  Visible := TRUE;

  SaveBackground;

  Draw;
END;


{******************************************************
 *                                                    *
 * Implementierung des Feldeditors                    *
 *                                                    *
 ******************************************************}


CONSTRUCTOR TFeldEditor.Init(R:TRect; ADatei:String;
    AHScrollBar, AVScrollBar:PScrollBar);
BEGIN
  Niki := NIL;

  INHERITED Init(R, ADatei, AHScrollBar, AVScrollBar);

  IF Niki=NIL THEN
  BEGIN
    New(Niki, Init(0, 0, rRechts, @Self));
    IF Niki = NIL THEN
    BEGIN
      MessageBox('Nicht genug Speicher für ein Feld', NIL, mfOkButton + mfError);
      IsValid := FALSE;
    END;
  END;

  Pos.X := 2;
  Pos.Y := 1;
  Speed := GetNumOption('SPEED', 1);
  Prog := NIL;

  Edit;
  UpdateCursor;
  UpdateInfoWindow;
END;

DESTRUCTOR TFeldEditor.Done;
BEGIN
  ResetMode;

  IF Niki<>NIL THEN Dispose( Niki, Done );
  INHERITED Done;
END;


{******************************************************
 * Zurücksetzen in den Edit-Modus                     *
 ******************************************************}

PROCEDURE TFeldEditor.ResetMode;
BEGIN
  CASE Status OF
    stPaused, stRunning, stDebug : StopRun;
    stTeachIn : StopTeachIn;
  END;

  Edit;

  INHERITED ResetMode;
END;


{******************************************************
 * Laden und Speichern                                *
 ******************************************************}

PROCEDURE TFeldEditor.WriteFile(VAR S:TStream);
BEGIN
  Niki^.Hide;
  INHERITED WriteFile(S);
  Niki^.Show;
  Niki^.Store(S);
END;

PROCEDURE TFeldEditor.ReadFile(VAR S:TStream);
BEGIN
  IF Niki<>NIL THEN Dispose(Niki, Done);

  INHERITED ReadFile(S);

  New(Niki, Load(S, @Self));
  IF Niki = NIL THEN
  BEGIN
    MessageBox('Nicht genug Speicher für ein Feld', NIL, mfOkButton + mfError);
    IsValid := FALSE;
  END;
END;


{******************************************************
 * Ereignisverwaltung                                 *
 ******************************************************}

PROCEDURE TFeldEditor.HandleEvent(VAR Event:TEvent);
VAR Klick:TPoint;
    TempX, TempY: SmallInt;
BEGIN
  CASE Status OF
    stEdit:
      CASE Event.What OF
        evCommand : CASE Event.Command OF
                      cmTeachIn : TeachIn;
                      cmVorrat : Vorrat;
                    END;
        evMouseMove, evMouseDown :
              BEGIN
                MakeLocal(Event.Where, Klick);
                TempX := Klick.X; TempY := Klick.Y;
                MakeLogical(TempX, TempY);
                Klick.X := TempX; Klick.Y := TempY;

                IF Event.Buttons=1 THEN
                BEGIN
                  SetWall(Klick.X, Klick.Y, NOT IsWall(Klick.x, Klick.Y));

                  DrawLine( Klick.Y-1 );
                  DrawLine( Klick.Y );
                  DrawLine( Klick.Y+1 );
                END
                ELSE IF Event.Buttons=2 THEN
                         MoveNikiTo(Klick.x, Klick.y);

                MoveCursorTo(Klick.X, Klick.Y);

                Modified := TRUE;
              END;
        evKeydown :   CASE Event.KeyCode OF
                        kbLeft : MoveCursor(-2,0);
                        kbRight: MoveCursor(2,0);
                        kbUp:    MoveCursor(0,-1);
                        kbDown:  MoveCursor(0,1);
                        kbHome:  MoveCursorTo(0, Cursor.Y+Delta.Y);
                        kbEnd:   MoveCursorTo(SizeX-1, Cursor.Y+Delta.Y);
                        kbPgUp:  MoveCursor(0, -Size.Y);
                        kbPgDn:  MoveCursor(0, Size.Y);
                       ELSE CASE Event.CharCode OF
                        ' ':BEGIN
                              Klick.X := Pos.X;
                              Klick.Y := Pos.Y;

                              SetWall(Klick.X, Klick.Y,
                                NOT IsWall(Klick.x, Klick.Y));

                              DrawLine( Klick.Y-1 );
                              DrawLine( Klick.Y );
                              DrawLine( Klick.Y+1 );

                              Modified := TRUE;
                            END;
                        '+': ChangeVorrat(Pos.X, Pos.Y, TRUE);
                        '-': ChangeVorrat(Pos.X, Pos.Y, FALSE);
                        'p': MoveNikiTo(Pos.X, Pos.Y);
                        END;
                      END
      END;
    stRunning: CASE Event.What OF
                 evNothing:Idle;
                 evCommand:CASE Event.Command OF
                             cmReset : StopRun;
                           END;
                 evKeyDown:CASE Event.KeyCode OF
                             kbEsc:StopRun;
                             kbF8: BEGIN
                                     ExecCommand := TRUE;
                                     Status := stDebug;
                                     UpdateInfoWindow;
                                   END;
                             ELSE CASE Event.CharCode OF
                                    ' ', 'p', 'P': BEGIN
                                                     Status := stPaused;
                                                     UpdateInfoWindow;
                                                   END;
                                  END;

                           END;
               END;
    stDebug:   CASE Event.What OF
                 evNothing: Idle;
                 evCommand:CASE Event.Command OF
                             cmReset : StopRun;
                           END;
                 evKeyDown:CASE Event.KeyCode OF
                             kbEsc, kbEnter:StopRun;
                             kbF8: ExecCommand := TRUE;
                             kbF9: BEGIN
                                     Status := stRunning;
                                     UpdateInfoWindow;
                                   END;
                           END;
               END;
    stPaused: CASE Event.What OF
                evCommand:CASE Event.Command OF
                            cmReset : StopRun;
                          END;
                evKeyDown, evMouseDown :
                  BEGIN
                    Status := stRunning;
                    UpdateInfoWindow;
                  END;
              END;
    stTeachIn: CASE Event.What OF
                 evKeyDown : CASE Event.KeyCode OF
                               kbEsc, kbEnter : StopTeachIn;
                               ELSE RecordAction(Event);
                             END;
               END;
  END;

  CASE Event.What OF
    evCommand : CASE Event.Command OF
                  cmSpeed : SetSpeed;
                  cmPrintFeld : Print;
                END;
  END;

  INHERITED HandleEvent(Event);
END;


{******************************************************
 * Steuerung des Cursors                              *
 ******************************************************}

PROCEDURE TFeldEditor.TrackCursor;
VAR p:TPoint;
BEGIN
  p.x := Delta.X;
  p.y := Delta.Y;

  IF Cursor.X<0 THEN Inc(p.x, Cursor.X);
  IF Cursor.Y<0 THEN Inc(p.y, Cursor.Y);
  IF Cursor.X>=Size.X THEN Inc(p.x, Cursor.X-Size.X+1);
  IF Cursor.Y>=Size.Y THEN Inc(p.y, Cursor.Y-Size.Y+1);

  IF (p.x<>Delta.X) OR (p.y<>Delta.Y) THEN
  BEGIN
    ScrollTo( p.x, p.y );
    Draw;
  END;
END;

PROCEDURE TFeldEditor.MoveCursor(x,y:Integer);
BEGIN
  MoveCursorTo(x + Pos.X, y + Pos.Y);
END;

PROCEDURE TFeldEditor.MoveCursorTo(x,y:Integer);
BEGIN
  IF x<0 THEN x := 0 ELSE
    IF x>SizeX-1 THEN x := SizeX-1;

  IF y<0 THEN y := 0 ELSE
    IF y>SizeY-1 THEN y := SizeY-1;

  IF (x AND 3)>0 THEN
    x := (x AND NOT 3)+2
  ELSE
    x := (x AND NOT 3);

  Pos.X := x;
  Pos.Y := y;

  UpdateCursor;
  TrackCursor;
END;

PROCEDURE TFeldEditor.UpdateCursor;
VAR x, y:Integer;
BEGIN
  x := Pos.X;
  y := Pos.Y;

  MakePhysical(x,y);

  SetCursor( x, y);
END;

PROCEDURE TFeldEditor.UpdateInfoWindow;
BEGIN
  IF InfoWindow<>NIL THEN
  BEGIN
    InfoWindow^.SetMode(Status);
    InfoWindow^.SetVorrat(Niki^.Vorrat);
    InfoWindow^.SetPosition( (Niki^.X DIV 4)+1, (Niki^.Y DIV 2)+1 );
  END;
END;

VAR ErrorInfo:RECORD
                Num:Longint;
                Pos:Longint;
              END;

PROCEDURE TFeldEditor.ShowError;
VAR R:TRect;
    Error:PErrorLine;
    s:String;
BEGIN
  Beep;

  Owner^.GetExtent(R);
  inc(R.A.Y);
  inc(R.A.X);
  dec(R.B.X);
  R.B.Y:=R.A.Y+1;

  CASE Prog^.Status OF
    stNoVorrat:    s:='Fehler #%d: Nichts zum Ablegen vorhanden oder Platz voll';
    stNoPalette:   s:='Fehler #%d: Nichts zum Aufnehmen vorhanden';
    stHitWall:     s:='Fehler #%d: Wand im Weg';
    stNoMemory:    s:='Fehler #%d: Zu wenig Speicher vorhanden';
    stStackErr:    s:='Fehler #%d: Stacküberlauf';
    stUnknownOpcode: s:='Interner Interpreter-Fehler #%d an PCode-Position %d';
    stFileError:   s:='Fehler #%d: Dateifehler';
    ELSE s:='Unbekannter Fehler #%d';
  END;
  Error := New(PErrorLine, Init(R, s, 2));
  IF Error = NIL THEN
  BEGIN
    MessageBox('Nicht genug Speicher zum Anzeigen des Fehlers'
      , NIL, mfOkButton + mfError);
    IsValid := FALSE;
  END ELSE
  BEGIN
    ErrorInfo.Num := Prog^.Status;
    ErrorInfo.Pos := Prog^.IP;
    Error^.SetData( ErrorInfo );

    Owner^.ExecView( Error );

    Dispose( Error, Done );
  END;
END;


{******************************************************
 * Starten eines Programms                            *
 ******************************************************}

PROCEDURE TFeldEditor.Run(ADatei:STRING; Debug:BOOLEAN);
BEGIN
  IF (Status=stRunning) OR (Status=stPaused) OR (Status=stDebug) THEN StopRun;
  IF SaveFile(GetTemp+'\RUN.TMP') THEN
  BEGIN
    IF Debug THEN Status := stDebug ELSE Status := stRunning;

    Paused := FALSE;
    ExecCommand := TRUE;

    HideCursor;
    UpdateInfoWindow;

    MyTimer := NewCounter;
    IF MyTimer<0 THEN
    BEGIN

      MessageBox('Nicht genug Resourcen zum Ausführen des Programms', NIL, mfOkButton + mfError);
      IsValid := FALSE;

      StopRun;
    END ELSE
    BEGIN
      New(Prog, Init(ADatei, Niki));
      IF Prog = NIL THEN
      BEGIN
        MessageBox('Nicht genug Speicher zum Ausführen des Programms', NIL, mfOkButton + mfError);
        IsValid := FALSE;
        StopRun;
      END;
    END;
  END ELSE
    MessageBox('Can''t write temporal file', NIL, mfError+mfOkButton);
END;

PROCEDURE TFeldEditor.StopRun;
BEGIN
  ReleaseCounter( MyTimer );

  IF Prog<>NIL THEN Dispose(Prog, Done);
  Prog := NIL;

  IF NOT LoadFile(GetTemp+'\RUN.TMP') THEN
  BEGIN
    MessageBox('Can''t reload temporal file', NIL, mfError+mfOkButton);
  END;

  FDelete(GetTemp+'\RUN.TMP');
  Draw;
  Edit;
END;


PROCEDURE TFeldEditor.Finished;
VAR R:TRect;
    Msg:PParamLine;
BEGIN
  Owner^.GetExtent(R);
  inc(R.A.Y);
  inc(R.A.X);
  dec(R.B.X);
  R.B.Y:=R.A.Y+1;

  Msg := New(PParamLine, Init(R, 'Programm beendet', 0));
  IF Msg = NIL THEN
  BEGIN
    MessageBox('Nicht genug Speicher zum Anzeigen der Fertig-Meldung',
       NIL, mfOkButton + mfError);
    IsValid := FALSE;
  END ELSE
  BEGIN
    Owner^.ExecView( Msg );
    Dispose( Msg, Done );
  END;
END;



{******************************************************
 * Abspielen des Programms im Hintergrund             *
 ******************************************************}

PROCEDURE TFeldEditor.ShowLine;
VAR x,y,a,b:Word;
    l:Longint;
BEGIN
  IF EditWindow<>NIL THEN
  BEGIN
    WITH EditWindow^ DO
    BEGIN
      x := 1;
      y := 1;
      FOR a := 0 TO Editor^.BufLen DO
      BEGIN
        IF (y = Prog^.ActLine) AND (x = 1) THEN Break;

        inc(x);
        IF Editor^.BufChar(a)=#10 THEN
        BEGIN
          x := 1;
          inc(y);
        END;
      END;

      FOR b := a TO Editor^.BufLen DO
        IF Editor^.BufChar(b)=#10 THEN break;

      Editor^.SetSelect(a, b, TRUE);
      Editor^.TrackCursor(TRUE);
    END;
  END;
END;


PROCEDURE TFeldEditor.Idle;
CONST OldLine:Integer=-1;
BEGIN
  IF (Status=stRunning) THEN
  BEGIN
    IF (Prog^.Status=stOk) AND (Counter(MyTimer)>=Speed) AND NOT Paused THEN
    BEGIN
      IF Prog^.RunStep THEN SetCounter( MyTimer, 0 );

      DrawLine(Niki^.Y-2);
      DrawLine(Niki^.Y);
      DrawLine(Niki^.Y+2);

      UpdateInfoWindow;

      CASE Prog^.Status OF
        stOk:;
        stBreak:BEGIN
                  Finished;
                  StopRun;
                END;
        ELSE BEGIN
               ShowError;
               StopRun;
             END;
      END;
    END;
  END ELSE
  IF (Status=stDebug) THEN
    IF (Prog^.Status=stOk) AND (Counter(MyTimer)>=Speed) AND NOT Paused
      AND (ExecCommand = TRUE) THEN
    BEGIN
      IF Prog^.RunStep THEN SetCounter( MyTimer, 0 );

      IF Prog^.BreakPoint THEN
      BEGIN
        Prog^.BreakPoint := FALSE;

        IF OldLine<>Prog^.ActLine THEN
        BEGIN
          ExecCommand := FALSE;
          ShowLine;
        END;

        OldLine := Prog^.ActLine;
      END;

      DrawLine(Niki^.Y-2);
      DrawLine(Niki^.Y);
      DrawLine(Niki^.Y+2);

      UpdateInfoWindow;

      CASE Prog^.Status OF
        stOk:;
        stBreak:BEGIN
                  Finished;
                  StopRun;
                END;
        ELSE BEGIN
               ShowError;
               StopRun;
             END;
      END;
    END;

END;



{******************************************************
 * Aufnehmen eines Programms                          *
 ******************************************************}

PROCEDURE TFeldEditor.TeachIn;
VAR R:TRect;
BEGIN
  IF (Status=stEdit) THEN
  BEGIN
    IF SaveFile(GetTemp+'\TEACH.TMP') THEN
    BEGIN
      Status := stTeachIn;

      TeachInBuf := PFileEditor(Clipboard);
      IF TeachInBuf=NIL THEN StopTeachIn ELSE
      BEGIN
        TeachInBuf^.DeleteSelect;

        TeachLine('PROGRAM TeachIn;');
        TeachLine('BEGIN');

        HideCursor;

        UpdateInfoWindow;
      END;
    END ELSE
      MessageBox('Can''t write temporal file', NIL, mfError+mfOkButton);
  END;
END;

PROCEDURE TFeldEditor.StopTeachIn;
VAR Event:TEvent;
BEGIN
  IF (Status=stTeachIn) THEN
  BEGIN
    IF TeachInBuf<>NIL THEN
    BEGIN
      TeachLine('END.');

      IF MessageBox('Wollen sie den aufgenommenen Teil als Programm speichern?',
           NIL, mfYesButton+mfNoButton)=cmYes THEN TeachInBuf^.Save;
    END;

    {IF MessageBox('Soll der alte Zustand des Feldes wiederhergestellt werden?',
         NIL, mfYesButton+mfNoButton) = cmYes THEN}
    BEGIN
      IF NOT LoadFile(GetTemp+'\TEACH.TMP') THEN
      BEGIN
        MessageBox('Can''t reload temporal file', NIL, mfError+mfOkButton);
      END;
    END;

    FDelete(GetTemp+'\TEACH.TMP');

    Draw;
    Edit;
  END;
END;

PROCEDURE TFeldEditor.RecordAction(Event:TEvent);
BEGIN
  IF Niki<>NIL THEN
    CASE Event.KeyCode OF
      kbLeft : BEGIN
                 Niki^.Left;
                 DrawLine( Niki^.Y );

                 TeachLine('  Drehe_Links;');
               END;
      kbUp   : BEGIN
                 IF NOT Niki^.Go(TRUE) THEN
                 BEGIN
                   Beep;
                   StopTeachIn;
                 END ELSE
                 BEGIN
                   TeachLine('  Vor;');
                 END;

                 DrawLine( Niki^.Y-2 );
                 DrawLine( Niki^.Y );
                 DrawLine( Niki^.Y+2 );
               END;
      kbDel  : BEGIN
                 IF NOT Niki^.Take THEN
                 BEGIN
                   Beep;
                   StopTeachIn;
                 END ELSE
                   TeachLine('  Nimm_Auf;');
               END;
      kbIns  : BEGIN
                 IF NOT Niki^.Put THEN
                 BEGIN
                   Beep;
                   StopTeachIn;
                 END ELSE
                   TeachLine('  Gib_Ab;');
               END;
    END;

  UpdateInfoWindow;
END;

PROCEDURE TFeldEditor.TeachLine(s:String);
VAR Alt:Boolean;
BEGIN
  IF TeachInBuf<>NIL THEN
  BEGIN
    s := s + #13#10;
    Alt := TeachInBuf^.Overwrite;
    TeachInBuf^.Overwrite := FALSE;
    Message(TeachInBuf, evCommand, cmTextEnd, NIL);
    TeachInBuf^.InsertText(@s[1], length(s), FALSE);
    TeachInBuf^.SetSelect(0, TeachInBuf^.BufLen, FALSE);
    TeachInBuf^.Overwrite := Alt;
  END;
END;


{******************************************************
 * Editierfunktionen des Editors                      *
 ******************************************************}

PROCEDURE TFeldEditor.Edit;
BEGIN
  Status := stEdit;

  ShowCursor;
  UpdateInfoWindow;
END;

PROCEDURE TFeldEditor.SetWall(x,y:Integer; Mode:BOOLEAN);
BEGIN
  IF (x<=SizeX-2) AND (x>=1) AND (y<=SizeY-2) AND (y>=1) THEN
  BEGIN
    IF (x AND 3)=0 THEN
    BEGIN
      IF (y AND 1)=1 THEN
      BEGIN
        x := x AND NOT 3;
        y := y AND NOT 1;

        IF Mode THEN
          Feld[y+1,x].z := Walls[wVert]
        ELSE
          Feld[y+1,x].z := Walls[wNo];

        UpdateCorner(x,y);
        UpdateCorner(x,y+2);
      END;
    END ELSE
    IF (y AND 1)=0 THEN
    BEGIN
      x := x AND NOT 3;
      y := y AND NOT 1;

      IF Mode THEN
      BEGIN
        Feld[y,x+1].z := Walls[wHor];
        Feld[y,x+2].z := Walls[wHor];
        Feld[y,x+3].z := Walls[wHor];
      END ELSE
      BEGIN
        Feld[y,x+1].z := Walls[wNo];
        Feld[y,x+2].z := Walls[wNo];
        Feld[y,x+3].z := Walls[wNo];
      END;

      UpdateCorner(x,y);
      UpdateCorner(x+4,y);

      Modified := TRUE;
    END;
  END;
END;

PROCEDURE TFeldEditor.ChangeVorrat(x,y:Integer; Mode:BOOLEAN);
BEGIN
  IF (x AND 3=2) AND (y AND 1=1) THEN
  BEGIN
    Niki^.Hide;

    IF Mode=TRUE THEN
    BEGIN
      IF Feld[y,x].z <> '9' THEN
      BEGIN
        IF Feld[y,x].z=' ' THEN Feld[y,x].z:='1'
        ELSE inc(Feld[y,x].z);
      END;
    END ELSE
          CASE Feld[y,x].z OF
            '2'..'9' : Dec(Feld[y,x].z);
            '1'      : Feld[y,x].z:=' ';
          END;

    Niki^.Show;

    DrawLine(y);

    Modified := TRUE;
  END;
END;

PROCEDURE TFeldEditor.MoveNikiTo(x,y:Integer);
BEGIN
  IF (x AND 3<>0) AND (y AND 1=1) THEN
  BEGIN
    X:=(X AND NOT 3)+2;

    IF (X=Niki^.X) AND (Y=Niki^.Y) THEN
    BEGIN
      Niki^.Turn(-1);
      Niki^.Draw;
      DrawLine(Niki^.y);
    END ELSE
    BEGIN
      Niki^.Hide;
      DrawLine(Niki^.y);

      Niki^.MoveTo(x, y);
      Niki^.Show;
      DrawLine(y);
      UpdateInfoWindow;
    END;

    Modified := TRUE;
  END;
END;

FUNCTION TFeldEditor.IsWall(x,y:Integer):BOOLEAN;
BEGIN
  IF (x<=SizeX-1) AND (x>=0) AND (y<=SizeY-1) AND (y>=0) THEN
    IsWall := Feld[y,x].z <> Walls[wNo]
  ELSE IsWall := FALSE;
END;


PROCEDURE TFeldEditor.UpdateCorner(x,y:Integer);
VAR Kind:Byte;
BEGIN
  IF (x<=SizeX-1) AND (x>=0) AND (y<=SizeY-1) AND (y>=0) THEN
  BEGIN

    Kind := 0;

    IF IsWall(x-1,y) THEN Inc(Kind, 1);
    IF IsWall(x,y-1) THEN Inc(Kind, 2);
    IF IsWall(x+1,y) THEN Inc(Kind, 4);
    IF IsWall(x,y+1) THEN Inc(Kind, 8);

    Feld[y,x].z := Walls[Kind];
  END;
END;

PROCEDURE TFeldEditor.Draw;
VAR y:Integer;
BEGIN
  FOR y:=Delta.Y TO Delta.Y+Size.Y-1 DO
    DrawLine( y );
END;


{******************************************************
 * Funktionen zum Handling von Nikis Vorrat           *
 ******************************************************}

PROCEDURE TFeldEditor.Vorrat;
VAR s: ShortString;
    v:Integer;
    Code:Integer;
BEGIN
  System.Str(Niki^.Vorrat, s);
  IF InputBox('Vorrat ändern', 'Vorrat:', s, 2)=cmOk THEN
  BEGIN
    Val(s, v, Code);
    IF (Code<>0) OR (v<0) OR (v>99) THEN
      MessageBox('Vorrat muß zwischen 0 und 99 liegen', NIL,
          mfOkButton+mfError)
    ELSE
      BEGIN
        Niki^.Vorrat := v;
        UpdateInfoWindow;
      END;
  END;
END;

FUNCTION TFeldEditor.GetVorrat:Word;
BEGIN
  GetVorrat := Niki^.Vorrat;
END;


{******************************************************
 * Einstellen der Interpretiergeschwindigkeit         *
 ******************************************************}

PROCEDURE TFeldEditor.SetSpeed;
VAR s: ShortString;
    v:Integer;
    Code:Integer;
BEGIN
  System.Str(Speed, s);
  IF InputBox('Geschwindigkeit ändern', 'Geschwindigkeit:', s, 2)=cmOk THEN
  BEGIN
    Val(s, v, Code);
    IF (Code<>0) OR (v<0) OR (v>99) THEN
      MessageBox('Geschwindigkeit muß zwischen 0 und 99 liegen', NIL,
          mfOkButton+mfError)
    ELSE
      Speed := v;
  END;
END;


{******************************************************
 * Drucken eines Feldes                               *
 ******************************************************}

PROCEDURE TFeldEditor.Print;
BEGIN
  IF Application^.ExecuteDialog(
       New(PPrintDialog, Init(mdFeld)), @PrintOptions)=cmOk THEN
  BEGIN
    Application^.ExecuteDialog( New(PFeldPrint,
      Init(@Self)),
      @PrintOptions)
  END;
END;

{******************************************************
 *                                                    *
 * Implementierung des Editierfensters                *
 *                                                    *
 ******************************************************}

CONSTRUCTOR TFeldWindow.Init(R:TRect; ADatei:STRING);
VAR HScrollbar, VScrollbar:PScrollBar;
BEGIN
  INHERITED Init(R, ADatei, wnNoNumber);
  Options := Options OR ofTileable;
  {State := State AND NOT sfShadow;}

  GrowMode := 0;

  R.Assign(18, Size.Y - 1, Size.X - 2, Size.Y);
  HScrollBar := New(PScrollBar, Init(R));
  HScrollBar^.Hide;
  Insert(HScrollBar);

  R.Assign(Size.X - 1, 1, Size.X, Size.Y - 1);
  VScrollBar := New(PScrollBar, Init(R));
  VScrollBar^.Hide;
  Insert(VScrollBar);

  GetExtent(R);
  inc(R.A.X);
  inc(R.A.Y);
  dec(R.B.X);
  dec(R.B.Y);
  New(Feld, Init(R, ADatei, HScrollbar, VScrollbar));
  Insert(Feld);

  GrowTo(Size.X,Size.Y);

  UpdateTitle;
END;

DESTRUCTOR TFeldWindow.Done;
BEGIN
  IF FeldWindow = @Self THEN FeldWindow := NIL;
  INHERITED Done;
END;

FUNCTION TFeldWindow.CanClose:BOOLEAN;
BEGIN
  IF Feld<>NIL THEN CanClose := Feld^.CanClose ELSE
    CanClose := TRUE;
END;

PROCEDURE TFeldWindow.HandleEvent(VAR Event:TEvent);
BEGIN
  CASE Event.What OF
    evCommand : CASE Event.Command OF
                  cmClose:;
                END;
    evBroadcast : CASE Event.Command OF
                    cmUpdateTitle : BEGIN
                                      UpdateTitle;
                                      ClearEvent(Event);
                                    END;
                  END
  END;
  INHERITED HandleEvent(Event);
END;

PROCEDURE TFeldWindow.Idle;
BEGIN
  IF Feld<>NIL THEN Feld^.Idle;
END;

PROCEDURE TFeldWindow.SizeLimits(var Min, Max: TPoint);
VAR Dummy:TPoint;
BEGIN
  INHERITED SizeLimits(Min, Dummy);
  Feld^.SizeLimits(Dummy, Max);

  inc(Max.X, 2);
  inc(Max.Y, 2);

  Min.X := 23;
END;

FUNCTION TFeldWindow.GetPalette: PPalette;
CONST P: String[Length(CFeld)] = CFeld;
BEGIN
  GetPalette := @P;
END;

FUNCTION TFeldWindow.GetTitle(MaxLen: LongInt): ShortString;
BEGIN
  IF Feld<>NIL THEN GetTitle := Feld^.GetTitle;
END;

PROCEDURE TFeldWindow.UpdateTitle;
BEGIN
  Frame^.Draw;
END;

PROCEDURE TFeldWindow.Run(ADatei:STRING; Debug:BOOLEAN);
BEGIN
  IF Feld<>NIL THEN Feld^.Run(ADatei, Debug);
END;

END.