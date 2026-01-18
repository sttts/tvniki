PROGRAM Laby;

PROCEDURE Search;
BEGIN
  IF Left_Clear THEN
  BEGIN
    Turn_Left;
    Forward;
  END ELSE
    IF Front_Clear THEN Forward
    ELSE
      IF Right_Clear THEN
      BEGIN
        Turn_Left;
        Turn_Left;
        Turn_Left;
        Forward;
      END ELSE
      BEGIN
        Turn_Left;
        Turn_Left;
        Forward;
      END;
END;

BEGIN
  WHILE NOT Space_Occupied DO Search;
END.
