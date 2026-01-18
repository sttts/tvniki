PROGRAM Guess_Number;

PROCEDURE Turn_Right;
BEGIN
  Turn_Left;
  Turn_Left;
  Turn_Left;
END;

PROCEDURE Row;
BEGIN
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
END;

PROCEDURE Middle;
BEGIN
  Put_Down;
  Forward;
  Forward;
  Put_Down;
  Forward;
  Forward;
  Put_Down;
END;

PROCEDURE Move_Away;
BEGIN
  Turn_Left;
  Turn_Left;
  Forward;
  Turn_Right;
  Forward;
  Forward;
  Forward;
  Turn_Right;
  Forward;
  Forward;
  Forward;
  Turn_Left;
  Forward;
END;

PROCEDURE Digit0;
BEGIN
  Move_Away;
  Row;
  Turn_Right;
  Forward;
  Turn_Right;
  Put_Down;
  Forward;
  Forward;
  Forward;
  Forward;
  Put_Down;
  Turn_Left;
  Forward;
  Turn_Left;
  Row;
  Forward;
END;

PROCEDURE Digit1;
BEGIN
  Move_Away;
  Turn_Right;
  Forward;
  Forward;
  Turn_Left;
  Row;
  Forward;
END;

PROCEDURE Digit2;
BEGIN
  Move_Away;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Forward;
  Put_Down;
  Turn_Right;
  Forward;
  Turn_Right;
  Middle;
  Turn_Left;
  Forward;
  Turn_Left;
  Put_Down;
  Forward;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
END;

PROCEDURE Digit3;
BEGIN
  Move_Away;
  Middle;
  Turn_Right;
  Forward;
  Turn_Right;
  Middle;
  Turn_Left;
  Forward;
  Turn_Left;
  Row;
  Forward;
END;

PROCEDURE Digit4;
BEGIN
  Move_Away;
  Forward;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Turn_Right;
  Forward;
  Turn_Right;
  Forward;
  Forward;
  Put_Down;
  Forward;
  Forward;
  Turn_Left;
  Forward;
  Turn_Left;
  Row;
  Forward;
END;

PROCEDURE Digit5;
BEGIN
  Move_Away;
  Put_Down;
  Forward;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Turn_Right;
  Forward;
  Turn_Right;
  Middle;
  Turn_Left;
  Forward;
  Turn_Left;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Forward;
  Put_Down;
  Forward;
END;

PROCEDURE Digit6;
BEGIN
  Move_Away;
  Row;
  Turn_Right;
  Forward;
  Turn_Right;
  Middle;
  Turn_Left;
  Forward;
  Turn_Left;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Forward;
  Put_Down;
  Forward;
END;

PROCEDURE Digit7;
BEGIN
  Move_Away;
  Forward;
  Forward;
  Forward;
  Forward;
  Put_Down;
  Turn_Right;
  Forward;
  Turn_Right;
  Put_Down;
  Forward;
  Forward;
  Forward;
  Forward;
  Turn_Left;
  Forward;
  Turn_Left;
  Row;
  Forward;
END;

PROCEDURE Digit8;
BEGIN
  Move_Away;
  Row;
  Turn_Right;
  Forward;
  Turn_Right;
  Middle;
  Turn_Left;
  Forward;
  Turn_Left;
  Row;
  Forward;
END;

PROCEDURE Digit9;
BEGIN
  Move_Away;
  Put_Down;
  Forward;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Turn_Right;
  Forward;
  Turn_Right;
  Middle;
  Turn_Left;
  Forward;
  Turn_Left;
  Row;
  Forward;
END;

PROCEDURE Return_Path;
BEGIN
  Turn_Left;
  Forward;
  Forward;
  Forward;
  Turn_Left;
  WHILE Front_Clear DO Forward;
  Turn_Right;
  Forward;
  Forward;
  Turn_Left;
  Forward;
  Forward;
  Forward;
  Turn_Right;
  Forward;
  Turn_Left;
  Turn_Left;
END;

PROCEDURE Which_Digit;
BEGIN
  IF NOT Space_Occupied THEN Digit0;
  IF Space_Occupied THEN
  BEGIN
    Pick_Up;
    IF NOT Space_Occupied THEN Digit1;
    IF Space_Occupied THEN
    BEGIN
      Pick_Up;
      IF NOT Space_Occupied THEN Digit2;
      IF Space_Occupied THEN
      BEGIN
        Pick_Up;
        IF NOT Space_Occupied THEN Digit3;
        IF Space_Occupied THEN
        BEGIN
          Pick_Up;
          IF NOT Space_Occupied THEN Digit4;
          IF Space_Occupied THEN
          BEGIN
            Pick_Up;
            IF NOT Space_Occupied THEN Digit5;
            IF Space_Occupied THEN
            BEGIN
              Pick_Up;
              IF NOT Space_Occupied THEN Digit6;
              IF Space_Occupied THEN
              BEGIN
                Pick_Up;
                IF NOT Space_Occupied THEN Digit7;
                IF Space_Occupied THEN
                BEGIN
                  Pick_Up;
                  IF NOT Space_Occupied THEN Digit8;
                  IF Space_Occupied THEN
                  BEGIN
                    Pick_Up;
                    IF NOT Space_Occupied THEN Digit9;
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
  Forward;
  Forward;
  Which_Digit;
  Return_Path;
END.
