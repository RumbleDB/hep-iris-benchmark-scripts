import module namespace hep = "../../common/hep.jq";
declare variable $input-path as anyURI external := anyURI("../../../data/Run2012B_SingleMu.root");

let $filtered := (
  for $event in parquet-file($input-path)
  where size($event.Muon) > 1
  where exists(
    for $muon1 at $i in $event.Muon[]
    for $muon2 at $j in $event.Muon[]
    where $i < $j
    where $muon1.charge != $muon2.charge
    let $invariant-mass := hep:compute-invariant-mass($muon1, $muon2)
    where 60 < $invariant-mass and $invariant-mass < 120
    return {}
  )
  return $event.MET.pt
)

return hep:histogram($filtered, 0, 2000, 100)
