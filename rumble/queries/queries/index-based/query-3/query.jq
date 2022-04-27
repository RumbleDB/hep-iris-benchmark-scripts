import module namespace hep = "../../common/hep.jq";
declare variable $input-path as anyURI external := anyURI("../../../data/Run2012B_SingleMu.root");

let $filtered :=
  for $event in parquet-file($input-path)
  for $i in (1 to size($event.Jet_pt))
  where abs($event.Jet_eta[[$i]]) < 1
  return $event.Jet_pt[[$i]]

return hep:histogram($filtered, 15, 60, 100)
