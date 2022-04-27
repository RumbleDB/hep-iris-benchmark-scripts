WITH Leptons AS (
  SELECT
    *,
    ARRAY(
      SELECT AS STRUCT
        Pt, Eta, Phi, Mass, Charge, "m" AS Type
      FROM UNNEST(Muon)
      UNION ALL
      SELECT AS STRUCT
        Pt, Eta, Phi, Mass, Charge, "e" AS Type
      FROM UNNEST(Electron)
    ) AS Lepton
  FROM `{bigquery_dataset}.{input_table}`
),
TriLeptonsWithOtherLepton AS (
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
  WHERE ARRAY_LENGTH(Lepton) >= 3
),
TriLeptonsWithMassAndOtherLepton AS (
  SELECT
    *,
    SQRT(2 * MET.pt * BestTriLepton.otherLepton.Pt *
         (1.0 - COS(DeltaPhi(STRUCT(MET.phi AS Phi),
                             BestTriLepton.otherLepton)))) AS transverseMass
  FROM TriLeptonsWithOtherLepton
  WHERE BestTriLepton IS NOT NULL
)
SELECT
  HistogramBin(transverseMass, 15, 250, 100) AS x,
  COUNT(*) AS y
FROM TriLeptonsWithMassAndOtherLepton
WHERE transverseMass IS NOT NULL
GROUP BY x
ORDER BY x
