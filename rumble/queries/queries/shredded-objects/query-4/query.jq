import module namespace hep = "../../common/hep.jq";
declare variable $input-path as anyURI external := anyURI("../../../data/Run2012B_SingleMu.root");

let $filtered :=
  for $event in hep:restructure-data-parquet($input-path)
  where count($event.Jet[][$$.pt > 40]) > 1
  return $event.MET_pt

return hep:histogram($filtered, 0, 2000, 100)
