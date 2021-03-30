import re

# The query to be analyzed
query = """
declare function hep:histogram($values, $lo, $hi, $num-bins) {
  let $width := ($hi - $lo) div $num-bins
  let $half-width := $width div 2

  let $underflow := round(($lo - $half-width) div $width)
  let $overflow := round(($hi - $half-width) div $width)

  for $v in $values
  let $bucket-idx :=
    if ($v < $lo) then $underflow
    else
      if ($v > $hi) then $overflow
      else round(($v - $half-width) div $width)
  let $center := $bucket-idx * $width + $half-width

  group by $center
  order by $center
  return {"x": $center, "y": count($v)}
};

declare function hep:RhoZ-to-eta($rho, $z) {
  let $temp := $z div $rho
  return log($temp + sqrt($temp * $temp + 1.0))
};


declare function hep:PtEtaPhiM-to-PxPyPzE($vect) {
  let $x := $vect.pt * cos($vect.phi)
  let $y := $vect.pt * sin($vect.phi)
  let $z := $vect.pt * math:sinh($vect.eta)
  let $temp := $vect.pt * math:cosh($vect.eta)
  let $e := $temp * $temp + $vect.mass * $vect.mass
  return {"x": $x, "y": $y, "z": $z, "e": $e}
};



declare function hep:add-PtEtaPhiM($particle1, $particle2) {
  hep:PxPyPzE-to-PtEtaPhiM(
    hep:add-PxPyPzE(
      hep:PtEtaPhiM-to-PxPyPzE($particle1),
      hep:PtEtaPhiM-to-PxPyPzE($particle2)
      )
    )
};

declare function hep:add-PxPyPzE($particle1, $particle2) {
  let $x := $particle1.x + $particle2.x
  let $y := $particle1.y + $particle2.y
  let $z := $particle1.z + $particle2.z
  let $e := $particle1.e + $particle2.e
  return {"x": $x, "y": $y, "z": $z, "e": $e}
};


declare function hep:PxPyPzE-to-PtEtaPhiM($particle) {
  let $x2 := $particle.x * $particle.x
  let $y2 := $particle.y * $particle.y
  let $z2 := $particle.z * $particle.z
  let $e2 := $particle.e * $particle.e

  let $pt := sqrt($x2 + $y2)
  let $eta := hep:RhoZ-to-eta($pt, $particle.z)
  let $phi := if ($particle.x = 0.0 and $particle.y = 0.0)
        then 0.0
        else atan2($particle.y, $particle.x)
  let $mass := sqrt($e2 - $z2 - $y2 - $x2)

  return {"pt": $pt, "eta": $eta, "phi": $phi, "mass": $mass}
};


declare function o-8:find-closest-lepton-pair($leptons) {
  (
    for $lepton1 at $i in $leptons
    for $lepton2 at $j in $leptons
    where $i < $j
    where $lepton1.type = $lepton2.type and $lepton1.charge != $lepton2.charge
    order by abs(91.2 - hep:add-PtEtaPhiM($lepton1, $lepton2).mass) ascending
    return {"i": $i, "j": $j}
  )[1]
};


declare function hep:concat-leptons($event) {
  let $muons := (
    for $muon in $event.muons[]
    return {| $muon, {"type": "m"}  |}
  )

  let $electrons := (
    for $electron in $event.electrons[]
    return {| $electron, {"type": "e"}  |}
  )

  return ($muons, $electrons)
};


let $filtered := (
  for $event in hep:restructure-data-parquet($input-path)
  where integer($event.nMuon + $event.nElectron) > 2

  let $leptons := hep:concat-leptons($event)
  let $closest-lepton-pair := o-8:find-closest-lepton-pair($leptons)
  where exists($closest-lepton-pair)

  return max(
    for $lepton at $i in $leptons
    where $i != $closest-lepton-pair.i and $i != $closest-lepton-pair.j
    return $lepton.pt
  )
)
"""

# The dictionary which stores the counts
dict_counter = {
  "FUNCTION": 0,
  "LET": 0,
  "FOR": 0,
  "IF": 0,
  "GROUP": 0,
  "ORDER": 0,
  "WHERE": 0,
  "COUNT": 0,
  "EXISTS": 0,
  "EMPTY": 0
}

# Code which splits the query and counts the hits
tokens = query.split()
for token in tokens:
  split_tokens = re.split("[^A-Z]", token.upper())
  for split_token in split_tokens:
    if split_token in dict_counter:
      dict_counter[split_token] += 1

# Code which prints the tokens
for k, v in dict_counter.items():
  print(k, "=", v)
