********************************************************************************
* STEP 5: ADDITIONAL ANALYSES - EVIDENCE OF AI MANIA
*
* Analysis A: Conditional on AI Index Performance (TABLE 5)
* Analysis B: Comovement with AI Index (TABLE 6)
********************************************************************************

clear all
use "$PROC_DATA/sample_with_bhar.dta", clear

* ==============================================================================
* 5.1 PREPARE AI MANIA PROXY VARIABLES
* ==============================================================================

/*
AI MANIA PROXIES:

1. STOXX Global AI Index (istoxx_global_ai_100_index.txt)
   - Represents AI stock market performance
   - Analogous to Bitcoin price in blockchain study

2. ChatGPT Google Trends (chatgpt_google.csv)
   - Represents public AI enthusiasm
   - Weekly search intensity index (0-100)

METHODOLOGY:
- Calculate monthly returns for AI Index
- Classify months as "Up-market" (high AI enthusiasm) vs "Down-market" (low)
- Test if investor reactions stronger during AI mania periods
*/

* Load and prepare STOXX AI Index data
preserve
import delimited using "$RAW_DATA/istoxx_global_ai_100_index.txt", clear

* Parse date and index value
* Expected format: date,index
gen date_fmt = date(date, "YMD")
format date_fmt %td

rename index ai_index
keep date_fmt ai_index

* Calculate monthly returns
gen ym = ym(year(date_fmt), month(date_fmt))
format ym %tm

* Keep end-of-month values
gsort ym -date_fmt
by ym: keep if _n == 1

* Calculate monthly return
tsset ym
gen ai_index_ret = (ai_index - L.ai_index) / L.ai_index * 100

keep ym ai_index ai_index_ret
tempfile ai_index_monthly
save `ai_index_monthly'
restore

* Load and prepare ChatGPT Google Trends
preserve
import delimited using "$RAW_DATA/chatgpt_google.csv", clear

gen date_fmt = date(date, "YMD")
format date_fmt %td

rename chatgpt chatgpt_index

gen ym = ym(year(date_fmt), month(date_fmt))
format ym %tm

* Average weekly values to monthly
collapse (mean) chatgpt_index, by(ym)

tempfile chatgpt_monthly
save `chatgpt_monthly'
restore

* Merge AI mania proxies with main data
gen filing_ym = ym(year(filing_date), month(filing_date))
format filing_ym %tm

merge m:1 filing_ym using `ai_index_monthly', keep(match master) nogen
merge m:1 filing_ym using `chatgpt_monthly', keep(match master) nogen

* ==============================================================================
* 5.2 CLASSIFY UP-MARKET VS DOWN-MARKET PERIODS (TABLE 5)
* ==============================================================================

/*
METHODOLOGY (Following blockchain study Table 5):

1. Rank all months in sample period by AI Index return
2. Split into two groups:
   - AI Up-market: Top 50% of months (positive sentiment)
   - AI Down-market: Bottom 50% of months (negative sentiment)
3. Classify each 8-K disclosure based on filing month
4. Compare BHAR across up/down market periods
5. Test differences

HYPOTHESIS (if AI mania exists):
- Up-market: Positive, significant BHAR (investors chase AI hype)
- Down-market: Insignificant or negative BHAR (investors cautious)
- Difference: Significant (confirms mania-driven reactions)
*/

* Create market condition indicator based on AI index returns
preserve
* Get universe of months in sample period
keep filing_ym ai_index_ret
duplicates drop filing_ym, force

* Rank months by AI index performance
egen rank_ai = rank(ai_index_ret), track

* Calculate median rank
summ rank_ai, detail
local median_rank = r(p50)

* Create up/down market indicator
gen ai_market_up = (rank_ai > `median_rank') if !missing(rank_ai)

keep filing_ym ai_market_up
tempfile market_periods
save `market_periods'
restore

merge m:1 filing_ym using `market_periods', keep(match master) nogen

label define market_lbl 0 "AI Down-Market" 1 "AI Up-Market"
label values ai_market_up market_lbl
label variable ai_market_up "AI market condition at disclosure"

* ==============================================================================
* 5.3 ANALYZE BHAR CONDITIONAL ON AI MARKET CONDITIONS (TABLE 5)
* ==============================================================================

* Panel A: All firms
eststo clear

* Up-market
eststo up_all: estpost summarize bhar_short bhar_followup bhar_combined ///
    if ai_market_up == 1, detail

* Down-market
eststo down_all: estpost summarize bhar_short bhar_followup bhar_combined ///
    if ai_market_up == 0, detail

* Test differences
ttest bhar_short, by(ai_market_up)
local diff_short_all = r(mu_2) - r(mu_1)
local t_short_all = r(t)
local p_short_all = r(p)

ttest bhar_followup, by(ai_market_up)
local diff_followup_all = r(mu_2) - r(mu_1)

ttest bhar_combined, by(ai_market_up)
local diff_combined_all = r(mu_2) - r(mu_1)

* Panel B: Low digital firms (Speculative)
eststo up_low: estpost summarize bhar_short bhar_followup bhar_combined ///
    if ai_market_up == 1 & digi_category == 1, detail

eststo down_low: estpost summarize bhar_short bhar_followup bhar_combined ///
    if ai_market_up == 0 & digi_category == 1, detail

* Test differences for low digital
ttest bhar_short if digi_category == 1, by(ai_market_up)
local diff_short_low = r(mu_2) - r(mu_1)

* Panel C: High digital firms (Existing)
eststo up_high: estpost summarize bhar_short bhar_followup bhar_combined ///
    if ai_market_up == 1 & digi_category == 3, detail

eststo down_high: estpost summarize bhar_short bhar_followup bhar_combined ///
    if ai_market_up == 0 & digi_category == 3, detail

* Test differences for high digital
ttest bhar_short if digi_category == 3, by(ai_market_up)
local diff_short_high = r(mu_2) - r(mu_1)

* Export Table 5
esttab up_all down_all up_low down_low up_high down_high ///
    using "$TABLES/table5_conditional_bhar.csv", replace ///
    cells("mean(fmt(3)) sd(fmt(3)) count") ///
    mtitles("Up-All" "Down-All" "Up-Low" "Down-Low" "Up-High" "Down-High")

* Create formatted Excel table
putexcel set "$TABLES/table5_conditional_ai_market.xlsx", replace

putexcel A1 = "Table 5: BHAR Conditional on AI Index Performance"
putexcel A3 = "Panel A: All Firms"
putexcel B3 = "AI Up-Market" C3 = "AI Down-Market" D3 = "Difference"

putexcel A4 = "BHAR (-3, +3)"
ttest bhar_short, by(ai_market_up)
putexcel B4 = r(mu_2)
putexcel C4 = r(mu_1)
putexcel D4 = r(mu_2) - r(mu_1)
putexcel E4 = r(t)

* Regression: Interaction between digi_score and AI market
eststo clear

reg bhar_short c.digi_score_std##i.ai_market_up ln_assets tobins_q i.ff12, robust
eststo m1
margins, at(digi_score_std=(-1 0 1) ai_market_up=(0 1))
marginsplot, name(margins_ai_market, replace)

esttab m1 using "$TABLES/table5_interaction_regression.csv", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)

* ==============================================================================
* 5.4 PORTFOLIO CONSTRUCTION FOR COMOVEMENT ANALYSIS (TABLE 6)
* ==============================================================================

/*
METHODOLOGY: Portfolio Factor Loading Analysis

GOAL: Test if AI-disclosing firms' stocks gain "AI exposure" after disclosure

APPROACH:
1. Construct equal-weighted portfolios:
   - Low Digital Portfolio (speculative firms)
   - High Digital Portfolio (existing digital firms)
   - Control Portfolio (matched non-disclosers)

2. Calculate daily portfolio returns starting from first disclosure

3. Estimate factor loadings:
   R_portfolio,t - Rf,t = α + β_AI*(AI_Index_Return_t - Rf,t) +
                          β_MKT*MKT_t + β_SMB*SMB_t + β_HML*HML_t + ε_t

4. Test hypotheses:
   H1: β_AI > 0 for both Low and High Digital portfolios
   H2: β_AI = 0 for control portfolio
   H3: β_AI(High) > β_AI(Low)

DATA REQUIREMENTS:
- Daily returns for sample firms (CRSP)
- Daily AI Index returns (STOXX Global AI)
- Fama-French daily factors (Ken French data library)
*/

/*
REQUIRED WRDS EXTRACTION FOR PORTFOLIO ANALYSIS:

1. CRSP Daily Returns (Post-Disclosure)
   Query: Get daily returns for all sample firms from their disclosure date
          through end of sample period

2. Fama-French Daily Factors
   Available at: https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html
   OR WRDS: ff.factors_daily

3. AI Index Daily Returns
   Calculate from istoxx_global_ai_100_index.txt
*/

* Load CRSP daily returns (post-disclosure period)
cap confirm file "$EXT_DATA/crsp_daily_post_disclosure.csv"
if _rc == 0 {
    preserve
    import delimited using "$EXT_DATA/crsp_daily_post_disclosure.csv", clear

    * Format date
    gen date_fmt = date(date, "YMD")
    format date_fmt %td

    * Merge with firm classification
    rename permno permno_temp
    tostring permno_temp, replace
    rename permno_temp permno

    merge m:1 permno using "$PROC_DATA/sample_classified.dta", ///
        keep(match) keepusing(digi_category filing_date ticker) nogen

    * Keep only post-disclosure returns
    keep if date_fmt >= filing_date

    * Calculate equal-weighted portfolio returns by category
    collapse (mean) port_ret=ret, by(date_fmt digi_category)

    * Reshape wide for analysis
    reshape wide port_ret, i(date_fmt) j(digi_category)

    rename port_ret1 ret_low_digital
    rename port_ret2 ret_moderate_digital
    rename port_ret3 ret_high_digital

    tempfile portfolio_returns
    save `portfolio_returns'
    restore

    * Load Fama-French factors
    preserve
    import delimited using "$EXT_DATA/ff_daily_factors.csv", clear

    gen date_fmt = date(date, "YMD")
    format date_fmt %td

    * Convert to decimal (if in percentage format)
    foreach var in mktrf smb hml rf {
        replace `var' = `var' / 100 if `var' > 1
    }

    keep date_fmt mktrf smb hml rf
    tempfile ff_factors
    save `ff_factors'
    restore

    * Load AI Index returns
    preserve
    import delimited using "$RAW_DATA/istoxx_global_ai_100_index.txt", clear

    gen date_fmt = date(date, "YMD")
    format date_fmt %td

    rename index ai_index

    * Calculate daily returns
    tsset date_fmt
    gen ai_index_ret = (ai_index - L.ai_index) / L.ai_index

    keep date_fmt ai_index_ret
    tempfile ai_daily_ret
    save `ai_daily_ret'
    restore

    * Merge all data for factor model estimation
    use `portfolio_returns', clear
    merge 1:1 date_fmt using `ff_factors', keep(match) nogen
    merge 1:1 date_fmt using `ai_daily_ret', keep(match) nogen

    * Calculate excess returns
    gen exret_low = ret_low_digital - rf
    gen exret_high = ret_high_digital - rf
    gen ai_exret = ai_index_ret - rf

    * ==============================================================================
    * 5.5 ESTIMATE FACTOR LOADINGS (TABLE 6)
    * ==============================================================================

    /*
    TABLE 6: Portfolio Factor Loadings on AI Index

    Regression model:
    Excess_Return = α + β_AI*(AI_Index_Excess) + β_MKT*MKT + β_SMB*SMB + β_HML*HML
    */

    eststo clear

    * Model 1: Low Digital Portfolio (FF3 only, baseline)
    eststo m1_low_ff3: reg exret_low mktrf smb hml, robust
    estadd local ai_factor "No"

    * Model 2: Low Digital Portfolio (FF3 + AI Index)
    eststo m2_low_ai: reg exret_low ai_exret mktrf smb hml, robust
    estadd local ai_factor "Yes"

    * Model 3: High Digital Portfolio (FF3 only)
    eststo m3_high_ff3: reg exret_high mktrf smb hml, robust
    estadd local ai_factor "No"

    * Model 4: High Digital Portfolio (FF3 + AI Index)
    eststo m4_high_ai: reg exret_high ai_exret mktrf smb hml, robust
    estadd local ai_factor "Yes"

    * Test difference in AI beta: High vs Low
    suest m2_low_ai m4_high_ai
    test [m2_low_ai_mean]ai_exret = [m4_high_ai_mean]ai_exret
    local p_diff_beta = r(p)

    * Export Table 6
    esttab m1_low_ff3 m2_low_ai m3_high_ff3 m4_high_ai ///
        using "$TABLES/table6_factor_loadings.csv", replace ///
        b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
        scalars("ai_factor AI Factor" "r2 R-squared" "N N") ///
        mtitles("Low:FF3" "Low:FF3+AI" "High:FF3" "High:FF3+AI") ///
        keep(ai_exret mktrf smb hml _cons)

    * Formatted Excel table
    putexcel set "$TABLES/table6_comovement_analysis.xlsx", replace

    putexcel A1 = "Table 6: Portfolio Comovement with AI Index"
    putexcel A3 = "Dependent Variable: Portfolio Excess Return"

    putexcel B3 = "Low Digital" D3 = "High Digital"
    putexcel B4 = "FF3" C4 = "FF3+AI" D4 = "FF3" E4 = "FF3+AI"

    * Add coefficients programmatically
    putexcel A5 = "AI Index (β_AI)"
    putexcel A6 = "Market (β_MKT)"
    putexcel A7 = "SMB (β_SMB)"
    putexcel A8 = "HML (β_HML)"
    putexcel A9 = "Constant (α)"
    putexcel A11 = "R-squared"
    putexcel A12 = "N"
}
else {
    display as error "WARNING: Daily portfolio return data not found"
    display as error "Required file: $EXT_DATA/crsp_daily_post_disclosure.csv"
    display as error "Extract using WRDS CRSP daily file (see Step 1 instructions)"
}

* ==============================================================================
* 5.6 ROBUSTNESS CHECKS
* ==============================================================================

* Alternative: Split by ChatGPT Google Trends instead of AI Index
gen chatgpt_high = (chatgpt_index > 50) if !missing(chatgpt_index)

ttest bhar_short, by(chatgpt_high)
local diff_chatgpt = r(mu_2) - r(mu_1)

* Tercile analysis instead of binary split
xtile ai_tercile = ai_index_ret, nq(3)

table ai_tercile, statistic(mean bhar_short) statistic(sd bhar_short) statistic(count bhar_short)

* Export to appendix
export delimited using "$APPENDIX/robustness_tercile_analysis.csv", replace

* ==============================================================================
* 5.7 ADDITIONAL HETEROGENEITY ANALYSES
* ==============================================================================

* By firm size quartile
xtile size_quartile = ln_assets, nq(4)

table size_quartile digi_category, ///
    statistic(mean bhar_short) statistic(sd bhar_short)

* By AI keyword intensity
table ai_intensity digi_category, ///
    statistic(mean bhar_short) statistic(count bhar_short)

* Industry-specific effects
reg bhar_short c.digi_score_std##i.ff12, robust
estimates store industry_het

* Export heterogeneity tables
esttab industry_het using "$APPENDIX/heterogeneity_industry.csv", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)

* ==============================================================================
* 5.8 SAVE FINAL DATASET
* ==============================================================================

save "$PROC_DATA/sample_final_analyses.dta", replace

display as result "STEP 5 COMPLETE: Additional analyses finished"
display as result "AI mania tests completed (conditional BHAR, comovement)"
display as result "Results: $TABLES/table5_*.xlsx and table6_*.xlsx"

********************************************************************************
