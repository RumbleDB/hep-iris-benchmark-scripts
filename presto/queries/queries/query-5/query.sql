WITH temp AS (
  SELECT event, MET.pt, COUNT(*)
  FROM {input_table}
  CROSS JOIN UNNEST(Muon) WITH ORDINALITY
    AS m1 (pt, eta, phi, mass, charge, pfRelIso03_all, pfRelIso04_all, tightId,
           softId, dxy, dxyErr, dz, dzErr, jetIdx, genPartIdx, idx)
  CROSS JOIN UNNEST(Muon) WITH ORDINALITY
    AS m2 (pt, eta, phi, mass, charge, pfRelIso03_all, pfRelIso04_all, tightId,
           softId, dxy, dxyErr, dz, dzErr, jetIdx, genPartIdx, idx)
  WHERE
    cardinality(Muon) > 1 AND
    m1.idx < m2.idx AND
    m1.charge <> m2.charge AND
    SQRT(2 * m1.pt * m2.pt * (COSH(m1.eta - m2.eta) - COS(m1.phi - m2.phi))) BETWEEN 60 AND 120
  GROUP BY event, MET.pt
  HAVING COUNT(*) > 0
)
SELECT
  mysql.default.HistogramBin(pt, 0, 2000, 100) AS x,
  COUNT(*) AS y
FROM temp
GROUP BY mysql.default.HistogramBin(pt, 0, 2000, 100)
ORDER BY x;
