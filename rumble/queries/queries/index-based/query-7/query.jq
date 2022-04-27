import module namespace hep = "../../common/hep.jq";
import module namespace hep-i = "../../common/hep-i.jq";
declare variable $input-path as anyURI external := anyURI("../../../data/Run2012B_SingleMu.root");

let $filtered := (
  for $event in parquet-file($input-path)

  let $filtered-jet-pts := (
    for $i in (1 to size($event.Jet_pt))
    where $event.Jet_pt[[$i]] > 30

    let $leptons := hep-i:concat-leptons($event)

    where empty(
      for $j in (1 to size($leptons.pt))
      let $delta-R := hep-i:delta-R(
        $event.Jet_phi[[$i]], $leptons.phi[[$j]],
        $event.Jet_eta[[$i]], $leptons.eta[[$j]])
      where $leptons.pt[[$j]] > 10 and $delta-R < 0.4
      return {}
    )

    return $event.Jet_pt[[$i]]
  )

  where exists($filtered-jet-pts)
  return sum($filtered-jet-pts)
)

return hep:histogram($filtered, 15, 200, 100)
