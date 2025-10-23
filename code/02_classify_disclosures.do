********************************************************************************
* STEP 2: DISCLOSURE CLASSIFICATION USING KINDERMANN (2021) DIGI SCORE
*
* Unlike blockchain study's binary classification (Speculative vs Existing),
* we use ex-ante digitalization level as continuous measure
********************************************************************************

clear all
use "$PROC_DATA/sample_firms.dta", clear

* ==============================================================================
* 2.1 CONTINUOUS CLASSIFICATION: KINDERMANN (2021) DIGITALIZATION SCORE
* ==============================================================================

/*
CLASSIFICATION METHODOLOGY - DIGITAL ORIENTATION SCORE

Instead of manually coding 8-Ks as "Speculative" (0) or "Existing" (1), we use
the validated Kindermann et al. (2021) digitalization score from 10-K filings
as a CONTINUOUS measure of firm's ex-ante digital capabilities.

THEORETICAL JUSTIFICATION:
1. More precise than binary: captures gradations of digital sophistication
2. Ex-ante measure: score from 10-K filed BEFORE AI disclosure
3. Validated instrument: published in European Management Journal
4. Replicable: based on computer-aided text analysis (CATA)

KINDERMANN (2021) DIGITAL ORIENTATION DIMENSIONS:
1. Digital Technology Scope (33 terms)
   - Examples: cloud, blockchain, IoT, virtual, sensor, software

2. Digital Capabilities (46 terms)
   - Examples: analytics, AI, machine learning, big data, autonomous

3. Digital Ecosystem Coordination (37 terms)
   - Examples: API, multi-channel, online, platform, smartphone, SaaS

4. Digital Architecture Configuration (32 terms)
   - Examples: automated, algorithm, digital, database, cybersecurity, robot

SCORING:
- Word count per dimension / total words * 1000
- Sum across 4 dimensions = total digi score
- Range in our sample: 0 to ~75 (from 10-K filings 2021-2022)
- Mean: ~25-30, Median: ~20

INTERPRETATION FOR AI DISCLOSURE STUDY:
- LOW digi score (0-10): "Speculative" firms
  * Minimal digital infrastructure pre-AI disclosure
  * AI announcement likely opportunistic/exploratory
  * Expect larger stock market reaction (hype-driven)

- MODERATE digi score (10-40): "Transition" firms
  * Some digital capabilities, now expanding to GenAI
  * Strategic digital transformation underway
  * Mixed market reactions

- HIGH digi score (>40): "Existing Digital" firms
  * Well-established digital operations
  * AI disclosure signals natural extension of capabilities
  * Expect muted market reaction (already priced in)
*/

* ==============================================================================
* 2.2 CREATE CLASSIFICATION VARIABLES
* ==============================================================================

* Continuous measure (primary)
gen digi_score = digi_score_2021
label variable digi_score "Kindermann (2021) digital orientation score"

* Create categorical classifications for subgroup analyses
gen digi_category = .
replace digi_category = 1 if digi_score >= 0 & digi_score < 10
replace digi_category = 2 if digi_score >= 10 & digi_score < 40
replace digi_category = 3 if digi_score >= 40 & !missing(digi_score)

label define digi_cat 1 "Low Digital (Speculative)" ///
                      2 "Moderate Digital (Transition)" ///
                      3 "High Digital (Existing)", replace
label values digi_category digi_cat
label variable digi_category "Digital maturity category"

* Binary classification (for comparison with blockchain study)
gen speculative = (digi_score < 20) if !missing(digi_score)
gen existing = (digi_score >= 20) if !missing(digi_score)

label variable speculative "Low digital orientation (speculative)"
label variable existing "High digital orientation (existing)"

* Standardized score for regressions
egen digi_score_std = std(digi_score)
label variable digi_score_std "Digitalization score (standardized)"

* ==============================================================================
* 2.3 DISTRIBUTION ANALYSIS
* ==============================================================================

* Summary statistics by classification
table digi_category, statistic(frequency) statistic(percent)
summ digi_score, detail

* Cross-tabulation with AI keyword intensity
gen ai_intensity = .
replace ai_intensity = 1 if ai_keyword_count < 5
replace ai_intensity = 2 if ai_keyword_count >= 5 & ai_keyword_count < 10
replace ai_intensity = 3 if ai_keyword_count >= 10 & !missing(ai_keyword_count)

label define ai_int 1 "Low AI mentions (<5)" ///
                    2 "Moderate AI mentions (5-10)" ///
                    3 "High AI mentions (10+)", replace
label values ai_intensity ai_int

table digi_category ai_intensity, statistic(frequency)

* ==============================================================================
* 2.4 DISCLOSURE CONTEXT CLASSIFICATION (PANEL C REPLICATION)
* ==============================================================================

/*
For replication of Table 2 Panel C in blockchain study, classify disclosure
context using text analysis of 8-K abstract and snippets.

CONTEXT CATEGORIES:
1. Mergers and acquisitions (AI companies)
2. Board member/executive changes (AI expertise)
3. AI-related products/services
4. AI technology adoption/integration
5. Future AI plans/exploration
6. Customer AI exposure
7. AI subsidiary or investments
*/

* Initialize context indicators
gen context_ma = 0
gen context_executive = 0
gen context_product = 0
gen context_adoption = 0
gen context_future = 0
gen context_customer = 0
gen context_investment = 0

* M&A context
replace context_ma = 1 if regexm(lower(abstract), "acqui|merger|acquisition|purchase.*company")

* Executive/board changes
replace context_executive = 1 if regexm(lower(abstract), "appoint|hire|chief.*officer|board.*director|executive")

* Product/service
replace context_product = 1 if regexm(lower(abstract), "product|service|solution|platform|application|launch")

* Technology adoption
replace context_adoption = 1 if regexm(lower(abstract), "adopt|implement|deploy|integrate|utilize.*ai|technology")

* Future plans
replace context_future = 1 if regexm(lower(abstract), "plan|intend|explore|investigate|evaluat|future|strategy")

* Customer exposure
replace context_customer = 1 if regexm(lower(abstract), "customer|client|user|demand|market")

* Investment/subsidiary
replace context_investment = 1 if regexm(lower(abstract), "invest|subsidiary|venture|partnership|collaboration")

* Primary context (take first match)
gen primary_context = .
replace primary_context = 1 if context_ma == 1
replace primary_context = 2 if context_executive == 1 & primary_context == .
replace primary_context = 3 if context_product == 1 & primary_context == .
replace primary_context = 4 if context_adoption == 1 & primary_context == .
replace primary_context = 5 if context_future == 1 & primary_context == .
replace primary_context = 6 if context_customer == 1 & primary_context == .
replace primary_context = 7 if context_investment == 1 & primary_context == .

label define context_lbl 1 "M&A" 2 "Executive Change" 3 "Product/Service" ///
                         4 "Technology Adoption" 5 "Future Plans" ///
                         6 "Customer Exposure" 7 "Investment", replace
label values primary_context context_lbl
label variable primary_context "Primary disclosure context"

* ==============================================================================
* 2.5 TEMPORAL PATTERNS
* ==============================================================================

* Create quarter-year variable
gen filing_quarter = qofd(filing_date)
format filing_quarter %tq

gen filing_year = year(filing_date)
gen filing_ym = ym(year(filing_date), month(filing_date))
format filing_ym %tm

* ChatGPT launch indicator
gen post_chatgpt = (filing_date >= td(30nov2022))
label variable post_chatgpt "Post-ChatGPT launch (Nov 30, 2022)"

* ==============================================================================
* 2.6 VALIDATION: COMPARE WITH MANUAL CODING (IF AVAILABLE)
* ==============================================================================

/*
OPTIONAL: Manual validation subsample

For a random sample of ~50 firms, manually code as Speculative/Existing
following blockchain study methodology:

SPECULATIVE criteria:
- Vague future plans to "explore" AI
- Hiring AI-experienced employee only
- Mentioning AI in general strategy without specifics
- No evidence of existing AI products/services

EXISTING criteria:
- Existing AI products or services
- AI-enabled features in products
- Acquisition of AI companies
- AI infrastructure investments
- Significant customer exposure to AI

Compare manual coding with digi_score classification:
- Spearman correlation
- ROC curve analysis
- Optimal threshold determination
*/

* Placeholder for manual codes (if validation performed)
gen manual_speculative = .
gen manual_existing = .

* If manual codes exist, calculate agreement
cap {
    corr digi_score manual_existing, covariance
    roctab manual_existing digi_score
}

* ==============================================================================
* 2.7 SAVE CLASSIFIED SAMPLE
* ==============================================================================

* Label all classification variables
label data "AI 8-K Sample with Kindermann (2021) Classification"

* Save
compress
save "$PROC_DATA/sample_classified.dta", replace

* Export summary table
preserve
collapse (count) n=ticker (mean) mean_digi=digi_score ///
         (sd) sd_digi=digi_score (p50) median_digi=digi_score ///
         (min) min_digi=digi_score (max) max_digi=digi_score, ///
         by(digi_category)

export delimited using "$TABLES/classification_summary.csv", replace
restore

* Context distribution table
preserve
contract primary_context, freq(n) percent(pct)
export delimited using "$TABLES/context_distribution.csv", replace
restore

display as result "STEP 2 COMPLETE: Classification completed"
display as result "Continuous digi score used instead of binary Speculative/Existing"
display as result "Output: $PROC_DATA/sample_classified.dta"

********************************************************************************
