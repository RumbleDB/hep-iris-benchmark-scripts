WITH temp AS (
  SELECT event, MET.pt, COUNT(*)
  FROM {input_table}
  CROSS JOIN UNNEST(Muon) WITH ORDINALITY AS _m1(m1, idx1)
  CROSS JOIN UNNEST(Muon) WITH ORDINALITY AS _m2(m2, idx2)
  WHERE
    cardinality(Muon) > 1 AND
    idx1 < idx2
    AND m1.charge <> m2.charge AND
    SQRT(2 * m1.pt * m2.pt * (COSH(m1.eta - m2.eta) - COS(m1.phi - m2.phi))) BETWEEN 60 AND 120
  GROUP BY event, MET.pt
  HAVING COUNT(*) > 0
)
SELECT
  FLOOR((
    CASE
      WHEN pt < 0 THEN -1
      WHEN pt > 2000 THEN 2001
      ELSE pt
    END) / 20) * 20 + 10 AS x,
  COUNT(*) AS y
FROM temp
GROUP BY FLOOR((
    CASE
      WHEN pt < 0 THEN -1
      WHEN pt > 2000 THEN 2001
      ELSE pt
    END) / 20) * 20 + 10
ORDER BY x;
