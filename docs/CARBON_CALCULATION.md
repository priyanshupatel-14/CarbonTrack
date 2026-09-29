# Carbon Calculation & Emission Factors

## Overview
CarbonTrack estimates the carbon footprint savings (in kg CO2e) for sustainable actions and personal campus activities. This is an educational tool and campus metric, not a certified carbon credit trading system.

Green Points awarded in CarbonTrack represent an internal campus reward currency, strictly decoupled from commercial carbon offsets or compliance carbon markets.

---

## Emission Factor Model & Audit

### Versioning & Immutability Architecture
Emission factors represent measurable carbon-emission activities (e.g., petrol vehicle distance, grid electricity consumption, meal type).
They are modeled independently of sustainable actions.

Each factor record contains:
- `activityType` (e.g., `PETROL_CAR`, `ELECTRICITY_CONSUMPTION`)
- `unit` (e.g., `km`, `kWh`, `meals`, `kg`)
- `factorValue` (e.g., `0.716` kg CO2e/kWh)
- `source` (e.g., "CEA CO2 Baseline Database v19 (India)")
- `version` (e.g., "2024.1", "2024.IN-CEA")
- `validFrom` / `validTo` dates

If an emission factor's methodology or regional data changes, a **new version is inserted with an updated validity window rather than mutating historical records**. This guarantees that all historical carbon calculations remain strictly reproducible and auditable.

---

## Indian Campus Emission Factors Audit

During Phase 9, an audit of the initial development emission factors was conducted to align CarbonTrack with the Indian campus operating context:

| Category | Activity Type | Unit | Initial Dev Factor | Indian Campus Benchmark | Authoritative Indian Source | Boundary / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **ELECTRICITY** | `ELECTRICITY_CONSUMPTION` | `kWh` | 0.207 (UK DEFRA) | **0.716** kg CO2/kWh | **Central Electricity Authority (CEA) of India** — *CO2 Baseline Database for the Indian Power Sector, User Guide Version 19.0 (November 2023)* | Combined Margin / National Grid Average. Reflects India's thermal coal grid share (~73%). |
| **TRANSPORTATION** | `PETROL_CAR` | `km` | 0.192 | **0.142** kg CO2/km | **ARAI / MoPNG (Ministry of Petroleum & Natural Gas)** vehicle emission baseline | Average Indian compact sedan/hatchback (~1200cc engine) at standard city fuel economy. |
| **TRANSPORTATION** | `DIESEL_CAR` | `km` | 0.171 | **0.155** kg CO2/km | **ARAI / MoPNG India** vehicle fleet baseline | Average Indian compact diesel utility vehicle. |
| **TRANSPORTATION** | `PETROL_TWO_WHEELER` | `km` | 0.113 | **0.038** kg CO2/km | **PCRA (Petroleum Conservation Research Association) India** | Typical Indian commuter motorcycle/scooter (100cc-125cc, 50-60 km/L). Significantly lower than Western motorcycles. |
| **TRANSPORTATION** | `PUBLIC_BUS` | `km` | 0.105 | **0.045** kg CO2/pass-km | **ASRTU (Association of State Road Transport Undertakings) / BMTC/DTC** | Average occupancy of 35-40 passengers in urban Indian transit buses. |
| **TRANSPORTATION** | `TRAIN` / `METRO` | `km` | 0.035 | **0.028** kg CO2/pass-km | **DMRC / BMRCL Sustainability Reports (2022-2023)** | Mass Rapid Transit System powered by Indian grid with regenerative braking. |
| **TRANSPORTATION** | `WALKING` | `km` | 0.000 | **0.000** kg CO2/km | Direct Zero Emission Standard | Active human-powered mobility. |
| **TRANSPORTATION** | `CYCLING` | `km` | 0.000 | **0.000** kg CO2/km | Direct Zero Emission Standard | Active human-powered mobility. |
| **FOOD** | `VEGAN` | `meals` | 0.700 | **0.650** kg CO2e/meal | **ICAR (Indian Council of Agricultural Research) & CSE India** | Plant-based Indian meal (rice, dal, roti, seasonal vegetables). |
| **FOOD** | `VEGETARIAN` | `meals` | 1.200 | **0.950** kg CO2e/meal | **ICAR / CSE India** | Traditional Indian lacto-vegetarian meal including dairy (curd, paneer, ghee). |
| **FOOD** | `NON_VEGETARIAN` | `meals` | 3.300 | **2.200** kg CO2e/meal | **ICAR / CSE India** | Indian poultry/mutton curry meal. Lower than Western beef-heavy diets. |
| **WASTE** | `GENERAL_WASTE` | `kg` | 0.450 | **0.460** kg CO2e/kg | **CPCB (Central Pollution Control Board, India) MSW Guidelines** | Unsegregated municipal solid waste sent to open landfill. |
| **WASTE** | `PLASTIC` (Recycled) | `kg` | 0.040 | **0.042** kg CO2e/kg | **TERI (The Energy and Resources Institute)** | Diverted and recycled rigid polymer waste. |
| **WASTE** | `PAPER` (Recycled) | `kg` | 0.020 | **0.022** kg CO2e/kg | **TERI** | Diverted paper recycled into cardboard/paper pulp. |

---

## Calculation Formula & Execution Boundary

### Formula
```text
CO2e (kg) = Quantity × Emission_Factor_Value
```

### Calculation Boundaries & Explicit Limitations
1. **Direct Activity Boundary (Scope 1 & Scope 2)**:
   - Electricity calculation evaluates **Scope 2** grid emissions at the plug (generation + transmission baseline).
   - Fuel transport calculations evaluate direct **tank-to-wheel (Scope 1)** emissions.
2. **Explicit Non-Claims**:
   - CarbonTrack does **NOT** calculate full Cradle-to-Grave Life Cycle Assessments (LCA) for manufactured goods, campus infrastructure capital goods, or Scope 3 supply chains.
   - Food footprint calculations are estimates based on standardized dietary archetypes, not meal-specific agricultural lifecycle tracing.
   - Walking and cycling are assigned zero operational emissions; embodied manufacturing footprints of bicycles/shoes are outside the scope.

---

## Storage & Audit Traceability

Each time an activity is logged or verified, two entities are committed:
1. `CarbonActivity`: Stores user-submitted raw quantity, unit, category, activity type, and timestamp.
2. `CarbonCalculation`: Stores:
   - `emissionFactor`: Foreign key to exact factor record
   - `factorValueUsed`: Value snapshot (BigDecimal)
   - `factorVersion`: Version string snapshot (e.g. `2024.1`)
   - `co2e`: Calculated emission in kg CO2e

This snapshot structure ensures that subsequent policy or regulatory updates to emission factors will not retrospectively rewrite historical student balances or campus reporting periods.
