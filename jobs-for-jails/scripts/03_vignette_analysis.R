# ==============================================================================
# Jobs for Jails: Vignette Experiment Analysis
# ==============================================================================
# Purpose: Analyze the 2x2 factorial vignette experiment
# Author: Charles Crabtree
# ==============================================================================

# Load packages
library(tidyverse)
library(estimatr)      # Robust standard errors
library(modelsummary)  # Regression tables
library(marginaleffects)
library(ggthemes)
library(broom)
library(sandwich)
library(lmtest)

# ==============================================================================
# LOAD AND PREPARE DATA
# ==============================================================================

# Load Qualtrics data (update path when data is collected)
# df <- read_csv("data/raw/qualtrics_export.csv")

# For development: simulate data
set.seed(42)
n <- 2000

df <- tibble(
  response_id = 1:n,
  # Treatment assignment
  facility_frame = sample(c("detention", "processing"), n, replace = TRUE),
  economic_emphasis = sample(c("jobs", "no_jobs"), n, replace = TRUE),
  # Pre-treatment covariates
  party_id = sample(c("Democrat", "Republican", "Independent"), n, 
                    replace = TRUE, prob = c(0.35, 0.30, 0.35)),
  economic_anxiety = rnorm(n, 3.5, 1.2),  # 1-7 scale
  immigration_attitude = rnorm(n, 4, 1.5), # 1-7 scale (pre-treatment)
  local_unemployment = rnorm(n, 5, 2),     # Percent, from BLS by ZIP
  age = round(rnorm(n, 45, 15)),
  female = rbinom(n, 1, 0.52),
  education = sample(c("HS or less", "Some college", "Bachelor's", "Graduate"), 
                     n, replace = TRUE, prob = c(0.30, 0.30, 0.25, 0.15)),
  # Manipulation checks (1 = correct)
  manip_check_facility = rbinom(n, 1, 0.85),
  manip_check_economic = rbinom(n, 1, 0.88),
  attention_check_pass = rbinom(n, 1, 0.92)
) %>%
  mutate(
    # Create treatment indicators
    detention = ifelse(facility_frame == "detention", 1, 0),
    jobs = ifelse(economic_emphasis == "jobs", 1, 0),
    # Generate outcome with treatment effects
    support_facility = 4 +
      -0.25 * detention +           # Detention framing reduces support
      0.35 * jobs +                  # Jobs framing increases support
      0.30 * detention * jobs +      # Interaction: jobs mitigates detention effect
      0.15 * (party_id == "Republican") +
      -0.10 * (party_id == "Democrat") +
      0.08 * economic_anxiety +
      0.05 * local_unemployment +
      rnorm(n, 0, 1.3),
    support_facility = pmin(pmax(support_facility, 1), 7),  # Bound to 1-7
    # Support for ICE raids (secondary outcome)
    support_raids = 3.5 +
      0.20 * detention +
      0.25 * jobs +
      0.20 * detention * jobs +
      0.30 * (party_id == "Republican") +
      -0.25 * (party_id == "Democrat") +
      rnorm(n, 0, 1.4),
    support_raids = pmin(pmax(support_raids, 1), 7),
    # Condition labels
    condition = case_when(
      detention == 1 & jobs == 1 ~ "Detention + Jobs",
      detention == 1 & jobs == 0 ~ "Detention Only",
      detention == 0 & jobs == 1 ~ "Processing + Jobs",
      detention == 0 & jobs == 0 ~ "Processing Only"
    )
  )

# ==============================================================================
# SAMPLE DESCRIPTIVES AND BALANCE CHECKS
# ==============================================================================

cat("==== SAMPLE SIZE ====\n")
cat(paste0("Total N: ", nrow(df), "\n"))
cat(paste0("Passed attention check: ", sum(df$attention_check_pass), "\n"))
cat(paste0("Passed both manipulation checks: ", 
           sum(df$manip_check_facility == 1 & df$manip_check_economic == 1), "\n\n"))

# Balance table
cat("==== TREATMENT BALANCE ====\n")
df %>%
  group_by(facility_frame, economic_emphasis) %>%
  summarise(
    n = n(),
    mean_age = mean(age),
    pct_female = mean(female) * 100,
    mean_econ_anxiety = mean(economic_anxiety),
    pct_republican = mean(party_id == "Republican") * 100,
    .groups = "drop"
  ) %>%
  print()

# Balance test (F-tests for pre-treatment covariates)
cat("\n==== BALANCE TESTS ====\n")

balance_vars <- c("age", "female", "economic_anxiety", "local_unemployment")

balance_tests <- map_dfr(balance_vars, function(var) {
  formula <- as.formula(paste(var, "~ detention * jobs"))
  model <- lm(formula, data = df)
  f_test <- summary(model)$fstatistic
  p_val <- pf(f_test[1], f_test[2], f_test[3], lower.tail = FALSE)
  
  tibble(
    variable = var,
    F_statistic = round(f_test[1], 3),
    p_value = round(p_val, 3)
  )
})

print(balance_tests)

# ==============================================================================
# MAIN ANALYSIS: 2x2 FACTORIAL
# ==============================================================================

cat("\n==== MAIN RESULTS: SUPPORT FOR FACILITY ====\n")

# Model 1: Simple 2x2 without controls (robust SEs)
m1 <- lm_robust(
  support_facility ~ detention * jobs,
  data = df,
  se_type = "HC2"
)

# Model 2: With pre-treatment covariates (robust SEs)
m2 <- lm_robust(
  support_facility ~ detention * jobs + 
    party_id + economic_anxiety + local_unemployment + 
    age + female + education,
  data = df,
  se_type = "HC2"
)

# Model 3: Full model with additional interactions (robust SEs)
m3 <- lm_robust(
  support_facility ~ detention * jobs * party_id + 
    economic_anxiety + local_unemployment + age + female + education,
  data = df,
  se_type = "HC2"
)

# Display results
modelsummary(
  list(
    "Base" = m1, 
    "With Controls" = m2, 
    "Three-way Interaction" = m3
  ),
  stars = TRUE,
  gof_omit = "AIC|BIC|Log",
  coef_rename = c(
    "detention" = "Detention Frame",
    "jobs" = "Jobs Emphasis",
    "detention:jobs" = "Detention × Jobs",
    "party_idRepublican" = "Republican",
    "party_idIndependent" = "Independent",
    "economic_anxiety" = "Economic Anxiety",
    "local_unemployment" = "Local Unemployment"
  )
)

# ==============================================================================
# MARGINAL EFFECTS
# ==============================================================================

cat("\n==== MARGINAL EFFECTS ====\n")

# Average marginal effect of jobs emphasis by facility framing
ame_jobs <- avg_comparisons(
  m2, 
  variables = "jobs",
  by = "detention"
)
print(ame_jobs)

# Average marginal effect of detention framing by jobs emphasis
ame_detention <- avg_comparisons(
  m2,
  variables = "detention",
  by = "jobs"
)
print(ame_detention)

# ==============================================================================
# HETEROGENEOUS TREATMENT EFFECTS
# ==============================================================================

cat("\n==== HETEROGENEOUS EFFECTS BY PARTISANSHIP ====\n")

# Separate models by party
models_by_party <- df %>%
  group_by(party_id) %>%
  group_map(~ {
    lm_robust(
      support_facility ~ detention * jobs,
      data = .x,
      se_type = "HC2"
    )
  }, .keep = TRUE)

names(models_by_party) <- c("Democrat", "Independent", "Republican")

# Extract interaction coefficients
het_effects <- map_dfr(names(models_by_party), function(party) {
  mod <- models_by_party[[party]]
  coef_row <- tidy(mod) %>% filter(term == "detention:jobs")
  
  tibble(
    party = party,
    estimate = coef_row$estimate,
    std.error = coef_row$std.error,
    p.value = coef_row$p.value,
    conf.low = coef_row$conf.low,
    conf.high = coef_row$conf.high
  )
})

print(het_effects)

# ==============================================================================
# HETEROGENEOUS EFFECTS BY ECONOMIC CONDITIONS
# ==============================================================================

cat("\n==== HETEROGENEOUS EFFECTS BY LOCAL UNEMPLOYMENT ====\n")

# Create unemployment terciles
df <- df %>%
  mutate(
    unemployment_tercile = ntile(local_unemployment, 3),
    unemployment_level = factor(unemployment_tercile, 
                                labels = c("Low", "Medium", "High"))
  )

# Model with three-way interaction
m_unemployment <- lm_robust(
  support_facility ~ detention * jobs * unemployment_level +
    party_id + economic_anxiety + age + female,
  data = df,
  se_type = "HC2"
)

summary(m_unemployment)

# Marginal effects by unemployment level
ame_by_unemployment <- avg_comparisons(
  m_unemployment,
  variables = "detention",
  by = c("jobs", "unemployment_level")
)

print(ame_by_unemployment)

# ==============================================================================
# SECONDARY OUTCOME: SUPPORT FOR ICE RAIDS
# ==============================================================================

cat("\n==== SECONDARY OUTCOME: SUPPORT FOR ICE RAIDS ====\n")

m_raids <- lm_robust(
  support_raids ~ detention * jobs + 
    party_id + economic_anxiety + local_unemployment + 
    age + female + education,
  data = df,
  se_type = "HC2"
)

summary(m_raids)

# ==============================================================================
# VISUALIZATION
# ==============================================================================

# Cell means plot
cell_means <- df %>%
  group_by(facility_frame, economic_emphasis) %>%
  summarise(
    mean = mean(support_facility),
    se = sd(support_facility) / sqrt(n()),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(
    ci_low = mean - 1.96 * se,
    ci_high = mean + 1.96 * se
  )

p_cell_means <- ggplot(cell_means, 
                       aes(x = facility_frame, y = mean, 
                           fill = economic_emphasis)) +
  geom_col(position = position_dodge(0.8), width = 0.7, alpha = 0.8) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high),
                position = position_dodge(0.8), width = 0.2) +
  scale_fill_manual(
    values = c("jobs" = "#2166AC", "no_jobs" = "#B2182B"),
    labels = c("Jobs Emphasized", "No Jobs"),
    name = "Economic Frame"
  ) +
  scale_x_discrete(labels = c("Detention Center", "Processing Facility")) +
  scale_y_continuous(limits = c(1, 7), breaks = 1:7) +
  labs(
    title = "Support for Proposed Facility by Treatment Condition",
    subtitle = "Mean values with 95% confidence intervals",
    x = "Facility Framing",
    y = "Support (1-7 scale)"
  ) +
  theme_tufte(base_size = 14) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 16),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12)
  )

ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/cell_means.pdf",
       p_cell_means, width = 9, height = 7)
ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/cell_means.png",
       p_cell_means, width = 9, height = 7, dpi = 300)

# Interaction plot
p_interaction <- ggplot(cell_means,
                        aes(x = economic_emphasis, y = mean, 
                            color = facility_frame, group = facility_frame)) +
  geom_point(size = 4) +
  geom_line(linewidth = 1.2) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = 0.1) +
  scale_color_manual(
    values = c("detention" = "#B2182B", "processing" = "#2166AC"),
    labels = c("Detention Center", "Processing Facility"),
    name = "Facility Type"
  ) +
  scale_x_discrete(labels = c("Jobs Emphasized", "No Jobs Mentioned")) +
  scale_y_continuous(limits = c(3, 5.5)) +
  labs(
    title = "Interaction: Jobs Emphasis Mitigates Detention Framing Effect",
    x = "Economic Frame",
    y = "Support for Facility (1-7)"
  ) +
  theme_tufte(base_size = 14) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 16),
    axis.title = element_text(size = 14)
  )

ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/interaction_plot.pdf",
       p_interaction, width = 9, height = 7)

# Heterogeneous effects by party
p_het_party <- ggplot(het_effects, 
                      aes(x = party, y = estimate, color = party)) +
  geom_point(size = 4) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_manual(
    values = c("Democrat" = "#2166AC", "Independent" = "#4DAF4A", "Republican" = "#B2182B")
  ) +
  labs(
    title = "Interaction Effect (Detention × Jobs) by Party",
    subtitle = "Point estimates with 95% CIs from robust regression",
    x = "Party Identification",
    y = "Interaction Coefficient"
  ) +
  theme_tufte(base_size = 14) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 16),
    axis.title = element_text(size = 14)
  )

ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/het_effects_party.pdf",
       p_het_party, width = 9, height = 7)

# ==============================================================================
# ROBUSTNESS CHECKS
# ==============================================================================

cat("\n==== ROBUSTNESS CHECKS ====\n")

# 1. Exclude attention check failures
df_clean <- df %>% filter(attention_check_pass == 1)

m_robust1 <- lm_robust(
  support_facility ~ detention * jobs + party_id + economic_anxiety,
  data = df_clean,
  se_type = "HC2"
)

cat("Excluding attention check failures:\n")
tidy(m_robust1) %>% filter(str_detect(term, "detention|jobs")) %>% print()

# 2. Exclude manipulation check failures
df_manip <- df %>% 
  filter(manip_check_facility == 1 & manip_check_economic == 1)

m_robust2 <- lm_robust(
  support_facility ~ detention * jobs + party_id + economic_anxiety,
  data = df_manip,
  se_type = "HC2"
)

cat("\nExcluding manipulation check failures:\n")
tidy(m_robust2) %>% filter(str_detect(term, "detention|jobs")) %>% print()

# 3. Alternative specifications (ordered probit)
library(MASS)
m_oprobit <- polr(
  factor(round(support_facility)) ~ detention * jobs + party_id,
  data = df,
  method = "probit"
)

cat("\nOrdered probit results:\n")
summary(m_oprobit)

# ==============================================================================
# EXPORT RESULTS
# ==============================================================================

# Save main results table
modelsummary(
  list("Base" = m1, "With Controls" = m2),
  output = "/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/output/tables/main_results.tex",
  stars = TRUE,
  title = "Effects of Facility Framing and Economic Emphasis on Support"
)

# Save processed data
write_csv(df, "/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/data/processed/analysis_data.csv")

cat("\n==== ANALYSIS COMPLETE ====\n")
cat("Results saved to output/tables/\n")
cat("Plots saved to plots/\n")
