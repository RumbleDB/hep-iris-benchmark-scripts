SELECT
  run, luminosityBlock, event, HLT, PV, MET,
  ARRAY(SELECT AS STRUCT element.* FROM UNNEST(Muon.list)) AS Muon,
  ARRAY(SELECT AS STRUCT element.* FROM UNNEST(Electron.list)) AS Electron,
  ARRAY(SELECT AS STRUCT element.* FROM UNNEST(Photon.list)) AS Photon,
  ARRAY(SELECT AS STRUCT element.* FROM UNNEST(Jet.list)) AS Jet,
  ARRAY(SELECT AS STRUCT element.* FROM UNNEST(Tau.list)) AS Tau
FROM `dataset_id.table_name`
