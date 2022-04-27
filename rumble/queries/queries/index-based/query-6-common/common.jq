module namespace i-6 = "common.jq";
import module namespace hep = "../../common/hep.jq";
import module namespace hep-i = "../../common/hep-i.jq";

declare function i-6:find-min-triplet-idx($event) {
  (
    for $i in (1 to (size($event.Jet_pt) - 2))
    for $j in (($i + 1) to (size($event.Jet_pt) - 1))
    for $k in (($j + 1) to size($event.Jet_pt))
    let $particle1 := hep-i:make-jet($event, $i)
    let $particle2 := hep-i:make-jet($event, $j)
    let $particle3 := hep-i:make-jet($event, $k)
    let $tri-jet := hep:make-tri-jet($particle1, $particle2, $particle3)
    order by abs(172.5 - $tri-jet.mass) ascending
    return {"trijet": $tri-jet, "idxs": [$i, $j, $k]}
  )[1]
};
