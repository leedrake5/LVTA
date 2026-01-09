# Automated LVTA Update Script
# Downloads FINRA margin statistics, appends raw data to Google Sheet
# (formulas in sheet calculate LVTA metrics), regenerates plots, and commits.

source("~/GitHub/LVTA/R/back.r")

library(httr)
library(readxl)
library(googlesheets4)
library(tidyverse)
library(lubridate)

# Configuration
FINRA_URL <- "https://www.finra.org/sites/default/files/2021-03/margin-statistics.xlsx"
SHEET_URL <- "https://docs.google.com/spreadsheets/d/1Qq2EYhEZeQfszqlYD-lyEsa6VJcGZSq4V9KabMUf2fE"
REPO_PATH <- "~/GitHub/LVTA"
TEMP_FILE <- tempfile(fileext = ".xlsx")

cat("=== LVTA Automated Update ===\n")
cat("Running at:", as.character(Sys.time()), "\n\n")

# Step 1: Download FINRA Excel data
cat("Step 1: Downloading FINRA margin statistics...\n")
response <- GET(FINRA_URL, write_disk(TEMP_FILE, overwrite = TRUE))

if (status_code(response) != 200) {
  stop("Failed to download FINRA data. HTTP status: ", status_code(response))
}
cat("  Downloaded successfully.\n\n")

# Step 2: Parse the Excel file
cat("Step 2: Parsing Excel data...\n")
finra_raw <- read_excel(TEMP_FILE)

# Expected columns from FINRA:
# - Date column (Month/Year format)
# - Debit Balances in Customers' Securities Margin Accounts
# - Free Credit Balances in Customers' Cash Accounts
# - Free Credit Balances in Customers' Securities Margin Accounts

# Rename columns to match Google Sheet headers exactly
colnames(finra_raw) <- c("Date", "Debt Balances", "Free Credit Balances Cash", "Free Credit Balances Margin")

# Parse FINRA date format (e.g., "Nov-25" -> "2025-11-01")
finra_data <- finra_raw %>%
  filter(!is.na(`Debt Balances`)) %>%
  mutate(
    # Parse "Mon-YY" format and set to first of month
    Date = parse_date_time(paste0("01-", Date), orders = "dmy") %>% as.Date()
  ) %>%
  filter(!is.na(Date)) %>%
  arrange(Date)

# Format date for Google Sheets (YYYY-MM-DD)
finra_data <- finra_data %>%
  mutate(Date = format(Date, "%Y-%m-%d"))

cat("  Parsed", nrow(finra_data), "rows from FINRA.\n\n")

# Step 3: Get existing data from Google Sheet
cat("Step 3: Fetching existing Google Sheet data...\n")
existing_data <- read_sheet(SHEET_URL, sheet = "LVTA")

existing_dates <- existing_data$Date
cat("  Found", length(existing_dates), "existing records.\n\n")

# Step 4: Find new data to append (raw columns only - formulas calculate LVTA)
cat("Step 4: Checking for new data...\n")
new_data <- finra_data %>%
  filter(!(Date %in% existing_dates)) %>%
  select(Date, `Debt Balances`, `Free Credit Balances Cash`, `Free Credit Balances Margin`)

if (nrow(new_data) == 0) {
  cat("  No new data to add. Google Sheet is up to date.\n")
  cat("\n=== Update complete (no changes) ===\n")
  quit(save = "no", status = 0)
}

cat("  Found", nrow(new_data), "new month(s) to add:\n")
for (i in 1:nrow(new_data)) {
  cat("    -", new_data$Date[i], "\n")
}
cat("\n")

# Step 5: Append raw data to Google Sheet (arrayformulas will calculate LVTA metrics)
cat("Step 5: Appending raw data to Google Sheet...\n")
sheet_append(SHEET_URL, new_data, sheet = "LVTA")
cat("  Appended successfully. Sheet formulas will calculate LVTA metrics.\n\n")

# Step 6: Regenerate plots
cat("Step 6: Regenerating LVTA plots...\n")
source("~/GitHub/LVTA/R/LVTA.r")
cat("  Plots regenerated.\n\n")

# Step 7: Git commit and push
cat("Step 7: Committing and pushing changes...\n")
setwd(REPO_PATH)

# Add plot files
system("git add Plots/*.jpg")

# Check if there are changes to commit
git_status <- system("git diff --cached --quiet", intern = FALSE)

if (git_status != 0) {
  # There are staged changes
  commit_msg <- paste0("Update LVTA data and plots - ", format(Sys.Date(), "%B %Y"))
  system(paste0('git commit -m "', commit_msg, '"'))

  # Push to remote
  push_result <- system("git push")

  if (push_result == 0) {
    cat("  Pushed successfully.\n")
  } else {
    cat("  Warning: Push failed. You may need to push manually.\n")
  }
} else {
  cat("  No plot changes to commit.\n")
}

cat("\n=== Update complete ===\n")
cat("New months added:", nrow(new_data), "\n")

# Cleanup
unlink(TEMP_FILE)
