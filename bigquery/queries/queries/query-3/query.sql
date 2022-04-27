SELECT
  HistogramBin(j.pt, 15, 60, 100) AS x,
  COUNT(*) AS y
FROM `{bigquery_dataset}.{input_table}`
CROSS JOIN UNNEST(Jet) AS j
WHERE ABS(eta) < 1
GROUP BY x
ORDER BY x
