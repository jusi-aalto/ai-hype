********************************************************************************
* STEP 6: GENERATE PUBLICATION-QUALITY TABLES AND FIGURES
*
* Creates formatted output for academic paper submission
********************************************************************************

clear all
use "$PROC_DATA/sample_final_analyses.dta", clear

* ==============================================================================
* 6.1 PUBLICATION SETTINGS
* ==============================================================================

* Set graph scheme for consistent appearance
set scheme s2color

* Table formatting options
local table_format "csv rtf tex"  // Export to multiple formats

* Figure resolution
local fig_dpi 300
local fig_width 4000

* ==============================================================================
* 6.2 TABLE 1: SAMPLE CONSTRUCTION AND ATTRITION
* ==============================================================================

/*
Panel A: Sample Selection Process
- Initial AI 8-Ks identified (Oct 2022 - Oct 2025)
- Exclude: investment funds, insufficient data, etc.
- Final sample size

Panel B: Comparison with Blockchain Study
*/

putexcel set "$TABLES/table1_sample_construction.xlsx", replace

putexcel A1 = "Table 1: Sample Construction"
putexcel A3 = "Panel A: Sample Selection"
putexcel A4 = "Initial 8-K filings with AI keywords (Oct 2022 - Oct 2025)"
putexcel A5 = "Less: Duplicate firms (keep first disclosure only)"
putexcel A6 = "Less: Investment funds"
putexcel A7 = "Less: Missing stock price data (CRSP)"
putexcel A8 = "Less: Missing financial data (Compustat)"
putexcel A9 = "Less: Missing digitalization score"
putexcel A10 = "Final sample"

* Count observations at each step (using actual data)
count
putexcel B4 = r(N)

* Calculate attrition (placeholders - adjust based on actual filters)
count if missing(permno)
local missing_crsp = r(N)
putexcel B7 = `missing_crsp'

count if missing(at)
local missing_compustat = r(N)
putexcel B8 = `missing_compustat'

count if missing(digi_score)
local missing_digi = r(N)
putexcel B9 = `missing_digi'

count if !missing(permno) & !missing(at) & !missing(digi_score)
putexcel B10 = r(N)

putexcel A12 = "Panel B: Comparison with Blockchain Study (Cheng et al. 2019)"
putexcel A13 = "Sample period"
putexcel B13 = "Oct 2022 - Oct 2025" C13 = "Jan 2017 - Feb 2018"

putexcel A14 = "Technology event"
putexcel B14 = "ChatGPT Launch (Nov 30, 2022)" C14 = "Bitcoin Peak ($19,783)"

putexcel A15 = "Final sample size"
count if !missing(bhar_short)
putexcel B15 = r(N)
putexcel C15 = "82 firms"

* ==============================================================================
* 6.3 TABLE 2: SAMPLE DESCRIPTION
* ==============================================================================

* Panel A: Temporal distribution (already created in Step 3)
* Panel B: Industry distribution (already created in Step 3)
* Panel C: Disclosure context (already created in Step 3)

* Combine into one formatted table
putexcel set "$TABLES/table2_sample_description.xlsx", replace

putexcel A1 = "Table 2: Sample Description"
putexcel A3 = "Panel A: Distribution by Quarter and Year"

* Import temporal data and format nicely
preserve
import delimited using "$TABLES/table2_panelA_temporal.csv", clear

* Add to Excel
putexcel A4 = "Quarter" B4 = "N" C4 = "%" D4 = "ChatGPT Trends" E4 = "AI Stock Index"

local row = 5
forval i = 1/`=_N' {
    putexcel A`row' = filing_quarter[`i']
    putexcel B`row' = n_disclosures[`i']
    local row = `row' + 1
}
restore

* ==============================================================================
* 6.4 TABLE 3: FIRM CHARACTERISTICS
* ==============================================================================

* Enhanced version with statistical tests
eststo clear

* Low Digital firms
eststo low: estpost summarize ln_assets ln_mve tobins_q roa roe loss ///
                              firm_age hp_index analyst_coverage ///
                              if digi_category == 1, detail

* Moderate Digital firms
eststo mod: estpost summarize ln_assets ln_mve tobins_q roa roe loss ///
                              firm_age hp_index analyst_coverage ///
                              if digi_category == 2, detail

* High Digital firms
eststo high: estpost summarize ln_assets ln_mve tobins_q roa roe loss ///
                               firm_age hp_index analyst_coverage ///
                               if digi_category == 3, detail

* Export to LaTeX for paper
esttab low mod high using "$TABLES/table3_characteristics.tex", replace ///
    cells("mean(fmt(3)) sd(fmt(3))") ///
    mtitles("Low Digital" "Moderate Digital" "High Digital") ///
    title("Table 3: Firm Characteristics by Digital Orientation Category") ///
    nonumbers booktabs

* Also export to Excel with t-tests
putexcel set "$TABLES/table3_firm_characteristics.xlsx", replace

putexcel A1 = "Table 3: Firm Characteristics by Ex-Ante Digital Orientation"
putexcel A2 = "Note: Ex-ante digitalization measured by Kindermann (2021) score from 10-K filings"

putexcel A4 = "Variable" ///
         B4 = "Low Digital (n=)" ///
         D4 = "High Digital (n=)" ///
         F4 = "Difference" ///
         G4 = "t-stat"

* Fill in means, SDs, and t-tests for key variables
local row = 5
local vars ln_assets ln_mve tobins_q roa roe loss firm_age hp_index

foreach var of local vars {
    * Variable label
    local lab: variable label `var'
    putexcel A`row' = "`lab'"

    * Low digital: mean (SD)
    qui summ `var' if digi_category == 1
    putexcel B`row' = r(mean)
    putexcel C`row' = r(sd)

    * High digital: mean (SD)
    qui summ `var' if digi_category == 3
    putexcel D`row' = r(mean)
    putexcel E`row' = r(sd)

    * T-test
    qui ttest `var' if inlist(digi_category, 1, 3), by(digi_category)
    putexcel F`row' = r(mu_1) - r(mu_2)
    putexcel G`row' = r(t)

    local row = `row' + 1
}

* ==============================================================================
* 6.5 TABLE 4: EVENT STUDY RESULTS (Already created in Step 4)
* ==============================================================================

* Add stars for significance to existing table
use "$PROC_DATA/sample_with_bhar.dta", clear

* Create formatted table with significance stars
putexcel set "$TABLES/table4_bhar_final.xlsx", replace

putexcel A1 = "Table 4: Buy-and-Hold Abnormal Returns Around First AI Disclosure"
putexcel A2 = "Event day 0 = first AI-related 8-K filing date"

putexcel A4 = "" B4 = "(-3, +3)" C4 = "(+4, +30)" D4 = "(-3, +30)"

* Panel A: All firms
putexcel A5 = "Panel A: All Firms"

ttest bhar_short = 0
local mean_short = r(mu_1)
local t_short = r(t)
local p_short = r(p)
local stars_short = cond(`p_short'<0.01, "***", cond(`p_short'<0.05, "**", cond(`p_short'<0.10, "*", "")))

putexcel A6 = "Mean BHAR (%)"
putexcel B6 = `mean_short'
putexcel B7 = "`stars_short'"

* Repeat for other windows...
ttest bhar_followup = 0
putexcel C6 = r(mu_1)

ttest bhar_combined = 0
putexcel D6 = r(mu_1)

* Panel B: By digital orientation
putexcel A10 = "Panel B: By Digital Orientation Category"

* Continue with subgroup analyses...

* ==============================================================================
* 6.6 FIGURE 1: TIMELINE OF AI BOOM
* ==============================================================================

* Create timeline figure showing key AI events and disclosure clustering

twoway (scatter filing_date ticker if digi_category==1, ///
            msymbol(circle) mcolor(red%60) msize(small)) ///
       (scatter filing_date ticker if digi_category==3, ///
            msymbol(triangle) mcolor(blue%60) msize(small)), ///
       title("Timeline of First AI Disclosures") ///
       subtitle("October 2022 - October 2025") ///
       ytitle("Firm (anonymized)") xtitle("Filing Date") ///
       xlabel(, format(%tdMon_YYYY) angle(45)) ///
       xline(`=td(30nov2022)', lpattern(dash) lcolor(black)) ///
       text(, "ChatGPT Launch" placement(ne)) ///
       legend(order(1 "Low Digital" 2 "High Digital") rows(1)) ///
       graphregion(color(white)) bgcolor(white) ///
       name(fig1_timeline, replace)

graph export "$FIGURES/figure1_timeline.png", replace width(`fig_width')
graph export "$FIGURES/figure1_timeline.pdf", replace

* ==============================================================================
* 6.7 FIGURE 2: TEMPORAL PATTERN (Already created in Step 3, enhance here)
* ==============================================================================

* Enhanced version with annotations
preserve
import delimited using "$TABLES/table2_panelA_temporal.csv", clear

* Create quarterly date variable
gen qdate = tq(1960q1) + _n - 1
format qdate %tq

* Normalize indices to 100 at ChatGPT launch
summ chatgpt_index if qdate == tq(2022q4)
local chatgpt_base = r(mean)
gen chatgpt_norm = (chatgpt_index / `chatgpt_base') * 100

* Plot with dual axes
twoway (bar n_disclosures qdate, yaxis(1) barwidth(0.7) color(gs10)) ///
       (line chatgpt_norm qdate, yaxis(2) lwidth(thick) color(orange)) ///
       (line ai_stock_index qdate, yaxis(2) lwidth(thick) color(green) lpattern(dash)), ///
       title("First AI Disclosures and AI Mania Proxies", size(medium)) ///
       subtitle("Quarterly Data: October 2022 - October 2025", size(small)) ///
       xtitle("Quarter") ///
       ytitle("Number of First AI Disclosures", axis(1) size(small)) ///
       ytitle("Index (ChatGPT Launch = 100)", axis(2) size(small)) ///
       xlabel(#8, format(%tqCY) angle(45)) ///
       ylabel(, axis(1) angle(0)) ylabel(, axis(2) angle(0)) ///
       xline(`=tq(2022q4)', lpattern(solid) lcolor(black) lwidth(thin)) ///
       text(15 `=tq(2022q4)' "ChatGPT Launch", placement(ne) size(vsmall)) ///
       legend(order(1 "AI Disclosures" 2 "ChatGPT Google Trends" 3 "STOXX Global AI Index") ///
              rows(1) size(small) position(6)) ///
       graphregion(color(white)) bgcolor(white) ///
       name(fig2_enhanced, replace)

graph export "$FIGURES/figure2_temporal_enhanced.png", replace width(`fig_width')
graph export "$FIGURES/figure2_temporal_enhanced.pdf", replace
restore

* ==============================================================================
* 6.8 FIGURE 3: CUMULATIVE ABNORMAL RETURNS (Created in Step 4, refine here)
* ==============================================================================

* If daily AR data available, create publication-quality version
cap confirm file "$EXT_DATA/wrds_daily_ar.csv"
if _rc == 0 {
    preserve
    import delimited using "$EXT_DATA/wrds_daily_ar.csv", clear

    merge m:1 cusip8 using "$PROC_DATA/sample_classified.dta", ///
        keep(match) nogen keepusing(digi_category speculative)

    * Calculate CAR
    sort cusip8 event_day
    by cusip8: gen car = sum(ar) * 100  // Convert to percentage

    * Collapse to mean CAR by group and day
    collapse (mean) car_mean=car (semean) car_se=car (count) n=car, ///
        by(event_day speculative)

    * 95% CI
    gen car_lb = car_mean - 1.96*car_se
    gen car_ub = car_mean + 1.96*car_se

    * Publication-quality plot
    twoway (rarea car_lb car_ub event_day if speculative==1, ///
                color(red%15) lwidth(none)) ///
           (line car_mean event_day if speculative==1, ///
                lcolor(red) lwidth(thick) lpattern(solid)) ///
           (rarea car_lb car_ub event_day if speculative==0, ///
                color(blue%15) lwidth(none)) ///
           (line car_mean event_day if speculative==0, ///
                lcolor(blue) lwidth(thick) lpattern(solid)), ///
           title("Cumulative Abnormal Returns: First AI Disclosure", size(medium)) ///
           subtitle("With 95% Confidence Intervals", size(small)) ///
           xtitle("Event Day Relative to First AI 8-K Filing") ///
           ytitle("Cumulative Abnormal Return (%)") ///
           xlabel(-3(1)30, grid) ///
           ylabel(, format(%3.1f) angle(0)) ///
           xline(0, lpattern(solid) lcolor(black) lwidth(thin)) ///
           xline(3, lpattern(dash) lcolor(gray) lwidth(thin)) ///
           yline(0, lpattern(solid) lcolor(gray)) ///
           legend(order(2 "Low Digital Firms (95% CI)" ///
                       4 "High Digital Firms (95% CI)") ///
                  rows(2) position(11) ring(0) size(small)) ///
           note("Event day 0 = first AI-related 8-K filing. Abnormal returns calculated using" ///
                "Fama-French 3-factor model with estimation window [-175, -26].", size(vsmall)) ///
           graphregion(color(white)) bgcolor(white) ///
           scheme(s2color) ///
           name(fig3_final, replace)

    graph export "$FIGURES/figure3_cumulative_ar_final.png", replace width(`fig_width')
    graph export "$FIGURES/figure3_cumulative_ar_final.pdf", replace
    restore
}

* ==============================================================================
* 6.9 FIGURE 4: DIGITALIZATION SCORE DISTRIBUTION
* ==============================================================================

* Histogram with kernel density overlay
histogram digi_score, percent ///
    title("Ex-Ante Digital Orientation of AI-Disclosing Firms", size(medium)) ///
    subtitle("Measured by Kindermann (2021) Score from 10-K Filings", size(small)) ///
    xtitle("Digital Orientation Score") ///
    ytitle("Percent of Firms") ///
    bin(30) color(navy%70) ///
    kdensity kdenopts(lcolor(red) lwidth(thick)) ///
    xline(10, lpattern(dash) lcolor(green)) ///
    xline(40, lpattern(dash) lcolor(green)) ///
    text(8 10 "Low/Moderate" "Threshold", placement(e) size(vsmall)) ///
    text(8 40 "Moderate/High" "Threshold", placement(e) size(vsmall)) ///
    note("Sample: Firms filing first AI-related 8-K between Oct 2022 and Oct 2025." ///
         "Digi score from most recent 10-K before AI disclosure.", size(vsmall)) ///
    graphregion(color(white)) bgcolor(white) ///
    name(fig4_digi_dist, replace)

graph export "$FIGURES/figure4_digi_distribution.png", replace width(`fig_width')
graph export "$FIGURES/figure4_digi_distribution.pdf", replace

* ==============================================================================
* 6.10 FIGURE 5: BHAR BY DIGITALIZATION LEVEL
* ==============================================================================

* Box plots showing BHAR distribution by digi category
graph box bhar_short, over(digi_category) ///
    title("Short-Term Market Reaction by Digital Orientation", size(medium)) ///
    subtitle("BHAR (-3, +3) Around First AI Disclosure", size(small)) ///
    ytitle("Buy-and-Hold Abnormal Return (%)") ///
    yline(0, lcolor(black) lpattern(solid)) ///
    box(1, color(red%60)) box(2, color(orange%60)) box(3, color(blue%60)) ///
    marker(1, mcolor(red%30) msize(small)) ///
    marker(2, mcolor(orange%30) msize(small)) ///
    marker(3, mcolor(blue%30) msize(small)) ///
    note("Boxes show interquartile range, whiskers extend to 1.5*IQR." ///
         "Outliers plotted as individual points.", size(vsmall)) ///
    graphregion(color(white)) bgcolor(white) ///
    name(fig5_bhar_box, replace)

graph export "$FIGURES/figure5_bhar_by_category.png", replace width(`fig_width')
graph export "$FIGURES/figure5_bhar_by_category.pdf", replace

* ==============================================================================
* 6.11 APPENDIX TABLES
* ==============================================================================

* Appendix A: Example Disclosures (requires manual input)
putexcel set "$APPENDIX/appendix_a_examples.xlsx", replace

putexcel A1 = "Appendix A: Example AI Disclosures by Category"
putexcel A3 = "Panel A: Low Digital Firms (Speculative)"
putexcel A4 = "Company" B4 = "Filing Date" C4 = "Digi Score" D4 = "Abstract (excerpt)"

* Fill with actual examples (select representative firms)
* This requires manual curation

putexcel A10 = "Panel B: High Digital Firms (Existing)"
* Continue with high digi examples...

* Appendix B: Variable Definitions
putexcel set "$APPENDIX/appendix_b_variables.xlsx", replace

putexcel A1 = "Appendix B: Variable Definitions and Data Sources"
putexcel A3 = "Variable" B3 = "Definition" C3 = "Source"

local row = 4
putexcel A`row' = "digi_score" ///
         B`row' = "Kindermann (2021) digital orientation score from 10-K filing" ///
         C`row' = "Computed from EDGAR 10-K filings"

local row = `row' + 1
putexcel A`row' = "bhar_short" ///
         B`row' = "Buy-and-hold abnormal return, days -3 to +3 relative to AI 8-K" ///
         C`row' = "WRDS Event Study (CRSP, Fama-French)"

* Continue for all variables...

* Appendix C: Robustness Tests Summary
eststo clear
estimates clear

* Store all robustness specifications
qui reg bhar_short digi_score_std ln_assets, robust
eststo robust1

qui reg bhar_short digi_score_std ln_assets tobins_q, robust
eststo robust2

qui reg bhar_short digi_score_std ln_assets tobins_q i.ff12, robust
eststo robust3

esttab robust1 robust2 robust3 using "$APPENDIX/appendix_c_robustness.tex", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Appendix C: Robustness Tests - Alternative Specifications") ///
    mtitles("Baseline" "Add Tobin's Q" "Add Industry FE") ///
    booktabs

* ==============================================================================
* 6.12 SUMMARY LOG FILE
* ==============================================================================

* Create summary log of all results
log using "$TABLES/results_summary.txt", text replace

display "=========================================="
display "AI MANIA REPLICATION STUDY - RESULTS SUMMARY"
display "=========================================="
display ""

display "SAMPLE:"
count
display "Total firms with first AI disclosure: " r(N)

count if digi_category == 1
display "Low Digital firms: " r(N)

count if digi_category == 3
display "High Digital firms: " r(N)

display ""
display "KEY FINDINGS:"

display "1. Average BHAR (-3, +3):"
summ bhar_short, detail
ttest bhar_short = 0
display "   t-statistic = " r(t)
display "   p-value = " r(p)

display ""
display "2. BHAR by Digital Category:"
ttest bhar_short if inlist(digi_category, 1, 3), by(digi_category)
display "   Low Digital mean: " r(mu_1) "%"
display "   High Digital mean: " r(mu_2) "%"
display "   Difference: " r(mu_1) - r(mu_2) "%"
display "   t-statistic: " r(t)
display "   p-value: " r(p)

display ""
display "3. AI Up-Market vs Down-Market:"
ttest bhar_short, by(ai_market_up)
display "   Down-market mean: " r(mu_1) "%"
display "   Up-market mean: " r(mu_2) "%"
display "   Difference: " r(mu_2) - r(mu_1) "%"
display "   p-value: " r(p)

display ""
display "=========================================="
log close

* ==============================================================================
* 6.13 CREATE README FOR REPLICATION PACKAGE
* ==============================================================================

file open readme using "$PROJECT_DIR/REPLICATION_README.txt", write replace

file write readme "=========================================" _n
file write readme "REPLICATION PACKAGE" _n
file write readme "Riding the Generative AI Mania:" _n
file write readme "Public Firms' AI Disclosures" _n
file write readme "=========================================" _n _n

file write readme "CONTENTS:" _n
file write readme "1. Code (STATA .do files)" _n
file write readme "   - 00_master.do: Run all analyses" _n
file write readme "   - 01_data_processing.do: Sample construction" _n
file write readme "   - 02_classify_disclosures.do: Kindermann classification" _n
file write readme "   - 03_descriptives.do: Tables 2-3, Figure 2" _n
file write readme "   - 04_event_study.do: Table 4, Figure 3" _n
file write readme "   - 05_additional_analyses.do: Tables 5-6" _n
file write readme "   - 06_output_tables.do: Final formatting" _n _n

file write readme "2. Data Sources:" _n
file write readme "   RAW DATA (included):" _n
file write readme "   - ai_8k_oct2022_oct_2025.csv: AI-related 8-K filings" _n
file write readme "   - kindermann_2021_10k_edgar_2005_2025.txt: Digi scores" _n
file write readme "   - chatgpt_google.csv: Google Trends data" _n
file write readme "   - istoxx_global_ai_100_index.txt: AI stock index" _n _n

file write readme "   EXTERNAL DATA (requires WRDS access):" _n
file write readme "   - CRSP daily stock returns" _n
file write readme "   - Compustat annual fundamentals" _n
file write readme "   - Fama-French factor returns" _n
file write readme "   - See 01_data_processing.do for extraction code" _n _n

file write readme "3. Output:" _n
file write readme "   - Tables (LaTeX, Excel, CSV formats)" _n
file write readme "   - Figures (PNG and PDF)" _n
file write readme "   - Appendix materials" _n _n

file write readme "INSTRUCTIONS:" _n
file write readme "1. Set file paths in 00_master.do (line 15)" _n
file write readme "2. Extract WRDS data using code in 01_data_processing.do" _n
file write readme "3. Run WRDS Event Study (see 04_event_study.do instructions)" _n
file write readme "4. Execute: do 00_master.do" _n _n

file write readme "SOFTWARE REQUIREMENTS:" _n
file write readme "- STATA 16 or later" _n
file write readme "- WRDS account (institutional subscription)" _n
file write readme "- Packages: estout, putexcel" _n _n

file write readme "CITATION:" _n
file write readme "If using this code, please cite both:" _n
file write readme "1. Our paper (TBD)" _n
file write readme "2. Kindermann et al. (2021) for digitalization measure" _n
file write readme "3. Cheng et al. (2019) for methodology" _n

file close readme

display as result "STEP 6 COMPLETE: All tables and figures generated"
display as result "Tables: $TABLES/"
display as result "Figures: $FIGURES/"
display as result "Appendix: $APPENDIX/"
display as result "Summary log: $TABLES/results_summary.txt"
display as result "Replication README: $PROJECT_DIR/REPLICATION_README.txt"

********************************************************************************
* END OF OUTPUT GENERATION
********************************************************************************
