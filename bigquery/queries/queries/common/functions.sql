CREATE TEMP FUNCTION Pi() AS (ACOS(-1));
CREATE TEMP FUNCTION FMod(x ANY TYPE, y ANY TYPE) AS
  (x - TRUNC(x/y) * y);
CREATE TEMP FUNCTION FMod2Pi(x ANY TYPE) AS
  (FMod(x, 2 * Pi()));
CREATE TEMP FUNCTION Square(x ANY TYPE) AS (x*x);
CREATE TEMP FUNCTION DeltaPhi(p1 ANY TYPE, p2 ANY TYPE) AS (
  CASE
  WHEN FMod2Pi(p1.Phi - p2.Phi) < -Pi() THEN FMod2Pi(p1.Phi - p2.Phi) + 2 * Pi()
  WHEN FMod2Pi(p1.Phi - p2.Phi) >  Pi() THEN FMod2Pi(p1.Phi - p2.Phi) - 2 * Pi()
  ELSE FMod2Pi(p1.Phi - p2.Phi)
  END
);
CREATE TEMP FUNCTION DeltaR(p1 ANY TYPE, p2 ANY TYPE) AS
  (SQRT(Square(p1.Eta - p2.Eta) + Square(DeltaPhi(p1, p2))));
CREATE TEMP FUNCTION RhoZ2Eta(Rho FLOAT64, Z FLOAT64) AS
  (log(Z/Rho + sqrt(Z/Rho * Z/Rho + 1.0)));
CREATE TEMP FUNCTION PtEtaPhiM2PxPyPzE(pepm STRUCT<Pt FLOAT64, Eta FLOAT64, Phi FLOAT64, Mass FLOAT64>) AS
  (STRUCT(pepm.Pt * cos(pepm.Phi) AS x,
          pepm.Pt * sin(pepm.Phi) AS y,
          pepm.Pt * sinh(pepm.Eta) AS z,
          sqrt((pepm.Pt * cosh(pepm.Eta))*(pepm.Pt * cosh(pepm.Eta)) + pepm.Mass * pepm.Mass) AS e));
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
CREATE TEMP FUNCTION AddPxPyPzE3(
    xyzt1 STRUCT<X FLOAT64, Y FLOAT64, Z FLOAT64, T FLOAT64>,
    xyzt2 STRUCT<X FLOAT64, Y FLOAT64, Z FLOAT64, T FLOAT64>,
    xyzt3 STRUCT<X FLOAT64, Y FLOAT64, Z FLOAT64, T FLOAT64>) AS
  (AddPxPyPzE2(xyzt1, AddPxPyPzE2(xyzt2, xyzt3)));
CREATE TEMP FUNCTION AddPtEtaPhiM2(
    pepm1 STRUCT<Pt FLOAT64, Eta FLOAT64, Phi FLOAT64, Mass FLOAT64>,
    pepm2 STRUCT<Pt FLOAT64, Eta FLOAT64, Phi FLOAT64, Mass FLOAT64>) AS
  (PxPyPzE2PtEtaPhiM(
     AddPxPyPzE2(
       PtEtaPhiM2PxPyPzE(pepm1),
       PtEtaPhiM2PxPyPzE(pepm2))));
CREATE TEMP FUNCTION AddPtEtaPhiM3(
    pepm1 STRUCT<Pt FLOAT64, Eta FLOAT64, Phi FLOAT64, Mass FLOAT64>,
    pepm2 STRUCT<Pt FLOAT64, Eta FLOAT64, Phi FLOAT64, Mass FLOAT64>,
    pepm3 STRUCT<Pt FLOAT64, Eta FLOAT64, Phi FLOAT64, Mass FLOAT64>) AS
  (PxPyPzE2PtEtaPhiM(
     AddPxPyPzE3(
       PtEtaPhiM2PxPyPzE(pepm1),
       PtEtaPhiM2PxPyPzE(pepm2),
       PtEtaPhiM2PxPyPzE(pepm3))));
CREATE TEMP FUNCTION HistogramBinHelper(
    value ANY TYPE, lo ANY TYPE, hi ANY TYPE, bin_width ANY TYPE) AS (
  FLOOR((
    CASE
      WHEN value < lo THEN lo - bin_width / 4
      WHEN value > hi THEN hi + bin_width / 4
      ELSE value
    END - FMod(lo, bin_width)) / bin_width) * bin_width
      + bin_width / 2 + FMod(lo, bin_width)
);
CREATE TEMP FUNCTION HistogramBin(
    value ANY TYPE, lo ANY TYPE, hi ANY TYPE, num_bins ANY TYPE) AS (
  HistogramBinHelper(value, lo, hi, (hi - lo) / num_bins)
);
