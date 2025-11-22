# Energetium

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Typst Package](https://img.shields.io/badge/typst-package-239dad.svg)](https://typst.app/)
[![Version](https://img.shields.io/badge/version-0.1.0-green.svg)](https://github.com/yourusername/energetium)

**Energetium** is a Typst package for chemistry energetics and kinetics calculations.

## Features

### Thermodynamics Calculations
- **Reaction Enthalpy (ΔH°)**: Calculate enthalpy changes using Hess's Law
- **Reaction Entropy (ΔS°)**: Compute entropy changes for chemical reactions
- **Gibbs Free Energy (ΔG°)**: Calculate spontaneity indicators
- **Equilibrium Constants (K)**: Determine equilibrium position from thermodynamic data
- **Built-in Database**: Comprehensive standard formation data for common substances (Maybe changed to fetch from external source in future)

### Reaction Kinetics
- **Arrhenius Equation**: Calculate rate constants with temperature dependence
- **Eyring Equation**: Transition state theory calculations
- **Activation Energy**: Determine Ea from experimental rate data
- **Half-Life Calculations**: Support for zero-, first-, and second-order reactions
- **Complete Kinetics Analysis**: Integrated analysis with multiple parameters

### Display & Formatting
- **Detailed Analysis Tables**: Comprehensive thermodynamic data presentation
- **Customizable Precision**: Control decimal places and display modes

## Installation

### From Typst Universe (Recommended)

```typst
#import "@preview/energetium:0.1.0": *
```

## Quick Start

### Basic Thermodynamics Calculation

```typst
#import "@preview/energetium:0.1.0": *

// Combustion of methane: CH₄ + 2O₂ → CO₂ + 2H₂O
#let reactants = (("CH4", 1), ("O2", 2))
#let products = (("CO2", 1), ("H2O", 2))

#let analysis = analyze-reaction(reactants, products)
#display-analysis(analysis)
```

### Detailed Reaction Analysis

```typst
#import "@preview/energetium:0.1.0": *

// Formation of ammonia: N₂ + 3H₂ → 2NH₃
#calculate-reaction(
  (("N2", 1), ("H2", 3)),
  (("NH3", 2)),
  temp: 298.15,
  show-details: true (or false),
  precision: 2
)
```

### Kinetics Calculation

```typst
#import "@preview/energetium:0.1.0": *

// Calculate rate constant using Arrhenius equation
#let k = calc-rate-constant-arrhenius(
  1e13,      // Pre-exponential factor (A)
  50,        // Activation energy (kJ/mol)
  temp: 298.15
)

Rate constant: #format-result(k, precision: 3, scientific: true)

// Calculate half-life for first-order reaction
#let t_half = calc-half-life(k.value, order: 1)
Half-life: #format-result(t_half, precision: 2)
```

## API Reference

### Thermodynamics Functions

##### `calc-reaction-enthalpy(reactants, products, data: thermo-data)`
Calculate the enthalpy change of a reaction using Hess's Law.

**Parameters:**
- `reactants`: Array of tuples `(formula, coefficient)`
- `products`: Array of tuples `(formula, coefficient)`
- `data`: Optional custom thermodynamic data dictionary

**Returns:** Dictionary with `value` (number) and `unit` (string)

**Example:**
```typst
#let delta-h = calc-reaction-enthalpy(
  (("CH4", 1), ("O2", 2)),
  (("CO2", 1), ("H2O", 2))
)
```

##### `calc-reaction-entropy(reactants, products, data: thermo-data)`
Calculate the entropy change of a reaction.

**Returns:** Dictionary with entropy change in J/(mol·K)

##### `calc-gibbs-energy(enthalpy, entropy, temp: 298.15)`
Calculate Gibbs free energy: ΔG = ΔH - T·ΔS

**Parameters:**
- `enthalpy`: Enthalpy change (kJ/mol)
- `entropy`: Entropy change (J/(mol·K))
- `temp`: Temperature (K, default: 298.15)

**Returns:** Dictionary with ΔG in kJ/mol

##### `calc-equilibrium-constant(gibbs-energy, temp: 298.15)`
Calculate equilibrium constant from Gibbs free energy: K = exp(-ΔG / RT)

**Returns:** Dictionary with dimensionless K value

##### `analyze-reaction(reactants, products, temp: 298.15, precision: 2)`
Complete reaction analysis including ΔH°, ΔS°, ΔG°, and K.

**Returns:** Dictionary with all calculated values

##### `calculate-reaction(reactants, products, temp: 298.15, show-details: true)`
Quick reaction calculation with formatted output.

### Kinetics Functions

##### `calc-rate-constant-arrhenius(a, ea, temp: 298.15)`
Calculate rate constant using Arrhenius equation: k = A·exp(-Ea/(R·T))

**Parameters:**
- `a`: Pre-exponential factor (frequency factor)
- `ea`: Activation energy (kJ/mol)
- `temp`: Temperature (K)

**Returns:** Dictionary with rate constant and unit

##### `calc-rate-constant-eyring(delta-h-activation, delta-s-activation, temp: 298.15)`
Calculate rate constant using Eyring equation (transition state theory).

**Parameters:**
- `delta-h-activation`: Enthalpy of activation (kJ/mol)
- `delta-s-activation`: Entropy of activation (J/(mol·K))
- `temp`: Temperature (K)

**Returns:** Dictionary with rate constant (s⁻¹)

##### `calc-activation-energy(k1, t1, k2, t2)`
Calculate activation energy from rate constants at two temperatures.

**Parameters:**
- `k1`, `k2`: Rate constants
- `t1`, `t2`: Temperatures (K)

**Returns:** Dictionary with Ea in kJ/mol

##### `calc-half-life(k, order: 1, initial-conc: 1.0)`
Calculate half-life for reactions of different orders.

**Parameters:**
- `k`: Rate constant
- `order`: Reaction order (0, 1, or 2)
- `initial-conc`: Initial concentration (required for 0th and 2nd order)

**Returns:** Dictionary with half-life in seconds

##### `analyze-kinetics(a, ea, temp: 298.15, order: 1, precision: 2)`
Complete kinetics analysis with multiple parameters.

### Formatting Functions

##### `format-number(value, precision: 2, scientific: auto)`
Format numbers with optional scientific notation.

##### `format-result(result, precision: 2, scientific: auto)`
Format calculation results with values and units.

##### `format-reaction(reactants, products)`
Format chemical reaction equations nicely.

### Data Access

##### `get-substance-data(formula, data: thermo-data)`
Get thermodynamic data for a specific substance.

**Returns:** Dictionary with `delta_Hf`, `S`, and `delta_Gf`

## Examples

### Example 1: Haber Process Analysis

```typst
#import "@preview/energetium:0.1.0": *
#import "@preview/typsium:0.3.0": ce

= Haber Process: #ce[N2 + 3H2 <=> 2NH3]

#calculate-reaction(
  (("N2", 1), ("H2", 3)),
  (("NH3", 2)),
  temp: 298.15,
  show-details: true
)

// At elevated temperature (500°C = 773.15 K)
== High Temperature Analysis

#let analysis_high = analyze-reaction(
  (("N2", 1), ("H2", 3)),
  (("NH3", 2)),
  temp: 773.15
)

#display-analysis(analysis_high)
```

### Example 2: Enzyme Kinetics

```typst
#import "@preview/energetium:0.1.0": *

= Enzyme-Catalyzed Reaction Kinetics

#let kinetics = analyze-kinetics(
  1e12,           // Pre-exponential factor
  45,             // Activation energy (kJ/mol)
  temp: 310,      // Body temperature (37°C)
  order: 1,
  precision: 3
)

#display-kinetics(kinetics)
```

### Example 3: Activation Energy Determination

```typst
#import "@preview/energetium:0.1.0": *

= Experimental Activation Energy Determination

Reaction: #ce[2NO2 → 2NO + O2]

*Experimental Data:*
- At 600 K: k = 0.54 M⁻¹s⁻¹
- At 700 K: k = 5.2 M⁻¹s⁻¹

#let ea = calc-activation-energy(0.54, 600, 5.2, 700)

*Calculated Activation Energy:* #format-result(ea, precision: 1)
```

## Data Sources

The thermodynamic data included in this package is sourced from reliable chemistry references:
- NIST Chemistry WebBook
- CRC Handbook of Chemistry and Physics
- Standard thermodynamic tables

## Development

### Building from Source

#### Prerequisites
- Rust (latest stable version)
- wasm-pack
- Typst CLI

#### Build Steps
(if you really wish to build it yourself)

```bash
# Clone the repository
git clone https://github.com/Typsium/energetium.git
cd energetium

# Build the WebAssembly module
cd wasm
cargo build --target wasm32-unknown-unknown --release

# Copy the WASM file
cp target/wasm32-unknown-unknown/release/energetium_wasm.wasm ../energetium.wasm

# Test the package
cd ..
typst compile tests/test.typ
```

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Contribution Guidelines

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code of Conduct

Please note that this project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md) (not created yet). By participating, you are expected to uphold this code.

## Roadmap ~~coming s∞n~~

- [ ] Additional thermodynamic properties (heat capacity, etc.)
- [ ] More extensive substance database
- [ ] Electrochemistry calculations
- [ ] Phase equilibrium calculations
- [ ] Chemical equilibrium solvers
- [ ] Plotting capabilities for kinetics data
- [ ] Support for custom units

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Typst](https://typst.app/) - A modern markup-based typesetting system
- WebAssembly acceleration powered by [Rust](https://www.rust-lang.org/)
- Thermodynamic data from NIST and CRC sources

## Support

- **Documentation**: [Full documentation](https://github.com/Typsium/energetium/wiki)
- **Issues**: [GitHub Issues](https://github.com/Typsium/energetium/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Typsium/energetium/discussions)

## Author

**tryptophawa**(**β-吲哚基丙氨酸awa**)

## Project Status

This project is ~~not~~ under active development. The API and Database is under continuous improvement.

