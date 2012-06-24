BEGIN 
  WHILE vorne_frei AND (hat_vorrat OR rechts_frei) DO 
  BEGIN
    IF hat_Vorrat THEN Gib_Ab;
    Vor;
  END;
END.