CREATE EXTERNAL TABLE {tablename} (
    event           BIGINT,
    run             INT,
    luminosityBlock BIGINT,
    HLT STRUCT<
            IsoMu24_eta2p1:BOOLEAN,
            IsoMu24:BOOLEAN,
            IsoMu17_eta2p1_LooseIsoPFTau20:BOOLEAN>,
    PV  STRUCT<npvs:INT, x:FLOAT, y:FLOAT, z:FLOAT>,
    MET STRUCT<pt:FLOAT, phi:FLOAT, sumet:FLOAT, significance:FLOAT,
               CovXX:FLOAT, CovXY:FLOAT, CovYY:FLOAT>,
    Electron ARRAY<
                 STRUCT<pt:FLOAT, eta:FLOAT, phi:FLOAT, mass:FLOAT, charge:INT,
                        pfRelIso03_all:FLOAT, dxy:FLOAT, dxyErr:FLOAT, dz:FLOAT,
                        dzErr:FLOAT, cutBasedId:BOOLEAN, pfId:BOOLEAN, jetIdx:INT,
                        genPartIdx:INT>>,
    Muon ARRAY<
             STRUCT<pt:FLOAT, eta:FLOAT, phi:FLOAT, mass:FLOAT, charge:INT,
                    pfRelIso03_all:FLOAT, pfRelIso04_all:FLOAT, tightId:BOOLEAN,
                    softId:BOOLEAN, dxy:FLOAT, dxyErr:FLOAT, dz:FLOAT,
                    dzErr:FLOAT, jetIdx:INT, genPartIdx:INT>>,
    Jet ARRAY<
            STRUCT<pt:FLOAT, eta:FLOAT, phi:FLOAT, mass:FLOAT,
                   puId:BOOLEAN, btag:FLOAT>>
)
STORED AS PARQUET
LOCATION '{location}';
