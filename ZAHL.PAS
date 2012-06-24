PROGRAM Nummern_raten;
 
PROCEDURE drehe_rechts;
BEGIN
 drehe_links;
 drehe_links;
 drehe_links;
END;
 
PROCEDURE reihe;
BEGIN
 gib_ab;
 vor;
 gib_ab;
 vor;
 gib_ab;
 vor;
 gib_ab;
 vor;
 gib_ab;
END;
 
PROCEDURE mitte;
BEGIN
 gib_ab;
 vor;
 vor;
 gib_ab;
 vor;
 vor;
 gib_ab;
END;
 
PROCEDURE hinweg;
BEGIN
 drehe_links;
 drehe_links;
 vor;
 drehe_rechts;
 vor;
 vor;
 vor;
 drehe_rechts;
 vor;
 vor;
 vor;
 drehe_links;
 vor;
END;
 
PROCEDURE Zahl0;
BEGIN
 hinweg;
 reihe;
 drehe_rechts;
 vor;
 drehe_rechts;
 gib_ab;
 vor;
 vor;
 vor;
 vor;
 gib_ab;
 drehe_links;
 vor;
 drehe_links;
 reihe;
 vor;
END;
 
PROCEDURE Zahl1;
BEGIN
 hinweg;
 drehe_rechts;
 vor;
 vor;
 drehe_links;
 reihe;
 vor;
END;
 
PROCEDURE Zahl2;
BEGIN
 hinweg;
 gib_ab;
 vor;
 gib_ab;
 vor;
 gib_ab;
 vor;
 vor;
 gib_ab;
 drehe_rechts;
 vor;
 drehe_rechts;
 mitte;
 drehe_links;
 vor;
 drehe_links;
 gib_ab;
 vor;
 vor;
 gib_ab;
 vor;
 gib_ab;
 vor;
 gib_ab;
 vor;
END;
 
PROCEDURE Zahl3;
BEGIN
 hinweg;
 mitte;
 drehe_rechts;
 vor;
 drehe_rechts;
 mitte;
 drehe_links;
 vor;
 drehe_links;
 reihe;
 vor;
END;
 
PROCEDURE Zahl4;
BEGIN
 hinweg;
 vor;
 vor;
 gib_ab;
 vor;
 gib_ab;
 vor;
 gib_ab;
 drehe_rechts;
 vor;
 drehe_rechts;
 vor;
 vor;
 gib_ab;
 vor;
 vor;
 drehe_links;
 vor;
 drehe_links;
 reihe;
 vor;
END;
 
PROCEDURE Zahl5;
BEGIN
 hinweg;
 gib_ab;
 vor;
 vor;
 gib_ab;
 vor;
 gib_ab;
 vor;
 gib_ab;
 drehe_rechts;
 vor;
 drehe_rechts;
 mitte;
 drehe_links;
 vor;
 drehe_links;
 gib_ab;
 vor;
 gib_ab;
 vor;
 gib_ab;
 vor;
 vor;
 gib_ab;
 vor;
END;
 
PROCEDURE Zahl6;
BEGIN
 hinweg;
 reihe;
 drehe_rechts;
 vor;
 drehe_rechts;
 mitte;
 drehe_links;
 vor;
 drehe_links;
 gib_ab;
 vor;
 gib_ab;
 vor;
 gib_ab;
 vor;
 vor;
 gib_ab;
 vor;
END;
 
PROCEDURE Zahl7;
BEGIN
 hinweg;
 vor;
 vor;
 vor;
 vor;
 gib_ab;
 drehe_rechts;
 vor;
 drehe_rechts;
 gib_ab;
 vor;
 vor;
 vor;
 vor;
 drehe_links;
 vor;
 drehe_links;
 reihe;
 vor;
END;
 
PROCEDURE Zahl8;
BEGIN
 hinweg;
 reihe;
 drehe_rechts;
 vor;
 drehe_rechts;
 mitte;
 drehe_links;
 vor;
 drehe_links;
 reihe;
 vor;
END;
 
PROCEDURE Zahl9;
BEGIN
 hinweg;
 gib_ab;
 vor;
 vor;
 gib_ab;
 vor;
 gib_ab;
 vor;
 gib_ab;
 drehe_rechts;
 vor;
 drehe_rechts;
 mitte;
 drehe_links;
 vor;
 drehe_links;
 reihe;
 vor;
END;
 
PROCEDURE rueckweg;
BEGIN
 drehe_links;
 vor;
 vor;
 vor;
 drehe_links;
 WHILE vorne_frei DO vor;
 drehe_rechts;
 vor;
 vor;
 drehe_links;
 vor;
 vor;
 vor;
 drehe_rechts;
 vor;
 drehe_links;
 drehe_links;
END;
 
PROCEDURE welche_Zahl;
BEGIN
 IF NOT Platz_belegt THEN Zahl0;
 IF Platz_belegt THEN
 BEGIN
  nimm_auf;
  IF NOT Platz_belegt THEN Zahl1;
  IF Platz_belegt THEN
  BEGIN
   nimm_auf;
   IF NOT Platz_belegt THEN Zahl2;
   IF Platz_belegt THEN
   BEGIN
    nimm_auf;
    IF NOT Platz_belegt THEN Zahl3;
    IF Platz_belegt THEN
    BEGIN
     nimm_auf;
     IF NOT Platz_belegt THEN Zahl4;
     IF Platz_belegt THEN
     BEGIN
      nimm_auf;
      IF NOT Platz_belegt THEN Zahl5;
      IF Platz_belegt THEN
      BEGIN
       nimm_auf;
       IF NOT Platz_belegt THEN Zahl6;
       IF Platz_belegt THEN
       BEGIN
        nimm_auf;
        IF NOT Platz_belegt THEN Zahl7;
        IF Platz_belegt THEN
        BEGIN
         nimm_auf;
         IF NOT Platz_belegt THEN Zahl8;
          IF Platz_belegt THEN
         BEGIN
          nimm_auf;
          IF NOT Platz_belegt THEN Zahl9;
         END;
        END;
       END;
      END;
     END;
    END;
   END;
  END;
 END;
END;
 
 
 
BEGIN
 vor;
 vor;
 welche_Zahl;
 rueckweg;
END.