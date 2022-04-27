import module namespace hep = "../../common/hep.jq";
import module namespace query-6 = "../query-6-common/common.jq";
declare variable $input-path as anyURI external := anyURI("../../../data/Run2012B_SingleMu.root");

let $filtered :=
  for $event in parquet-file($input-path)
  where size($event.Jet) > 2
  return query-6:find-min-triplet($event).trijet.pt

return hep:histogram($filtered, 15, 40, 100)
