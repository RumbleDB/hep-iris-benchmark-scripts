WITH RunWithTriJets AS (
  SELECT *,
    (SELECT AS STRUCT
        [j1, j2, j3] AS jets,
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
),
MaxBTags AS (
  SELECT (SELECT MAX(tj.btag) FROM UNNEST(triJet.jets) AS tj) AS maxBtag
  FROM RunWithTriJets
)
SELECT
  HistogramBin(maxBtag, 0, 1, 100) AS x,
  COUNT(*) AS y
FROM MaxBTags
GROUP BY x
ORDER BY x
