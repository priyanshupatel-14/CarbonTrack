# Carbon Calculation

## Overview
CarbonTrack estimates the carbon footprint savings (in kg CO2e) for sustainable actions. This is an educational tool and metric, not a certified carbon credit system.

## Emission Factors
Emission factors represent measurable carbon-emission activities (e.g., "petrol vehicle distance", "electricity kWh").
They are modeled **independent of sustainable actions**. 
Each factor includes:
- Activity type (e.g., "Petrol Car")
- Unit (e.g., "km")
- Factor value (e.g., 0.192 kg CO2e/km)
- Source (e.g., "EPA", "Defra")
- Version (e.g., "2024.1")
- Validity Dates

If an emission factor's methodology changes, a new version is inserted rather than overwriting the old one. This ensures historical carbon calculations remain strictly reproducible.

## Calculation Formula
`CO2e = quantity * emission_factor_value`

Where unit compatibility is strictly enforced (e.g., if activity quantity is in `km`, the emission factor must also be defined per `km`).

## Implemented Categories (V1)
The following categories and activity types are supported in the initial version:
- **TRANSPORTATION** (`PETROL_CAR`, `DIESEL_CAR`, `PETROL_TWO_WHEELER`, `PUBLIC_BUS`, `TRAIN`, `WALKING`, `CYCLING`)
  - Unit: `km`
  - Formula: `CO2e = km * factor`
  - Note: `WALKING` and `CYCLING` use a 0.0 factor explicitly representing zero direct emissions.
- **ELECTRICITY** (`ELECTRICITY_CONSUMPTION`)
  - Unit: `kWh`
  - Formula: `CO2e = kWh * factor`
- **FOOD** (`VEGAN`, `VEGETARIAN`, `MIXED`, `NON_VEGETARIAN`)
  - Unit: `meals`
  - Formula: `CO2e = meals * factor`
  - Note: Based on high-level estimates per meal.
- **WASTE** (`GENERAL_WASTE`, `PAPER`, `PLASTIC`, `GLASS`, `METAL`)
  - Unit: `kg`
  - Formula: `CO2e = kg * factor`

## Historical Reproducibility
The system stores both a `CarbonActivity` (the user input) and a `CarbonCalculation` (the executed calculation result).
The calculation persistently records:
- The specific `emission_factor_id` used
- The exact `factor_value_used` at the time
- The `factor_version`
- The resulting `co2e`

If an emission factor's methodology changes, a new row is inserted in `emission_factors` with an incremented version and new `valid_from` date. The backend will use the newly active version for future calculations without silently altering historical `CarbonCalculation` records. The client never supplies the emission factor ID; the server is solely responsible for determining the applicable factor.
