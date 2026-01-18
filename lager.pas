PROGRAM Warehouse;

PROCEDURE Go_To_Wall;
BEGIN
  WHILE Front_Clear DO Forward;
END;

PROCEDURE Turn_Right;
BEGIN
  Turn_Left;
  Turn_Left;
  Turn_Left;
END;

PROCEDURE Turn_Around;
BEGIN
  Turn_Left;
  Turn_Left;
END;

PROCEDURE Go_To_Stack;
BEGIN
  Turn_Left;
  Go_To_Wall;
  Turn_Left;
  Forward;
  Turn_Around;
END;

PROCEDURE Back;
BEGIN
  Forward;
  Turn_Right;
  Go_To_Wall;
  Turn_Left;
END;

PROCEDURE Fetch;
BEGIN
  Go_To_Stack;
  WHILE Space_Occupied DO Pick_Up;
  Back;
END;

PROCEDURE Store;
BEGIN
  IF Has_Supply THEN
  BEGIN
    Turn_Left;
    Forward;
    Put_Down;
    Turn_Around;
    Forward;
    Turn_Left;
  END;
END;

PROCEDURE Deliver;
BEGIN
  Go_To_Stack;
  WHILE Has_Supply DO Put_Down;
  Back;
END;

BEGIN
  Fetch;
  WHILE Front_Clear DO
  BEGIN
    Forward;
    Forward;
    Store;
  END;

  Turn_Around;
  Go_To_Wall;
  Turn_Around;
  IF Has_Supply THEN Deliver;
END.
