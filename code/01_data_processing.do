********************************************************************************
* STEP 1: DATA PROCESSING AND SAMPLE CONSTRUCTION
* Author: AI Hype Research Team
* Date: October 2025
********************************************************************************

clear all

* ==============================================================================
* 1.1 LOAD AND CLEAN 8-K AI DISCLOSURE DATA
* ==============================================================================

* Import 8-K filings with AI keywords
import delimited using "$RAW_DATA/ai_8k_oct2022_oct_2025.csv", clear

* Clean and format variables
rename name company_name
rename keyinstn company_key
rename filingdate filing_date_raw
rename keyfilecollection filing_id
rename keywordmentioncount ai_keyword_count

* Convert filing date to Stata date format
gen filing_date = date(filing_date_raw, "YMD")
format filing_date %td
drop filing_date_raw

* Extract ticker symbol from company name (format: "(EXCHANGE:TICKER) Company Name")
gen ticker = regexs(1) if regexm(company_name, "\(.*?:([A-Z]+)\)")
replace ticker = trim(ticker)

* Clean company name (remove ticker prefix)
gen company_clean = regexs(1) if regexm(company_name, "\) (.+)$")
replace company_clean = company_name if missing(company_clean)
replace company_clean = trim(company_clean)

* ==============================================================================
* 1.2 IDENTIFY FIRST AI DISCLOSURE PER FIRM
* ==============================================================================

* Sort by company and date
gsort company_key filing_date

* Flag first AI disclosure for each company
by company_key: gen first_disclosure = (_n == 1)

* Keep only first disclosures
keep if first_disclosure == 1

* Basic sample size
count
display "Sample size (first AI 8-Ks): " r(N)

* ==============================================================================
* 1.3 MERGE WITH KINDERMANN (2021) DIGITALIZATION SCORES
* ==============================================================================

/*
CLASSIFICATION APPROACH - KINDERMANN (2021) DIGITAL ORIENTATION SCORE

Instead of manual binary classification (Speculative vs Existing), we use the
validated "digi" score from Kindermann et al. (2021, European Management Journal)
as a CONTINUOUS measure of ex-ante firm digitalization level.

METHODOLOGY:
- Computer-aided text analysis (CATA) of 10-K filings
- Measures 4 dimensions of digital orientation:
  1. Digital technology scope (e.g., cloud, blockchain, IoT)
  2. Digital capabilities (e.g., analytics, AI, machine learning)
  3. Digital ecosystem coordination (e.g., API, multi-channel, platform)
  4. Digital architecture configuration (e.g., automation, digitalization)

- Dictionary of 148 validated keywords/phrases
- Score = (count of digital words / total words) * 1000
- Higher score = more digitally oriented firm ex-ante

INTERPRETATION:
- Low digi score (~0-5) = "Speculative" firms (low pre-existing digital capacity)
- High digi score (>10) = "Existing" firms (established digital operations)
- Continuous measure allows richer analysis of heterogeneous effects

SOURCE: kindermann_2021_10k_edgar_2005_2025.txt
*/

* Load Kindermann digitalization scores
preserve
import delimited using "$RAW_DATA/kindermann_2021_10k_edgar_2005_2025.txt", clear

* Keep most recent score before AI disclosure (use 2021 or 2022)
keep if inrange(year(date(period_ending, "YMD")), 2021, 2022)

* For firms with multiple years, keep most recent
gen period_date = date(period_ending, "YMD")
gsort cik -period_date
by cik: keep if _n == 1

* Clean company identifier
rename cik company_cik
rename digi digi_score_2021
rename conm company_name_10k
rename sic sic_code

keep company_cik digi_score_2021 company_name_10k sic_code

tempfile digi_scores
save `digi_scores'
restore

* Merge requires CIK - need to obtain from company_key or ticker
* NOTE: Manual matching or EDGAR API lookup may be required
* For now, create placeholder for CIK
gen company_cik = .
* TODO: Populate CIK using SEC EDGAR mapping (ticker -> CIK or keyInstn -> CIK)

merge m:1 company_cik using `digi_scores', keep(match master) nogen

* ==============================================================================
* 1.4 OBTAIN STOCK PRICE AND FIRM IDENTIFIER DATA FROM WRDS/CRSP
* ==============================================================================

/*
REQUIRED DATA FROM WRDS - CRSP (CENTER FOR RESEARCH IN SECURITY PRICES)

ACCESS: wrds.wharton.upenn.edu (requires institutional subscription)

DATASETS NEEDED:
1. CRSP Daily Stock File (crsp.dsf)
   - Daily returns, prices, trading volume
   - Event window: [-175, +30] days around first AI 8-K filing

2. CRSP Stock Header (crsp.dsenames)
   - Links TICKER -> PERMNO (permanent identifier)
   - Links PERMNO -> CUSIP
   - Company names, exchange codes

3. CRSP/Compustat Merged (crsp.ccmxpf_linktable)
   - Links PERMNO (CRSP) -> GVKEY (Compustat)
   - Enables merging stock data with fundamentals

HOW TO EXTRACT:

OPTION A: WRDS Web Query
--------------------------
1. Go to: https://wrds-www.wharton.upenn.edu/
2. Navigate to: CRSP -> Stock/Security Files -> Daily Stock File
3. Query Parameters:
   - Date Range: 2022-04-01 to 2025-12-31 (covers [-175, +30] for all events)
   - Company List: Upload ticker list from this sample
   - Variables: PERMNO, date, CUSIP, TICKER, RET, PRC, VOL, SHROUT
4. Download as CSV

OPTION B: WRDS SAS/R/Python (Recommended for large samples)
-----------------------------------------------------------
*/

* SAS CODE EXAMPLE (run on WRDS server):
/*
%let wrds=wrds-cloud.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

rsubmit;

* Get list of tickers;
proc upload data=ticker_list out=mylib.tickers; run;

* Get PERMNO-CUSIP mapping;
proc sql;
create table stock_ids as
select a.ticker, b.permno, b.cusip, b.ncusip, b.namedt, b.nameendt
from mylib.tickers as a
left join crsp.dsenames as b
on upcase(a.ticker) = upcase(b.ticker)
where namedt <= '31DEC2025'd and nameendt >= '01JAN2022'd;
quit;

* Get daily returns;
proc sql;
create table daily_returns as
select a.permno, a.date, a.cusip, a.ticker, a.ret, a.prc, a.vol, a.shrout
from crsp.dsf as a
inner join stock_ids as b
on a.permno = b.permno
where a.date between '01APR2022'd and '31DEC2025'd;
quit;

proc download data=daily_returns out=daily_returns; run;
endrsubmit;
*/

* R CODE EXAMPLE (using WRDS pgdata package):
/*
library(RPostgres)
library(tidyverse)

# Connect to WRDS
wrds <- dbConnect(
  Postgres(),
  host = 'wrds-pgdata.wharton.upenn.edu',
  port = 9737,
  dbname = 'wrds',
  user = 'your_username',
  password = rstudioapi::askForPassword("WRDS Password")
)

# Upload ticker list
tickers <- read_csv("ticker_list.csv")

# Get PERMNO-CUSIP mapping
stock_ids <- dbGetQuery(wrds, "
  SELECT ticker, permno, cusip, ncusip, comnam, namedt, nameendt
  FROM crsp.dsenames
  WHERE namedt <= '2025-12-31' AND nameendt >= '2022-01-01'
")

# Merge with our tickers
tickers_matched <- tickers %>%
  left_join(stock_ids, by = "ticker")

# Get daily returns for event window
daily_returns <- dbGetQuery(wrds, "
  SELECT permno, date, cusip, ret, prc, vol, shrout
  FROM crsp.dsf
  WHERE date BETWEEN '2022-04-01' AND '2025-12-31'
    AND permno IN (?)
", params = list(unique(tickers_matched$permno)))

# Export
write_csv(daily_returns, "crsp_daily_returns.csv")
write_csv(tickers_matched, "crsp_stock_identifiers.csv")

dbDisconnect(wrds)
*/

* Import CRSP identifiers (after extraction from WRDS)
* NOTE: File must be created using WRDS queries above
cap confirm file "$EXT_DATA/crsp_stock_identifiers.csv"
if _rc == 0 {
    preserve
    import delimited using "$EXT_DATA/crsp_stock_identifiers.csv", clear

    * Keep relevant mapping variables
    keep ticker permno cusip ncusip comnam

    * Create 8-digit CUSIP (required for WRDS Event Study)
    gen cusip8 = substr(cusip, 1, 8)

    duplicates drop ticker, force
    tempfile crsp_ids
    save `crsp_ids'
    restore

    merge 1:1 ticker using `crsp_ids', keep(match master) nogen
}
else {
    display as error "ERROR: CRSP identifier file not found."
    display as error "Please extract data from WRDS first (see code comments)."
    gen permno = .
    gen cusip8 = ""
}

* ==============================================================================
* 1.5 OBTAIN FIRM FINANCIAL CHARACTERISTICS FROM COMPUSTAT
* ==============================================================================

/*
REQUIRED DATA FROM WRDS - COMPUSTAT ANNUAL FUNDAMENTALS

ACCESS: wrds.wharton.upenn.edu

DATASET: comp.funda (Compustat - Capital IQ Annual Fundamentals)

VARIABLES NEEDED (measured 12 months prior to AI disclosure):
- GVKEY: Firm identifier
- DATADATE: Fiscal year end date
- AT: Total assets
- CSHO: Common shares outstanding
- PRCC_F: Fiscal year closing price
- SALE: Sales/Revenue
- OIBDP: Operating income before depreciation
- CEQ: Common equity
- REVT: Total revenue
- NI: Net income
- DLTIS: Long-term debt issuance
- FINCF: Financing cash flow
- AGE: Firm age (calculated from incorporation date)

CALCULATED VARIABLES:
- Market value = CSHO * PRCC_F
- Tobin's Q = (MVE + PS + DEBT) / AT
- ROA = NI / AT
- ROE = NI / CEQ
- Loss indicator = (NI < 0)
- Equity issuance = DLTIS
- Hadlock-Pierce financial constraint index = -0.737*SIZE + 0.043*SIZE^2 - 0.040*AGE

HOW TO EXTRACT:
*/

* SAS CODE FOR COMPUSTAT EXTRACTION:
/*
rsubmit;

* Get PERMNO-GVKEY link;
proc sql;
create table ccm_link as
select lpermno as permno, gvkey, linkdt, linkenddt
from crsp.ccmxpf_linktable
where linktype in ('LU', 'LC') and linkprim in ('P', 'C');
quit;

* Get Compustat fundamentals;
proc sql;
create table compustat as
select
    a.gvkey, a.datadate, a.fyear,
    a.at, a.csho, a.prcc_f, a.sale, a.revt,
    a.oibdp, a.ni, a.ceq, a.dltt, a.dlc,
    a.dltis, a.fincf, a.sich, a.sic,
    (a.csho * a.prcc_f) as mve,
    a.ni / a.at as roa,
    a.ni / a.ceq as roe,
    case when a.ni < 0 then 1 else 0 end as loss,
    /* Tobin's Q calculation */
    ((a.csho*a.prcc_f) + a.pstkrv + (a.dltt + a.dlc) - a.act) / a.at as tobins_q
from comp.funda as a
where a.indfmt='INDL'
    and a.datafmt='STD'
    and a.popsrc='D'
    and a.consol='C'
    and a.datadate between '01JAN2020'd and '31DEC2024'd
;
quit;

* Merge with CCM link;
proc sql;
create table compustat_final as
select a.*, b.permno
from compustat as a
left join ccm_link as b
on a.gvkey = b.gvkey
    and b.linkdt <= a.datadate
    and (a.datadate <= b.linkenddt or missing(b.linkenddt));
quit;

proc download data=compustat_final out=compustat; run;
endrsubmit;
*/

* Import Compustat data
cap confirm file "$EXT_DATA/compustat_extract.csv"
if _rc == 0 {
    preserve
    import delimited using "$EXT_DATA/compustat_extract.csv", clear

    * Convert dates
    gen datadate_fmt = date(datadate, "YMD")
    format datadate_fmt %td

    * Keep most recent fiscal year before AI disclosure for each PERMNO
    * Will merge based on PERMNO and appropriate time window

    tempfile compustat
    save `compustat'
    restore

    * Merge with main data
    * Match to fiscal year ending within 12 months before AI disclosure
    gen merge_year = year(filing_date) - 1

    merge m:1 permno merge_year using `compustat', ///
        keep(match master) keepusing(at mve sale tobins_q roa roe loss ///
        dltis fincf sic) nogen
}
else {
    display as error "WARNING: Compustat data not found. Creating placeholders."
    gen at = .
    gen mve = .
    gen sale = .
    gen tobins_q = .
    gen roa = .
    gen roe = .
    gen loss = .
}

* ==============================================================================
* 1.6 CALCULATE FIRM AGE
* ==============================================================================

* Firm age = years since first appearance in Compustat
* Alternative: Use founding date from Jay Ritter IPO database or Capital IQ

gen firm_age = year(filing_date) - 1990  // Placeholder - adjust based on actual incorporation

* ==============================================================================
* 1.7 CALCULATE HADLOCK-PIERCE FINANCIAL CONSTRAINT INDEX
* ==============================================================================

* HP Index = -0.737*SIZE + 0.043*SIZE^2 - 0.040*AGE
* SIZE = log(inflation-adjusted total assets), capped at log($4.5B)
* AGE = min(firm age, 37)

gen size_adj = ln(at)
replace size_adj = ln(4500) if size_adj > ln(4500) & !missing(size_adj)

gen age_adj = min(firm_age, 37)

gen hp_index = -0.737*size_adj + 0.043*(size_adj^2) - 0.040*age_adj

* ==============================================================================
* 1.8 OBTAIN ADDITIONAL CONTROL VARIABLES FROM WRDS
* ==============================================================================

/*
OTHER REQUIRED WRDS DATASETS:

1. AUDIT ANALYTICS (audit.auditnonreli)
   - Going concern opinions: gc_opinion
   - Big 4 auditor: big4_auditor
   - Internal control weaknesses: icw_exists

   QUERY:
   SELECT company_fkey, filing_date, gc_opinion, big4_auditor, icw
   FROM audit.auditnonreli
   WHERE filing_date BETWEEN '2021-01-01' AND '2024-12-31'

2. I/B/E/S ANALYST COVERAGE (ibes.detsumm)
   - Number of analysts: numest

   QUERY:
   SELECT ticker, statpers, numest, meanest, medest
   FROM ibes.detsumm
   WHERE statpers BETWEEN '2021-01-01' AND '2024-12-31'

3. THOMSON REUTERS 13F (tr_13f.s34)
   - Institutional ownership: sum(shares) / total shares

   QUERY:
   SELECT cusip, rdate, fdate, shares, mgrno
   FROM tfn.s34
   WHERE fdate BETWEEN '2021-01-01' AND '2024-12-31'

4. FAMA-FRENCH FACTORS (ff.factors_daily)
   - Already available as research dataset
   - Direct download: https://wrds-www.wharton.upenn.edu/pages/get-data/fama-french-data-library/

   QUERY:
   SELECT date, mktrf, smb, hml, rf
   FROM ff.factors_daily
   WHERE date BETWEEN '2022-01-01' AND '2025-12-31'
*/

* Placeholder for analyst coverage
gen analyst_coverage = .

* Placeholder for institutional ownership
gen inst_ownership = .

* Placeholder for auditor variables
gen big4_auditor = .
gen going_concern = .
gen ic_weakness = .

* ==============================================================================
* 1.9 CREATE MATCHED CONTROL SAMPLE
* ==============================================================================

/*
CONTROL SAMPLE CONSTRUCTION:

For each firm with first AI 8-K disclosure, match to 1-3 control firms that:
1. Did NOT file AI-related 8-K in our sample period
2. Same industry (3-digit SIC code)
3. Closest total assets (within 50-200% of treatment firm)
4. Active in the same fiscal year

MATCHING PROCEDURE:
- Use Compustat universe minus treatment firms
- Match without replacement
- Use coarsened exact matching (CEM) or propensity score matching
*/

preserve
* Load full Compustat universe (from WRDS extraction)
* Filter to firms without AI 8-K disclosures
* Perform matching algorithm

* TODO: Implement matching algorithm based on available controls
restore

* ==============================================================================
* 1.10 SAVE PROCESSED SAMPLE
* ==============================================================================

* Create industry classification (Fama-French 12 industries)
* Based on SIC codes - implement FF12 mapping

gen ff12_industry = .
* TODO: Implement FF12 industry classification lookup

* Label variables
label variable ticker "Stock ticker symbol"
label variable cusip8 "8-digit CUSIP"
label variable permno "CRSP permanent company identifier"
label variable filing_date "Date of first AI-related 8-K filing"
label variable digi_score_2021 "Kindermann (2021) digitalization score"
label variable ai_keyword_count "Count of AI keywords in 8-K"
label variable at "Total assets ($MM)"
label variable mve "Market value of equity ($MM)"
label variable tobins_q "Tobin's Q"
label variable roa "Return on assets"
label variable roe "Return on equity"
label variable loss "Loss indicator (1=negative income)"
label variable firm_age "Firm age (years)"
label variable hp_index "Hadlock-Pierce financial constraint index"

* Summary statistics
summ digi_score_2021 at mve tobins_q roa firm_age, detail

* Save final sample
compress
save "$PROC_DATA/sample_firms.dta", replace

* Export ticker-CUSIP list for WRDS Event Study (Step 4)
keep ticker cusip8 filing_date
keep if !missing(cusip8)
export delimited using "$PROC_DATA/event_study_input.csv", replace

display as result "STEP 1 COMPLETE: Sample construction finished"
display as result "Output saved to: $PROC_DATA/sample_firms.dta"

********************************************************************************
