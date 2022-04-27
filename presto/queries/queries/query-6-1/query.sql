-- Compute the PtEtaPhiM2PxPyPzE for each jet
WITH xyze_jets AS (
  SELECT
    event,
    transform(JET,
              j -> CAST(ROW(j.pt,
                            j.pt * cos(j.phi),
                            j.pt * sin(j.phi),
                            j.pt * ( ( exp(j.eta) - exp(-j.eta) ) / 2.0 ),
                            sqrt(j.pt * cosh(j.eta) * j.pt * cosh(j.eta) + j.mass * j.mass)) AS
                        ROW (pt REAL, x REAL, y REAL, z REAL, e REAL))) AS Jet
  FROM {input_table}
),


-- Compute jet triplets
tri_jets AS (
  SELECT
    event,
    CAST( ROW( m1.pt, m1.x, m1.y, m1.z, m1.e ) AS ROW( pt REAL, x REAL, y REAL, z REAL, e REAL ) ) AS m1,
    CAST( ROW( m2.pt, m2.x, m2.y, m2.z, m2.e ) AS ROW( pt REAL, x REAL, y REAL, z REAL, e REAL ) ) AS m2,
    CAST( ROW( m3.pt, m3.x, m3.y, m3.z, m3.e ) AS ROW( pt REAL, x REAL, y REAL, z REAL, e REAL ) ) AS m3
  FROM xyze_jets
  CROSS JOIN UNNEST(Jet) WITH ORDINALITY AS m1 (pt, x, y, z, e, idx)
  CROSS JOIN UNNEST(Jet) WITH ORDINALITY AS m2 (pt, x, y, z, e, idx)
  CROSS JOIN UNNEST(Jet) WITH ORDINALITY AS m3 (pt, x, y, z, e, idx)
  WHERE m1.idx < m2.idx AND m2.idx < m3.idx
),


-- Compute AddPxPyPzE3 and (partial) PxPyPzE2PtEtaPhiM for each TriJet system
condensed_tri_jet AS (
  SELECT
    event, m1, m2, m3,
    m1.x + m2.x + m3.x AS x,
    m1.y + m2.y + m3.y AS y,
    m1.z + m2.z + m3.z AS z,
    m1.e + m2.e + m3.e AS e,
    (m1.x + m2.x + m3.x) * (m1.x + m2.x + m3.x) AS x2,
    (m1.y + m2.y + m3.y) * (m1.y + m2.y + m3.y) AS y2,
    (m1.z + m2.z + m3.z) * (m1.z + m2.z + m3.z) AS z2,
    (m1.e + m2.e + m3.e) * (m1.e + m2.e + m3.e) AS e2
  FROM tri_jets
),


-- Find the system with the lowest mass
singular_system AS (
  SELECT
    event,
    min_by(
      CAST(sqrt(x2 + y2) AS REAL),
      abs(172.5 - sqrt(e2 - x2 - y2 - z2))
    ) AS tri_jet_pt
  FROM condensed_tri_jet
  GROUP BY event
)


-- Generate the histogram
SELECT
  mysql.default.HistogramBin(tri_jet_pt, 15, 40, 100) AS x,
  COUNT(*) AS y
FROM singular_system
GROUP BY mysql.default.HistogramBin(tri_jet_pt, 15, 40, 100)
ORDER BY x;
