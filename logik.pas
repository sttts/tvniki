BEGIN
  WHILE Front_Clear AND (Has_Supply OR Right_Clear) DO
  BEGIN
    IF Has_Supply THEN Put_Down;
    Forward;
  END;
END.
