-- This file contains unit tests of the HEP function library
CREATE TEMP FUNCTION Norm(pepm STRUCT<Pt FLOAT64, Eta FLOAT64, Phi FLOAT64, Mass FLOAT64>) AS
  (sqrt(pepm.Pt*pepm.Pt + pepm.Eta*pepm.Eta + pepm.Phi*pepm.Phi + pepm.Mass*pepm.Mass));
CREATE TEMP FUNCTION Distance(v1 STRUCT<Pt FLOAT64, Eta FLOAT64, Phi FLOAT64, Mass FLOAT64>,
                              v2 STRUCT<Pt FLOAT64, Eta FLOAT64, Phi FLOAT64, Mass FLOAT64>) AS
  (Norm(STRUCT(v1.Pt - v2.Pt, v1.Eta - v2.Eta, v1.Phi - v2.Phi, v1.Mass - v2.Mass)));
WITH ConversionTests AS (
  SELECT
    Distance(
      STRUCT(i,j,k,l),
      PxPyPzE2PtEtaPhiM(PtEtaPhiM2PxPyPzE(STRUCT(i,j,k,l)))) < 10e-14 AS outcome
  FROM UNNEST(GENERATE_ARRAY(1,3)) AS i,
       UNNEST(GENERATE_ARRAY(1,3)) AS j,
       UNNEST(GENERATE_ARRAY(1,3)) AS k,
       UNNEST(GENERATE_ARRAY(1,3)) AS l
),
AdditionTests AS (
  SELECT AddPxPyPzE2(STRUCT(1, 1, 1, 1), STRUCT(1, 1, 1, 1)) = STRUCT(2, 2, 2, 2) UNION ALL
  SELECT AddPxPyPzE2(STRUCT(0, 0, 0, 0), STRUCT(1, 1, 1, 1)) = STRUCT(1, 1, 1, 1) UNION ALL
  SELECT AddPxPyPzE2(STRUCT(1, 2, 3, 4), STRUCT(4, 3, 2, 1)) = STRUCT(5, 5, 5, 5) UNION ALL
  SELECT AddPxPyPzE3(STRUCT(1, 1, 1, 1),
                     STRUCT(1, 1, 1, 1),
                     STRUCT(1, 1, 1, 1)) = STRUCT(3, 3, 3, 3) UNION ALL
  SELECT Distance(AddPtEtaPhiM2(STRUCT(1, 1, 1, 1), STRUCT(1, 1, 1, 1)),
                  STRUCT(2, 1, 1, 2)) < 10e-14 UNION ALL
  SELECT Distance(AddPtEtaPhiM2(STRUCT(0.5, 1, 1.5, 2), STRUCT(3, 2, 1, 0)),
                  STRUCT(3.447136157112324, 1.917038257310314, 1.069595855582019, 6.080260775883978)) < 10e-14 UNION ALL
  SELECT Distance(AddPtEtaPhiM2(STRUCT(0.5, 1, 1.5, 2), STRUCT(1, 1, 1, 1)),
                  STRUCT(1.458623516158427, 1.021427505465948, 1.165090670378742, 3.259561057534407)) < 10e-14 UNION ALL
  SELECT Distance(AddPtEtaPhiM3(STRUCT(0.5, 1, 1.5, 2), STRUCT(1, 1, 1, 1), STRUCT(2, 1.5, 1, 0.5)),
                  STRUCT(3.447136157112324, 1.324295084525344, 1.069595855582019, 5.271610723174633)) < 10e-14
)
SELECT CAST(outcome AS INT64) AS x, COUNT(*) AS y
FROM (
  SELECT * FROM ConversionTests UNION ALL
  SELECT * FROM AdditionTests
)
GROUP BY x
ORDER BY x
