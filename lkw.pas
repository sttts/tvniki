PROGRAM Lkw;
 
PROCEDURE drehe_rechts;
BEGIN
 drehe_links;
 drehe_links;
 drehe_links;
END;
 
PROCEDURE suche_Lkw;
BEGIN
 drehe_links;
 REPEAT vor UNTIL NOT vorne_frei;
 drehe_links;
 vor;
 drehe_rechts;
 vor;
END;
 
PROCEDURE naechste_Seite;
BEGIN
 vor;
 drehe_rechts;
 vor;
 vor;
 drehe_rechts;
 vor;
END;
 
PROCEDURE naechste_Box;
BEGIN
 REPEAT vor UNTIL NOT vorne_frei;
 drehe_links;
 vor;
END;
 
PROCEDURE gr_Lkw;
BEGIN
 nimm_auf;
 nimm_auf;
 suche_Lkw;
 gib_ab;
 vor;
 gib_ab;
 vor;
 gib_ab;
 naechste_Seite;
 gib_ab;
 vor;
 gib_ab;
 vor;
 gib_ab;
 naechste_Box;
END;
 
PROCEDURE kl_Lkw;
BEGIN
 suche_Lkw;
 gib_ab;
 vor;
 gib_ab;
 naechste_Seite;
 gib_ab;
 vor;
 gib_ab;
 naechste_Box;
END;
 
PROCEDURE vier_oder_sechs;
BEGIN
 nimm_auf;
 nimm_auf;
 nimm_auf;
 nimm_auf;
 IF Platz_belegt THEN gr_Lkw;
 IF NOT Platz_belegt THEN kl_Lkw;
END;
 
PROCEDURE rueckweg;
BEGIN
 drehe_links;
 vor;
 drehe_links;
 WHILE vorne_frei DO vor;
 drehe_links;
 vor;
 drehe_links;
END;
 
BEGIN
 vor;
 vor;
 WHILE Platz_belegt DO vier_oder_sechs;
 rueckweg;
END.
 