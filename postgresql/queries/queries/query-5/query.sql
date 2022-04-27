SELECT HISTOGRAM_BIN((MET).pt, 0.0, 2000.0, (2000.0 - 0.0) / 100.0) AS x,
  COUNT(*) AS y
FROM %(input_table)s AS e
WHERE EXISTS(
  SELECT *
  FROM (SELECT (m).* FROM UNNEST(Muon) WITH ORDINALITY AS m) AS m1,
       (SELECT (m).* FROM UNNEST(Muon) WITH ORDINALITY AS m) AS m2
  WHERE
    m1.ordinality < m2.ordinality AND
    m1.charge != m2.charge AND
    INVARIANT_MASS(m1, m2) BETWEEN 60 AND 120)
GROUP BY x
ORDER BY x;