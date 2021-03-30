import re

# The query to be analyzed
query = """
CREATE TEMP FUNCTION PtEtaPhiM2PxPyPzE(pepm STRUCT<Pt FLOAT64, Eta FLOAT64, Phi FLOAT64, Mass FLOAT64>) AS
  (STRUCT(pepm.Pt * cos(pepm.Phi) AS x,
          pepm.Pt * sin(pepm.Phi) AS y,
          pepm.Pt * sinh(pepm.Eta) AS z,
          sqrt((pepm.Pt * cosh(pepm.Eta))*(pepm.Pt * cosh(pepm.Eta)) + pepm.Mass * pepm.Mass) AS e));
CREATE TEMP FUNCTION RhoZ2Eta(Rho FLOAT64, Z FLOAT64) AS
  (log(Z/Rho + sqrt(Z/Rho * Z/Rho + 1.0)));
CREATE TEMP FUNCTION PxPyPzE2PtEtaPhiM(xyzt STRUCT<X FLOAT64, Y FLOAT64, Z FLOAT64, T FLOAT64>) AS
  (STRUCT(sqrt(xyzt.X*xyzt.X + xyzt.Y*xyzt.Y) AS Pt,
          RhoZ2Eta(sqrt(xyzt.X*xyzt.X + xyzt.Y*xyzt.Y), xyzt.z) AS Eta,
          CASE WHEN (xyzt.X = 0.0 AND xyzt.Y = 0.0) THEN 0 ELSE atan2(xyzt.Y, xyzt.X) END AS Phi,
          sqrt(xyzt.T*xyzt.T - xyzt.X*xyzt.X - xyzt.Y*xyzt.Y - xyzt.Z*xyzt.Z) AS Mass));
CREATE TEMP FUNCTION AddPxPyPzE2(
    xyzt1 STRUCT<X FLOAT64, Y FLOAT64, Z FLOAT64, T FLOAT64>,
    xyzt2 STRUCT<X FLOAT64, Y FLOAT64, Z FLOAT64, T FLOAT64>) AS
  (STRUCT(xyzt1.X + xyzt2.X AS X,
          xyzt1.Y + xyzt2.Y AS Y,
          xyzt1.Z + xyzt2.Z AS Z,
          xyzt1.T + xyzt2.T AS T));
CREATE TEMP FUNCTION AddPtEtaPhiM2(
    pepm1 STRUCT<Pt FLOAT64, Eta FLOAT64, Phi FLOAT64, Mass FLOAT64>,
    pepm2 STRUCT<Pt FLOAT64, Eta FLOAT64, Phi FLOAT64, Mass FLOAT64>) AS
  (PxPyPzE2PtEtaPhiM(
     AddPxPyPzE2(
       PtEtaPhiM2PxPyPzE(pepm1),
       PtEtaPhiM2PxPyPzE(pepm2))));
CREATE TEMP FUNCTION Pi() AS (ACOS(-1));
CREATE TEMP FUNCTION FMod(x ANY TYPE, y ANY TYPE) AS
  (x - TRUNC(x/y) * y);
CREATE TEMP FUNCTION FMod2Pi(x ANY TYPE) AS
  (FMod(x, 2 * Pi()));
CREATE TEMP FUNCTION DeltaPhi(p1 ANY TYPE, p2 ANY TYPE) AS (
  FMod2Pi(p1.Phi - p2.Phi + Pi()) - Pi()
);
WITH Leptons AS (
  SELECT
    *,
    nMuon + nElectron AS nLepton,
    ARRAY(
      SELECT AS STRUCT
        Pt, Eta, Phi, Mass, Charge, "m" AS Type
      FROM UNNEST(Muon)
      UNION ALL
      SELECT AS STRUCT
        Pt, Eta, Phi, Mass, Charge, "e" AS Type
      FROM UNNEST(Electron)
    ) AS Lepton
  FROM root_playground.Run2012B_SingleMu_small_JetsMuonsElectrons
),
TriLeptionsWithOtherLepton AS (
  SELECT
    *,
    (
      SELECT AS STRUCT
        i1, i2,
        (
          SELECT AS STRUCT
            *
          FROM UNNEST(Lepton) l3 WITH OFFSET i3
          WHERE i3 <> i1 AND i3 <> i2
          ORDER BY l3.Pt DESC
          LIMIT 1
        ) AS otherLepton,
        AddPtEtaPhiM2(STRUCT(l1.Pt, l1.Eta, l1.Phi, l1.Mass),
                      STRUCT(l2.Pt, l2.Eta, l2.Phi, l2.Mass)) AS Dilepton
      FROM UNNEST(Lepton) l1 WITH OFFSET i1,
           UNNEST(Lepton) l2 WITH OFFSET i2
      WHERE
        i1 < i2 AND
        l1.charge = -l2.charge AND
        l1.type   =  l2.type
      ORDER BY
        ABS(AddPtEtaPhiM2(STRUCT(l1.Pt, l1.Eta, l1.Phi, l1.Mass),
                          STRUCT(l2.Pt, l2.Eta, l2.Phi, l2.Mass)).Mass - 91.2) ASC
      LIMIT 1
    ) AS BestTriLepton
  FROM Leptons
  WHERE nLepton >= 3
),
TriLeptionsWithMassAndOtherLepton AS (
  SELECT
    *,
    SQRT(2 * MET_pt * BestTriLepton.otherLepton.Pt *
         (1.0 - COS(DeltaPhi(STRUCT(MET_phi AS Phi),
                             BestTriLepton.otherLepton)))) AS transverseMass
  FROM TriLeptionsWithOtherLepton
  WHERE BestTriLepton IS NOT NULL
)
SELECT
  FLOOR((
    CASE
      WHEN BestTriLepton.otherLepton.pt < 15 THEN 14.55
      WHEN BestTriLepton.otherLepton.pt > 60 THEN 60
      ELSE BestTriLepton.otherLepton.pt
    END - 15) / 0.45) * 0.45 + 15 + 0.225 AS x,
  COUNT(*) AS y
FROM TriLeptionsWithMassAndOtherLepton
WHERE BestTriLepton.otherLepton.pt IS NOT NULL
GROUP BY x
ORDER BY x
"""

# The dictionary which stores the counts
dict_counter = {
  "SELECT": 0,
  "CAST": 0,
  "CASE": 0,
  "WHEN": 0,
  "WHERE": 0,
  "GROUP": 0,
  "COUNT": 0,
  "ORDER": 0,
  "JOIN": 0,
  "CARDINALITY": 0,
  "FILTER": 0,
  "WITH": 0,
  "AND": 0,
  "HAVING": 0,
  "DROP": 0,
  "CREATE": 0,
  "COALESCE": 0,
  "TRANSFORM": 0,
  "UNNEST": 0,
  "FUNCTION": 0,
  "LIMIT": 0,
  "EXISTS": 0,
  "UNION": 0,
  "MAX_BY": 0,
  "MIN_BY": 0,
  "ARRAY_MAX": 0,
  "SUM": 0 
}

# Code which splits the query and counts the hits
tokens = query.split()
for token in tokens:
  split_tokens = re.split("[^A-Z]", token.upper())
  for split_token in split_tokens:
    if split_token in dict_counter:
      dict_counter[split_token] += 1

# Code which prints the tokens
for k, v in dict_counter.items():
  print(k, "=", v)
