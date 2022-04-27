WITH RunWithTriJets AS (
  SELECT *,
    (SELECT
        AddPtEtaPhiM3(STRUCT(j1.Pt, j1.Eta, j1.Phi, j1.Mass),
                      STRUCT(j2.Pt, j2.Eta, j2.Phi, j2.Mass),
                      STRUCT(j3.Pt, j3.Eta, j3.Phi, j3.Mass)) AS triJet
     FROM UNNEST(Jet) j1 WITH OFFSET i,
          UNNEST(Jet) j2 WITH OFFSET j,
          UNNEST(Jet) j3 WITH OFFSET k
     WHERE i < j AND j < k
     ORDER BY abs(triJet.mass - 172.5) ASC
     LIMIT 1) AS triJet
  FROM `{bigquery_dataset}.{input_table}`
  WHERE ARRAY_LENGTH(Jet) >= 3
)
SELECT
  HistogramBin(triJet.Pt, 15, 40, 100) AS x,
  COUNT(*) AS y
FROM RunWithTriJets
GROUP BY x
ORDER BY x
