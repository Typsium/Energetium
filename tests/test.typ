#import "../lib.typ": *

#set page(width: 21cm, height: auto, margin: 1.5cm)
#set text(size: 11pt)


#calculate-reaction(
  (("H2(g)", 3), ("N2(g)", 1)),
  (("NH3(g)", 2),),
  temp: 298.15,
  precision: 3,
)

= Experimental Activation Energy Determination

*Experimental Data:*
- At 600 K: k = 0.54 M⁻¹s⁻¹
- At 700 K: k = 5.2 M⁻¹s⁻¹

#let ea = calc-activation-energy(0.54, 60, 5.2, 70)

*Calculated Activation Energy:* #format-result(ea, precision: 1)
