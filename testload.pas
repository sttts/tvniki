program TestLoad;
{ Unit test for .ROB field file loading - mimics TFeld exactly }

uses Objects, SysUtils;

const
  SizeX = 61;
  SizeY = 21;

type
  TChar = record
    z: String[4];
    f: Byte;
  end;

var
  Feld: array[0..SizeY-1, 0..SizeX-1] of TChar;
  FileName: String;
  TestsPassed, TestsFailed: Integer;

{ === CP437 conversion functions (copied from nikiflwn.pas) === }

function CP437toUTF8(c: Byte): String;
begin
  case c of
    $B3: CP437toUTF8 := '│';
    $C4: CP437toUTF8 := '─';
    $DA: CP437toUTF8 := '┌';
    $BF: CP437toUTF8 := '┐';
    $C0: CP437toUTF8 := '└';
    $D9: CP437toUTF8 := '┘';
    $C3: CP437toUTF8 := '├';
    $B4: CP437toUTF8 := '┤';
    $C2: CP437toUTF8 := '┬';
    $C1: CP437toUTF8 := '┴';
    $C5: CP437toUTF8 := '┼';
    $FA: CP437toUTF8 := '·';
    $F9: CP437toUTF8 := '·';
    $10: CP437toUTF8 := '►';
    $11: CP437toUTF8 := '◄';
    $1E: CP437toUTF8 := '▲';
    $1F: CP437toUTF8 := '▼';
  else
    CP437toUTF8 := Chr(c);
  end;
end;

function UTF8toCP437(s: String): Byte;
begin
  if s = '│' then UTF8toCP437 := $B3
  else if s = '─' then UTF8toCP437 := $C4
  else if s = '┌' then UTF8toCP437 := $DA
  else if s = '┐' then UTF8toCP437 := $BF
  else if s = '└' then UTF8toCP437 := $C0
  else if s = '┘' then UTF8toCP437 := $D9
  else if s = '├' then UTF8toCP437 := $C3
  else if s = '┤' then UTF8toCP437 := $B4
  else if s = '┬' then UTF8toCP437 := $C2
  else if s = '┴' then UTF8toCP437 := $C1
  else if s = '┼' then UTF8toCP437 := $C5
  else if s = '·' then UTF8toCP437 := $FA
  else if s = '►' then UTF8toCP437 := $10
  else if s = '◄' then UTF8toCP437 := $11
  else if s = '▲' then UTF8toCP437 := $1E
  else if s = '▼' then UTF8toCP437 := $1F
  else if Length(s) > 0 then UTF8toCP437 := Ord(s[1])
  else UTF8toCP437 := Ord(' ');
end;

{ === Test helpers === }

procedure TestAssert(condition: Boolean; testName: String);
begin
  if condition then
  begin
    WriteLn('  PASS: ', testName);
    Inc(TestsPassed);
  end
  else
  begin
    WriteLn('  FAIL: ', testName);
    Inc(TestsFailed);
  end;
end;

{ === Test: CP437 to UTF8 conversion === }
procedure TestCP437Conversion;
begin
  WriteLn('Test: CP437 to UTF-8 conversion');
  TestAssert(CP437toUTF8($DA) = '┌', 'Top-left corner $DA -> ┌');
  TestAssert(CP437toUTF8($C4) = '─', 'Horizontal $C4 -> ─');
  TestAssert(CP437toUTF8($B3) = '│', 'Vertical $B3 -> │');
  TestAssert(CP437toUTF8($FA) = '·', 'Middle dot $FA -> ·');
  TestAssert(CP437toUTF8($20) = ' ', 'Space $20 -> space');
  TestAssert(CP437toUTF8($31) = '1', 'Digit 1 $31 -> 1');
end;

{ === Test: UTF8 to CP437 conversion === }
procedure TestUTF8Conversion;
begin
  WriteLn('Test: UTF-8 to CP437 conversion');
  TestAssert(UTF8toCP437('┌') = $DA, 'Top-left corner ┌ -> $DA');
  TestAssert(UTF8toCP437('─') = $C4, 'Horizontal ─ -> $C4');
  TestAssert(UTF8toCP437('│') = $B3, 'Vertical │ -> $B3');
  TestAssert(UTF8toCP437('·') = $FA, 'Middle dot · -> $FA');
  TestAssert(UTF8toCP437(' ') = $20, 'Space -> $20');
  TestAssert(UTF8toCP437('1') = $31, 'Digit 1 -> $31');
end;

{ === Test: Round-trip conversion === }
procedure TestRoundTrip;
var
  original: Byte;
  converted: String;
  back: Byte;
begin
  WriteLn('Test: Round-trip CP437 -> UTF8 -> CP437');
  for original := 0 to 255 do
  begin
    converted := CP437toUTF8(original);
    back := UTF8toCP437(converted);
    if (original in [$B3,$C4,$DA,$BF,$C0,$D9,$C3,$B4,$C2,$C1,$C5,$FA,$F9,$10,$11,$1E,$1F]) or
       (original < 128) then
    begin
      if back <> original then
      begin
        { $F9 maps to same as $FA, that's OK }
        if not ((original = $F9) and (back = $FA)) then
        begin
          WriteLn('  FAIL: Round-trip for $', HexStr(original, 2),
                  ' -> "', converted, '" -> $', HexStr(back, 2));
          Inc(TestsFailed);
          Exit;
        end;
      end;
    end;
  end;
  WriteLn('  PASS: All round-trips successful');
  Inc(TestsPassed);
end;

{ === Test: Load actual .ROB file === }
procedure TestLoadFile(fn: String);
var
  S: TBufStream;
  Id: PShortString;
  x, y: Integer;
  c: Byte;
begin
  WriteLn('Test: Load file "', fn, '"');

  S.Init(fn, stOpen, 2048);
  TestAssert(S.Status = stOk, 'File opens successfully');
  if S.Status <> stOk then
  begin
    WriteLn('    Status = ', S.Status);
    Exit;
  end;

  Id := S.ReadStr;
  TestAssert(Id <> nil, 'ReadStr returns non-nil');
  if Id = nil then
  begin
    S.Done;
    Exit;
  end;

  TestAssert(Id^ = 'FELD', 'File ID is "FELD" (got "' + Id^ + '")');
  DisposeStr(Id);

  { Read field data with conversion }
  for y := 0 to SizeY-1 do
    for x := 0 to SizeX-1 do
    begin
      S.Read(c, 1);
      Feld[y, x].z := CP437toUTF8(c);
    end;

  TestAssert(S.Status = stOk, 'All field data read successfully');
  S.Done;

  { Check some expected values }
  TestAssert(Feld[0, 0].z = '┌', 'Top-left is corner (got "' + Feld[0,0].z + '")');
  TestAssert(Feld[0, 1].z = '─', 'Position [0,1] is horizontal line');

  WriteLn('  First row sample: ', Feld[0,0].z, Feld[0,1].z, Feld[0,2].z, Feld[0,3].z, Feld[0,4].z);
end;

{ === Test all example .ROB files === }
procedure TestAllROBFiles;
const
  ROBFiles: array[0..4] of String = (
    'LABY.ROB',
    'LAGER.ROB',
    'LKW.ROB',
    'CONTAIN1.ROB',
    'ZAHL.ROB'
  );
var
  i: Integer;
begin
  for i := 0 to High(ROBFiles) do
  begin
    if FileExists(ROBFiles[i]) then
    begin
      TestLoadFile(ROBFiles[i]);
      WriteLn;
    end
    else
      WriteLn('Note: ', ROBFiles[i], ' not found, skipping');
  end;
end;

{ === Main === }
begin
  TestsPassed := 0;
  TestsFailed := 0;

  WriteLn('=== TFeld Unit Tests ===');
  WriteLn;

  TestCP437Conversion;
  WriteLn;

  TestUTF8Conversion;
  WriteLn;

  TestRoundTrip;
  WriteLn;

  if ParamCount >= 1 then
  begin
    TestLoadFile(ParamStr(1));
    WriteLn;
  end
  else
  begin
    { Test all example .ROB files }
    TestAllROBFiles;
  end;

  WriteLn('=== Results ===');
  WriteLn('Passed: ', TestsPassed);
  WriteLn('Failed: ', TestsFailed);

  if TestsFailed > 0 then
    Halt(1);
end.
