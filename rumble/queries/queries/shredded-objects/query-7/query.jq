import module namespace hep = "../../common/hep.jq";
declare variable $input-path as anyURI external := anyURI("../../../data/Run2012B_SingleMu.root");

let $filtered := (
  for $event in hep:restructure-data-parquet($input-path)

  let $filtered-jets := (
    for $jet in $event.Jet[]
    where $jet.pt > 30

    let $leptons := hep:concat-leptons($event)
    where empty(
      for $lepton in $leptons
      where $lepton.pt > 10 and hep:delta-R($jet, $lepton) < 0.4
      return {}
    )

    return $jet
  )

  where exists($filtered-jets)
  return sum($filtered-jets.pt)
)

return hep:histogram($filtered, 15, 200, 100)
