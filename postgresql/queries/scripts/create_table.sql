-- Drop the table if it already exists
DROP TABLE IF EXISTS Run2012B_SingleMu_%(data_size)s_raw CASCADE;

-- Creates the `Run2012B_SingleMu` schema
CREATE TABLE IF NOT EXISTS Run2012B_SingleMu_%(data_size)s_raw (
	run  INTEGER,
	luminosityBlock  BIGINT,
	event  BIGINT,
	HLT_IsoMu24_eta2p1  BOOLEAN,
	HLT_IsoMu24  BOOLEAN,
	HLT_IsoMu17_eta2p1_LooseIsoPFTau20  BOOLEAN,
	PV_npvs  INTEGER,
	PV_x  REAL,
	PV_y  REAL,
	PV_z  REAL,
	nMuon  INTEGER,
	nElectron  INTEGER,
	nTau  INTEGER,
	nPhoton  INTEGER,
	MET_pt  REAL,
	MET_phi  REAL,
	MET_sumet  REAL,
	MET_significance  REAL,
	MET_CovXX  REAL,
	MET_CovXY  REAL,
	MET_CovYY  REAL,
	nJet  INTEGER,
	Muon_pt  REAL [],
	Muon_eta  REAL [],
	Muon_phi  REAL [],
	Muon_mass  REAL [],
	Muon_charge  INTEGER [],
	Muon_pfRelIso03_all  REAL [],
	Muon_pfRelIso04_all  REAL [],
	Muon_tightId  BOOLEAN [],
	Muon_softId  BOOLEAN [],
	Muon_dxy  REAL [],
	Muon_dxyErr  REAL [],
	Muon_dz  REAL [],
	Muon_dzErr  REAL [],
	Muon_jetIdx  INTEGER [],
	Muon_genPartIdx  INTEGER [],
	Electron_pt  REAL [],
	Electron_eta  REAL [],
	Electron_phi  REAL [],
	Electron_mass  REAL [],
	Electron_charge  INTEGER [],
	Electron_pfRelIso03_all  REAL [],
	Electron_dxy  REAL [],
	Electron_dxyErr  REAL [],
	Electron_dz  REAL [],
	Electron_dzErr  REAL [],
	Electron_cutBasedId  BOOLEAN [],
	Electron_pfId  BOOLEAN [],
	Electron_jetIdx  INTEGER [],
	Electron_genPartIdx  INTEGER [],
	Tau_pt  REAL [],
	Tau_eta  REAL [],
	Tau_phi  REAL [],
	Tau_mass  REAL [],
	Tau_charge  INTEGER [],
	Tau_decayMode  INTEGER [],
	Tau_relIso_all  REAL [],
	Tau_jetIdx  INTEGER [],
	Tau_genPartIdx  INTEGER [],
	Tau_idDecayMode  BOOLEAN [],
	Tau_idIsoRaw  REAL [],
	Tau_idIsoVLoose  BOOLEAN [],
	Tau_idIsoLoose  BOOLEAN [],
	Tau_idIsoMedium  BOOLEAN [],
	Tau_idIsoTight  BOOLEAN [],
	Tau_idAntiEleLoose  BOOLEAN [],
	Tau_idAntiEleMedium  BOOLEAN [],
	Tau_idAntiEleTight  BOOLEAN [],
	Tau_idAntiMuLoose  BOOLEAN [],
	Tau_idAntiMuMedium  BOOLEAN [],
	Tau_idAntiMuTight  BOOLEAN [],
	Photon_pt  REAL [],
	Photon_eta  REAL [],
	Photon_phi  REAL [],
	Photon_mass  REAL [],
	Photon_charge  INTEGER [],
	Photon_pfRelIso03_all  REAL [],
	Photon_jetIdx  INTEGER [],
	Photon_genPartIdx  INTEGER [],
	Jet_pt  REAL [],
	Jet_eta  REAL [],
	Jet_phi  REAL [],
	Jet_mass  REAL [],
	Jet_puId  BOOLEAN [],
	Jet_btag  REAL []
);


-- Create the view
CREATE VIEW Run2012B_SingleMu_%(data_size)s AS
SELECT RUN, 
	   luminosityBlock, 
	   event,
	   CAST (ROW(MET_pt, MET_phi, MET_sumet, MET_significance, MET_CovXX, MET_CovXY, MET_CovYY) AS metType) AS MET,
	   CAST (ROW(HLT_IsoMu24_eta2p1, HLT_IsoMu24, HLT_IsoMu17_eta2p1_LooseIsoPFTau20) AS hltType) AS HLT,
	   CAST (ROW(PV_npvs, PV_x, PV_y, PV_z) AS pvType) AS PV,
	   array(
	   	(SELECT CAST(ROW(pt,eta,phi,mass,charge,pfRelIso03_all,pfRelIso04_all,tightId,softId,dxy,dxyErr,dz,dzErr,jetIdx,genPartIdx) AS muonType) FROM UNNEST(Muon_pt, Muon_eta, Muon_phi, Muon_mass, Muon_charge, Muon_pfRelIso03_all, Muon_pfRelIso04_all, Muon_tightId, Muon_softId, Muon_dxy, Muon_dxyErr, Muon_dz, Muon_dzErr, Muon_jetIdx, Muon_genPartIdx) AS t(pt,eta,phi,mass,charge,pfRelIso03_all,pfRelIso04_all,tightId,softId,dxy,dxyErr,dz,dzErr,jetIdx,genPartIdx))
	   ) AS Muon,
	   array(
	   	(SELECT CAST(ROW(pt, eta, phi, mass, charge, pfRelIso03_all, dxy, dxyErr, dz, dzErr, cutBasedId, pfId, jetIdx, genPartIdx) AS electronType) FROM UNNEST(Electron_pt, Electron_eta, Electron_phi, Electron_mass, Electron_charge, Electron_pfRelIso03_all, Electron_dxy, Electron_dxyErr, Electron_dz, Electron_dzErr, Electron_cutBasedId, Electron_pfId, Electron_jetIdx, Electron_genPartIdx) AS t(pt, eta, phi, mass, charge, pfRelIso03_all, dxy, dxyErr, dz, dzErr, cutBasedId, pfId, jetIdx, genPartIdx))
	   ) AS Electron,
	   array(
	   	(SELECT CAST(ROW(pt, eta, phi, mass, charge, pfRelIso03_all, jetIdx, genPartIdx) AS photonType) FROM UNNEST(Photon_pt, Photon_eta, Photon_phi, Photon_mass, Photon_charge, Photon_pfRelIso03_all, Photon_jetIdx, Photon_genPartIdx) AS t(pt, eta, phi, mass, charge, pfRelIso03_all, jetIdx, genPartIdx))
	   ) AS Photon,
	   array(
	   	(SELECT CAST(ROW(pt, eta, phi, mass, puId, btag) AS jetType) FROM UNNEST(Jet_pt, Jet_eta, Jet_phi, Jet_mass, Jet_puId, Jet_btag) AS t(pt, eta, phi, mass, puId, btag))
	   ) AS Jet,
	   array(
	   	(SELECT CAST(ROW(pt, eta, phi, mass, charge, decayMode, relIso_all, jetIdx, genPartIdx, idDecayMode, idIsoRaw, idIsoVLoose, idIsoLoose, idIsoMedium, idIsoTight, idAntiEleLoose, idAntiEleMedium, idAntiEleTight, idAntiMuLoose, idAntiMuMedium, idAntiMuTight) AS tauType) FROM UNNEST(Tau_pt, Tau_eta, Tau_phi, Tau_mass, Tau_charge, Tau_decayMode, Tau_relIso_all, Tau_jetIdx, Tau_genPartIdx, Tau_idDecayMode, Tau_idIsoRaw, Tau_idIsoVLoose, Tau_idIsoLoose, Tau_idIsoMedium, Tau_idIsoTight, Tau_idAntiEleLoose, Tau_idAntiEleMedium, Tau_idAntiEleTight, Tau_idAntiMuLoose, Tau_idAntiMuMedium, Tau_idAntiMuTight) AS t(pt, eta, phi, mass, charge, decayMode, relIso_all, jetIdx, genPartIdx, idDecayMode, idIsoRaw, idIsoVLoose, idIsoLoose, idIsoMedium, idIsoTight, idAntiEleLoose, idAntiEleMedium, idAntiEleTight, idAntiMuLoose, idAntiMuMedium, idAntiMuTight))
	   ) AS Tau
FROM Run2012B_SingleMu_%(data_size)s_raw;


-- Import the data into the DB
COPY Run2012B_SingleMu_%(data_size)s_raw FROM '%(data_path)s' WITH (FORMAT csv, HEADER, ENCODING 'UTF-8');

ANALYZE Run2012B_SingleMu_%(data_size)s_raw;
ANALYZE Run2012B_SingleMu_%(data_size)s;