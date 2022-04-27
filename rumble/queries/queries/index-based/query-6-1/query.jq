import module namespace hep = "../../common/hep.jq";
import module namespace i-6 = "../query-6-common/common.jq";
declare variable $input-path as anyURI external := anyURI("../../../data/Run2012B_SingleMu.root");

let $filtered :=
  for $event in parquet-file($input-path)
  where $event.nJet > 2
  let $min-triplet := i-6:find-min-triplet-idx($event)
  return $min-triplet.trijet.pt

return hep:histogram($filtered, 15, 40, 100)
