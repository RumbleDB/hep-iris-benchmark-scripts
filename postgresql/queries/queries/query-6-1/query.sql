WITH EventsWithTriJet AS (
 SELECT *, (
  SELECT ADD_PT_ETA_PHI_M3(j1, j2, j3) AS j123
       FROM (SELECT (j).* FROM UNNEST(Jet) WITH ORDINALITY as j) AS j1,
            (SELECT (j).* FROM UNNEST(Jet) WITH ORDINALITY as j) AS j2,
            (SELECT (j).* FROM UNNEST(Jet) WITH ORDINALITY as j) AS j3
       WHERE j1.ordinality < j2.ordinality AND j2.ordinality < j3.ordinality
       ORDER BY ABS((ADD_PT_ETA_PHI_M3(j1, j2, j3)).mass - 172.5) ASC LIMIT 1) AS triJet
 FROM %(input_table)s
)
SELECT HISTOGRAM_BIN((e.triJet).pt, 15.0, 40.0, (40.0 - 15.0) / 100.0) AS x,
  COUNT(*) AS y
FROM EventsWithTriJet AS e
WHERE triJet IS NOT NULL
GROUP BY x
ORDER BY x;