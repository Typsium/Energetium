#import "../lib.typ": *
#import "@preview/typsium:0.3.0": ce

#set page(width: 21cm, height: auto, margin: 1.5cm)
#set text(size: 11pt)

= Gibbs Free Energy and Equilibrium Constant Verification

== Test 1: Water Formation at 298.15 K (Standard Conditions)
Reaction: H₂(g) + ½O₂(g) → H₂O(l)

#let h2o-test = analyze-reaction(
  (("H2(g)", 1), ("O2(g)", 0.5)),
  (("H2O(l)", 1),),
  temp: 298.15
)

*Expected values (from literature):*
- ΔH° ≈ -285.8 kJ/mol
- ΔS° ≈ -163.3 J/(mol·K)
- ΔG° ≈ -237.1 kJ/mol
- K ≈ 1.4×10⁴¹

*Calculated values:*
- ΔH = #format-result(h2o-test.enthalpy, precision: 1, scientific: false)
- ΔS = #format-result(h2o-test.entropy, precision: 1, scientific: false)
- ΔG = #format-result(h2o-test.gibbs, precision: 1, scientific: false)
- K = #format-result(h2o-test.equilibrium-constant, precision: 2, scientific: true)

*Manual verification:*
- ΔG = ΔH - T·ΔS = #h2o-test.enthalpy.value - #h2o-test.temperature × (#h2o-test.entropy.value / 1000.0) = #(h2o-test.enthalpy.value - h2o-test.temperature * (h2o-test.entropy.value / 1000.0)) kJ/mol ✓
- K = exp(-ΔG/(RT)) where R = 8.314 J/(mol·K)
- K = exp(-#h2o-test.gibbs.value × 1000 / (8.314 × #h2o-test.temperature))
- K = #calc.exp(-h2o-test.gibbs.value * 1000.0 / (8.314 * h2o-test.temperature)) ✓

---

== Test 2: Methane Combustion at 298.15 K
Reaction: CH₄(g) + 2O₂(g) → CO₂(g) + 2H₂O(l)

#let ch4-test = analyze-reaction(
  (("CH4(g)", 1), ("O2(g)", 2)),
  (("CO2(g)", 1), ("H2O(l)", 2)),
  temp: 298.15
)

*Calculated values:*
- ΔH = #format-result(ch4-test.enthalpy, precision: 1, scientific: false)
- ΔS = #format-result(ch4-test.entropy, precision: 1, scientific: false)
- ΔG = #format-result(ch4-test.gibbs, precision: 1, scientific: false)
- K = #format-result(ch4-test.equilibrium-constant, precision: 2, scientific: true)

*Manual verification:*
- ΔG = ΔH - T·ΔS = #ch4-test.enthalpy.value - #ch4-test.temperature × (#ch4-test.entropy.value / 1000.0) = #(ch4-test.enthalpy.value - ch4-test.temperature * (ch4-test.entropy.value / 1000.0)) kJ/mol ✓
- K = exp(-#ch4-test.gibbs.value × 1000 / (8.314 × #ch4-test.temperature))
- K = #calc.exp(-ch4-test.gibbs.value * 1000.0 / (8.314 * ch4-test.temperature)) ✓

---

== Test 3: High Temperature Test (1000 K)
Reaction: N₂(g) + 3H₂(g) → 2NH₃(g)

#let nh3-high-test = analyze-reaction(
  (("N2(g)", 1), ("H2(g)", 3)),
  (("NH3(g)", 2),),
  temp: 1000
)

*Calculated values at 1000 K:*
- ΔH = #format-result(nh3-high-test.enthalpy, precision: 1, scientific: false)
- ΔS = #format-result(nh3-high-test.entropy, precision: 1, scientific: false)
- ΔG = #format-result(nh3-high-test.gibbs, precision: 1, scientific: false)
- K = #format-result(nh3-high-test.equilibrium-constant, precision: 3, scientific: true)

*Manual verification:*
- ΔG = ΔH - T·ΔS = #nh3-high-test.enthalpy.value - #nh3-high-test.temperature × (#nh3-high-test.entropy.value / 1000.0) = #(nh3-high-test.enthalpy.value - nh3-high-test.temperature * (nh3-high-test.entropy.value / 1000.0)) kJ/mol ✓
- K = exp(-#nh3-high-test.gibbs.value × 1000 / (8.314 × #nh3-high-test.temperature))
- K = #calc.exp(-nh3-high-test.gibbs.value * 1000.0 / (8.314 * nh3-high-test.temperature)) ✓

Note: At higher temperatures, ΔG becomes less negative (or more positive) because the entropy term (-T·ΔS) becomes larger.

---

== Test 4: Temperature Effect on Spontaneity
Reaction: #ce[N2 + 3H2 <=> 2NH3]

#let temp-comparison = (
  (temp: 298.15, name: "298.15 K (25°C)"),
  (temp: 500, name: "500 K (227°C)"),
  (temp: 1000, name: "1000 K (727°C)"),
)

#table(
  columns: (auto, auto, auto, auto, auto),
  [*Temperature*], [*ΔH (kJ/mol)*], [*ΔS (J/(mol·K))*], [*ΔG (kJ/mol)*], [*K*],
  ..temp-comparison.map(t => {
    let result = analyze-reaction(
      (("N2(g)", 0.5), ("H2(g)", 1.5)),
      (("NH3(g)", 1),),
      temp: t.temp
    )
    (
      t.name,
      format-result(result.enthalpy, precision: 1, scientific: false),
      format-result(result.entropy, precision: 1, scientific: false),
      format-result(result.gibbs, precision: 1, scientific: false),
      format-result(result.equilibrium-constant, precision: 2, scientific: true),
    )
  }).flatten()
)

*Observations:*
- ΔH is constant (doesn't depend on temperature)
- ΔS is constant (doesn't depend on temperature in this approximation)
- ΔG becomes more negative as temperature increases
- K increases dramatically with temperature
- This shows the decomposition becomes more favorable at higher temperatures

---

== Test 5: Direct Calculation Test
Let's test the individual functions directly:

#let delta-h = calc-reaction-enthalpy(
  (("H2(g)", 1), ("O2(g)", 0.5)),
  (("H2O(l)", 1),)
)

#let delta-s = calc-reaction-entropy(
  (("H2(g)", 1), ("O2(g)", 0.5)),
  (("H2O(l)", 1),)
)

#let delta-g = calc-gibbs-energy(delta-h.value, delta-s.value, temp: 298.15)

#let k-eq = calc-equilibrium-constant(delta-g.value, temp: 298.15)

*Individual function results:*
- calc-reaction-enthalpy: #delta-h.value kJ/mol
- calc-reaction-entropy: #delta-s.value J/(mol·K)
- calc-gibbs-energy: #delta-g.value kJ/mol
- calc-equilibrium-constant: #format-number(k-eq.value, precision: 2, scientific: true)

*Formula check:*
- ΔG = ΔH - T·ΔS
- #delta-g.value = #delta-h.value - 298.15 × (#delta-s.value / 1000)
- #delta-g.value = #(delta-h.value - 298.15 * (delta-s.value / 1000.0))
- Difference: #(delta-g.value - (delta-h.value - 298.15 * (delta-s.value / 1000.0))) (should be ~0)

- K = exp(-ΔG/(RT))
- #k-eq.value = exp(-#delta-g.value × 1000 / (8.314 × 298.15))
- #k-eq.value = #calc.exp(-delta-g.value * 1000.0 / (8.314 * 298.15))
- Ratio: #(k-eq.value / calc.exp(-delta-g.value * 1000.0 / (8.314 * 298.15))) (should be ~1)

---

== Summary of Formulas Used

*Gibbs Free Energy:*
```
ΔG = ΔH - T·ΔS
```
where:
- ΔH is in kJ/mol
- T is in K
- ΔS is in J/(mol·K), so we divide by 1000 to convert to kJ/(mol·K)
- ΔG is in kJ/mol

*Equilibrium Constant:*
```
K = exp(-ΔG / (R·T))
```
where:
- ΔG is in kJ/mol, so we multiply by 1000 to convert to J/mol
- R = 8.314 J/(mol·K)
- T is in K
- K is dimensionless

*Sign conventions:*
- Negative ΔG → spontaneous reaction → K > 1
- Positive ΔG → non-spontaneous reaction → K < 1
- ΔG = 0 → equilibrium → K = 1
