********************************************************************************
* STEP 4: EVENT STUDY - INVESTOR REACTIONS TO AI DISCLOSURES
*
* METHODOLOGY: Buy-and-Hold Abnormal Returns (BHAR) using WRDS Event Study Tool
* Abnormal returns calculated EXTERNALLY via WRDS, then imported and analyzed
********************************************************************************

clear all
use "$PROC_DATA/sample_classified.dta", clear

* ==============================================================================
* 4.1 WRDS EVENT STUDY TOOL - DATA PREPARATION
* ==============================================================================

/*
WRDS EVENT STUDY METHODOLOGY:

Instead of manual BHAR calculation, we use the WRDS Event Study Tool:
https://wrds-www.wharton.upenn.edu/pages/get-data/wrds-event-study/

ADVANTAGES:
1. Automated calculation of expected returns using factor models
2. Handles missing data, delistings, confounding events
3. Produces standardized test statistics
4. Widely used and validated in finance research

INPUT REQUIREMENTS:
1. CUSIP (8-digit) or PERMNO
2. Event date
3. Event window specification
4. Estimation window specification

OUR SPECIFICATION:
- Event date: filing_date (first AI 8-K)
- Event windows:
  * Short-term: (-3, +3) days
  * Follow-up: (+4, +30) days
  * Combined: (-3, +30) days
- Estimation window: (-175, -26) days before event
- Factor model: Fama-French 3-factor model
*/

* ==============================================================================
* 4.2 CREATE INPUT FILE FOR WRDS EVENT STUDY
* ==============================================================================

preserve
keep ticker cusip8 permno filing_date digi_score digi_category speculative existing

* Remove firms without valid identifiers
drop if missing(cusip8) | missing(filing_date)

* Format date as YYYYMMDD for WRDS
gen event_date_wrds = string(year(filing_date), "%04.0f") + ///
                      string(month(filing_date), "%02.0f") + ///
                      string(day(filing_date), "%02.0f")

* Keep necessary variables
keep cusip8 permno event_date_wrds ticker digi_score digi_category speculative existing

* Export for WRDS Event Study upload
export delimited using "$PROC_DATA/wrds_event_study_input.csv", replace

* Count events
count
local n_events = r(N)
display as result "Created WRDS Event Study input file with `n_events' events"
display as result "File location: $PROC_DATA/wrds_event_study_input.csv"
restore

* ==============================================================================
* 4.3 WRDS EVENT STUDY TOOL - STEP-BY-STEP INSTRUCTIONS
* ==============================================================================

/*
HOW TO USE WRDS EVENT STUDY TOOL:

STEP 1: Log in to WRDS
-----------------------
1. Go to: https://wrds-www.wharton.upenn.edu/
2. Sign in with institutional credentials
3. Navigate to: Support -> WRDS Tools -> Event Study

STEP 2: Upload Event File
--------------------------
1. Click "Upload Request File"
2. Upload: wrds_event_study_input.csv
3. File format options:
   - Identifier: CUSIP (8-digit)
   - Date format: YYYYMMDD
   - Delimiter: Comma

STEP 3: Configure Study Parameters
-----------------------------------
EVENT WINDOW SPECIFICATIONS (run 3 separate analyses):

Analysis 1: Short-term reaction
- Event window: -3 to +3 days
- Estimation window: -175 to -26 days
- Output suffix: "_short"

Analysis 2: Follow-up period
- Event window: +4 to +30 days
- Estimation window: -175 to -26 days
- Output suffix: "_followup"

Analysis 3: Combined window
- Event window: -3 to +30 days
- Estimation window: -175 to -26 days
- Output suffix: "_combined"

STEP 4: Model Selection
------------------------
- Return model: Fama-French 3-Factor Model
- Risk-free rate: Include (from Ken French data library)
- Estimation method: OLS
- Minimum estimation period: 90 days

STEP 5: Additional Options
---------------------------
- Include: Cumulative abnormal returns (CAR)
- Include: Buy-and-hold abnormal returns (BHAR)
- Include: Test statistics (t-stat, rank test)
- Output format: CSV

STEP 6: Submit and Download
----------------------------
1. Submit job (processing takes 5-30 minutes depending on sample size)
2. Download results when complete
3. Save files to: $EXT_DATA/
   - wrds_car_short.csv
   - wrds_car_followup.csv
   - wrds_car_combined.csv

ALTERNATIVE: SAS CODE FOR WRDS EVENT STUDY
-------------------------------------------
*/

* SAS code to run event study on WRDS server:
/*
%let wrds = wrds-cloud.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

rsubmit;

* Upload event file;
proc upload data=event_list out=mylib.events; run;

* Load CRSP daily stock file;
proc sql;
create table stock_data as
select a.cusip, a.date, a.ret, a.retx
from crsp.dsf as a
inner join mylib.events as b
on a.cusip = b.cusip
where a.date between intnx('day', b.event_date, -200)
                 and intnx('day', b.event_date, 50);
quit;

* Load Fama-French factors;
proc sql;
create table ff_factors as
select date, mktrf, smb, hml, rf
from ff.factors_daily
where date between '01JAN2022'd and '31DEC2025'd;
quit;

* Merge stock returns with FF factors;
proc sql;
create table returns_merged as
select a.*, b.mktrf, b.smb, b.hml, b.rf,
       a.ret - b.rf as excess_ret
from stock_data as a
left join ff_factors as b
on a.date = b.date;
quit;

* Estimate Fama-French model parameters;
proc reg data=returns_merged noprint outest=ff_params;
by cusip;
model excess_ret = mktrf smb hml;
where event_day between -175 and -26;
run;

* Calculate abnormal returns;
proc sql;
create table abnormal_returns as
select a.cusip, a.date, a.event_day,
       a.ret,
       b.intercept + b.mktrf*a.mktrf + b.smb*a.smb + b.hml*a.hml as expected_ret,
       a.ret - (b.intercept + b.mktrf*a.mktrf + b.smb*a.smb + b.hml*a.hml) as ar
from returns_merged as a
left join ff_params as b
on a.cusip = b.cusip
where a.event_day between -3 and 30;
quit;

* Calculate CAR and BHAR;
proc sql;
create table event_returns as
select cusip,
       sum(ar) as car_short where event_day between -3 and 3,
       sum(ar) as car_followup where event_day between 4 and 30,
       sum(ar) as car_combined where event_day between -3 and 30,
       exp(sum(log(1+ar)))-1 as bhar_short where event_day between -3 and 3,
       exp(sum(log(1+ar)))-1 as bhar_followup where event_day between 4 and 30,
       exp(sum(log(1+ar)))-1 as bhar_combined where event_day between -3 and 30
from abnormal_returns
group by cusip;
quit;

proc download data=event_returns out=event_returns; run;
endrsubmit;
*/

* ==============================================================================
* 4.4 IMPORT WRDS EVENT STUDY RESULTS
* ==============================================================================

/*
After running WRDS Event Study, import the results here.
Expected file structure:
- cusip8 or permno
- car (cumulative abnormal return)
- bhar (buy-and-hold abnormal return)
- car_tstat (t-statistic)
- estimation_days (number of days in estimation window)
*/

* Import short-term window results (-3, +3)
cap confirm file "$EXT_DATA/wrds_car_short.csv"
if _rc == 0 {
    preserve
    import delimited using "$EXT_DATA/wrds_car_short.csv", clear

    rename car bhar_short
    rename car_tstat tstat_short

    keep cusip8 permno bhar_short tstat_short
    duplicates drop

    tempfile bhar_short
    save `bhar_short'
    restore

    merge 1:1 cusip8 using `bhar_short', keep(match master) nogen
}
else {
    display as error "WARNING: WRDS short-term results not found"
    display as error "Please run WRDS Event Study first (see instructions above)"
    gen bhar_short = .
    gen tstat_short = .
}

* Import follow-up window results (+4, +30)
cap confirm file "$EXT_DATA/wrds_car_followup.csv"
if _rc == 0 {
    preserve
    import delimited using "$EXT_DATA/wrds_car_followup.csv", clear

    rename car bhar_followup
    rename car_tstat tstat_followup

    keep cusip8 permno bhar_followup tstat_followup
    duplicates drop

    tempfile bhar_followup
    save `bhar_followup'
    restore

    merge 1:1 cusip8 using `bhar_followup', keep(match master) nogen
}
else {
    gen bhar_followup = .
    gen tstat_followup = .
}

* Import combined window results (-3, +30)
cap confirm file "$EXT_DATA/wrds_car_combined.csv"
if _rc == 0 {
    preserve
    import delimited using "$EXT_DATA/wrds_car_combined.csv", clear

    rename car bhar_combined
    rename car_tstat tstat_combined

    keep cusip8 permno bhar_combined tstat_combined
    duplicates drop

    tempfile bhar_combined
    save `bhar_combined'
    restore

    merge 1:1 cusip8 using `bhar_combined', keep(match master) nogen
}
else {
    gen bhar_combined = .
    gen tstat_combined = .
}

* Convert to percentage returns
foreach var in bhar_short bhar_followup bhar_combined {
    replace `var' = `var' * 100
    label variable `var' "`var' (%)"
}

* ==============================================================================
* 4.5 ANALYZE EVENT STUDY RESULTS (TABLE 4 REPLICATION)
* ==============================================================================

/*
TABLE 4: BUY-AND-HOLD ABNORMAL RETURNS (BHAR)

Panel A: All firms
Panel B: By digitalization level (Low/Moderate/High)
Panel C: Tests of differences

Columns:
1. (-3, +3) Short-term reaction
2. (+4, +30) Follow-up period
3. (-3, +30) Combined window
*/

* Panel A: All firms
eststo clear

* Overall means
eststo all_firms: estpost summarize bhar_short bhar_followup bhar_combined, detail

* Test if different from zero
foreach var in bhar_short bhar_followup bhar_combined {
    ttest `var' = 0
    local mean_`var' = r(mu_1)
    local t_`var' = r(t)
    local p_`var' = r(p)
    local n_`var' = r(N_1)
}

* Panel B: By digitalization category
eststo low_digi: estpost summarize bhar_short bhar_followup bhar_combined ///
    if digi_category == 1, detail

eststo mod_digi: estpost summarize bhar_short bhar_followup bhar_combined ///
    if digi_category == 2, detail

eststo high_digi: estpost summarize bhar_short bhar_followup bhar_combined ///
    if digi_category == 3, detail

* Export summary table
esttab all_firms low_digi mod_digi high_digi ///
    using "$TABLES/table4_bhar_summary.csv", replace ///
    cells("mean(fmt(3)) sd(fmt(3)) count") ///
    mtitles("All Firms" "Low Digital" "Moderate Digital" "High Digital")

* Panel C: Tests of differences
preserve
gen group = digi_category

* Low vs High digital
ttest bhar_short if inlist(digi_category, 1, 3), by(group)
local diff_short = r(mu_1) - r(mu_2)
local t_diff_short = r(t)
local p_diff_short = r(p)

ttest bhar_followup if inlist(digi_category, 1, 3), by(group)
local diff_followup = r(mu_1) - r(mu_2)
local t_diff_followup = r(t)
local p_diff_followup = r(p)

ttest bhar_combined if inlist(digi_category, 1, 3), by(group)
local diff_combined = r(mu_1) - r(mu_2)
local t_diff_combined = r(t)
local p_diff_combined = r(p)
restore

* Create formatted Table 4
putexcel set "$TABLES/table4_bhar_results.xlsx", replace

putexcel A1 = "Table 4: Buy-and-Hold Abnormal Returns Around First AI Disclosure"
putexcel A3 = "Panel A: All Firms"
putexcel B3 = "(-3, +3)" C3 = "(+4, +30)" D3 = "(-3, +30)"
putexcel A4 = "Mean BHAR (%)"
putexcel B4 = `mean_bhar_short'
putexcel C4 = `mean_bhar_followup'
putexcel D4 = `mean_bhar_combined'
putexcel A5 = "t-statistic"
putexcel B5 = `t_bhar_short'
putexcel C5 = `t_bhar_followup'
putexcel D5 = `t_bhar_combined'

* ==============================================================================
* 4.6 TIME-SERIES PLOT OF CUMULATIVE ABNORMAL RETURNS (FIGURE 3 REPLICATION)
* ==============================================================================

/*
FIGURE 3: Cumulative Abnormal Returns Over Event Window

Requires daily abnormal returns from WRDS Event Study.
Expected file: wrds_daily_ar.csv with columns:
- cusip8, event_day, ar (abnormal return)
*/

cap confirm file "$EXT_DATA/wrds_daily_ar.csv"
if _rc == 0 {
    preserve
    import delimited using "$EXT_DATA/wrds_daily_ar.csv", clear

    * Calculate CAR by event day and digital category
    merge m:1 cusip8 using "$PROC_DATA/sample_classified.dta", ///
        keep(match) nogen keepusing(digi_category)

    * Calculate cumulative AR by day
    sort cusip8 event_day
    by cusip8: gen car = sum(ar)

    * Average across firms by category
    collapse (mean) car_mean=car (sem) car_se=car, by(event_day digi_category)

    * 95% confidence intervals
    gen car_lb = car_mean - 1.96*car_se
    gen car_ub = car_mean + 1.96*car_se

    * Plot
    twoway (rarea car_lb car_ub event_day if digi_category==1, color(red%20)) ///
           (line car_mean event_day if digi_category==1, lwidth(thick) color(red)) ///
           (rarea car_lb car_ub event_day if digi_category==3, color(blue%20)) ///
           (line car_mean event_day if digi_category==3, lwidth(thick) color(blue)), ///
           title("Cumulative Abnormal Returns Around First AI Disclosure") ///
           xtitle("Event Day (0 = First AI 8-K Filing)") ///
           ytitle("Cumulative Abnormal Return (%)") ///
           xline(0, lpattern(dash) lcolor(black)) ///
           yline(0, lpattern(solid) lcolor(gray)) ///
           legend(order(2 "Low Digital (95% CI)" 4 "High Digital (95% CI)") ///
                  rows(1) position(6)) ///
           graphregion(color(white)) bgcolor(white) ///
           name(fig3_car, replace)

    graph export "$FIGURES/figure3_cumulative_ar.png", replace width(3000)
    graph export "$FIGURES/figure3_cumulative_ar.pdf", replace
    restore
}

* ==============================================================================
* 4.7 REGRESSION ANALYSIS: BHAR ON DIGITALIZATION
* ==============================================================================

* Regression: BHAR on continuous digi score with controls
eststo clear

* Short-term window
eststo m1: reg bhar_short digi_score_std ln_assets tobins_q firm_age i.ff12, robust
estadd local fe_industry "Yes"

* Follow-up window
eststo m2: reg bhar_followup digi_score_std ln_assets tobins_q firm_age i.ff12, robust
estadd local fe_industry "Yes"

* Combined window
eststo m3: reg bhar_combined digi_score_std ln_assets tobins_q firm_age i.ff12, robust
estadd local fe_industry "Yes"

* Export regression table
esttab m1 m2 m3 using "$TABLES/table4b_bhar_regressions.csv", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("fe_industry Industry FE" "r2 R-squared" "N N") ///
    mtitles("(-3,+3)" "(+4,+30)" "(-3,+30)")

* ==============================================================================
* 4.8 SAVE RESULTS
* ==============================================================================

save "$PROC_DATA/sample_with_bhar.dta", replace

display as result "STEP 4 COMPLETE: Event study analysis finished"
display as result "Results saved to: $TABLES/table4_*"
display as result "Note: BHAR calculated using WRDS Event Study Tool"

********************************************************************************
