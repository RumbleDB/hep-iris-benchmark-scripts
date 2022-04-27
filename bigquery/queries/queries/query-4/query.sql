SELECT
  HistogramBin(MET.pt, 0, 2000, 100) AS x,
  COUNT(*) AS y
FROM `{bigquery_dataset}.{input_table}`
WHERE (SELECT COUNT(*) FROM UNNEST(JET) WHERE pt > 40) > 1
GROUP BY x
ORDER BY x
