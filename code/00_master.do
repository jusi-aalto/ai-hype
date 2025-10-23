********************************************************************************
* MASTER DO FILE
* Replication Study: Riding the Generative AI Mania
* Based on Cheng et al. (2019) Blockchain Mania methodology
********************************************************************************

clear all
set more off
set maxvar 10000

* ==============================================================================
* SET FILE PATHS - ADJUST THESE TO YOUR LOCAL ENVIRONMENT
* ==============================================================================

* Project directory
global PROJECT_DIR "/home/user/ai-hype"

* Data directories
global RAW_DATA    "$PROJECT_DIR/data/raw"
global PROC_DATA   "$PROJECT_DIR/data/processed"
global EXT_DATA    "$PROJECT_DIR/data/external"

* Output directories
global TABLES      "$PROJECT_DIR/output/tables"
global FIGURES     "$PROJECT_DIR/output/figures"
global APPENDIX    "$PROJECT_DIR/output/appendix"

* Code directory
global CODE        "$PROJECT_DIR/code"

* Create output directories if they don't exist
cap mkdir "$PROC_DATA"
cap mkdir "$EXT_DATA"
cap mkdir "$TABLES"
cap mkdir "$FIGURES"
cap mkdir "$APPENDIX"

* ==============================================================================
* EXECUTE ALL STEPS IN SEQUENCE
* ==============================================================================

* Step 1: Data Processing and Sample Construction
do "$CODE/01_data_processing.do"

* Step 2: Classification using Kindermann (2021) Digitalization Score
do "$CODE/02_classify_disclosures.do"

* Step 3: Descriptive Statistics
do "$CODE/03_descriptives.do"

* Step 4: Event Study (WRDS Event Study Tool)
do "$CODE/04_event_study.do"

* Step 5: Additional Analyses (AI Mania Tests)
do "$CODE/05_additional_analyses.do"

* Step 6: Generate Publication Tables and Figures
do "$CODE/06_output_tables.do"

********************************************************************************
* END OF MASTER FILE
********************************************************************************
