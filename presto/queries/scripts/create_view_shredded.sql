CREATE OR REPLACE VIEW {view_name} AS
WITH jets AS (
  SELECT event,
    array_agg(
      CAST(ROW(pt, eta, phi, mass, puId, btag) AS
           ROW(pt   REAL,
               eta  REAL,
               phi  REAL,
               mass REAL,
               puId BOOLEAN,
               btag REAL))) AS Jet
  FROM {table_name}
  CROSS JOIN UNNEST(Jet_pt, Jet_eta, Jet_phi, Jet_mass, Jet_puId, Jet_btag)
             AS t (pt, eta, phi, mass, puId, btag)
  GROUP BY event
),

electrons AS (
  SELECT event,
    array_agg(
      CAST(ROW(pt, eta, phi, mass, charge, pfRelIso03_all,
               dxy, dxyErr, dz, dzErr, cutBasedId,
               pfId, jetIdx, genPartIdx) AS
           ROW(pt           REAL,
               eta          REAL,
               phi          REAL,
               mass         REAL,
               charge       INTEGER,
               pfRelIso03_all REAL,
               dxy          REAL,
               dxyErr       REAL,
               dz           REAL,
               dzErr        REAL,
               cutBasedId   BOOLEAN,
               pfId         BOOLEAN,
               jetIdx       INTEGER,
               genPartIdx   INTEGER))) AS Electron
  FROM {table_name}
  CROSS JOIN UNNEST(Electron_pt, Electron_eta, Electron_phi, Electron_mass,
                    Electron_charge, Electron_pfRelIso03_all, Electron_dxy,
                    Electron_dxyErr,  Electron_dz, Electron_dzErr,
                    Electron_cutBasedId, Electron_pfId, Electron_jetIdx,
                    Electron_genPartIdx)
             AS t (pt, eta, phi, mass, charge, pfRelIso03_all, dxy, dxyErr, dz,
                   dzErr, cutBasedId, pfId, jetIdx, genPartIdx)
  GROUP BY event
),

muons AS (
  SELECT event,
    array_agg(
      CAST(ROW(pt, eta, phi, mass, charge,
               pfRelIso03_all, pfRelIso04_all, tightId, softId,
               dxy, dxyErr, dz, dzErr, jetIdx, genPartIdx) AS
           ROW(pt           REAL,
               eta          REAL,
               phi          REAL,
               mass         REAL,
               charge       INTEGER,
               pfRelIso03_all REAL,
               pfRelIso04_all REAL,
               tightId      BOOLEAN,
               softId       BOOLEAN,
               dxy          REAL,
               dxyErr       REAL,
               dz           REAL,
               dzErr        REAL,
               jetIdx       INTEGER,
               genPartIdx   INTEGER))) AS Muon
  FROM {table_name}
  CROSS JOIN UNNEST(Muon_pt, Muon_eta, Muon_phi, Muon_mass, Muon_charge,
                    Muon_pfRelIso03_all, Muon_pfRelIso04_all, Muon_tightId,
                    Muon_softId, Muon_dxy, Muon_dxyErr, Muon_dz, Muon_dzErr,
                    Muon_jetIdx, Muon_genPartIdx)
             AS t (pt, eta, phi, mass, charge, pfRelIso03_all, pfRelIso04_all,
                   tightId, softId, dxy, dxyErr, dz, dzErr, jetIdx, genPartIdx)
  GROUP BY event
)

SELECT
  main.event, run, luminosityBlock,
  CAST(ROW(HLT_IsoMu24_eta2p1, HLT_IsoMu24,
           HLT_IsoMu17_eta2p1_LooseIsoPFTau20) AS
       ROW(IsoMu24_eta2p1                   BOOLEAN,
           IsoMu24                          BOOLEAN,
           IsoMu17_eta2p1_LooseIsoPFTau20   BOOLEAN)) AS HLT,
  CAST(ROW(PV_npvs, PV_x, PV_y, PV_z) AS
       ROW(npvs     INTEGER,
           x        REAL,
           y        REAL,
           z        REAL)) AS PV,
  CAST(ROW(MET_pt, MET_phi, MET_sumet, MET_significance,
           MET_CovXX, MET_CovXY, MET_CovYY) AS
       ROW(pt           REAL,
           phi          REAL,
           sumet        REAL,
           significance REAL,
           CovXX        REAL,
           CovXY        REAL,
           CovYY        REAL)) AS MET,
  COALESCE(Electron, ARRAY []) AS Electron,
  COALESCE(Muon, ARRAY []) AS Muon,
  COALESCE(Jet, ARRAY []) AS Jet
FROM {table_name} AS main
FULL JOIN jets AS j on main.event = j.event
FULL JOIN electrons AS e ON main.event = e.event
FULL JOIN muons AS m ON main.event = m.event;
