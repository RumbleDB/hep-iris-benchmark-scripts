SELECT HISTOGRAM_BIN((MET).pt, 0.0, 2000.0, (2000.0 - 0.0) / 100.0) AS x, 
  COUNT(*) AS y
FROM %(input_table)s
GROUP BY x
ORDER BY x;