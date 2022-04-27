SELECT
  mysql.default.HistogramBin(j.pt, 15, 60, 100) AS x,
  COUNT(*) AS y
FROM {input_table}
CROSS JOIN UNNEST(Jet) AS j
WHERE abs(eta) < 1
GROUP BY mysql.default.HistogramBin(j.pt, 15, 60, 100)
ORDER BY x;
