PROGRAM Laby;

PROCEDURE Suche;
BEGIN
  IF Links_Frei THEN
  BEGIN
    Drehe_Links;
    Vor;
  END ELSE
    IF Vorne_Frei THEN Vor 
    ELSE
      IF Rechts_Frei THEN
      BEGIN
        Drehe_Links;
        Drehe_Links;
        Drehe_Links;
        Vor;
      END ELSE
      BEGIN
        Drehe_Links;
        Drehe_Links;
        Vor;
      END;
END;

BEGIN
  WHILE NOT Platz_belegt DO Suche;
END.