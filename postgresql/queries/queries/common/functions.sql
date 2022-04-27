CREATE OR REPLACE FUNCTION HISTOGRAM_BIN(IN v DOUBLE PRECISION, IN lo DOUBLE PRECISION,
  IN hi DOUBLE PRECISION, IN bin_width DOUBLE PRECISION)
RETURNS DOUBLE PRECISION AS $$
BEGIN
  RETURN FLOOR((
    CASE
      WHEN v < lo THEN lo - bin_width / 4
      WHEN v > hi THEN hi + bin_width / 4
      ELSE v
    END - MOD(CAST(lo AS NUMERIC), CAST(bin_width AS NUMERIC))) / bin_width) * bin_width + bin_width / 2 
      + MOD(CAST(lo AS NUMERIC), CAST(bin_width AS NUMERIC));
END; 
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION HISTOGRAM(IN vals DOUBLE PRECISION [], IN lo DOUBLE PRECISION, 
  IN hi DOUBLE PRECISION, IN num_bins int = 100)
RETURNS TABLE (x DOUBLE PRECISION, y BIGINT) AS $$
BEGIN
  RETURN QUERY
    SELECT HISTOGRAM_BIN(v, lo, hi, (hi - lo) / num_bins) AS x, COUNT(*) AS y
    FROM (SELECT UNNEST(vals)) as tmp (v)
    GROUP BY x
    ORDER BY x;
END;
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION INVARIANT_MASS(IN p1 anyelement, IN p2 anyelement)
RETURNS DOUBLE PRECISION AS $$
BEGIN
  RETURN SQRT(2 * p1.pt * p2.pt * (COSH(p1.eta - p2.eta) - COS(p1.phi - p2.phi)));
END;
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Rho_Z2_Eta(IN rho DOUBLE PRECISION, IN z DOUBLE PRECISION)
RETURNS DOUBLE PRECISION AS $$
BEGIN
  RETURN LN(z / rho + SQRT(z / rho * z / rho + 1.0));
END;
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION PT_ETA_PHI_M2_PxPyPzE(IN pepm anyelement) 
RETURNS quadType AS $$
DECLARE
  result_record quadType;
BEGIN
  SELECT pepm.pt * COS(pepm.phi), pepm.pt * SIN(pepm.phi), pepm.pt * SINH(pepm.eta),
    SQRT((pepm.pt * COSH(pepm.eta)) * (pepm.pt * COSH(pepm.eta)) + pepm.mass * pepm.mass)
  INTO result_record.x, result_record.y, result_record.z, result_record.t;
  RETURN result_record;
END;
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Px_Py_Pz_E2_Pt_Eta_Phi_M(IN xyzt anyelement) 
RETURNS pepmType AS $$
DECLARE
  result_record pepmType;
BEGIN
  SELECT SQRT(xyzt.x*xyzt.x + xyzt.y*xyzt.y), 
    Rho_Z2_Eta(SQRT(xyzt.x*xyzt.x + xyzt.y*xyzt.y), xyzt.z),
    CASE WHEN (xyzt.x = 0.0 AND xyzt.y = 0.0) THEN 0
    ELSE atan2(xyzt.y, xyzt.x) END,
    SQRT(xyzt.t * xyzt.t - xyzt.x * xyzt.x - xyzt.y * xyzt.y - xyzt.z * xyzt.z)
  INTO result_record.pt, result_record.eta, result_record.phi, result_record.mass; 
  RETURN result_record;
END;
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ADD_Px_Py_Pz_E3(IN xyzt1 anyelement, 
  IN xyzt2 anyelement, IN xyzt3 anyelement) 
RETURNS quadType AS $$
DECLARE
  result_record quadType;
BEGIN
  SELECT xyzt1.x + xyzt2.x + xyzt3.x, xyzt1.y + xyzt2.y + xyzt3.y, 
    xyzt1.z + xyzt2.z + xyzt3.z, xyzt1.t + xyzt2.t + xyzt3.t
  INTO result_record.x, result_record.y, result_record.z, result_record.t;
  RETURN result_record;
END;
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ADD_Px_Py_Pz_E2(IN xyzt1 anyelement, 
  IN xyzt2 anyelement) 
RETURNS quadType AS $$
DECLARE
  result_record quadType;
BEGIN
  SELECT xyzt1.x + xyzt2.x, xyzt1.y + xyzt2.y, xyzt1.z + xyzt2.z, 
  xyzt1.t + xyzt2.t
  INTO result_record.x, result_record.y, result_record.z, result_record.t;
  RETURN result_record;
END;
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ADD_PT_ETA_PHI_M3(IN pepm1 anyelement, 
  IN pepm2 anyelement, IN pepm3 anyelement) 
RETURNS pepmType AS $$
BEGIN
  RETURN Px_Py_Pz_E2_Pt_Eta_Phi_M(
    ADD_Px_Py_Pz_E3(
      PT_ETA_PHI_M2_PxPyPzE(pepm1),
      PT_ETA_PHI_M2_PxPyPzE(pepm2),
      PT_ETA_PHI_M2_PxPyPzE(pepm3)));
END;
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ADD_PT_ETA_PHI_M2(IN pepm1 anyelement, 
  IN pepm2 anyelement) 
RETURNS pepmType AS $$
BEGIN
  RETURN Px_Py_Pz_E2_Pt_Eta_Phi_M(
    ADD_Px_Py_Pz_E2(
      PT_ETA_PHI_M2_PxPyPzE(pepm1),
      PT_ETA_PHI_M2_PxPyPzE(pepm2)));
END;
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ADD_PT_ETA_PHI_M3(IN pepm1 anyelement, 
  IN pepm2 anyelement, IN pepm3 anyelement) 
RETURNS pepmType AS $$
BEGIN
  RETURN Px_Py_Pz_E2_Pt_Eta_Phi_M(
    ADD_Px_Py_Pz_E3(
      PT_ETA_PHI_M2_PxPyPzE(pepm1),
      PT_ETA_PHI_M2_PxPyPzE(pepm2),
      PT_ETA_PHI_M2_PxPyPzE(pepm3)));
END;
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION DELTA_PHI(IN p1_phi DOUBLE PRECISION, 
  IN p2_phi DOUBLE PRECISION)
RETURNS DOUBLE PRECISION AS $$
DECLARE
  tmp DOUBLE PRECISION;
BEGIN
  SELECT MOD(CAST((p1_phi - p2_phi) AS NUMERIC), CAST((2 * PI()) AS NUMERIC)) INTO tmp;

  RETURN CASE
    WHEN tmp < -PI() THEN tmp + 2 * PI()
    WHEN tmp >  PI() THEN tmp - 2 * PI()
    ELSE tmp
  END;
END;
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION DELTA_R(IN p1_eta DOUBLE PRECISION, 
  IN p1_phi DOUBLE PRECISION, IN p2_eta DOUBLE PRECISION, 
  IN p2_phi DOUBLE PRECISION)
RETURNS DOUBLE PRECISION AS $$
DECLARE
BEGIN  
  RETURN SQRT((p1_eta - p2_eta) ^ 2.0 + DELTA_PHI(p1_phi, p2_phi) ^ 2.0);
END;
$$ 
PARALLEL SAFE
LANGUAGE plpgsql;