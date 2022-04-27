-- Make the structure of Electrons and Muons uniform, and then union their arrays
WITH uniform_structure_leptons AS (
  SELECT
    event,
    MET,
    array_union(
      transform(
        COALESCE(Muon, ARRAY []),
        x -> CAST( ROW(x.pt, x.eta, x.phi, x.mass, x.charge, 'm') AS ROW( pt REAL, eta REAL, phi REAL, mass REAL, charge INTEGER, type CHAR ) )
      ),
      transform(
        COALESCE(Electron, ARRAY []),
        x -> CAST( ROW(x.pt, x.eta, x.phi, x.mass, x.charge, 'e') AS ROW( pt REAL, eta REAL, phi REAL, mass REAL, charge INTEGER, type CHAR ) )
      )
    ) AS Leptons
  FROM {input_table}
  WHERE cardinality(Muon) + cardinality(Electron) > 2
),


-- Create the Lepton pairs, transform the leptons using PtEtaPhiM2PxPyPzE and then sum the transformed leptons
lepton_pairs AS (
  SELECT
    *,
    CAST(
      ROW(
        pt1 * cos(phi1) + pt2 * cos(phi2),
        pt1 * sin(phi1) + pt2 * sin(phi2),
        pt1 * ( ( exp(eta1) - exp(-eta1) ) / 2.0 ) + pt2 * ( ( exp(eta2) - exp(-eta2) ) / 2.0 ),
        sqrt(pt1 * cosh(eta1) * pt1 * cosh(eta1) + mass1 * mass1) + sqrt(pt2 * cosh(eta2) * pt2 * cosh(eta2) + mass2 * mass2)
      ) AS
      ROW (x REAL, y REAL, z REAL, e REAL)
    ) AS l,
    idx1 AS l1_idx,
    idx2 AS l2_idx
  FROM uniform_structure_leptons
  CROSS JOIN UNNEST(Leptons) WITH ORDINALITY AS l1 (pt1, eta1, phi1, mass1, charge1, type1, idx1)
  CROSS JOIN UNNEST(Leptons) WITH ORDINALITY AS l2 (pt2, eta2, phi2, mass2, charge2, type2, idx2)
  WHERE idx1 < idx2 AND type1 = type2 AND charge1 != charge2
),


-- Apply the PtEtaPhiM2PxPyPzE transformation on the particle pairs, then retrieve the one with the mass closest to 91.2 for each event
processed_pairs AS (
  SELECT
    event,
    min_by(
      ROW(
        l1_idx,
        l2_idx,
        Leptons,
        MET.pt,
        MET.phi
      ),
      abs(91.2 - sqrt(l.e * l.e - l.x * l.x - l.y * l.y - l.z * l.z))
    ) AS system
  FROM lepton_pairs
  GROUP BY event
),


-- For each event get the max pt of the other leptons
other_max_pt AS (
  SELECT event, CAST(max_by(sqrt(2 * system[4] * pt * (1.0 - cos((system[5]- phi + pi()) % (2 * pi()) - pi()))), pt) AS REAL) AS pt
  FROM processed_pairs
  CROSS JOIN UNNEST(system[3]) WITH ORDINALITY AS l (pt, eta, phi, mass, charge, type, idx)
  WHERE idx != system[1] AND idx != system[2]
  GROUP BY event
)


-- Compute the histogram
SELECT
  mysql.default.HistogramBin(pt, 15, 250, 100) AS x,
  COUNT(*) AS y
FROM other_max_pt
GROUP BY mysql.default.HistogramBin(pt, 15, 250, 100)
ORDER BY x;
