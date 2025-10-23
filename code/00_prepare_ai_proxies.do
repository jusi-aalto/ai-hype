********************************************************************************
* HELPER SCRIPT: PREPARE AI MANIA PROXY DATA
*
* Prepares quarterly/monthly AI mania indicators for merging with main data:
* 1. ChatGPT Google Trends
* 2. STOXX Global AI Index returns
********************************************************************************

clear all

* ==============================================================================
* 1. PREPARE CHATGPT GOOGLE TRENDS DATA
* ==============================================================================

import delimited using "$RAW_DATA/chatgpt_google.csv", clear

* Parse date
gen date_fmt = date(date, "YMD")
format date_fmt %td

* Create time period variables
gen week = wofd(date_fmt)
gen month = mofd(date_fmt)
gen quarter = qofd(date_fmt)
gen year = year(date_fmt)

format week %tw
format month %tm
format quarter %tq

* Rename index variable
rename chatgpt chatgpt_index

* Aggregate to different frequencies
preserve
collapse (mean) chatgpt_index_monthly=chatgpt_index, by(month)
tempfile chatgpt_monthly
save `chatgpt_monthly'
restore

preserve
collapse (mean) chatgpt_index_quarterly=chatgpt_index, by(quarter)
tempfile chatgpt_quarterly
save `chatgpt_quarterly'
restore

* ==============================================================================
* 2. PREPARE STOXX GLOBAL AI INDEX DATA
* ==============================================================================

import delimited using "$RAW_DATA/istoxx_global_ai_100_index.txt", clear

* Parse date and index
gen date_fmt = date(date, "YMD")
format date_fmt %td

rename index ai_index

* Create time variables
gen month = mofd(date_fmt)
gen quarter = qofd(date_fmt)
gen year = year(date_fmt)
format month %tm
format quarter %tq

* Keep end-of-period values for each time period
gsort month -date_fmt
by month: gen month_end = (_n == 1)

gsort quarter -date_fmt
by quarter: gen quarter_end = (_n == 1)

* Calculate returns
tsset date_fmt
gen ai_index_ret_daily = (ai_index - L.ai_index) / L.ai_index * 100

* Monthly returns
preserve
keep if month_end
tsset month
gen ai_index_ret_monthly = (ai_index - L.ai_index) / L.ai_index * 100
keep month ai_index ai_index_ret_monthly
tempfile ai_monthly
save `ai_monthly'
restore

* Quarterly returns
preserve
keep if quarter_end
tsset quarter
gen ai_index_ret_quarterly = (ai_index - L.ai_index) / L.ai_index * 100
keep quarter ai_index ai_index_ret_quarterly
rename ai_index ai_stock_index
tempfile ai_quarterly
save `ai_quarterly'
restore

* ==============================================================================
* 3. MERGE AND CREATE COMBINED PROXY FILE
* ==============================================================================

* Quarterly file
use `chatgpt_quarterly', clear
merge 1:1 quarter using `ai_quarterly', nogen

* Normalize indices to 100 at ChatGPT launch (2022 Q4)
summ chatgpt_index_quarterly if quarter == tq(2022q4)
local base_chatgpt = r(mean)
gen chatgpt_index = (chatgpt_index_quarterly / `base_chatgpt') * 100

summ ai_stock_index if quarter == tq(2022q4)
local base_ai = r(mean)
replace ai_stock_index = (ai_stock_index / `base_ai') * 100

label variable chatgpt_index "ChatGPT Google Trends (Q4 2022 = 100)"
label variable ai_stock_index "STOXX Global AI Index (Q4 2022 = 100)"
label variable ai_index_ret_quarterly "Quarterly return on AI Index (%)"

* Save quarterly file
save "$PROC_DATA/ai_mania_proxies.dta", replace
export delimited using "$PROC_DATA/ai_mania_proxies.csv", replace

* Monthly file
use `chatgpt_monthly', clear
merge 1:1 month using `ai_monthly', nogen

save "$PROC_DATA/ai_mania_proxies_monthly.dta", replace

display as result "AI mania proxy data prepared:"
display as result "  - Quarterly: $PROC_DATA/ai_mania_proxies.dta"
display as result "  - Monthly: $PROC_DATA/ai_mania_proxies_monthly.dta"

********************************************************************************
