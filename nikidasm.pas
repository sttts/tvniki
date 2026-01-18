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
    HexData: String[20];
    Mnemonic: String[20];
    Desc: String[40];
  END;

  { Status indicator for register state }
  PDisasmIndicator = ^TDisasmIndicator;
  TDisasmIndicator = OBJECT(TView)
    RegIP: Word;
    RegCarry: Boolean;
    RegVorrat: Word;
    CONSTRUCTOR Init(VAR Bounds: TRect);
    PROCEDURE Draw; VIRTUAL;
    PROCEDURE Update(AIP: Word; ACarry: Boolean; AVorrat: Word);
  END;

  PDisasmViewer = ^TDisasmViewer;
  TDisasmViewer = OBJECT(TScroller)
    Lines: ARRAY[0..MaxDisasmLines-1] OF TDisasmLine;
    LineCount: Integer;
    FocusLine: Integer;      { Editor cursor sync line (grey highlight) }
    ExecLine: Integer;       { Current execution line (blue highlight) }
    CursorLine: Integer;     { Keyboard cursor line (black highlight) }
    LineMap: TLineMapArray;
    LineMapCount: Integer;
    ProgSize: Word;

    CONSTRUCTOR Init(VAR Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar);
    PROCEDURE HandleEvent(VAR Event: TEvent); VIRTUAL;
    PROCEDURE Draw; VIRTUAL;
    PROCEDURE LoadFile(AFileName: String);
    PROCEDURE Clear;
    PROCEDURE FocusSourceLine(Line: Word);
    PROCEDURE FocusAddr(Addr: Word);
  PRIVATE
    FUNCTION InstructionSize(Op: Byte): Integer;
    PROCEDURE DisassembleOp(Addr: Word; VAR Prog: ARRAY OF Byte;
      VAR Mnemonic, Desc: String);
    FUNCTION FindLineIndex(Addr: Word): Integer;
  END;

  PDisasmWindow = ^TDisasmWindow;
  TDisasmWindow = OBJECT(TWindow)
    Viewer: PDisasmViewer;
    Indicator: PDisasmIndicator;
    CurrentFile: String;

    CONSTRUCTOR Init(VAR Bounds: TRect);
    FUNCTION GetPalette: PPalette; VIRTUAL;
    PROCEDURE HandleEvent(VAR Event: TEvent); VIRTUAL;
  END;

VAR DisasmWindow: PDisasmWindow;
    DisasmFileName: String;  { Global buffer for passing filename }

IMPLEMENTATION
USES App, Opcodes, NikiCnst, NikiStrings, SysUtils;

{ TDisasmIndicator }

CONSTRUCTOR TDisasmIndicator.Init(VAR Bounds: TRect);
BEGIN
  INHERITED Init(Bounds);
  GrowMode := gfGrowLoY + gfGrowHiY + gfGrowHiX;
  RegIP := 0;
  RegCarry := FALSE;
  RegVorrat := 0;
END;

PROCEDURE TDisasmIndicator.Draw;
VAR
  B: TDrawBuffer;
  Color: Byte;
  S: String;
BEGIN
  Color := $70;  { Black on grey }
  FillStr(B, '═', Color, Size.X);

  { Format: ══ IP:123 ══ Carry:0 ══ Payload:5 ══ }
  S := ' IP:' + IntToStr(RegIP) + ' ';
  MoveStr(B[2], S, Color);

  IF RegCarry THEN
    S := ' Carry:1 '
  ELSE
    S := ' Carry:0 ';
  MoveStr(B[13], S, Color);

  S := ' ' + tr('Payload') + ':' + IntToStr(RegVorrat) + ' ';
  MoveStr(B[24], S, Color);

  WriteBuf(0, 0, Size.X, 1, B);
END;

PROCEDURE TDisasmIndicator.Update(AIP: Word; ACarry: Boolean; AVorrat: Word);
BEGIN
  IF (RegIP <> AIP) OR (RegCarry <> ACarry) OR (RegVorrat <> AVorrat) THEN
  BEGIN
    RegIP := AIP;
    RegCarry := ACarry;
    RegVorrat := AVorrat;
    DrawView;
  END;
END;

{ TDisasmViewer }

CONSTRUCTOR TDisasmViewer.Init(VAR Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar);
BEGIN
  INHERITED Init(Bounds, AHScrollBar, AVScrollBar);
  LineCount := 0;
  FocusLine := -1;
  ExecLine := -1;
  CursorLine := 0;
  LineMapCount := 0;
  ProgSize := 0;
  GrowMode := gfGrowHiX + gfGrowHiY;
END;

PROCEDURE TDisasmViewer.HandleEvent(VAR Event: TEvent);
VAR
  NewY: Integer;
  ClickLine: Integer;
  Mouse: TPoint;
BEGIN
  INHERITED HandleEvent(Event);

  { Handle mouse clicks }
  IF Event.What = evMouseDown THEN
  BEGIN
    MakeLocal(Event.Where, Mouse);
    ClickLine := Delta.Y + Mouse.Y;
    IF (ClickLine >= 0) AND (ClickLine < LineCount) THEN
    BEGIN
      { Move cursor line to clicked position }
      CursorLine := ClickLine;
      DrawView;

      { Update editor highlight - search backwards for nearest DBG marker }
      WHILE (ClickLine >= 0) AND (Lines[ClickLine].SourceLine = 0) DO
        Dec(ClickLine);
      IF (ClickLine >= 0) AND (Lines[ClickLine].SourceLine > 0) THEN
        Message(Desktop, evBroadcast, cmGotoEditorLine,
          Pointer(PtrUInt(Lines[ClickLine].SourceLine)))
      ELSE
        { No DBG found - assume pseudo DBG #1 before program }
        Message(Desktop, evBroadcast, cmGotoEditorLine, Pointer(PtrUInt(1)));

      ClearEvent(Event);
      Exit;
    END;
  END;

  IF Event.What = evKeyDown THEN
  BEGIN
    { Enter key: jump to source line }
    IF Event.KeyCode = kbEnter THEN
    BEGIN
      IF (CursorLine >= 0) AND (CursorLine < LineCount) THEN
      BEGIN
        { Search backwards for nearest DBG marker, default to line 1 }
        ClickLine := CursorLine;
        WHILE (ClickLine >= 0) AND (Lines[ClickLine].SourceLine = 0) DO
          Dec(ClickLine);
        IF (ClickLine >= 0) AND (Lines[ClickLine].SourceLine > 0) THEN
          Message(Desktop, evBroadcast, cmGotoEditorLine,
            Pointer(PtrUInt(Lines[ClickLine].SourceLine)))
        ELSE
          { No DBG found - assume pseudo DBG #1 before program }
          Message(Desktop, evBroadcast, cmGotoEditorLine, Pointer(PtrUInt(1)));
      END;
      ClearEvent(Event);
      Exit;
    END;

    NewY := CursorLine;
    CASE Event.KeyCode OF
      kbUp:    Dec(NewY);
      kbDown:  Inc(NewY);
      kbPgUp:  Dec(NewY, Size.Y - 1);
      kbPgDn:  Inc(NewY, Size.Y - 1);
      kbHome:  NewY := 0;
      kbEnd:   NewY := LineCount - 1;
    ELSE
      Exit;
    END;

    { Clamp to valid range }
    IF NewY < 0 THEN NewY := 0;
    IF NewY >= LineCount THEN NewY := LineCount - 1;
    IF NewY < 0 THEN NewY := 0;

    IF NewY <> CursorLine THEN
    BEGIN
      CursorLine := NewY;
      { Keep cursor in middle of window by scrolling }
      NewY := CursorLine - Size.Y DIV 2;
      IF NewY < 0 THEN NewY := 0;
      IF NewY > LineCount - Size.Y THEN NewY := LineCount - Size.Y;
      IF NewY < 0 THEN NewY := 0;
      ScrollTo(Delta.X, NewY);
      DrawView;

      { Update editor highlight to show corresponding source line }
      ClickLine := CursorLine;
      WHILE (ClickLine >= 0) AND (Lines[ClickLine].SourceLine = 0) DO
        Dec(ClickLine);
      IF (ClickLine >= 0) AND (Lines[ClickLine].SourceLine > 0) THEN
        Message(Desktop, evBroadcast, cmGotoEditorLine,
          Pointer(PtrUInt(Lines[ClickLine].SourceLine)))
      ELSE
        Message(Desktop, evBroadcast, cmGotoEditorLine, Pointer(PtrUInt(1)));
    END;
    ClearEvent(Event);
  END;
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

PROCEDURE TDisasmViewer.DisassembleOp(Addr: Word; VAR Prog: ARRAY OF Byte;
  VAR Mnemonic, Desc: String);
VAR
  Op: Byte;
  Operand: Word;
  OpStr: String;
BEGIN
  Op := Prog[Addr];
  Mnemonic := '';
  Desc := '';

  CASE Op OF
    ocBRK: BEGIN
      Mnemonic := 'BRK';
      Desc := tr('End program');
    END;
    ocJMP: BEGIN
      Operand := Prog[Addr+1] + Prog[Addr+2] * 256;
      Mnemonic := 'JMP ' + IntToStr(Operand);
      Desc := Format(tr('Jump to %d'), [Operand]);
    END;
    ocTURN: BEGIN
      Mnemonic := 'TURN';
      Desc := tr('Turn left');
    END;
    ocGO: BEGIN
      Mnemonic := 'GO';
      Desc := tr('Go forward');
    END;
    ocTAKE: BEGIN
      Mnemonic := 'TAKE';
      Desc := tr('Pick up');
    END;
    ocPUT: BEGIN
      Mnemonic := 'PUT';
      Desc := tr('Put down');
    END;
    ocCALL: BEGIN
      Operand := Prog[Addr+1] + Prog[Addr+2] * 256;
      Mnemonic := 'CALL ' + IntToStr(Operand);
      Desc := Format(tr('Call %d'), [Operand]);
    END;
    ocRET: BEGIN
      Mnemonic := 'RET';
      Desc := tr('Return');
    END;
    ocCVF: BEGIN
      Mnemonic := 'CVF';
      Desc := tr('Check front free');
    END;
    ocCLF: BEGIN
      Mnemonic := 'CLF';
      Desc := tr('Check left free');
    END;
    ocCRF: BEGIN
      Mnemonic := 'CRF';
      Desc := tr('Check right free');
    END;
    ocCPB: BEGIN
      Mnemonic := 'CPB';
      Desc := tr('Check place occupied');
    END;
    ocCV: BEGIN
      Mnemonic := 'CV';
      Desc := tr('Check has supply');
    END;
    ocJNC: BEGIN
      Operand := Prog[Addr+1] + Prog[Addr+2] * 256;
      Mnemonic := 'JNC ' + IntToStr(Operand);
      Desc := Format(tr('Jump if false to %d'), [Operand]);
    END;
    ocJC: BEGIN
      Operand := Prog[Addr+1] + Prog[Addr+2] * 256;
      Mnemonic := 'JC ' + IntToStr(Operand);
      Desc := Format(tr('Jump if true to %d'), [Operand]);
    END;
    ocPUSH: BEGIN
      Mnemonic := 'PUSH';
      Desc := tr('Push flag');
    END;
    ocPOP: BEGIN
      Mnemonic := 'POP';
      Desc := tr('Pop flag');
    END;
    ocSDEC: BEGIN
      Mnemonic := 'SDEC';
      Desc := tr('Decrement stack');
    END;
    ocDEBUG: BEGIN
      Operand := Prog[Addr+1] + Prog[Addr+2] * 256;
      Mnemonic := 'DBG #' + IntToStr(Operand);
      Desc := Format(tr('Source line %d'), [Operand]);
    END;
    ELSE BEGIN
      Str(Op, OpStr);
      Mnemonic := '??? (' + OpStr + ')';
      Desc := tr('Unknown opcode');
    END;
  END;
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
  IP, NameEnd: Word;
  Op: Byte;
  Mnemonic, Desc: String;
  ProgName: String;
  i: Integer;
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

    { After initial JMP, extract program name as data in 4-byte chunks }
    IF (IP = 3) AND (Prog[0] = ocJMP) THEN
    BEGIN
      { Find end of program name - look for DBG opcode }
      NameEnd := IP;
      WHILE (NameEnd < ProgSize) AND (Prog[NameEnd] <> ocDEBUG) DO
        Inc(NameEnd);

      { Output 4-byte chunks }
      WHILE (IP < NameEnd) AND (LineCount < MaxDisasmLines) DO
      BEGIN
        Lines[LineCount].Addr := IP;
        Lines[LineCount].SourceLine := 0;
        Lines[LineCount].HexData := '';
        ProgName := '';

        { Build up to 4 bytes }
        i := 0;
        WHILE (IP + i < NameEnd) AND (i < 4) DO
        BEGIN
          Lines[LineCount].HexData := Lines[LineCount].HexData + IntToHex(Prog[IP + i], 2) + ' ';
          ProgName := ProgName + Chr(Prog[IP + i]);
          Inc(i);
        END;

        Lines[LineCount].Mnemonic := 'DATA ''' + ProgName + '''';
        Lines[LineCount].Desc := tr('Raw data');
        Inc(LineCount);
        IP := IP + i;
      END;
      Continue;
    END;

    DisassembleOp(IP, Prog, Mnemonic, Desc);

    Lines[LineCount].Addr := IP;
    Lines[LineCount].SourceLine := 0;
    Lines[LineCount].Mnemonic := Mnemonic;
    Lines[LineCount].Desc := Desc;

    { Build hex data string for instruction bytes }
    Lines[LineCount].HexData := IntToHex(Prog[IP], 2);
    IF InstructionSize(Op) >= 2 THEN
      Lines[LineCount].HexData := Lines[LineCount].HexData + ' ' + IntToHex(Prog[IP+1], 2);
    IF InstructionSize(Op) >= 3 THEN
      Lines[LineCount].HexData := Lines[LineCount].HexData + ' ' + IntToHex(Prog[IP+2], 2);

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

    { Calculate next instruction address }
    IP := IP + InstructionSize(Op);
    Inc(LineCount);
  END;

  SetLimit(80, LineCount);
  ScrollTo(0, 0);
  DrawView;
END;

PROCEDURE TDisasmViewer.Clear;
BEGIN
  LineCount := 0;
  LineMapCount := 0;
  ProgSize := 0;
  CursorLine := -1;
  ExecLine := -1;
  Delta.X := 0;
  Delta.Y := 0;
  Limit.X := 80;
  Limit.Y := 1;
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
    { Skip past all consecutive DBG markers to first real instruction }
    CursorLine := BestIndex;
    WHILE (CursorLine < LineCount) AND
          (Copy(Lines[CursorLine].Mnemonic, 1, 3) = 'DBG') DO
      Inc(CursorLine);
    IF CursorLine >= LineCount THEN
      CursorLine := BestIndex;

    { Scroll to make cursor line visible }
    IF CursorLine < Delta.Y THEN
      ScrollTo(Delta.X, CursorLine)
    ELSE IF CursorLine >= Delta.Y + Size.Y THEN
      ScrollTo(Delta.X, CursorLine - Size.Y + 1);

    DrawView;
  END;
END;

PROCEDURE TDisasmViewer.FocusAddr(Addr: Word);
VAR
  Idx: Integer;
BEGIN
  Idx := FindLineIndex(Addr);
  IF Idx >= 0 THEN
  BEGIN
    ExecLine := Idx;

    { Scroll to make execution line visible }
    IF ExecLine < Delta.Y THEN
      ScrollTo(Delta.X, ExecLine)
    ELSE IF ExecLine >= Delta.Y + Size.Y THEN
      ScrollTo(Delta.X, ExecLine - Size.Y DIV 2);

    DrawView;
  END;
END;

PROCEDURE TDisasmViewer.Draw;
CONST
  AddrCol = 0;     { Address }
  HexCol = 6;      { Hex data (max 4 bytes = 12 chars) }
  MnemCol = 18;    { Mnemonic }
  DescCol = 36;    { Description }
VAR
  B: TDrawBuffer;
  NormalColor, MnemColor, ExecColor, CursorColor: Byte;
  i, Y: Integer;
  AddrStr: String[6];
  Mnem, Desc: String;
  IsExec, IsCursor: Boolean;
  LineColor: Byte;
BEGIN
  { Colors }
  NormalColor := $78;     { Dark grey on light grey }
  MnemColor := $70;       { Black on light grey }
  ExecColor := $1F;       { White on blue - execution line }
  CursorColor := $0F;     { White on black - cursor line }

  FOR Y := 0 TO Size.Y - 1 DO
  BEGIN
    i := Delta.Y + Y;
    MoveChar(B, ' ', NormalColor, Size.X);

    IF i < LineCount THEN
    BEGIN
      IsExec := (i = ExecLine);
      IsCursor := (i = CursorLine) AND (NOT IsExec);

      { Choose line color: execution > focus > cursor > normal }
      IF IsExec THEN
      BEGIN
        LineColor := ExecColor;
        MoveChar(B, ' ', ExecColor, Size.X);
      END
      ELSE IF IsCursor THEN
      BEGIN
        LineColor := CursorColor;
        MoveChar(B, ' ', CursorColor, Size.X);
      END
      ELSE
        LineColor := NormalColor;

      { Address }
      Str(Lines[i].Addr:4, AddrStr);
      MoveStr(B[AddrCol], AddrStr, LineColor);

      { Hex data }
      MoveStr(B[HexCol], Lines[i].HexData, LineColor);

      { Mnemonic }
      Mnem := Lines[i].Mnemonic;
      IF IsExec OR IsCursor THEN
        MoveStr(B[MnemCol], Mnem, LineColor)
      ELSE
        MoveStr(B[MnemCol], Mnem, MnemColor);

      { Description }
      Desc := Lines[i].Desc;
      MoveStr(B[DescCol], Desc, LineColor);
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

  { Create indicator in bottom frame }
  GetExtent(R);
  R.Assign(2, Size.Y - 1, Size.X - 2, Size.Y);
  Indicator := New(PDisasmIndicator, Init(R));
  Insert(Indicator);

  { Create viewer }
  GetExtent(R);
  Inc(R.A.X);
  Inc(R.A.Y);
  Dec(R.B.X, 2);
  Dec(R.B.Y, 1);
  Viewer := New(PDisasmViewer, Init(R, NIL, VScrollBar));
  Insert(Viewer);

  CurrentFile := '';
END;

FUNCTION TDisasmWindow.GetPalette: PPalette;
CONST
  { Custom grey palette: indices into CAppColor for black on grey }
  { 1=passive frame, 2=passive title, 3=active frame, 4=active title }
  { 5=frame icon, 6=scroller page, 7=scroller controls, 8=reserved }
  { Index 24=$70 (black/grey), 29=$70 (scroller), 30=$7F, 31=$7E }
  P: String[8] = #24#24#24#24#24#29#30#31;
BEGIN
  GetPalette := @P;
END;

PROCEDURE TDisasmWindow.HandleEvent(VAR Event: TEvent);
VAR
  IP: Word;
BEGIN
  { Handle events before inherited to catch them first }
  CASE Event.What OF
    evCommand: CASE Event.Command OF
      cmClose: BEGIN
        Hide;
        ClearEvent(Event);
        Exit;
      END;
    END;
    evBroadcast: CASE Event.Command OF
      cmUpdateDisasm: BEGIN
        IF (Viewer = NIL) OR (Indicator = NIL) THEN
        BEGIN
          ClearEvent(Event);
          Exit;
        END;
        IF DisasmFileName <> '' THEN
        BEGIN
          CurrentFile := DisasmFileName;
          Viewer^.LoadFile(CurrentFile);
          Viewer^.ExecLine := -1;
          Indicator^.Update(0, FALSE, 0);
        END
        ELSE
        BEGIN
          { Clear disasm when editor is dirty - just set data, no view calls }
          CurrentFile := '';
          Viewer^.Clear;
          Indicator^.RegIP := 0;
          Indicator^.RegCarry := FALSE;
          Indicator^.RegVorrat := 0;
        END;
        ClearEvent(Event);
        Exit;
      END;
      cmSyncDisasm: BEGIN
        IF (Viewer <> NIL) AND (Viewer^.LineMapCount > 0) THEN
          Viewer^.FocusSourceLine(Word(PtrUInt(Event.InfoPtr)));
        ClearEvent(Event);
        Exit;
      END;
      cmUpdateDisasmIP: BEGIN
        IF (Viewer = NIL) OR (Indicator = NIL) THEN
        BEGIN
          ClearEvent(Event);
          Exit;
        END;
        { InfoPtr contains packed value: (Carry SHL 32) OR (Vorrat SHL 16) OR IP }
        IP := Word(PtrUInt(Event.InfoPtr) AND $FFFF);
        Indicator^.Update(IP,
          (PtrUInt(Event.InfoPtr) AND $100000000) <> 0,
          Word((PtrUInt(Event.InfoPtr) SHR 16) AND $FFFF));
        Viewer^.FocusAddr(IP);
        ClearEvent(Event);
        Exit;
      END;
    END;
  END;

  INHERITED HandleEvent(Event);
END;

END.
