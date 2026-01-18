{$MODE OBJFPC}
{ tvNiki command-line compiler }

PROGRAM NikiC;

USES SysUtils, Compiler, NikiStrings;

VAR
  SourceFile, DestFile: String;
  Debug: Boolean;
  I: Integer;

PROCEDURE ShowHelp;
BEGIN
  Writeln('tvNiki Compiler');
  Writeln;
  Writeln('Usage: nikic [options] <source.pas>');
  Writeln;
  Writeln('Options:');
  Writeln('  -o <file>   Output file (default: source.nik)');
  Writeln('  -d          Include debug info');
  Writeln('  -h, --help  Show this help');
  Halt(0);
END;

BEGIN
  InitTranslation;

  SourceFile := '';
  DestFile := '';
  Debug := False;

  I := 1;
  WHILE I <= ParamCount DO
  BEGIN
    IF (ParamStr(I) = '-h') OR (ParamStr(I) = '--help') THEN
      ShowHelp
    ELSE IF ParamStr(I) = '-d' THEN
      Debug := True
    ELSE IF ParamStr(I) = '-o' THEN
    BEGIN
      Inc(I);
      IF I > ParamCount THEN
      BEGIN
        Writeln(StdErr, 'Error: -o requires an argument');
        Halt(1);
      END;
      DestFile := ParamStr(I);
    END
    ELSE IF ParamStr(I)[1] = '-' THEN
    BEGIN
      Writeln(StdErr, 'Error: Unknown option: ', ParamStr(I));
      Halt(1);
    END
    ELSE
      SourceFile := ParamStr(I);
    Inc(I);
  END;

  IF SourceFile = '' THEN
  BEGIN
    Writeln(StdErr, 'Error: No source file specified');
    Writeln(StdErr, 'Use nikic --help for usage');
    Halt(1);
  END;

  { Default output file: replace .pas with .nik }
  IF DestFile = '' THEN
  BEGIN
    IF LowerCase(ExtractFileExt(SourceFile)) = '.pas' THEN
      DestFile := ChangeFileExt(SourceFile, '.nik')
    ELSE
      DestFile := SourceFile + '.nik';
  END;

  IF Compile(SourceFile, DestFile, Debug) THEN
  BEGIN
    Writeln('Compiled: ', SourceFile, ' -> ', DestFile);
    Halt(0);
  END
  ELSE
  BEGIN
    IF ErrorLine > 0 THEN
      Writeln(StdErr, ErrorFile, ':', ErrorLine, ':', ErrorColumn, ': ', ErrorDescribtion)
    ELSE
      Writeln(StdErr, ErrorFile, ': ', ErrorDescribtion);
    Halt(1);
  END;
END.
