// Energetium - Chemistry Energetics Calculation Package
// Main library file with Typst-friendly API

// Load the WebAssembly plugin
#let energetics-plugin = plugin("energetium.wasm")

// Load thermodynamic data
#let thermo-data = json("data/Standard_E_formation.json")

/// Format a number with optional scientific notation
///
/// Arguments:
/// - value: Number to format
/// - precision: Number of decimal places (default: 2)
/// - scientific: Use scientific notation (default: auto - uses scientific for very large/small numbers)
///
/// -> str
#let format-number(value, precision: 2, scientific: auto) = {
  let use-sci = if scientific == auto {
    // Auto: use scientific for very large or very small numbers
    let abs-val = calc.abs(value)
    abs-val >= 1000 or (abs-val < 0.001 and abs-val != 0)
  } else {
    scientific
  }
  
  let result = energetics-plugin.format_number(
    bytes(repr(value)),
    bytes(str(precision)),
    bytes(if use-sci { "true" } else { "false" })
  )
  
  str(result)
}

/// Format a result with value and unit
/// -> str
#let format-result(result, precision: 2, scientific: auto) = {
  let formatted-value = format-number(result.value, precision: precision, scientific: scientific)
  if result.unit != "" {
    formatted-value + " " + result.unit
  } else {
    formatted-value
  }
}

/// Calculate the enthalpy change of a reaction using Hess's Law
///
/// Arguments:
/// - reactants: Array of tuples (formula, coefficient), e.g., (("CH4", 1), ("O2", 2))
/// - products: Array of tuples (formula, coefficient), e.g., (("CO2", 1), ("H2O", 2))
/// - data: Optional custom thermodynamic data dictionary (defaults to built-in data)
///
/// Returns: Dictionary with keys `value` (number) and `unit` (string)
///
/// Example:
/// ```typst
/// #let result = calc-reaction-enthalpy(
///   (("CH4", 1), ("O2", 2)),
///   (("CO2", 1), ("H2O", 2))
/// )
/// #result.value // -890.3
/// ```
/// -> dict
#let calc-reaction-enthalpy(reactants, products, data: thermo-data) = {
  let reactants-json = json.encode(reactants)
  let products-json = json.encode(products)
  let data-json = json.encode(data)
  
  let result-bytes = energetics-plugin.calculate_reaction_enthalpy(
    bytes(reactants-json),
    bytes(products-json),
    bytes(data-json)
  )
  
  json(result-bytes)
}

/// Calculate the entropy change of a reaction
///
/// Arguments:
/// - reactants: Array of tuples (formula, coefficient)
/// - products: Array of tuples (formula, coefficient)
/// - data: Optional custom thermodynamic data dictionary
///
/// Returns: Dictionary with keys `value` (number) and `unit` (string)
/// -> dict
#let calc-reaction-entropy(reactants, products, data: thermo-data) = {
  let reactants-json = json.encode(reactants)
  let products-json = json.encode(products)
  let data-json = json.encode(data)
  
  let result-bytes = energetics-plugin.calculate_reaction_entropy(
    bytes(reactants-json),
    bytes(products-json),
    bytes(data-json)
  )
  
  json(result-bytes)
}

/// Calculate Gibbs free energy change
/// ΔG = ΔH - T·ΔS
///
/// Arguments:
/// - enthalpy: Enthalpy change in kJ/mol
/// - entropy: Entropy change in J/(mol·K)
/// - temp: Temperature in Kelvin (default: 298.15 K)
///
/// Returns: Dictionary with keys `value` (number) and `unit` (string)
/// -> dict
#let calc-gibbs-energy(enthalpy, entropy, temp: 298.15) = {
  let result-bytes = energetics-plugin.calculate_gibbs_energy(
    bytes(repr(enthalpy)),
    bytes(repr(entropy)),
    bytes(repr(temp))
  )
  
  json(result-bytes)
}

/// Calculate equilibrium constant from Gibbs free energy
/// K = exp(-ΔG / RT)
///
/// Arguments:
/// - gibbs-energy: Gibbs free energy change in kJ/mol
/// - temp: Temperature in Kelvin (default: 298.15 K)
///
/// Returns: Dictionary with keys `value` (number) and `unit` (string)
/// -> dict
#let calc-equilibrium-constant(gibbs-energy, temp: 298.15) = {
  let result-bytes = energetics-plugin.calculate_equilibrium_constant(
    bytes(repr(gibbs-energy)),
    bytes(repr(temp))
  )
  
  json(result-bytes)
}

/// Get thermodynamic data for a specific substance
///
/// Arguments:
/// - formula: Chemical formula as string, e.g., "H2O"
/// - data: Optional custom thermodynamic data dictionary
///
/// Returns: Dictionary with keys `delta_Hf`, `S`, and `delta_Gf`
/// -> dict
#let get-substance-data(formula, data: thermo-data) = {
  let data-json = json.encode(data)
  
  let result-bytes = energetics-plugin.get_substance_data(
    bytes(formula),
    bytes(data-json)
  )
  
  json(result-bytes)
}

/// Format a chemical reaction equation nicely
///
/// Arguments:
/// - reactants: Array of tuples (formula, coefficient)
/// - products: Array of tuples (formula, coefficient)
///
/// Returns: Content representing the formatted equation
/// -> content
#let format-reaction(reactants, products) = {
  let format-side(components) = {
    components.enumerate().map(((i, comp)) => {
      let (formula, coeff) = comp
      let coeff-str = if coeff == 1 { "" } else { str(coeff) + " " }
      let sep = if i < components.len() - 1 { " + " } else { "" }
      coeff-str + formula + sep
    }).join()
  }
  
  format-side(reactants) + " → " + format-side(products)
}

/// Complete reaction analysis
///
/// Calculates ΔH, ΔS, and ΔG for a reaction and formats the results
///
/// Arguments:
/// - reactants: Array of tuples (formula, coefficient)
/// - products: Array of tuples (formula, coefficient)
/// - temp: Temperature in Kelvin (default: 298.15 K)
/// - data: Optional custom thermodynamic data dictionary
/// - precision: Number of decimal places (default: 2)
/// - scientific: Format mode (default: auto)
///
/// Returns: Dictionary with all calculated values
/// -> dict
#let analyze-reaction(reactants, products, temp: 298.15, data: thermo-data, precision: 2, scientific: auto) = {
  let delta-h = calc-reaction-enthalpy(reactants, products, data: data)
  let delta-s = calc-reaction-entropy(reactants, products, data: data)
  let delta-g = calc-gibbs-energy(delta-h.value, delta-s.value, temp: temp)
  let k-eq = calc-equilibrium-constant(delta-g.value, temp: temp)
  
  (
    enthalpy: delta-h,
    entropy: delta-s,
    gibbs: delta-g,
    equilibrium-constant: k-eq,
    temperature: temp,
    equation: format-reaction(reactants, products),
    precision: precision,
    scientific: scientific
  )
}

/// Detailed reaction analysis with individual substance data
///
/// Arguments:
/// - reactants: Array of tuples (formula, coefficient)
/// - products: Array of tuples (formula, coefficient)
/// - temp: Temperature in Kelvin (default: 298.15 K)
/// - data: Optional custom thermodynamic data dictionary
///
/// Returns: Dictionary with detailed analysis including individual substance data
/// -> dict
#let detailed-analysis(reactants, products, temp: 298.15, data: thermo-data) = {
  // Get individual substance data
  let reactant-details = reactants.map(((formula, coeff)) => {
    let substance-data = get-substance-data(formula, data: data)
    (
      formula: formula,
      coefficient: coeff,
      data: substance-data
    )
  })
  
  let product-details = products.map(((formula, coeff)) => {
    let substance-data = get-substance-data(formula, data: data)
    (
      formula: formula,
      coefficient: coeff,
      data: substance-data
    )
  })
  
  // Calculate reaction properties
  let delta-h = calc-reaction-enthalpy(reactants, products, data: data)
  let delta-s = calc-reaction-entropy(reactants, products, data: data)
  let delta-g = calc-gibbs-energy(delta-h.value, delta-s.value, temp: temp)
  let k-eq = calc-equilibrium-constant(delta-g.value, temp: temp)
  
  (
    equation: format-reaction(reactants, products),
    temperature: temp,
    reactants: reactant-details,
    products: product-details,
    reaction: (
      enthalpy: delta-h,
      entropy: delta-s,
      gibbs: delta-g,
      equilibrium-constant: k-eq
    )
  )
}

/// Display detailed analysis with all substance data
///
/// Arguments:
/// - analysis: Result from detailed-analysis()
/// - precision: Number of decimal places (default: 2)
/// - scientific: Use scientific notation (default: auto)
///
/// Returns: Content with complete analysis
/// -> content
#let display-detailed-analysis(analysis, precision: 2, scientific: auto) = {
  [
    = Reaction Equation
    
    #align(center)[
      #text(size: 12pt)[#analysis.equation]
    ]
    
    Temperature: #analysis.temperature K
    
    = Reactant Data
    
    #table(
      columns: 5,
      stroke: 0.5pt,
      [*Substance*], [*Coefficient*], [*ΔH°#sub[f] (kJ/mol)*], [*S° (J/(mol·K))*], [*ΔG°#sub[f] (kJ/mol)*],
      ..for item in analysis.reactants {
        (
          item.formula,
          str(item.coefficient),
          format-number(item.data.delta_Hf, precision: precision, scientific: scientific),
          format-number(item.data.S, precision: precision, scientific: scientific),
          format-number(item.data.delta_Gf, precision: precision, scientific: scientific)
        )
      }
    )
    
    = Product Data
    
    #table(
      columns: 5,
      stroke: 0.5pt,
      [*Substance*], [*Coefficient*], [*ΔH°#sub[f] (kJ/mol)*], [*S° (J/(mol·K))*], [*ΔG°#sub[f] (kJ/mol)*],
      ..for item in analysis.products {
        (
          item.formula,
          str(item.coefficient),
          format-number(item.data.delta_Hf, precision: precision, scientific: scientific),
          format-number(item.data.S, precision: precision, scientific: scientific),
          format-number(item.data.delta_Gf, precision: precision, scientific: scientific)
        )
      }
    )
    
    = Reaction Thermodynamic Data
    
    #table(
      columns: 2,
      stroke: 0.5pt,
      [*Property*], [*Value*],
      [ΔH°#sub[rxn]], [#format-result(analysis.reaction.enthalpy, precision: precision, scientific: scientific)],
      [ΔS°#sub[rxn]], [#format-result(analysis.reaction.entropy, precision: precision, scientific: scientific)],
      [ΔG°#sub[rxn]], [#format-result(analysis.reaction.gibbs, precision: precision, scientific: scientific)],
      [K], [#format-number(analysis.reaction.equilibrium-constant.value, precision: precision, scientific: true)],
    )
  ]
}

/// Display reaction analysis in a formatted table
///
/// Arguments:
/// - analysis: Result from analyze-reaction()
/// - precision: Number of decimal places (default: 2)
/// - scientific: Use scientific notation (default: auto)
///
/// Returns: Content representing a formatted table
/// -> content
#let display-analysis(analysis, precision: auto, scientific: auto) = {
  let prec = if precision == auto { analysis.precision } else { precision }
  let sci = if scientific == auto { analysis.scientific } else { scientific }
  
  table(
    columns: 2,
    stroke: 0.5pt,
    [*Property*], [*Value*],
    [Reaction], [#analysis.equation],
    [Temperature], [#analysis.temperature K],
    [ΔH°], [#format-result(analysis.enthalpy, precision: prec, scientific: sci)],
    [ΔS°], [#format-result(analysis.entropy, precision: prec, scientific: sci)],
    [ΔG°], [#format-result(analysis.gibbs, precision: prec, scientific: sci)],
    [K], [#format-number(analysis.equilibrium-constant.value, precision: prec, scientific: true)],
  )
}

/// Quick reaction calculation from equation
///
/// Arguments:
/// - reactants: Array of tuples (formula, coefficient)
/// - products: Array of tuples (formula, coefficient)
/// - temp: Temperature in Kelvin (default: 298.15 K)
/// - show-details: Show detailed substance data (default: true)
/// - precision: Number of decimal places (default: 2)
/// - scientific: Use scientific notation (default: auto)
///
/// Returns: Formatted content with all data
/// -> content
#let calculate-reaction(reactants, products, temp: 298.15, show-details: true, precision: 2, scientific: auto) = {
  if show-details {
    let analysis = detailed-analysis(reactants, products, temp: temp)
    display-detailed-analysis(analysis, precision: precision, scientific: scientific)
  } else {
    let analysis = analyze-reaction(reactants, products, temp: temp, precision: precision, scientific: scientific)
    display-analysis(analysis)
  }
}

// ============================================================================
// REACTION KINETICS FUNCTIONS
// ============================================================================

/// Calculate rate constant using Arrhenius equation
/// k = A·exp(-Ea/(R·T))
///
/// Arguments:
/// - a: Pre-exponential factor (frequency factor)
/// - ea: Activation energy (kJ/mol)
/// - temp: Temperature (K, default: 298.15)
///
/// Returns: Dictionary with rate constant value and unit
///
/// Example:
/// ```typst
/// #let k = calc-rate-constant-arrhenius(1e13, 50, temp: 298.15)
/// ```
#let calc-rate-constant-arrhenius(a, ea, temp: 298.15) = {
  let result-bytes = energetics-plugin.calculate_rate_constant_arrhenius(
    bytes(repr(a)),
    bytes(repr(ea)),
    bytes(repr(temp))
  )
  
  json(result-bytes)
}

/// Calculate rate constant using Eyring equation (transition state theory)
/// k = (kB·T/h)·exp(-ΔG‡/(R·T))
///
/// Arguments:
/// - delta-h-activation: Enthalpy of activation (kJ/mol)
/// - delta-s-activation: Entropy of activation (J/(mol·K))
/// - temp: Temperature (K, default: 298.15)
///
/// Returns: Dictionary with rate constant value and unit (s⁻¹)
///
/// Example:
/// ```typst
/// #let k = calc-rate-constant-eyring(60, -50, temp: 298.15)
/// ```
#let calc-rate-constant-eyring(delta-h-activation, delta-s-activation, temp: 298.15) = {
  let result-bytes = energetics-plugin.calculate_rate_constant_eyring(
    bytes(repr(delta-h-activation)),
    bytes(repr(delta-s-activation)),
    bytes(repr(temp))
  )
  
  json(result-bytes)
}

/// Calculate activation energy from rate constants at two temperatures
/// Ea = R·ln(k2/k1) / (1/T1 - 1/T2)
///
/// Arguments:
/// - k1: Rate constant at temperature T1
/// - t1: Temperature 1 (K)
/// - k2: Rate constant at temperature T2
/// - t2: Temperature 2 (K)
///
/// Returns: Dictionary with activation energy in kJ/mol
///
/// Example:
/// ```typst
/// #let ea = calc-activation-energy(0.001, 300, 0.01, 350)
/// ```
#let calc-activation-energy(k1, t1, k2, t2) = {
  let result-bytes = energetics-plugin.calculate_activation_energy(
    bytes(repr(k1)),
    bytes(repr(t1)),
    bytes(repr(k2)),
    bytes(repr(t2))
  )
  
  json(result-bytes)
}

/// Calculate half-life for a reaction
/// - Zero order: t_1/2 = [A]0 / (2k)
/// - First order: t_1/2 = ln(2) / k
/// - Second order: t_1/2 = 1 / (k[A]0)
///
/// Arguments:
/// - k: Rate constant
/// - order: Reaction order (0, 1, or 2, default: 1)
/// - initial-conc: Initial concentration (default: 1.0, required for 0th and 2nd order)
///
/// Returns: Dictionary with half-life in seconds
///
/// Example:
/// ```typst
/// #let t-half = calc-half-life(0.693, order: 1)
/// ```
#let calc-half-life(k, order: 1, initial-conc: 1.0) = {
  let result-bytes = energetics-plugin.calculate_half_life(
    bytes(repr(k)),
    bytes(str(order)),
    bytes(repr(initial-conc))
  )
  
  json(result-bytes)
}

/// Analyze reaction kinetics with multiple parameters
///
/// Arguments:
/// - a: Pre-exponential factor
/// - ea: Activation energy (kJ/mol)
/// - temp: Temperature (K)
/// - order: Reaction order
/// - initial-conc: Initial concentration (optional)
/// - precision: Number of decimal places
/// - scientific: Scientific notation mode
///
/// Returns: Dictionary with all kinetic parameters
#let analyze-kinetics(a, ea, temp: 298.15, order: 1, initial-conc: 1.0, precision: 2, scientific: auto) = {
  let k = calc-rate-constant-arrhenius(a, ea, temp: temp)
  let t-half = calc-half-life(k.value, order: order, initial-conc: initial-conc)
  
  (
    rate-constant: k,
    half-life: t-half,
    activation-energy: (value: ea, unit: "kJ/mol"),
    pre-exponential: (value: a, unit: ""),
    temperature: temp,
    order: order,
    precision: precision,
    scientific: scientific
  )
}

/// Display kinetics analysis results
#let display-kinetics(analysis) = {
  let prec = analysis.precision
  let sci = analysis.scientific
  
  [
    *Reaction Kinetics Analysis*
    
    *Temperature:* #format-number(analysis.temperature, precision: 1, scientific: false) K
    
    *Activation Energy (Ea):* #format-result(analysis.activation-energy, precision: prec, scientific: sci)
    
    *Pre-exponential Factor (A):* #format-result(analysis.pre-exponential, precision: prec, scientific: true)
    
    *Rate Constant (k):* #format-result(analysis.rate-constant, precision: prec, scientific: sci)
    
    *Reaction Order:* #analysis.order
    
    *Half-life (t₁/₂):* #format-result(analysis.half-life, precision: prec, scientific: sci)
  ]
}
