WITH EventsWithLeptons AS (
  SELECT e.*, 
    array_cat(
      (SELECT array_agg(CAST(ROW(x.pt, x.eta, x.phi, x.mass, x.charge, 'm') AS leptonType)) FROM UNNEST(e.Muon) as x),
      (SELECT array_agg(CAST(ROW(x.pt, x.eta, x.phi, x.mass, x.charge, 'e') AS leptonType)) FROM UNNEST(e.Electron) as x)) AS Lepton
  FROM %(input_table)s AS e
), EventsWithTriLeptons AS (
  SELECT e.*, l1, l2, 
      (SELECT CAST(ROW(l3.pt, l3.eta, l3.phi, l3.mass, l3.charge, 'x') AS leptonType)
        FROM UNNEST(e.Lepton) WITH ORDINALITY AS l3(pt, eta, phi, mass, charge, type, idx)
        WHERE 
        CAST(l3.idx AS int) != l1.idx AND 
        CAST(l3.idx AS int) != l2.idx
        ORDER BY l3.pt DESC
        LIMIT 1) AS l3
  FROM EventsWithLeptons AS e
  CROSS JOIN UNNEST(e.Lepton) WITH ORDINALITY AS l1(pt, eta, phi, mass, charge, type, idx)
  CROSS JOIN UNNEST(e.Lepton) WITH ORDINALITY AS l2(pt, eta, phi, mass, charge, type, idx)
  WHERE
    ARRAY_LENGTH(e.Lepton, 1) > 2 AND
    l1.idx < l2.idx AND
    l1.charge != l2.charge AND
    l1.type = l2.type
), EventsWithTriLeptonsRanked AS (
  SELECT MET, l3, RANK() OVER (PARTITION BY event ORDER BY ABS(91.2 - (ADD_PT_ETA_PHI_M2(l1, l2)).mass)) r 
  FROM EventsWithTriLeptons
)
SELECT HISTOGRAM_BIN(SQRT(2 * (e.MET).pt * (e.l3).pt * (1.0 - 
  COS(DELTA_PHI((e.MET).phi, (e.l3).phi)))), 15.0, 250.0, (250.0 - 15.0) / 
  100.0) AS x, COUNT(*) AS y
FROM EventsWithTriLeptonsRanked as e
WHERE e.r = 1
GROUP BY x
ORDER BY x;