# STATA Code for AI Mania Replication Study

## Overview

This folder contains STATA scripts to replicate the methodology from Cheng et al. (2019) "Riding the Blockchain Mania" for studying Generative AI disclosures during 2022-2025.

## File Structure

```
code/
├── 00_master.do                    # Master script - runs all analyses
├── 00_prepare_ai_proxies.do        # Helper: Prepare AI mania indicators
├── 01_data_processing.do           # Sample construction & WRDS data merging
├── 02_classify_disclosures.do      # Kindermann (2021) classification
├── 03_descriptives.do              # Tables 2-3, temporal figures
├── 04_event_study.do               # Event study (WRDS Event Study Tool)
├── 05_additional_analyses.do       # AI mania tests (Tables 5-6)
├── 06_output_tables.do             # Publication-ready output
└── README_CODE.md                  # This file
```

## Execution Order

### Quick Start (All Steps)
```stata
do code/00_master.do
```

### Step-by-Step Execution
```stata
do code/01_data_processing.do
do code/02_classify_disclosures.do
do code/03_descriptives.do
do code/04_event_study.do
do code/05_additional_analyses.do
do code/06_output_tables.do
```

## Key Methodological Choices

### 1. Classification: Kindermann (2021) Digital Orientation Score

**Departure from Blockchain Study:**
- **Original**: Manual binary classification (Speculative vs Existing)
- **Our Approach**: Continuous digitalization score from Kindermann et al. (2021)

**Rationale:**
1. **Validated measure**: Published in *European Management Journal*
2. **Ex-ante**: Measured from 10-K filings *before* AI disclosure
3. **Objective**: Computer-aided text analysis (no subjective coding)
4. **Granular**: Continuous measure allows heterogeneity analysis

**Implementation:**
- Source: `kindermann_2021_10k_edgar_2005_2025.txt`
- 4 dimensions: Technology Scope, Capabilities, Ecosystem, Architecture
- 148 validated keywords across dimensions
- Score = (digital word count / total words) × 1000

**Interpretation:**
- **Low score (0-10)**: "Speculative" firms - minimal digital infrastructure
- **Moderate (10-40)**: "Transition" firms - building digital capabilities
- **High (>40)**: "Existing" firms - established digital operations

### 2. Event Study: WRDS Event Study Tool

**Why External Tool:**
- Industry-standard methodology
- Handles: missing data, confounding events, statistical tests
- Transparent and replicable
- Used in hundreds of published papers

**Specifications:**
```
Event Date: filing_date (first AI 8-K)
Event Windows:
  - Short-term: (-3, +3) days
  - Follow-up: (+4, +30) days
  - Combined: (-3, +30) days

Estimation Window: (-175, -26) days

Factor Model: Fama-French 3-factor
  Expected_Return = α + β₁*MKT + β₂*SMB + β₃*HML

BHAR = Actual_Return - Expected_Return
```

**Input File:** `wrds_event_study_input.csv`
- Columns: cusip8, event_date_wrds (YYYYMMDD), ticker

**Output Files:**
- `wrds_car_short.csv`
- `wrds_car_followup.csv`
- `wrds_car_combined.csv`

**Instructions:** See detailed guide in `04_event_study.do` lines 50-150

### 3. AI Mania Proxies

**Two indicators:**

1. **ChatGPT Google Trends** (`chatgpt_google.csv`)
   - Weekly search intensity for "ChatGPT"
   - Represents public AI enthusiasm
   - Peaked September 2024 (index = 100)

2. **STOXX Global AI Index** (`istoxx_global_ai_100_index.txt`)
   - Daily values of AI stock index
   - Represents AI market performance
   - Analogous to Bitcoin price in blockchain study

**Usage:**
- Up/down market classification (Table 5)
- Factor loading analysis (Table 6)
- Temporal correlation with disclosures (Figure 2)

## Required WRDS Data Extractions

### Priority 1: Essential for Event Study

**1. CRSP Stock Identifiers**
```stata
/* Map tickers to PERMNO and CUSIP */
Dataset: crsp.dsenames
Variables: ticker, permno, cusip, ncusip, comnam
Filter: namedt <= '2025-12-31' AND nameendt >= '2022-01-01'
```

**2. CRSP Daily Returns**
```stata
/* Event window returns */
Dataset: crsp.dsf
Variables: permno, date, cusip, ret, prc, vol, shrout
Filter: date BETWEEN '2022-04-01' AND '2025-12-31'
        AND permno IN (sample_firms)
```

**3. WRDS Event Study**
- Use web interface or SAS code in `04_event_study.do`
- Upload CUSIP-date pairs
- Select Fama-French 3-factor model
- Download CAR/BHAR results

### Priority 2: Firm Characteristics

**4. Compustat Annual Fundamentals**
```stata
Dataset: comp.funda
Variables: gvkey, datadate, at, csho, prcc_f, sale, ni, ceq,
           dltis, fincf, sic
Filter: datadate BETWEEN '2020-01-01' AND '2024-12-31'
        AND indfmt='INDL' AND datafmt='STD' AND consol='C'
```

**5. CRSP-Compustat Link**
```stata
Dataset: crsp.ccmxpf_linktable
Variables: lpermno, gvkey, linkdt, linkenddt
Filter: linktype IN ('LU','LC') AND linkprim IN ('P','C')
```

### Priority 3: Additional Controls (Optional)

**6. I/B/E/S Analyst Coverage**
```stata
Dataset: ibes.detsumm
Variables: ticker, statpers, numest
```

**7. Thomson Reuters 13F Holdings**
```stata
Dataset: tfn.s34
Variables: cusip, rdate, fdate, shares, mgrno
```

**8. Audit Analytics**
```stata
Dataset: audit.auditnonreli
Variables: company_fkey, filing_date, gc_opinion, big4_auditor
```

**9. Fama-French Factors (Free Download)**
```stata
Source: Ken French Data Library
URL: https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html
File: Fama/French 3 Factors [Daily]
```

## Output Structure

### Tables (CSV, Excel, LaTeX)
```
output/tables/
├── table1_sample_construction.xlsx
├── table2_sample_description.xlsx
├── table2_panelA_temporal.csv
├── table2_panelB_industry.csv
├── table2_panelC_context.csv
├── table3_firm_characteristics.xlsx
├── table4_bhar_results.xlsx
├── table4b_bhar_regressions.csv
├── table5_conditional_ai_market.xlsx
├── table6_factor_loadings.csv
└── results_summary.txt
```

### Figures (PNG, PDF)
```
output/figures/
├── figure1_timeline.png
├── figure2_temporal_pattern.png
├── figure3_cumulative_ar.png
├── figure4_digi_distribution.png
└── figure5_bhar_by_category.png
```

### Appendix Materials
```
output/appendix/
├── appendix_a_examples.xlsx         # Example disclosures
├── appendix_b_variables.xlsx        # Variable definitions
├── appendix_c_robustness.tex        # Robustness tests
└── robustness_tercile_analysis.csv
```

## Variable Naming Conventions

### Core Variables
- `digi_score`: Kindermann (2021) digital orientation score (continuous)
- `digi_category`: 1=Low, 2=Moderate, 3=High digital
- `speculative`: Binary indicator (digi_score < 20)
- `existing`: Binary indicator (digi_score >= 20)

### Event Study Variables
- `bhar_short`: Buy-and-hold abnormal return (-3, +3)
- `bhar_followup`: BHAR (+4, +30)
- `bhar_combined`: BHAR (-3, +30)
- `tstat_*`: T-statistics for BHAR

### Firm Characteristics
- `at`: Total assets ($MM)
- `mve`: Market value of equity ($MM)
- `tobins_q`: Tobin's Q ratio
- `roa`: Return on assets (%)
- `roe`: Return on equity (%)
- `firm_age`: Years since founding
- `hp_index`: Hadlock-Pierce financial constraint index

### AI Mania Proxies
- `ai_market_up`: 1 if AI up-market month, 0 if down-market
- `chatgpt_index`: Google Trends for ChatGPT (normalized)
- `ai_index_ret`: Monthly return on STOXX AI Index (%)

## Adjustable Parameters

### File Paths
Edit `00_master.do` lines 15-20:
```stata
global PROJECT_DIR "/home/user/ai-hype"
global RAW_DATA    "$PROJECT_DIR/data/raw"
global PROC_DATA   "$PROJECT_DIR/data/processed"
global EXT_DATA    "$PROJECT_DIR/data/external"
```

### Classification Thresholds
Edit `02_classify_disclosures.do` lines 65-70:
```stata
* Adjust digitalization category cutoffs
gen digi_category = .
replace digi_category = 1 if digi_score < 10      // Low
replace digi_category = 2 if digi_score < 40      // Moderate
replace digi_category = 3 if digi_score >= 40     // High
```

### Event Windows
Edit `04_event_study.do` lines 80-90:
```stata
* Modify event windows in WRDS Event Study input
Event window: -3 to +3 days      // Short-term
Event window: +4 to +30 days     // Follow-up
Estimation: -175 to -26 days     // Parameter estimation
```

## Troubleshooting

### Common Errors

**1. Missing WRDS data files**
```
Error: File not found - crsp_stock_identifiers.csv
Solution: Extract data from WRDS using instructions in 01_data_processing.do
```

**2. CUSIP-PERMNO merge fails**
```
Error: Merge master using crsp_ids, no matches
Solution: Check ticker format, ensure uppercase, verify WRDS date range
```

**3. Event Study returns empty**
```
Error: bhar_short missing for all observations
Solution: Run WRDS Event Study first (see 04_event_study.do lines 50-150)
         Verify cusip8 format (8 characters)
         Check event_date_wrds format (YYYYMMDD)
```

**4. Digitalization scores missing**
```
Error: digi_score_2021 missing for XX% of sample
Solution: Manual matching of CIK may be required
         Alternative: Use ticker or company name matching
         Contact Kindermann et al. for updated dataset
```

### Performance Tips

1. **Large sample handling**: Use `compress` after each merge
2. **Memory management**: `clear all` at start of each script
3. **Parallel processing**: Run WRDS extractions simultaneously
4. **Checkpoint saves**: Each step saves intermediate .dta file

## Software Requirements

- **STATA**: Version 16 or later (17/18 recommended)
- **Required packages**:
  ```stata
  ssc install estout      // Regression tables
  ssc install outreg2     // Table export (optional)
  ```
- **WRDS access**: Institutional subscription required
- **Disk space**: ~500MB for data files

## Citation

If using this code, please cite:

1. **This study**: [TBD - Paper citation when published]

2. **Kindermann et al. (2021)** for digitalization measure:
   ```
   Kindermann, B., Beutel, S., Garcia de Lomana, G., Strese, S.,
   Bendig, D., & Brettel, M. (2021). Digital orientation:
   Conceptualization and operationalization of a new strategic
   orientation. European Management Journal, 39(5), 645-657.
   ```

3. **Cheng et al. (2019)** for methodology:
   ```
   Cheng, S. F., De Franco, G., Jiang, H., & Lin, P. (2019).
   Riding the Blockchain Mania: Public Firms' Speculative 8-K
   Disclosures. Management Science, 65(12), 5901-5913.
   ```

## Contact

For questions about the code or replication:
- Check inline comments in each .do file
- Review `CLAUDE.md` for conceptual background
- See `REPLICATION_README.txt` for data sources

---

**Last Updated**: October 23, 2025
**STATA Version**: 17 (compatible with 16-18)
**Author**: AI Hype Research Team
