module namespace math = "math.jq";

declare function math:sinh($x) {
  (exp($x) - exp(-$x)) div 2.0
};

declare function math:cosh($x) {
  (exp($x) + exp(-$x)) div 2.0
};
