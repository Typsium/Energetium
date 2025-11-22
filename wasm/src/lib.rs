use wasm_minimal_protocol::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// Initialize the protocol
initiate_protocol!();

/// Format a float number in scientific notation
fn format_scientific(value: f64, precision: usize) -> String {
    if value == 0.0 {
        return "0".to_string();
    }
    
    let abs_value = value.abs();
    let exponent = abs_value.log10().floor() as i32;
    let mantissa = value / 10_f64.powi(exponent);
    
    // For numbers close to 1, use regular notation
    if exponent.abs() < 3 && abs_value >= 0.001 && abs_value < 1000.0 {
        format!("{:.prec$}", value, prec = precision)
    } else {
        format!("{:.prec$}×10^{}", mantissa, exponent, prec = precision)
    }
}

/// Data structure for thermodynamic properties
#[derive(Serialize, Deserialize, Debug)]
struct ThermodynamicData {
    #[serde(rename = "delta_Hf")]
    delta_hf: f64,  // Standard enthalpy of formation (kJ/mol)
    #[serde(rename = "S")]
    s: f64,         // Standard entropy (J/(mol·K))
    #[serde(rename = "delta_Gf")]
    delta_gf: f64,  // Standard Gibbs free energy of formation (kJ/mol)
}

/// Result structure for calculations
#[derive(Serialize, Deserialize)]
struct CalculationResult {
    value: f64,
    unit: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    formatted: Option<String>,
}

impl CalculationResult {
    fn new(value: f64, unit: &str) -> Self {
        Self {
            value,
            unit: unit.to_string(),
            formatted: None,
        }
    }
}

/// Calculate reaction enthalpy using Hess's Law
/// ΔH_reaction = Σ(ΔH_f products) - Σ(ΔH_f reactants)
#[wasm_func]
pub fn calculate_reaction_enthalpy(
    reactants_json: &[u8],
    products_json: &[u8],
    data_json: &[u8],
) -> Result<Vec<u8>, String> {
    // Parse input data
    let reactants: Vec<(String, f64)> = serde_json::from_slice(reactants_json)
        .map_err(|e| format!("Failed to parse reactants: {}", e))?;
    
    let products: Vec<(String, f64)> = serde_json::from_slice(products_json)
        .map_err(|e| format!("Failed to parse products: {}", e))?;
    
    let data: HashMap<String, ThermodynamicData> = serde_json::from_slice(data_json)
        .map_err(|e| format!("Failed to parse thermodynamic data: {}", e))?;
    
    // Calculate ΔH = Σ(products) - Σ(reactants)
    let mut delta_h = 0.0;
    
    // Add products contribution
    for (formula, coeff) in products {
        let thermo_data = data.get(&formula)
            .ok_or_else(|| format!("No data found for product: {}", formula))?;
        delta_h += coeff * thermo_data.delta_hf;
    }
    
    // Subtract reactants contribution
    for (formula, coeff) in reactants {
        let thermo_data = data.get(&formula)
            .ok_or_else(|| format!("No data found for reactant: {}", formula))?;
        delta_h -= coeff * thermo_data.delta_hf;
    }
    
    let result = CalculationResult::new(delta_h, "kJ/mol");
    
    Ok(serde_json::to_vec(&result).unwrap())
}

/// Calculate reaction entropy change
/// ΔS_reaction = Σ(S products) - Σ(S reactants)
#[wasm_func]
pub fn calculate_reaction_entropy(
    reactants_json: &[u8],
    products_json: &[u8],
    data_json: &[u8],
) -> Result<Vec<u8>, String> {
    let reactants: Vec<(String, f64)> = serde_json::from_slice(reactants_json)
        .map_err(|e| format!("Failed to parse reactants: {}", e))?;
    
    let products: Vec<(String, f64)> = serde_json::from_slice(products_json)
        .map_err(|e| format!("Failed to parse products: {}", e))?;
    
    let data: HashMap<String, ThermodynamicData> = serde_json::from_slice(data_json)
        .map_err(|e| format!("Failed to parse thermodynamic data: {}", e))?;
    
    let mut delta_s = 0.0;
    
    for (formula, coeff) in products {
        let thermo_data = data.get(&formula)
            .ok_or_else(|| format!("No data found for product: {}", formula))?;
        delta_s += coeff * thermo_data.s;
    }
    
    for (formula, coeff) in reactants {
        let thermo_data = data.get(&formula)
            .ok_or_else(|| format!("No data found for reactant: {}", formula))?;
        delta_s -= coeff * thermo_data.s;
    }
    
    let result = CalculationResult::new(delta_s, "J/(mol·K)");
    
    Ok(serde_json::to_vec(&result).unwrap())
}

/// Calculate Gibbs free energy change
/// ΔG = ΔH - T·ΔS
#[wasm_func]
pub fn calculate_gibbs_energy(
    enthalpy_bytes: &[u8],
    entropy_bytes: &[u8],
    temperature_bytes: &[u8],
) -> Result<Vec<u8>, String> {
    let enthalpy: f64 = std::str::from_utf8(enthalpy_bytes)
        .map_err(|e| format!("Invalid UTF-8 in enthalpy: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse enthalpy: {}", e))?;
    
    let entropy: f64 = std::str::from_utf8(entropy_bytes)
        .map_err(|e| format!("Invalid UTF-8 in entropy: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse entropy: {}", e))?;
    
    let temperature: f64 = std::str::from_utf8(temperature_bytes)
        .map_err(|e| format!("Invalid UTF-8 in temperature: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse temperature: {}", e))?;
    
    // ΔG = ΔH - T·ΔS (convert entropy from J/(mol·K) to kJ/(mol·K))
    let delta_g = enthalpy - temperature * (entropy / 1000.0);
    
    let result = CalculationResult::new(delta_g, "kJ/mol");
    
    Ok(serde_json::to_vec(&result).unwrap())
}

/// Calculate equilibrium constant from Gibbs free energy
/// K = exp(-ΔG / RT)
#[wasm_func]
pub fn calculate_equilibrium_constant(
    gibbs_energy_bytes: &[u8],
    temperature_bytes: &[u8],
) -> Result<Vec<u8>, String> {
    let delta_g: f64 = std::str::from_utf8(gibbs_energy_bytes)
        .map_err(|e| format!("Invalid UTF-8 in Gibbs energy: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse Gibbs energy: {}", e))?;
    
    let temperature: f64 = std::str::from_utf8(temperature_bytes)
        .map_err(|e| format!("Invalid UTF-8 in temperature: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse temperature: {}", e))?;
    
    const R: f64 = 8.314; // J/(mol·K)
    
    // K = exp(-ΔG / RT), convert ΔG from kJ/mol to J/mol
    let k = (-delta_g * 1000.0 / (R * temperature)).exp();
    
    let result = CalculationResult::new(k, "");
    
    Ok(serde_json::to_vec(&result).unwrap())
}

/// Get formation data for a single substance
#[wasm_func]
pub fn get_substance_data(
    formula_bytes: &[u8],
    data_json: &[u8],
) -> Result<Vec<u8>, String> {
    let formula = std::str::from_utf8(formula_bytes)
        .map_err(|e| format!("Invalid UTF-8 in formula: {}", e))?;
    
    let data: HashMap<String, ThermodynamicData> = serde_json::from_slice(data_json)
        .map_err(|e| format!("Failed to parse thermodynamic data: {}", e))?;
    
    let substance_data = data.get(formula)
        .ok_or_else(|| format!("No data found for substance: {}", formula))?;
    
    Ok(serde_json::to_vec(substance_data).unwrap())
}

/// Format a number with scientific notation
/// Input: value (number), precision (digits), use_scientific (boolean)
#[wasm_func]
pub fn format_number(
    value_bytes: &[u8],
    precision_bytes: &[u8],
    scientific_bytes: &[u8],
) -> Result<Vec<u8>, String> {
    let value: f64 = std::str::from_utf8(value_bytes)
        .map_err(|e| format!("Invalid UTF-8 in value: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse value: {}", e))?;
    
    let precision: usize = std::str::from_utf8(precision_bytes)
        .map_err(|e| format!("Invalid UTF-8 in precision: {}", e))?
        .parse()
        .unwrap_or(2);
    
    let use_scientific = std::str::from_utf8(scientific_bytes)
        .map_err(|e| format!("Invalid UTF-8 in scientific flag: {}", e))?
        .parse::<bool>()
        .unwrap_or(false);
    
    let formatted = if use_scientific {
        format_scientific(value, precision)
    } else {
        format!("{:.prec$}", value, prec = precision)
    };
    
    Ok(formatted.into_bytes())
}

/// Calculate rate constant using Arrhenius equation
/// k = A·exp(-Ea/(R·T))
/// 
/// Arguments:
/// - A: Pre-exponential factor (frequency factor)
/// - Ea: Activation energy (kJ/mol)
/// - T: Temperature (K)
/// 
/// Returns: Rate constant k (units depend on reaction order)
#[wasm_func]
pub fn calculate_rate_constant_arrhenius(
    a_bytes: &[u8],
    ea_bytes: &[u8],
    temperature_bytes: &[u8],
) -> Result<Vec<u8>, String> {
    let a: f64 = std::str::from_utf8(a_bytes)
        .map_err(|e| format!("Invalid UTF-8 in A: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse A: {}", e))?;
    
    let ea: f64 = std::str::from_utf8(ea_bytes)
        .map_err(|e| format!("Invalid UTF-8 in Ea: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse Ea: {}", e))?;
    
    let temperature: f64 = std::str::from_utf8(temperature_bytes)
        .map_err(|e| format!("Invalid UTF-8 in temperature: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse temperature: {}", e))?;
    
    const R: f64 = 8.314; // J/(mol·K)
    
    // k = A·exp(-Ea/(R·T)), convert Ea from kJ/mol to J/mol
    let k = a * (-ea * 1000.0 / (R * temperature)).exp();
    
    let result = CalculationResult::new(k, "");
    
    Ok(serde_json::to_vec(&result).unwrap())
}

/// Calculate rate constant using Eyring equation (transition state theory)
/// k = (kB·T/h)·exp(-ΔG‡/(R·T))
/// where ΔG‡ = ΔH‡ - T·ΔS‡
/// 
/// Arguments:
/// - delta_h_activation: Enthalpy of activation (kJ/mol)
/// - delta_s_activation: Entropy of activation (J/(mol·K))
/// - T: Temperature (K)
/// 
/// Returns: Rate constant k (s⁻¹)
#[wasm_func]
pub fn calculate_rate_constant_eyring(
    delta_h_bytes: &[u8],
    delta_s_bytes: &[u8],
    temperature_bytes: &[u8],
) -> Result<Vec<u8>, String> {
    let delta_h: f64 = std::str::from_utf8(delta_h_bytes)
        .map_err(|e| format!("Invalid UTF-8 in ΔH‡: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse ΔH‡: {}", e))?;
    
    let delta_s: f64 = std::str::from_utf8(delta_s_bytes)
        .map_err(|e| format!("Invalid UTF-8 in ΔS‡: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse ΔS‡: {}", e))?;
    
    let temperature: f64 = std::str::from_utf8(temperature_bytes)
        .map_err(|e| format!("Invalid UTF-8 in temperature: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse temperature: {}", e))?;
    
    const R: f64 = 8.314; // J/(mol·K)
    const KB: f64 = 1.380649e-23; // Boltzmann constant (J/K)
    const H: f64 = 6.62607015e-34; // Planck constant (J·s)
    const NA: f64 = 6.02214076e23; // Avogadro's number (mol⁻¹)
    
    // Calculate ΔG‡ = ΔH‡ - T·ΔS‡ (in J/mol)
    let delta_g = delta_h * 1000.0 - temperature * delta_s;
    
    // k = (kB·T/h)·exp(-ΔG‡/(R·T))
    // Note: kB/h has units s⁻¹·K⁻¹, multiply by T gives s⁻¹
    let kb_over_h = KB / H; // s⁻¹·K⁻¹
    let k = (kb_over_h * temperature / NA) * (-delta_g / (R * temperature)).exp();
    
    let result = CalculationResult::new(k, "s⁻¹");
    
    Ok(serde_json::to_vec(&result).unwrap())
}

/// Calculate activation energy from rate constants at two temperatures
/// ln(k2/k1) = (Ea/R)·(1/T1 - 1/T2)
/// Ea = R·ln(k2/k1) / (1/T1 - 1/T2)
#[wasm_func]
pub fn calculate_activation_energy(
    k1_bytes: &[u8],
    t1_bytes: &[u8],
    k2_bytes: &[u8],
    t2_bytes: &[u8],
) -> Result<Vec<u8>, String> {
    let k1: f64 = std::str::from_utf8(k1_bytes)
        .map_err(|e| format!("Invalid UTF-8 in k1: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse k1: {}", e))?;
    
    let t1: f64 = std::str::from_utf8(t1_bytes)
        .map_err(|e| format!("Invalid UTF-8 in T1: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse T1: {}", e))?;
    
    let k2: f64 = std::str::from_utf8(k2_bytes)
        .map_err(|e| format!("Invalid UTF-8 in k2: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse k2: {}", e))?;
    
    let t2: f64 = std::str::from_utf8(t2_bytes)
        .map_err(|e| format!("Invalid UTF-8 in T2: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse T2: {}", e))?;
    
    const R: f64 = 8.314; // J/(mol·K)
    
    // Ea = R·ln(k2/k1) / (1/T1 - 1/T2)
    let ea = R * (k2 / k1).ln() / (1.0/t1 - 1.0/t2) / 1000.0; // Convert to kJ/mol
    
    let result = CalculationResult::new(ea, "kJ/mol");
    
    Ok(serde_json::to_vec(&result).unwrap())
}

/// Calculate half-life for first-order reaction
/// t_1/2 = ln(2) / k
#[wasm_func]
pub fn calculate_half_life(
    k_bytes: &[u8],
    order_bytes: &[u8],
    initial_conc_bytes: &[u8],
) -> Result<Vec<u8>, String> {
    let k: f64 = std::str::from_utf8(k_bytes)
        .map_err(|e| format!("Invalid UTF-8 in k: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse k: {}", e))?;
    
    let order: i32 = std::str::from_utf8(order_bytes)
        .map_err(|e| format!("Invalid UTF-8 in order: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse order: {}", e))?;
    
    let initial_conc: f64 = std::str::from_utf8(initial_conc_bytes)
        .map_err(|e| format!("Invalid UTF-8 in initial concentration: {}", e))?
        .parse()
        .unwrap_or(1.0);
    
    let half_life = match order {
        0 => initial_conc / (2.0 * k), // Zero order: t_1/2 = [A]0 / (2k)
        1 => 2_f64.ln() / k,            // First order: t_1/2 = ln(2) / k
        2 => 1.0 / (k * initial_conc),  // Second order: t_1/2 = 1 / (k[A]0)
        _ => return Err(format!("Unsupported reaction order: {}", order)),
    };
    
    let result = CalculationResult::new(half_life, "s");
    
    Ok(serde_json::to_vec(&result).unwrap())
}
