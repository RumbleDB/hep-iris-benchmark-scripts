-- Compute sum of pt of each matching jet
WITH matching_jets AS (
  SELECT event, SUM(j.pt) AS pt_sum
  FROM {input_table}
  CROSS JOIN UNNEST(Jet) AS j (pt, eta, phi, mass, puId, btag)
  WHERE
    j.pt > 30 AND
    none_match(Electron,
               x -> x.pt > 10 AND
               sqrt( (j.eta - x.eta) * (j.eta - x.eta) +
                     pow( (j.phi - x.phi + pi()) % (2 * pi()) - pi(), 2) ) < 0.4) AND
    none_match(Muon,
               x -> x.pt > 10 AND
               sqrt( (j.eta - x.eta) * (j.eta - x.eta) +
                     pow( (j.phi - x.phi + pi()) % (2 * pi()) - pi(), 2) ) < 0.4)
  GROUP BY event
)
-- Compute the histogram
SELECT
  mysql.default.HistogramBin(pt_sum, 15, 200, 100) AS x,
  COUNT(*) AS y
FROM matching_jets
GROUP BY mysql.default.HistogramBin(pt_sum, 15, 200, 100)
ORDER BY x;
