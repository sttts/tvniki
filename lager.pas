PROGRAM Lager;

PROCEDURE Gehe_Bis_Wand;
BEGIN
  WHILE Vorne_Frei DO Vor;
END;

PROCEDURE Drehe_Rechts;
BEGIN
  Drehe_Links;
  Drehe_Links;
  Drehe_Links;
END;

PROCEDURE Drehen;
BEGIN
  Drehe_Links;
  Drehe_Links;
END;

PROCEDURE Gehe_zu_Stapel;
BEGIN
  Drehe_Links;
  Gehe_Bis_Wand;
  Drehe_Links;
  Vor;
  Drehen;
END;

PROCEDURE Zurueck;
BEGIN
  vor;
  Drehe_Rechts;
  Gehe_Bis_Wand;
  Drehe_Links;
END;

PROCEDURE Abholen;
BEGIN
  Gehe_zu_Stapel;
  WHILE Platz_Belegt DO Nimm_Auf;
  Zurueck;
END;

PROCEDURE Einlagern;
BEGIN
  IF Hat_Vorrat THEN
  BEGIN
    Drehe_Links;
    vor;
    Gib_Ab;
    Drehen;
    Vor;
    Drehe_Links;
  END;
END;

PROCEDURE Abliefern;
BEGIN
  Gehe_zu_Stapel;
  WHILE Hat_Vorrat DO Gib_Ab;
  Zurueck;
END;

BEGIN
  Abholen;
  WHILE Vorne_Frei DO
  BEGIN
    Vor;
    Vor;
    Einlagern;
  END;

  Drehen;
  Gehe_Bis_Wand;
  Drehen;
  IF Hat_Vorrat THEN Abliefern;
END.