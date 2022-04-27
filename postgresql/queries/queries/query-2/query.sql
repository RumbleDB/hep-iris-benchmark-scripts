SELECT HISTOGRAM_BIN((j).pt, 15.0, 60.0, (60.0 - 15.0) / 100.0) AS x, 
  COUNT(*) AS y
FROM %(input_table)s CROSS JOIN UNNEST(Jet) as j
GROUP BY x
ORDER BY x;
