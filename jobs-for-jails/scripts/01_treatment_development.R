# ==============================================================================
# Jobs for Jails: Treatment Development and Validation
# ==============================================================================
# Purpose: Develop and validate vignette treatments for the experiment
# Author: Charles Crabtree
# ==============================================================================

# Load packages
library(tidyverse)
library(randomizr)
library(knitr)
library(kableExtra)

# ==============================================================================
# TREATMENT CONDITIONS
# ==============================================================================

# Define the 2x2 factorial design
# Factor 1: Facility framing (detention center vs. processing facility)
# Factor 2: Economic emphasis (jobs mentioned vs. not mentioned)

treatments <- tibble(
  condition = 1:4,
  condition_name = c(
    "detention_no_jobs",
    "detention_jobs", 
    "processing_no_jobs",
    "processing_jobs"
  ),
  facility_frame = c(
    "detention_center",
    "detention_center",
    "processing_facility",
    "processing_facility"
  ),
  economic_emphasis = c(
    "no_jobs",
    "jobs",
    "no_jobs",
    "jobs"
  )
)

print(treatments)

# ==============================================================================
# VIGNETTE TEXT
# ==============================================================================

# Base components
location_text <- "The federal government has announced plans to build a new facility in [COUNTY], [STATE]."

# Facility framing variations
facility_frames <- list(
  detention_center = "The facility will be an ICE detention center that will house undocumented immigrants awaiting deportation hearings.",
  processing_facility = "The facility will be a federal immigration processing center that will handle administrative cases for individuals in the immigration system."
)

# Economic emphasis variations
economic_frames <- list(
  no_jobs = "The facility is expected to be operational within two years.",
  jobs = "The facility is expected to create approximately 350 permanent jobs for local residents, with an estimated $25 million annual impact on the local economy. Construction alone will employ over 500 workers from the area."
)

# Function to generate full vignette
generate_vignette <- function(facility_frame, economic_emphasis, 
                               county = "[YOUR COUNTY]", state = "[YOUR STATE]") {
  
  location <- str_replace_all(location_text, c("\\[COUNTY\\]" = county, "\\[STATE\\]" = state))
  facility <- facility_frames[[facility_frame]]
  economic <- economic_frames[[economic_emphasis]]
  
  paste(location, facility, economic, sep = " ")
}

# Generate all four vignettes
vignettes <- treatments %>%
  rowwise() %>%
  mutate(
    vignette_text = generate_vignette(facility_frame, economic_emphasis)
  ) %>%
  ungroup()

# Display vignettes
cat("\n==== VIGNETTE TEXTS ====\n\n")
for (i in 1:nrow(vignettes)) {
  cat(paste0("--- Condition ", i, ": ", vignettes$condition_name[i], " ---\n"))
  cat(vignettes$vignette_text[i])
  cat("\n\n")
}

# ==============================================================================
# RANDOMIZATION VALIDATION
# ==============================================================================

# Simulate randomization for N respondents
set.seed(12345)
n_respondents <- 2000

# Complete randomization (equal probability)
simulated_data <- tibble(
  respondent_id = 1:n_respondents,
  condition = complete_ra(N = n_respondents, num_arms = 4)
) %>%
  left_join(treatments, by = "condition")

# Check balance
cat("\n==== RANDOMIZATION BALANCE CHECK ====\n\n")
table(simulated_data$condition_name)
prop.table(table(simulated_data$condition_name))

# Chi-square test for uniform distribution
chisq.test(table(simulated_data$condition))

# ==============================================================================
# BLOCK RANDOMIZATION (by partisanship)
# ==============================================================================

# If we want to ensure balance within partisan groups
simulated_data_blocked <- tibble(
  respondent_id = 1:n_respondents,
  party_id = sample(c("Democrat", "Republican", "Independent"), 
                    n_respondents, replace = TRUE, 
                    prob = c(0.35, 0.30, 0.35))
) %>%
  mutate(
    condition = block_ra(blocks = party_id, num_arms = 4)
  ) %>%
  left_join(treatments, by = "condition")

# Check balance within blocks
cat("\n==== BLOCKED RANDOMIZATION BALANCE ====\n\n")
table(simulated_data_blocked$party_id, simulated_data_blocked$condition_name)

# ==============================================================================
# MANIPULATION CHECK ITEMS
# ==============================================================================

manipulation_checks <- list(
  
  facility_check = list(
    question = "Based on the passage you just read, what type of facility is being proposed?",
    options = c(
      "An ICE detention center",
      "A federal immigration processing center",
      "A border patrol station",
      "I don't remember"
    ),
    correct_detention = 1,
    correct_processing = 2
  ),
  
  economic_check = list(
    question = "Did the passage mention any economic benefits of the proposed facility?",
    options = c(
      "Yes, it mentioned job creation and economic impact",
      "No, it did not mention economic benefits",
      "I don't remember"
    ),
    correct_jobs = 1,
    correct_no_jobs = 2
  )
)

cat("\n==== MANIPULATION CHECK ITEMS ====\n\n")
print(manipulation_checks)

# ==============================================================================
# ATTENTION CHECK
# ==============================================================================

attention_check <- list(
  question = "To ensure you are paying attention, please select 'Strongly agree' for this item.",
  scale = c("Strongly disagree", "Disagree", "Somewhat disagree", 
            "Neither agree nor disagree", "Somewhat agree", "Agree", "Strongly agree"),
  correct = "Strongly agree"
)

# ==============================================================================
# EXPORT TREATMENTS FOR QUALTRICS
# ==============================================================================

# Create Qualtrics-ready format
qualtrics_treatments <- vignettes %>%
  select(condition, condition_name, vignette_text) %>%
  mutate(
    qualtrics_var = paste0("treatment_", condition)
  )

write_csv(qualtrics_treatments, 
          "/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/qualtrics/treatment_texts.csv")

cat("\nTreatment texts exported to qualtrics/treatment_texts.csv\n")

# ==============================================================================
# DYNAMIC LOCATION INSERTION
# ==============================================================================

# Function to create personalized vignette based on respondent's location
create_personalized_vignette <- function(condition, county, state) {
  
  row <- treatments %>% filter(condition == !!condition)
  
  generate_vignette(
    facility_frame = row$facility_frame,
    economic_emphasis = row$economic_emphasis,
    county = county,
    state = state
  )
}

# Example
cat("\n==== PERSONALIZED VIGNETTE EXAMPLE ====\n\n")
cat(create_personalized_vignette(2, "Maricopa County", "Arizona"))

# ==============================================================================
# PILOT TEST PROTOCOL
# ==============================================================================

pilot_protocol <- "
PILOT TEST PROTOCOL
===================

1. Sample: N = 100 from Prolific (US adults)

2. Goals:
   - Test comprehension of vignettes
   - Validate manipulation checks (>80% correct)
   - Check attention check pass rate
   - Estimate outcome variable distributions
   - Identify floor/ceiling effects

3. Procedure:
   a. Consent
   b. Demographics (including ZIP for county lookup)
   c. Pre-treatment attitudes (immigration, economy)
   d. Random assignment to 1 of 4 conditions
   e. Vignette presentation (timed: min 15 seconds)
   f. Manipulation checks
   g. Outcome measures
   h. Attention check
   i. Debrief

4. Success criteria:
   - Manipulation check accuracy > 80%
   - Attention check pass rate > 90%
   - No ceiling/floor effects on primary DV
   - Treatment groups balanced on pre-treatment covariates
"

cat(pilot_protocol)

# Save pilot protocol
writeLines(pilot_protocol, 
           "/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/docs/pilot_protocol.txt")
