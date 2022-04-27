SELECT
  HistogramBin(MET.pt, 0, 2000, 100) AS x,
  COUNT(*) AS y
FROM `{bigquery_dataset}.{input_table}`
WHERE ARRAY_LENGTH(Muon) >= 2 AND
  (SELECT COUNT(*) AS mass
   FROM UNNEST(Muon) m1 WITH OFFSET i
   CROSS JOIN UNNEST(Muon) m2 WITH OFFSET j
   WHERE
     m1.charge <> m2.charge AND i < j AND
     SQRT(2*m1.pt*m2.pt*(COSH(m1.eta-m2.eta)-COS(m1.phi-m2.phi))) BETWEEN 60 AND 120) > 0
GROUP BY x
ORDER BY x
