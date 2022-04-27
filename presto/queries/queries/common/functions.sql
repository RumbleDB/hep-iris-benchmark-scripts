CREATE OR REPLACE FUNCTION mysql.default.HistogramBin(
    value REAL, lo REAL, hi REAL, num_bins INTEGER)
RETURNS REAL DETERMINISTIC RETURNS NULL ON NULL INPUT
RETURN
  FLOOR((
    CASE
      WHEN value < lo THEN lo - ((hi - lo) / num_bins) / 4
      WHEN value > hi THEN hi + ((hi - lo) / num_bins) / 4
      ELSE value
    END - MOD(lo, (hi - lo) / num_bins))
        / ((hi - lo) / num_bins))
      * ((hi - lo) / num_bins)
      + MOD(lo, (hi - lo) / num_bins) + ((hi - lo) / num_bins) / 2;
