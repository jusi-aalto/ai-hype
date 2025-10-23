********************************************************************************
* STEP 3: DESCRIPTIVE STATISTICS AND TEMPORAL ANALYSIS
* Replicates Tables 2-3 and Figure 2 from blockchain study
********************************************************************************

clear all
use "$PROC_DATA/sample_classified.dta", clear

* ==============================================================================
* 3.1 SAMPLE DESCRIPTION (TABLE 2 PANELS A & B REPLICATION)
* ==============================================================================

* Panel A: Sample by year and quarter
preserve
collapse (count) n_disclosures=ticker, by(filing_year filing_quarter)

* Add ChatGPT Google Trends and AI Index data
merge 1:1 filing_quarter using "$PROC_DATA/ai_mania_proxies.dta", ///
    keep(match master) nogen

* Export for table
export delimited using "$TABLES/table2_panelA_temporal.csv", replace
restore

* Panel B: Sample by industry (Fama-French 12)
preserve
* Calculate FF12 industry from SIC code
* FF12 classification:
/*
1.  Consumer NonDurables: 0100-0999, 2000-2399, 2700-2799, 3100-3199, 3940-3989
2.  Consumer Durables: 2500-2519, 2590-2599, 3630-3659, 3710-3711, 3714-3714, 3716-3716, 3750-3751, 3792-3792, 3900-3939, 3990-3999
3.  Manufacturing: 2520-2589, 2600-2699, 2750-2769, 3000-3099, 3200-3569, 3580-3629, 3700-3709, 3712-3713, 3715-3715, 3717-3749, 3752-3791, 3793-3799, 3860-3899
4.  Energy: 1200-1399, 2900-2999
5.  Chemicals and Allied Products: 2800-2829, 2840-2899
6.  Business Equipment: 3570-3579, 3660-3692, 3694-3699, 3810-3839, 7370-7379
7.  Telecom: 4800-4899
8.  Utilities: 4900-4949
9.  Shops: 5200-5999
10. Healthcare: 2830-2839, 3693-3693, 3840-3859, 8000-8099
11. Finance: 6000-6999
12. Other: everything else
*/

gen ff12 = .
replace ff12 = 1 if inlist(int(sic_code/100), 1, 2, 3, 4, 5, 6, 7, 8, 9) | ///
                    inrange(sic_code, 2000, 2399) | inrange(sic_code, 2700, 2799) | ///
                    inrange(sic_code, 3100, 3199) | inrange(sic_code, 3940, 3989)
replace ff12 = 2 if inrange(sic_code, 2500, 2519) | inrange(sic_code, 2590, 2599) | ///
                    inrange(sic_code, 3630, 3659) | inrange(sic_code, 3710, 3711) | ///
                    inlist(sic_code, 3714, 3716) | inlist(sic_code, 3750, 3751, 3792) | ///
                    inrange(sic_code, 3900, 3939) | inrange(sic_code, 3990, 3999)
replace ff12 = 3 if inrange(sic_code, 2520, 2589) | inrange(sic_code, 2600, 2699) | ///
                    inrange(sic_code, 2750, 2769) | inrange(sic_code, 3000, 3099) | ///
                    inrange(sic_code, 3200, 3569) | inrange(sic_code, 3580, 3629) | ///
                    inrange(sic_code, 3700, 3709) | inrange(sic_code, 3712, 3713) | ///
                    inlist(sic_code, 3715) | inrange(sic_code, 3717, 3749) | ///
                    inrange(sic_code, 3752, 3791) | inrange(sic_code, 3793, 3799) | ///
                    inrange(sic_code, 3860, 3899)
replace ff12 = 4 if inrange(sic_code, 1200, 1399) | inrange(sic_code, 2900, 2999)
replace ff12 = 5 if inrange(sic_code, 2800, 2829) | inrange(sic_code, 2840, 2899)
replace ff12 = 6 if inrange(sic_code, 3570, 3579) | inrange(sic_code, 3660, 3692) | ///
                    inrange(sic_code, 3694, 3699) | inrange(sic_code, 3810, 3839) | ///
                    inrange(sic_code, 7370, 7379)
replace ff12 = 7 if inrange(sic_code, 4800, 4899)
replace ff12 = 8 if inrange(sic_code, 4900, 4949)
replace ff12 = 9 if inrange(sic_code, 5200, 5999)
replace ff12 = 10 if inrange(sic_code, 2830, 2839) | sic_code == 3693 | ///
                     inrange(sic_code, 3840, 3859) | inrange(sic_code, 8000, 8099)
replace ff12 = 11 if inrange(sic_code, 6000, 6999)
replace ff12 = 12 if ff12 == .

label define ff12_lbl 1 "Consumer NonDur" 2 "Consumer Dur" 3 "Manufacturing" ///
                      4 "Energy" 5 "Chemicals" 6 "Business Equip" ///
                      7 "Telecom" 8 "Utilities" 9 "Retail" ///
                      10 "Healthcare" 11 "Finance" 12 "Other", replace
label values ff12 ff12_lbl

collapse (count) n=ticker (mean) avg_digi=digi_score ///
         (sum) n_spec=speculative n_exist=existing, by(ff12)

export delimited using "$TABLES/table2_panelB_industry.csv", replace
restore

* Panel C: Disclosure context distribution
preserve
contract primary_context, freq(n) percent(pct)
export delimited using "$TABLES/table2_panelC_context.csv", replace
restore

* ==============================================================================
* 3.2 FIRM CHARACTERISTICS COMPARISON (TABLE 3 REPLICATION)
* ==============================================================================

/*
Compare firm characteristics across digitalization levels:
1. Low Digital (Speculative equivalent)
2. Moderate Digital
3. High Digital (Existing equivalent)

VARIABLES TO COMPARE:
A. General characteristics:
   - Size (ln total assets)
   - Market value
   - Revenue
   - Tobin's Q
   - Firm age

B. Performance:
   - ROA
   - ROE
   - Loss indicator
   - Prior year stock returns

C. Capital demand:
   - Equity issuance
   - Financing cash flow
   - HP financial constraint index
   - Going concern opinion (if available)

D. Monitoring:
   - Analyst coverage
   - Institutional ownership
   - Media coverage (if available)
   - Big 4 auditor
   - Internal control weakness
*/

* Prepare variables
gen ln_assets = ln(at)
gen ln_mve = ln(mve)
gen ln_sales = ln(sale)
gen ln_age = ln(firm_age)

label variable ln_assets "Log(Total Assets)"
label variable ln_mve "Log(Market Value)"
label variable ln_sales "Log(Sales)"
label variable ln_age "Log(Firm Age)"

* Table 3 generation
preserve

* Calculate means and t-tests for each digi_category
* Separate columns for Low/Moderate/High digital categories

local varlist ln_assets ln_mve ln_sales tobins_q ln_age ///
              roa roe loss dltis fincf hp_index ///
              analyst_coverage inst_ownership big4_auditor ///
              ai_keyword_count

* Summary table by digital category
table digi_category, ///
    statistic(mean ln_assets ln_mve ln_sales tobins_q ln_age) ///
    statistic(mean roa roe loss hp_index) ///
    statistic(sd ln_assets ln_mve tobins_q roa)

* Export detailed comparison
collapse (mean) mean_* = `varlist' ///
         (sd) sd_* = `varlist' ///
         (count) n = ticker, by(digi_category)

export delimited using "$TABLES/table3_firm_characteristics.csv", replace
restore

* T-tests between groups
preserve
ttest ln_assets, by(speculative)
local t_assets = r(t)
local p_assets = r(p)

ttest tobins_q, by(speculative)
local t_q = r(t)
local p_q = r(p)

ttest roa, by(speculative)
local t_roa = r(t)
local p_roa = r(p)

* Store results for table
restore

* ==============================================================================
* 3.3 TEMPORAL PATTERN VISUALIZATION (FIGURE 2 REPLICATION)
* ==============================================================================

/*
Create time series plot showing:
1. Number of first AI 8-K disclosures by quarter
2. Overlay with ChatGPT Google Trends index
3. Overlay with STOXX Global AI Index performance
4. Separate lines for low vs high digitalization firms
*/

preserve

* Collapse to quarterly level
collapse (count) n_total=ticker ///
         (sum) n_low_digi=(digi_category==1) ///
               n_high_digi=(digi_category==3), ///
         by(filing_quarter)

* Merge with AI mania proxy data (ChatGPT trends, AI index)
merge 1:1 filing_quarter using "$PROC_DATA/ai_mania_proxies.dta", ///
    keep(match master) nogen

* Format for plotting
format filing_quarter %tq

* Generate plot
twoway (bar n_total filing_quarter, yaxis(1) barwidth(0.8) color(gs12)) ///
       (line n_low_digi filing_quarter, yaxis(1) lwidth(medthick) color(red)) ///
       (line n_high_digi filing_quarter, yaxis(1) lwidth(medthick) color(blue)) ///
       (line chatgpt_index filing_quarter, yaxis(2) lwidth(medium) color(orange) lpattern(dash)) ///
       (line ai_stock_index filing_quarter, yaxis(2) lwidth(medium) color(green) lpattern(dot)), ///
       title("Temporal Pattern of AI Disclosures and AI Mania") ///
       subtitle("October 2022 - October 2025") ///
       xtitle("Filing Quarter") ///
       ytitle("Number of Disclosures", axis(1)) ///
       ytitle("Index (Normalized)", axis(2)) ///
       legend(order(1 "Total Disclosures" 2 "Low Digital Firms" ///
                    3 "High Digital Firms" 4 "ChatGPT Google Trends" ///
                    5 "STOXX AI Index") rows(2) size(small)) ///
       xline(`=tq(2022q4)', lpattern(solid) lcolor(black) lwidth(thin)) ///
       text(, placement(ne) "ChatGPT Launch") ///
       graphregion(color(white)) bgcolor(white) ///
       name(fig2_temporal, replace)

graph export "$FIGURES/figure2_temporal_pattern.png", replace width(3000)
graph export "$FIGURES/figure2_temporal_pattern.pdf", replace
restore

* ==============================================================================
* 3.4 ADDITIONAL DESCRIPTIVE ANALYSES
* ==============================================================================

* Distribution of digi scores
histogram digi_score, frequency ///
    title("Distribution of Kindermann (2021) Digitalization Scores") ///
    xtitle("Digital Orientation Score") ytitle("Frequency") ///
    xline(10 20 40, lpattern(dash)) ///
    graphregion(color(white)) bgcolor(white) ///
    name(digi_dist, replace)
graph export "$FIGURES/digi_score_distribution.png", replace

* Scatter: AI keyword count vs digi score
twoway (scatter ai_keyword_count digi_score, mcolor(navy%50)) ///
       (lfit ai_keyword_count digi_score, lcolor(red)), ///
       title("AI Disclosure Intensity vs Ex-Ante Digitalization") ///
       xtitle("Digital Orientation Score (Pre-Disclosure)") ///
       ytitle("AI Keyword Count in 8-K") ///
       legend(off) graphregion(color(white)) bgcolor(white) ///
       name(scatter_ai_digi, replace)
graph export "$FIGURES/scatter_ai_keywords_digi.png", replace

* Correlation matrix
pwcorr digi_score ai_keyword_count ln_assets tobins_q roa firm_age, ///
    star(0.05) sig

matrix C = r(C)
esttab matrix(C, fmt(3)) using "$TABLES/correlation_matrix.csv", replace

* ==============================================================================
* 3.5 SUMMARY STATISTICS TABLE
* ==============================================================================

eststo clear
estpost summarize digi_score ai_keyword_count ln_assets ln_mve tobins_q ///
                  roa roe loss firm_age hp_index, detail

esttab using "$TABLES/summary_statistics.csv", replace ///
    cells("count mean(fmt(3)) sd(fmt(3)) min(fmt(3)) p50(fmt(3)) max(fmt(3))") ///
    nomtitle nonumber

display as result "STEP 3 COMPLETE: Descriptive statistics generated"
display as result "Tables saved to: $TABLES/"
display as result "Figures saved to: $FIGURES/"

********************************************************************************
