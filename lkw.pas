PROGRAM Truck;

PROCEDURE Turn_Right;
BEGIN
  Turn_Left;
  Turn_Left;
  Turn_Left;
END;

PROCEDURE Find_Truck;
BEGIN
  Turn_Left;
  REPEAT Forward UNTIL NOT Front_Clear;
  Turn_Left;
  Forward;
  Turn_Right;
  Forward;
END;

PROCEDURE Next_Side;
BEGIN
  Forward;
  Turn_Right;
  Forward;
  Forward;
  Turn_Right;
  Forward;
END;

PROCEDURE Next_Box;
BEGIN
  REPEAT Forward UNTIL NOT Front_Clear;
  Turn_Left;
  Forward;
END;

PROCEDURE Big_Truck;
BEGIN
  Pick_Up;
  Pick_Up;
  Find_Truck;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Next_Side;
  Put_Down;
  Forward;
  Put_Down;
  Forward;
  Put_Down;
  Next_Box;
END;

PROCEDURE Small_Truck;
BEGIN
  Find_Truck;
  Put_Down;
  Forward;
  Put_Down;
  Next_Side;
  Put_Down;
  Forward;
  Put_Down;
  Next_Box;
END;

PROCEDURE Four_Or_Six;
BEGIN
  Pick_Up;
  Pick_Up;
  Pick_Up;
  Pick_Up;
  IF Space_Occupied THEN Big_Truck;
  IF NOT Space_Occupied THEN Small_Truck;
END;

PROCEDURE Return_Path;
BEGIN
  Turn_Left;
  Forward;
  Turn_Left;
  WHILE Front_Clear DO Forward;
  Turn_Left;
  Forward;
  Turn_Left;
END;

BEGIN
  Forward;
  Forward;
  WHILE Space_Occupied DO Four_Or_Six;
  Return_Path;
END.
