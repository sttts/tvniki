UNIT NikiStrings;

{ Simple translation support for tvNiki
  Usage: tr('English string') returns translated string or original }

INTERFACE

FUNCTION tr(const s: String): String;
FUNCTION GetCurrentLang: String;
PROCEDURE LoadTranslation(const LangCode: String);
PROCEDURE InitTranslation;

IMPLEMENTATION

USES Classes, SysUtils, Dos;

VAR
  Translations: TStringList;
  CurrentLang: String;

FUNCTION tr(const s: String): String;
VAR
  idx: Integer;
BEGIN
  IF Translations <> NIL THEN
  BEGIN
    idx := Translations.IndexOfName(s);
    IF idx >= 0 THEN
    BEGIN
      tr := Translations.ValueFromIndex[idx];
      Exit;
    END;
  END;
  tr := s;
END;

FUNCTION GetCurrentLang: String;
BEGIN
  GetCurrentLang := CurrentLang;
END;

PROCEDURE LoadTranslation(const LangCode: String);
VAR
  FileName: String;
  Lines: TStringList;
  i: Integer;
  Line: String;
BEGIN
  CurrentLang := LangCode;

  IF Translations = NIL THEN
    Translations := TStringList.Create
  ELSE
    Translations.Clear;

  Translations.NameValueSeparator := '=';

  { Look for translation file: niki.de.txt, niki.en.txt, etc. }
  FileName := 'niki.' + LangCode + '.txt';
  IF FileExists(FileName) THEN
  BEGIN
    Lines := TStringList.Create;
    Lines.LoadFromFile(FileName);
    FOR i := 0 TO Lines.Count - 1 DO
    BEGIN
      Line := Lines[i];
      { Skip empty lines and comments }
      IF (Length(Line) > 0) AND (Line[1] <> '#') THEN
        Translations.Add(Line);
    END;
    Lines.Free;
  END;
END;

PROCEDURE InitTranslation;
VAR
  Lang: String;
BEGIN
  { Get language from LANG env var (e.g., "de_DE.UTF-8" -> "de") }
  Lang := GetEnv('LANG');
  IF Length(Lang) >= 2 THEN
    Lang := LowerCase(Copy(Lang, 1, 2))
  ELSE
    Lang := 'en';
  LoadTranslation(Lang);
END;

INITIALIZATION
  Translations := NIL;
  CurrentLang := 'en';

FINALIZATION
  IF Translations <> NIL THEN
    Translations.Free;

END.
