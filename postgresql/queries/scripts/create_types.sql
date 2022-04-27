-- Remove the types if they already exist
DROP TYPE IF EXISTS metType, hltType, pvType, muonType, electronType, photonType, jetType, tauType, eventType, quadType, pepmType, quadType, pepmType, triJetType, leptonType CASCADE;

-- Create the particle types
CREATE TYPE metType AS (
    pt             DOUBLE PRECISION,
    phi            DOUBLE PRECISION,
    sumet          DOUBLE PRECISION,
    significance   DOUBLE PRECISION,
    CovXX          DOUBLE PRECISION,
    CovXY          DOUBLE PRECISION,
    CovYY          DOUBLE PRECISION
);

CREATE TYPE hltType AS (
    IsoMu24_eta2p1                 BOOLEAN,
    IsoMu24                        BOOLEAN,
    IsoMu17_eta2p1_LooseIsoPFTau20 BOOLEAN
);

CREATE TYPE pvType AS (
    npvs   INTEGER,
    x      DOUBLE PRECISION,
    y      DOUBLE PRECISION,
    z      DOUBLE PRECISION
);

CREATE TYPE muonType AS (
    pt             DOUBLE PRECISION,
    eta            DOUBLE PRECISION,
    phi            DOUBLE PRECISION,
    mass           DOUBLE PRECISION,
    charge         INTEGER,
    pfRelIso03_all DOUBLE PRECISION,
    pfRelIso04_all DOUBLE PRECISION,
    tightId        BOOLEAN,
    softId         BOOLEAN,
    dxy            DOUBLE PRECISION,
    dxyErr         DOUBLE PRECISION,
    dz             DOUBLE PRECISION,
    dzErr          DOUBLE PRECISION,
    jetIdx         INTEGER,
    genPartIdx     INTEGER
);

CREATE TYPE electronType AS (
    pt             DOUBLE PRECISION,
    eta            DOUBLE PRECISION,
    phi            DOUBLE PRECISION,
    mass           DOUBLE PRECISION,
    charge         INTEGER,
    pfRelIso03_all DOUBLE PRECISION,
    dxy            DOUBLE PRECISION,
    dxyErr         DOUBLE PRECISION,
    dz             DOUBLE PRECISION,
    dzErr          DOUBLE PRECISION,
    cutBasedId     BOOLEAN,
    pfId           BOOLEAN,
    jetIdx         INTEGER,
    genPartIdx     INTEGER
);

CREATE TYPE photonType AS (
    pt             DOUBLE PRECISION,
    eta            DOUBLE PRECISION,
    phi            DOUBLE PRECISION,
    mass           DOUBLE PRECISION,
    charge         INTEGER,
    pfRelIso03_all DOUBLE PRECISION,
    jetIdx         INTEGER,
    genPartIdx     INTEGER
);

CREATE TYPE jetType AS (
    pt     DOUBLE PRECISION,
    eta    DOUBLE PRECISION,
    phi    DOUBLE PRECISION,
    mass   DOUBLE PRECISION,
    puId   BOOLEAN,
    btag   DOUBLE PRECISION
);

CREATE TYPE tauType AS (
    pt                 DOUBLE PRECISION,
    eta                DOUBLE PRECISION,
    phi                DOUBLE PRECISION,
    mass               DOUBLE PRECISION,
    charge             INTEGER,
    decayMode          INTEGER,
    relIso_all         DOUBLE PRECISION,  -- XXX This attribute contains null values. Not sure why...
    jetIdx             INTEGER,
    genPartIdx         INTEGER,
    idDecayMode        BOOLEAN,
    idIsoRaw           DOUBLE PRECISION,
    idIsoVLoose        BOOLEAN,
    idIsoLoose         BOOLEAN,
    idIsoMedium        BOOLEAN,
    idIsoTight         BOOLEAN,
    idAntiEleLoose     BOOLEAN,
    idAntiEleMedium    BOOLEAN,
    idAntiEleTight     BOOLEAN,
    idAntiMuLoose      BOOLEAN,
    idAntiMuMedium     BOOLEAN,
    idAntiMuTight      BOOLEAN
);

CREATE TYPE eventType AS (
    run                INTEGER,
    luminosityBlock    BIGINT,
    event              BIGINT,
    MET                metType,
    HLT                hltType,
    PV                 pvType,
    Muon               muonType [],
    Electron           electronType [],
    Photon             photonType [],
    Jet                jetType [],
    Tau                tauType []
);


-- Return types for functions
CREATE TYPE quadType AS (x DOUBLE PRECISION, y DOUBLE PRECISION,
  z DOUBLE PRECISION, t DOUBLE PRECISION);
CREATE TYPE pepmType AS (pt DOUBLE PRECISION, eta DOUBLE PRECISION,
  phi DOUBLE PRECISION, mass DOUBLE PRECISION);
CREATE TYPE triJetType AS (triJet pepmType, btag1 DOUBLE PRECISION,
  btag2 DOUBLE PRECISION, btag3 DOUBLE PRECISION);
CREATE TYPE leptonType AS (pt DOUBLE PRECISION, eta DOUBLE PRECISION,
  phi DOUBLE PRECISION, mass DOUBLE PRECISION, charge DOUBLE PRECISION,
  type CHARACTER);
