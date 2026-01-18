UNIT NikiDasm;

INTERFACE
USES Objects, Views, Drivers, Dialogs;

CONST
  MaxDisasmLines = 512;
  MaxLineMaps = 1024;

TYPE
  { Line mapping: bytecode address -> source line }
  TLineMap = RECORD
    Addr: Word;
    Line: Word;
  END;
  TLineMapArray = ARRAY[0..MaxLineMaps-1] OF TLineMap;

  { Disassembled instruction }
  TDisasmLine = RECORD
    Addr: Word;
    SourceLine: Word;
    Text: String[60];
  END;

  PDisasmViewer = ^TDisasmViewer;
  TDisasmViewer = OBJECT(TScroller)
    Lines: ARRAY[0..MaxDisasmLines-1] OF TDisasmLine;
    LineCount: Integer;
    FocusLine: Integer;
    LineMap: TLineMapArray;
    LineMapCount: Integer;
    ProgSize: Word;

    CONSTRUCTOR Init(VAR Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar);
    PROCEDURE Draw; VIRTUAL;
    PROCEDURE LoadFile(AFileName: String);
    PROCEDURE FocusSourceLine(Line: Word);
  PRIVATE
    FUNCTION InstructionSize(Op: Byte): Integer;
    FUNCTION DisassembleOp(Addr: Word; VAR Prog: ARRAY OF Byte): String;
    FUNCTION FindLineIndex(Addr: Word): Integer;
  END;

  PDisasmWindow = ^TDisasmWindow;
  TDisasmWindow = OBJECT(TWindow)
    Viewer: PDisasmViewer;
    CurrentFile: String;

    CONSTRUCTOR Init(VAR Bounds: TRect);
    PROCEDURE HandleEvent(VAR Event: TEvent); VIRTUAL;
    FUNCTION GetPalette: PPalette; VIRTUAL;
  END;

VAR DisasmWindow: PDisasmWindow;
    DisasmFileName: String;  { Global buffer for passing filename }

IMPLEMENTATION
USES Opcodes, NikiCnst;

{ TDisasmViewer }

CONSTRUCTOR TDisasmViewer.Init(VAR Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar);
BEGIN
  INHERITED Init(Bounds, AHScrollBar, AVScrollBar);
  LineCount := 0;
  FocusLine := -1;
  LineMapCount := 0;
  ProgSize := 0;
  GrowMode := gfGrowHiX + gfGrowHiY;
END;

FUNCTION TDisasmViewer.InstructionSize(Op: Byte): Integer;
BEGIN
  CASE Op OF
    ocJMP, ocCALL, ocJC, ocJNC, ocDEBUG:
      InstructionSize := 3;
    ELSE
      InstructionSize := 1;
  END;
END;

FUNCTION TDisasmViewer.DisassembleOp(Addr: Word; VAR Prog: ARRAY OF Byte): String;
VAR
  Op: Byte;
  Operand: Word;
  S: String;
BEGIN
  Op := Prog[Addr];
  S := '';
  CASE Op OF
    ocBRK:  S := 'BRK';
    ocJMP:  BEGIN
              Operand := Prog[Addr+1] + Prog[Addr+2] * 256;
              Str(Operand, S);
              S := 'JMP    ' + S;
            END;
    ocTURN: S := 'TURN';
    ocGO:   S := 'GO';
    ocTAKE: S := 'TAKE';
    ocPUT:  S := 'PUT';
    ocCALL: BEGIN
              Operand := Prog[Addr+1] + Prog[Addr+2] * 256;
              Str(Operand, S);
              S := 'CALL   ' + S;
            END;
    ocRET:  S := 'RET';
    ocCVF:  S := 'CVF';
    ocCLF:  S := 'CLF';
    ocCRF:  S := 'CRF';
    ocCPB:  S := 'CPB';
    ocCV:   S := 'CV';
    ocJNC:  BEGIN
              Operand := Prog[Addr+1] + Prog[Addr+2] * 256;
              Str(Operand, S);
              S := 'JNC    ' + S;
            END;
    ocJC:   BEGIN
              Operand := Prog[Addr+1] + Prog[Addr+2] * 256;
              Str(Operand, S);
              S := 'JC     ' + S;
            END;
    ocPUSH: S := 'PUSH';
    ocPOP:  S := 'POP';
    ocSDEC: S := 'SDEC';
    ocDEBUG: BEGIN
               Operand := Prog[Addr+1] + Prog[Addr+2] * 256;
               Str(Operand, S);
               S := 'DBG    #' + S;
             END;
    ELSE BEGIN
           Str(Op, S);
           S := '??? (' + S + ')';
         END;
  END;
  DisassembleOp := S;
END;

FUNCTION TDisasmViewer.FindLineIndex(Addr: Word): Integer;
VAR i: Integer;
BEGIN
  FindLineIndex := -1;
  FOR i := 0 TO LineCount - 1 DO
    IF Lines[i].Addr = Addr THEN
    BEGIN
      FindLineIndex := i;
      Exit;
    END;
END;

PROCEDURE TDisasmViewer.LoadFile(AFileName: String);
VAR
  F: FILE;
  Prog: ARRAY[0..8191] OF Byte;
  BytesRead: Integer;
  IP: Word;
  Op: Byte;
  AddrStr: String[4];
BEGIN
  LineCount := 0;
  LineMapCount := 0;
  FocusLine := -1;
  ProgSize := 0;

  {$I-}
  Assign(F, AFileName);
  Reset(F, 1);
  IF IOResult <> 0 THEN Exit;
  BlockRead(F, Prog, SizeOf(Prog), BytesRead);
  Close(F);
  {$I+}
  IF IOResult <> 0 THEN Exit;

  ProgSize := BytesRead;
  IP := 0;

  WHILE (IP < ProgSize) AND (LineCount < MaxDisasmLines) DO
  BEGIN
    Op := Prog[IP];

    { Format address as 4-digit hex-like decimal }
    Str(IP:4, AddrStr);

    Lines[LineCount].Addr := IP;
    Lines[LineCount].SourceLine := 0;
    Lines[LineCount].Text := AddrStr + '  ' + DisassembleOp(IP, Prog);

    { Build line map from debug markers }
    IF Op = ocDEBUG THEN
    BEGIN
      IF LineMapCount < MaxLineMaps THEN
      BEGIN
        LineMap[LineMapCount].Addr := IP;
        LineMap[LineMapCount].Line := Prog[IP+1] + Prog[IP+2] * 256;
        Lines[LineCount].SourceLine := LineMap[LineMapCount].Line;
        Inc(LineMapCount);
      END;
    END;

    Inc(IP, InstructionSize(Op));
    Inc(LineCount);
  END;

  SetLimit(60, LineCount);
  ScrollTo(0, 0);
  DrawView;
END;

PROCEDURE TDisasmViewer.FocusSourceLine(Line: Word);
VAR
  i: Integer;
  BestIndex: Integer;
  BestLine: Word;
BEGIN
  IF LineMapCount = 0 THEN Exit;

  { Find the debug marker with the closest matching line }
  BestIndex := -1;
  BestLine := 0;
  FOR i := 0 TO LineMapCount - 1 DO
  BEGIN
    IF (LineMap[i].Line <= Line) AND (LineMap[i].Line > BestLine) THEN
    BEGIN
      BestLine := LineMap[i].Line;
      BestIndex := FindLineIndex(LineMap[i].Addr);
    END;
  END;

  IF BestIndex >= 0 THEN
  BEGIN
    FocusLine := BestIndex;

    { Scroll to make focus line visible }
    IF FocusLine < Delta.Y THEN
      ScrollTo(Delta.X, FocusLine)
    ELSE IF FocusLine >= Delta.Y + Size.Y THEN
      ScrollTo(Delta.X, FocusLine - Size.Y + 1);

    DrawView;
  END;
END;

PROCEDURE TDisasmViewer.Draw;
VAR
  B: TDrawBuffer;
  Color, FocusColor: Byte;
  i, Y: Integer;
  S: String;
BEGIN
  Color := GetColor(1);
  FocusColor := GetColor(2);

  FOR Y := 0 TO Size.Y - 1 DO
  BEGIN
    i := Delta.Y + Y;
    MoveChar(B, ' ', Color, Size.X);

    IF i < LineCount THEN
    BEGIN
      S := Lines[i].Text;
      IF i = FocusLine THEN
        MoveStr(B, S, FocusColor)
      ELSE
        MoveStr(B, S, Color);
    END;

    WriteLine(0, Y, Size.X, 1, B);
  END;
END;

{ TDisasmWindow }

CONSTRUCTOR TDisasmWindow.Init(VAR Bounds: TRect);
VAR
  R: TRect;
  VScrollBar: PScrollBar;
BEGIN
  INHERITED Init(Bounds, 'Disassemble', wnNoNumber);
  State := State AND NOT sfShadow;

  { Create vertical scrollbar }
  GetExtent(R);
  R.A.X := R.B.X - 1;
  Inc(R.A.Y);
  Dec(R.B.Y);
  VScrollBar := New(PScrollBar, Init(R));
  VScrollBar^.GrowMode := gfGrowLoX + gfGrowHiX + gfGrowHiY;
  Insert(VScrollBar);

  { Create viewer }
  GetExtent(R);
  Inc(R.A.X);
  Inc(R.A.Y);
  Dec(R.B.X, 2);
  Dec(R.B.Y);
  Viewer := New(PDisasmViewer, Init(R, NIL, VScrollBar));
  Insert(Viewer);

  CurrentFile := '';
END;

FUNCTION TDisasmWindow.GetPalette: PPalette;
{ Use grey dialog palette (CGrayDialog indices 32-39) }
CONST CDisasm: String[8] = #32#33#34#35#36#37#38#39;
BEGIN
  GetPalette := @CDisasm;
END;

PROCEDURE TDisasmWindow.HandleEvent(VAR Event: TEvent);
BEGIN
  { Handle broadcasts before inherited to catch them first }
  CASE Event.What OF
    evBroadcast: CASE Event.Command OF
      cmUpdateDisasm: BEGIN
        IF DisasmFileName <> '' THEN
        BEGIN
          CurrentFile := DisasmFileName;
          Viewer^.LoadFile(CurrentFile);
        END;
        ClearEvent(Event);
        Exit;
      END;
      cmSyncDisasm: BEGIN
        Viewer^.FocusSourceLine(Word(PtrUInt(Event.InfoPtr)));
        ClearEvent(Event);
        Exit;
      END;
    END;
  END;

  INHERITED HandleEvent(Event);

  CASE Event.What OF
    evCommand: CASE Event.Command OF
      cmClose: BEGIN
        Hide;
        ClearEvent(Event);
      END;
    END;
  END;
END;

END.
