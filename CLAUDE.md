# Replication Study: Riding the Generative AI Mania

## Project Overview

This project replicates the methodology from Cheng et al. (2019) "Riding the Blockchain Mania: Public Firms' Speculative 8-K Disclosures" to study how public companies disclosed Generative AI-related information during the 2022-2025 AI boom, and how investors reacted to these disclosures.

**Research Period**: October 2022 (ChatGPT pre-launch) to October 2025
**Key Event**: ChatGPT launch on November 30, 2022
**Original Paper**: blockchain_hype.pdf

---

## Research Questions

1. **Disclosure Timing**: Are firms opportunistic in the timing and content of their Generative AI disclosures during the AI mania period?

2. **Investor Rationality**: Do investors react rationally to AI-related 8-K disclosures, or do they overreact to speculative announcements?

3. **AI Mania Evidence**: Do market reactions correlate with AI technology hype (Google Trends, AI stock index performance)?

---

## Data Inventory

### ✅ Data Already Available

1. **ai_8k_oct2022_oct_2025.csv** (Primary sample)
   - Company 8-K filings mentioning AI keywords: "llm OR chatgpt OR gpt OR generative OR language model"
   - Time period: October 2022 - October 2025
   - Fields:
     - `name`: Company name with ticker symbol
     - `keyInstn`: Company identifier
     - `filingDate`: Date of 8-K filing
     - `keyFileCollection`: Filing ID
     - `abstract`: Summary of disclosure
     - `snippets`: Text excerpts containing AI keywords
     - `keywordMentionCount`: Number of AI keyword mentions
   - **Sample size**: ~50+ companies (needs full count)

2. **chatgpt_google.csv** (Mania proxy - Google Trends)
   - Weekly Google Trends data for "ChatGPT" searches
   - Time period: October 2020 - October 2025
   - Shows ChatGPT mania starting late November 2022
   - Peak interest: September 2024 (index = 100)
   - Fields: `date`, `chatgpt` (search index 0-100)

3. **istoxx_global_ai_100_index.txt** (AI market proxy)
   - Daily STOXX Global AI index values
   - Time period: August 2020 - present
   - Can serve as "AI price" proxy (analogous to Bitcoin price)
   - Fields: `date`, `index`

4. **8k_query.txt** (Search keywords used)
   - Documents the keyword search strategy

5. **blockchain_hype.pdf** (Original paper)
   - Complete methodology reference

### ❌ Data Still Needed

1. **Stock Price Data**
   - Daily stock returns for all sample firms
   - Sources: CRSP (Center for Research in Security Prices) or alternative
   - Period: Trading days from -175 to +30 relative to 8-K filing date
   - For: Event study methodology (BHAR calculation)

2. **Firm Financial Characteristics**
   - Source: Compustat (annual)
   - Variables needed (measured 12 months prior to disclosure):
     - Total assets
     - Market value
     - Revenue
     - Tobin's Q / Book-to-market ratio
     - Firm age
     - ROA, ROE
     - Loss indicator
     - Equity issuance
     - Financing cash flows
     - Financial constraint index (Hadlock-Pierce 2010)

3. **Auditor Data**
   - Source: Audit Analytics
   - Going concern opinions
   - Big-4 auditor indicator
   - Internal control weaknesses

4. **Information Environment**
   - Analyst coverage (I/B/E/S Detail)
   - Institutional ownership (Thomson Reuters)
   - Media coverage (RavenPack or similar)

5. **Market Data**
   - Fama-French 3-factor daily returns (from Kenneth French data library)
   - Risk-free rate (daily)
   - For: Abnormal return calculations

6. **Industry Classification**
   - SIC codes for industry matching
   - Fama-French 12 industry classification

7. **Control Sample**
   - Non-disclosing firms matched by:
     - Size (closest total assets)
     - Industry (same 3-digit SIC code)
   - For: Comparison analysis

---

## Methodology: Step-by-Step

### STEP 1: Sample Construction & Data Cleaning

**Objective**: Build final sample of initial AI 8-K disclosures

**Tasks**:
1. Load `ai_8k_oct2022_oct_2025.csv`
2. Identify **first** AI-related 8-K for each unique company
3. Manual reading and screening:
   - Exclude irrelevant mentions (boilerplate language, general industry discussion)
   - Exclude firms stating no intention to use AI
   - Exclude investment funds
4. Merge with stock price data (CRSP) - exclude firms without price data
5. Extract ticker symbols from company names
6. Create final sample dataset with one row per company

**Expected Output**:
- `sample_firms.csv`: Final sample with company identifiers, first filing date
- Sample size: ~50-80 firms (similar to blockchain study's 82 firms)

---

### STEP 2: Disclosure Classification (Speculative vs Existing)

**Objective**: Classify firms based on substance of AI disclosure

**Classification Criteria**:

**Speculative Firms** (lack meaningful AI commitment):
- Vague future plans to "explore" or "investigate" AI
- Hiring of AI-experienced employee/board member only
- Mentioning AI in general strategy without specifics
- No evidence of existing AI products/services/infrastructure

**Existing Firms** (meaningful AI track record):
- Existing AI products or services
- AI-enabled features in products
- Acquisition of AI companies/projects
- AI infrastructure investments
- Acceptance of AI-related business models
- Significant customer exposure to AI

**Process**:
1. Three independent reviewers read each 8-K's `abstract` and `snippets`
2. Classify each as Speculative (0) or Existing (1)
3. Resolve disagreements through discussion
4. Document examples (Appendix A style)

**Context Categories** (Panel C style):
1. Mergers and acquisitions (AI companies)
2. Board member/executive changes (AI expertise)
3. AI-related products/services
4. AI technology adoption/integration
5. Future AI plans
6. Customer AI exposure
7. AI subsidiary or investments

**Expected Output**:
- `sample_classified.csv`: Sample with classification variables
- Count keywords used in initial 8-K (`keywordMentionCount` already available)
- Distribution by classification and context

---

### STEP 3: Descriptive Statistics

**Objective**: Characterize sample firms and validate classification

**Analysis 3A: Temporal Patterns**
- Plot number of initial AI 8-Ks by quarter (Figure 2 replication)
- Overlay with:
  - ChatGPT Google Trends index
  - STOXX Global AI Index
- Separate plots for Speculative vs Existing firms

**Analysis 3B: Industry Distribution**
- Classify firms by Fama-French 12 industries
- Table 2 Panel B replication

**Analysis 3C: Disclosure Context**
- Frequency distribution by context categories
- Table 2 Panel C replication

**Analysis 3D: Firm Characteristics**
- Compare Speculative firms vs:
  - Size-industry matched control firms
  - Existing firms
- Variables (Table 3 replication):
  - **General**: Size, market value, revenue, Tobin's Q, age
  - **Performance**: ROA, ROE, loss indicator, stock returns
  - **Capital demand**: Equity issuance, financing cash flow, financial constraint index, going concern
  - **Monitoring**: Analyst coverage, institutional ownership, media coverage, Big-4 auditor, internal control weaknesses
- Calculate keyword count in initial 8-K

**Expected Output**:
- Figure: Temporal pattern of AI disclosures with mania proxies
- Table: Sample description by year, industry, context
- Table: Firm characteristics comparison

---

### STEP 4: Event Study - Investor Reactions

**Objective**: Measure market reactions to initial AI 8-K disclosures

**Methodology: Buy-and-Hold Abnormal Returns (BHAR)**

**Event Windows**:
- Initial reaction: (-3, +3) days relative to filing date
- Follow-up period: (+4, +30) days
- Combined period: (-3, +30) days

**Steps**:

1. **Calculate Normal Returns**:
   - Estimation window: (-175, -26) days before event
   - Fama-French 3-factor model: R_it = α_i + β_1,i × MKT_t + β_2,i × SMB_t + β_3,i × HML_t + ε_it
   - Estimate α and β coefficients for each firm

2. **Calculate Benchmark Returns**:
   - For each event window, calculate expected return using estimated model
   - BHAR_benchmark = Buy-and-hold return of benchmark portfolio

3. **Calculate Abnormal Returns**:
   - BHAR_i = (Actual buy-and-hold return)_i - (Benchmark buy-and-hold return)_i
   - Do this for each event window

4. **Statistical Tests**:
   - Calculate mean BHAR for:
     - All firms
     - Speculative firms only
     - Existing firms only
   - T-statistics for significance
   - Test differences: Speculative - Existing

5. **Benchmark Analysis**:
   - Calculate BHAR for all OTHER 8-Ks filed by sample firms in 12 months PRIOR to AI disclosure
   - Should be close to zero (validates method)

**Expected Output**:
- Table 4 replication: BHAR returns by firm type and window
- Figure 3 replication: Time-series plot of cumulative BHAR with confidence intervals
- Statistical significance tests

---

### STEP 5: Additional Analyses - Evidence of AI Mania

**Analysis 5A: Conditional on AI Index Performance**

**Objective**: Test if reactions stronger when AI enthusiasm higher

**Methodology**:
1. Calculate monthly returns for STOXX Global AI Index
2. Rank all months in sample period (Oct 2022 - Oct 2025)
3. Split into:
   - AI Up-market: Top 50% of months by AI index return
   - AI Down-market: Bottom 50% of months
4. Classify each 8-K by whether filing date falls in up or down period
5. Calculate BHAR (-3, +3) separately for up/down markets
6. Test difference

**Expected Results** (if mania exists):
- Positive, significant BHAR in up-markets
- Insignificant or negative BHAR in down-markets
- Significant difference between periods

**Output**: Table 5 replication

---

**Analysis 5B: Comovement with AI Index**

**Objective**: Test if AI-disclosing stocks gain AI exposure

**Methodology**:
1. Construct portfolios:
   - Speculative portfolio: Equal-weighted daily returns, add firms after first AI 8-K
   - Existing portfolio: Same methodology
   - Control portfolios: Use matched non-disclosing firms

2. Estimate factor loadings:
   - Model: R_portfolio,t = α + β_1 × AI_Index_Return_t + β_2 × MKT_t + β_3 × SMB_t + β_4 × HML_t + ε_t
   - AI_Index_Return_t = Daily return of STOXX Global AI Index minus risk-free rate

3. Test hypotheses:
   - H1: β_1 > 0 for Speculative and Existing portfolios (gain AI exposure)
   - H2: β_1 = 0 for control portfolios (no AI exposure)
   - H3: β_1(Existing) > β_1(Speculative) (Existing has more real exposure)

**Expected Results** (if mania exists):
- Positive, significant AI index loading for both Speculative and Existing
- Zero loading for control firms
- Stronger loading for Existing (more real AI exposure)

**Output**: Table 6 replication

---

## Analysis Plan Summary

### Primary Hypotheses

**H1: Opportunistic Disclosure Timing**
- Speculative firms concentrate disclosures during peak AI mania (2023-2024)
- Existing firms more evenly distributed across time
- Evidence: Figure showing temporal concentration of Speculative disclosures

**H2: Investor Overreaction**
- Speculative firms generate positive short-term abnormal returns
- These returns reverse in 30-day window
- Existing firms show minimal reaction
- Evidence: BHAR analysis showing +7-8% initial, -5-6% reversal for Speculative

**H3: AI Mania Matters**
- Stronger reactions when AI index performing well (up-market)
- Insignificant reactions in down-market
- Evidence: Conditional BHAR analysis

**H4: Investors Seek AI Exposure**
- Disclosing firms' stocks comove with AI index post-disclosure
- Control firms show no comovement
- Evidence: Factor loading analysis

---

## Extensions Beyond Original Study

### Potential Additional Analyses

1. **LLM-Enhanced Classification**
   - Use GPT-4 or Claude to classify disclosures as Speculative/Existing
   - Compare with manual classification
   - Analyze linguistic features predicting overreaction

2. **Keyword Sophistication**
   - Compare "ChatGPT" mentions vs "LLM" vs "generative AI"
   - Test if more technical language associated with less overreaction

3. **Company Size Heterogeneity**
   - Split by market cap quartiles
   - Test if overreaction stronger for smaller firms

4. **Post-Disclosure Performance**
   - Track longer-term outcomes (1 year, 2 years)
   - Did any Speculative firms deliver on AI promises?
   - Compare stock performance to fundamentals

5. **Media Amplification**
   - Correlate media coverage with market reaction
   - Test if media attention amplifies mania effect

6. **Cross-Sectional Predictors**
   - What firm characteristics predict:
     - Likelihood of Speculative disclosure?
     - Magnitude of overreaction?
   - Logit and OLS regressions

---

## Technical Implementation

### Required Code Modules

1. **Data Processing** (`01_data_processing.py`)
   - Load and clean 8-K data
   - Extract tickers, dates, text
   - Merge with financial data
   - Create matched control sample

2. **Classification** (`02_classify_disclosures.py`)
   - Manual review interface
   - Classification storage
   - Inter-rater reliability calculation
   - Context categorization

3. **Descriptive Analysis** (`03_descriptives.py`)
   - Temporal plots
   - Industry distributions
   - Firm characteristics tables
   - Summary statistics

4. **Event Study** (`04_event_study.py`)
   - BHAR calculation
   - Fama-French factor matching
   - Statistical tests
   - Visualization (cumulative returns plot)

5. **Additional Tests** (`05_additional_analyses.py`)
   - Up/down market split
   - Portfolio construction
   - Factor loadings estimation
   - Robustness checks

6. **Tables & Figures** (`06_output_tables.py`)
   - Formatted tables (LaTeX, HTML)
   - Publication-quality figures
   - Appendices

### Software Requirements

- **Python 3.8+**
  - pandas, numpy: Data manipulation
  - scipy, statsmodels: Statistical tests
  - matplotlib, seaborn: Visualization
  - wrds: Access to financial databases (if available)

- **R** (alternative for some analyses)
  - tidyverse: Data manipulation
  - broom: Statistical modeling
  - ggplot2: Visualization

---

## Data Access Strategy

### If WRDS Access Available

- Direct queries to CRSP, Compustat, I/B/E/S, Audit Analytics
- Use existing WRDS Python/R packages

### If No WRDS Access

**Alternative Sources**:

1. **Stock Prices**:
   - Yahoo Finance API (free, limited history)
   - Alpha Vantage API (free tier available)
   - Polygon.io (generous free tier)

2. **Financial Data**:
   - SEC EDGAR (free, requires parsing):
     - 10-K filings for annual financials
     - Use EDGAR API or web scraping
   - Financial Modeling Prep API (free tier)
   - Simfin (free financial data)

3. **Analyst Coverage**:
   - Estimize (alternative to I/B/E/S)
   - Company earnings call transcripts (estimate coverage)

4. **Institutional Ownership**:
   - SEC 13F filings (quarterly, requires aggregation)
   - WhaleWisdom (free tier)

5. **Market Factors**:
   - Fama-French factors: Free from Kenneth French's website
   - Risk-free rate: FRED (Federal Reserve Economic Data)

**Trade-offs**:
- Free data may have gaps or lower quality
- Requires more data cleaning
- May limit sample to well-covered firms

---

## Timeline Estimate

### Phase 1: Data Collection (2-3 weeks)
- Week 1: Stock price data acquisition
- Week 2: Financial characteristics data
- Week 3: Control variables, matching

### Phase 2: Classification (1 week)
- Manual review of 50-80 8-K disclosures
- Inter-rater reliability check
- Context categorization

### Phase 3: Analysis (2 weeks)
- Week 1: Descriptive statistics, temporal analysis
- Week 2: Event study, BHAR calculations

### Phase 4: Additional Tests (1 week)
- Up/down market analysis
- Portfolio construction
- Factor loadings

### Phase 5: Output & Writing (1-2 weeks)
- Tables and figures
- Results interpretation
- Draft paper sections

**Total**: 7-9 weeks for core replication

---

## Expected Findings

### Based on Original Paper and AI Context

**Likely Results**:

1. **Sharp increase in AI 8-Ks** after ChatGPT launch (Nov 2022)
   - Peak disclosures in 2023-2024
   - 70-80% driven by Speculative firms

2. **Speculative firms**: +5-10% BHAR in (-3, +3) window
   - Reversal of -4-8% in (+4, +30) window
   - Net effect close to zero

3. **Existing firms**: Minimal to zero reaction
   - AI activities likely already known

4. **Stronger reactions** when AI index returns positive
   - 10-15% BHAR in up-markets
   - 0% or negative in down-markets

5. **Portfolio comovement** with AI index
   - Positive, significant factor loading (0.05-0.10)
   - Stronger for Existing than Speculative

### Key Differences from Blockchain Study

**AI Context is Different**:
- **More mainstream adoption**: ChatGPT reached 100M users in 2 months (vs years for Bitcoin)
- **Corporate integration**: AI more immediately applicable to business operations
- **Multiple "AI prices"**: No single asset like Bitcoin (use NVIDIA stock? OpenAI valuation? AI index?)
- **Longer timeline available**: 3 years of data (2022-2025) vs blockchain's concentrated 2017 period

**Implications**:
- May find LESS extreme overreaction (AI more legitimate)
- More Existing firms (real AI integration happening)
- Less dramatic reversal (AI delivering actual value)
- BUT still expect mania effects given rapid hype cycle

---

## Key Challenges & Limitations

### Challenges

1. **No single "AI price" proxy**
   - Bitcoin was perfect for blockchain (direct, 1:1)
   - AI is broader technology
   - Using AI stock index is less direct
   - Consider alternatives: NVIDIA stock, Microsoft stock

2. **Faster mainstream adoption**
   - Harder to separate mania from real value
   - AI genuinely transforming business quickly
   - Speculative vs Existing line may blur

3. **Classification subjectivity**
   - More firms have some AI activity
   - Harder to classify as purely "Speculative"
   - Need clear, consistent criteria

4. **Data availability**
   - Recent time period = less cleaned data available
   - Some firms may be small/thinly traded
   - May need to drop firms lacking data

### Limitations

1. **Cannot prove managerial intent**
   - Don't observe whether managers deliberately hype
   - Correlation, not causation

2. **Retrospective bias**
   - Knowing AI succeeded may influence classification
   - Mitigate with blind review of disclosure text only

3. **External validity**
   - Results specific to AI mania 2022-2025
   - May not generalize to future tech hype cycles

4. **Sample size**
   - Likely smaller than desired due to data constraints
   - Power issues for detecting effects

---

## Deliverables

### Academic Paper Structure

1. **Introduction**
   - Motivation: AI mania parallels blockchain mania
   - Research questions
   - Preview of findings

2. **Background**
   - ChatGPT launch and AI boom
   - SEC concerns about AI disclosures
   - Theoretical framework (investor mania, strategic disclosure)

3. **Sample and Data**
   - 8-K disclosure identification
   - Classification methodology
   - Descriptive statistics

4. **Results**
   - Temporal patterns
   - Firm characteristics
   - Event study results
   - Additional analyses

5. **Conclusion**
   - Summary of findings
   - Implications
   - Limitations and future research

### Supplementary Materials

- **Appendix A**: Example disclosures (Speculative vs Existing)
- **Appendix B**: Variable definitions
- **Online Appendix**: Additional robustness tests
- **Replication Package**: Code and data (where shareable)

---

## Next Steps

### Immediate Actions

1. **Count total firms** in `ai_8k_oct2022_oct_2025.csv`
2. **Identify unique companies** (deduplicate by ticker)
3. **Extract first AI disclosure** per company
4. **Prioritize data acquisition**:
   - Stock prices (most critical for event study)
   - Basic financials (for matching and characteristics)
5. **Develop classification rubric** with clear examples
6. **Pilot analysis** with subset of 10-20 firms

### Questions to Resolve

1. **Which "AI price" to use?**
   - STOXX Global AI Index (current choice)
   - NVIDIA stock (most identified with AI boom)
   - Blend of multiple indicators?

2. **Time period adjustment?**
   - Keep Oct 2022 start (pre-ChatGPT baseline)?
   - Start Nov 2022 (ChatGPT launch)?

3. **Keyword expansion?**
   - Current: llm, chatgpt, gpt, generative, language model
   - Add: artificial intelligence, machine learning, AI?
   - Risk: too broad, lose specificity

4. **OTC firms?**
   - Include over-the-counter traded stocks (like blockchain study)?
   - Expect stronger effects but harder to get data

---

## Project Organization

```
ai-hype/
├── data/
│   ├── raw/
│   │   ├── ai_8k_oct2022_oct_2025.csv
│   │   ├── chatgpt_google.csv
│   │   ├── istoxx_global_ai_100_index.txt
│   │   └── [stock_prices.csv - to be added]
│   ├── processed/
│   │   ├── sample_firms.csv
│   │   ├── sample_classified.csv
│   │   └── merged_analysis.csv
│   └── external/
│       ├── ff_factors.csv (Fama-French factors)
│       └── compustat_extract.csv
├── code/
│   ├── 01_data_processing.py
│   ├── 02_classify_disclosures.py
│   ├── 03_descriptives.py
│   ├── 04_event_study.py
│   ├── 05_additional_analyses.py
│   └── 06_output_tables.py
├── output/
│   ├── tables/
│   ├── figures/
│   └── appendix/
├── docs/
│   ├── CLAUDE.md (this file)
│   ├── classification_rubric.md
│   └── variable_definitions.md
├── paper/
│   ├── main.tex
│   └── references.bib
└── blockchain_hype.pdf (reference paper)
```

---

## References

### Original Study
Cheng, S. F., De Franco, G., Jiang, H., & Lin, P. (2019). Riding the Blockchain Mania: Public Firms' Speculative 8-K Disclosures. *Management Science*, 65(12), 5901-5913.

### Key Methodological Papers
- Fama, E. F., & French, K. R. (1993). Common risk factors in the returns on stocks and bonds. *Journal of Financial Economics*, 33(1), 3-56.
- Kothari, S. P., & Warner, J. B. (2007). Econometrics of event studies. *Handbook of Empirical Corporate Finance*, 3-36.
- Cooper, M. J., Dimitrov, O., & Rau, P. R. (2001). A rose.com by any other name. *Journal of Finance*, 56(6), 2371-2388.

### AI Mania Context
- ChatGPT launch: November 30, 2022
- Reached 100M users: January 2023 (fastest-growing consumer app)
- Major AI developments 2023-2024:
  - GPT-4 (March 2023)
  - Google Bard/Gemini (Feb 2023)
  - Microsoft Copilot integration
  - Anthropic Claude
  - Meta LLaMA
  - Open-source AI explosion

---

## Contact & Collaboration

**Research Team**:
- Lead: [Your name]
- Affiliation: [Your institution]
- Contact: [Email]

**Data Contributors**:
- 8-K data source: [Specify if SEC EDGAR or vendor]
- Stock price data: [To be determined]

**Last Updated**: October 23, 2025

---

*This replication study aims to provide timely evidence on corporate AI disclosures during the Generative AI boom, parallel to the blockchain mania of 2017. The study combines rigorous academic methodology with practical insights for investors, regulators, and managers navigating technology hype cycles.*
