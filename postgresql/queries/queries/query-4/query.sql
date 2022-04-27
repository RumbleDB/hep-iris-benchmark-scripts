SELECT HISTOGRAM_BIN((MET).pt, 0.0, 2000.0, (2000.0 - 0.0) / 100.0) AS x,
        COUNT(*) AS y
FROM %(input_table)s 
WHERE (SELECT COUNT(*) FROM UNNEST(Jet) AS j
       WHERE (j).pt > 40) > 1
GROUP BY x
ORDER BY x;