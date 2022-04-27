import module namespace hep = "../../common/hep.jq";
declare variable $input-path as anyURI external := anyURI("../../../data/Run2012B_SingleMu.root");

let $filtered := parquet-file($input-path).MET.pt

return hep:histogram($filtered, 0, 2000, 100)
