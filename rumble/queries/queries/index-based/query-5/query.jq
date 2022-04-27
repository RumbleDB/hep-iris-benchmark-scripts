import module namespace hep = "../../common/hep.jq";
import module namespace hep-i = "../../common/hep-i.jq";
declare variable $input-path as anyURI external := anyURI("../../../data/Run2012B_SingleMu.root");

let $filtered := (
  for $event in parquet-file($input-path)
  where $event.nMuon > 1
  where exists(
    for $i in (1 to (size($event.Muon_charge) - 1))
    for $j in (($i + 1) to size($event.Muon_charge))
    where $event.Muon_charge[[$i]] != $event.Muon_charge[[$j]]
    let $invariant-mass := hep-i:compute-invariant-mass($event, $i, $j)
    where 60 < $invariant-mass and $invariant-mass < 120
    return {}
  )
  return $event.MET_pt
)

return hep:histogram($filtered, 0, 2000, 100)
