SELECT
  FLOOR((
    CASE
      WHEN MET.pt < 0 THEN -1
      WHEN MET.pt > 2000 THEN 2001
      ELSE MET.pt
    END) / 20) * 20 + 10 AS x,
  COUNT(*) AS y
FROM {input_table}
GROUP BY FLOOR((
    CASE
      WHEN MET.pt < 0 THEN -1
      WHEN MET.pt > 2000 THEN 2001
      ELSE MET.pt
    END) / 20) * 20 + 10
ORDER BY x;
