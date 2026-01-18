UNIT NikiStrings;

{ Simple translation support for tvNiki
  Usage: tr('English string') returns translated string or original }

INTERFACE

FUNCTION tr(const s: String): String;
PROCEDURE LoadTranslation(const LangCode: String);

IMPLEMENTATION

USES Classes, SysUtils;

VAR
  Translations: TStringList;

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

PROCEDURE LoadTranslation(const LangCode: String);
VAR
  FileName: String;
BEGIN
  IF Translations = NIL THEN
    Translations := TStringList.Create
  ELSE
    Translations.Clear;

  { Look for translation file: niki.de.txt, niki.en.txt, etc. }
  FileName := 'niki.' + LangCode + '.txt';
  IF FileExists(FileName) THEN
  BEGIN
    Translations.LoadFromFile(FileName);
    Translations.NameValueSeparator := '=';
  END;
END;

INITIALIZATION
  Translations := NIL;

FINALIZATION
  IF Translations <> NIL THEN
    Translations.Free;

END.
