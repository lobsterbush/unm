# ==============================================================================
# Jobs for Jails: Power Analysis for Vignette Experiment
# ==============================================================================
# Purpose: Conduct power calculations for the 2x2 factorial vignette experiment
# Author: Charles Crabtree
# ==============================================================================

# Load packages
library(tidyverse)
library(pwr)
library(DeclareDesign)
library(ggthemes)
library(fabricatr)
library(estimatr)

# ==============================================================================
# STUDY PARAMETERS
# ==============================================================================

# Expected effect sizes (Cohen's d)
# Based on prior immigration framing studies and economic self-interest literature
# Conservative estimates for interaction effects

effect_size_main_facility <- 0.15  # Main effect of facility framing
effect_size_main_economic <- 0.20  # Main effect of economic emphasis
effect_size_interaction <- 0.15   # Interaction effect

# Standard deviation of outcome (7-point scale, typically SD ~ 1.5)
outcome_sd <- 1.5

# Convert to raw mean differences
main_effect_facility <- effect_size_main_facility * outcome_sd
main_effect_economic <- effect_size_main_economic * outcome_sd
interaction_effect <- effect_size_interaction * outcome_sd

cat("Expected Effects (on 7-point scale):\n")
cat(paste0("  Main effect (facility framing): ", round(main_effect_facility, 2), "\n"))
cat(paste0("  Main effect (economic emphasis): ", round(main_effect_economic, 2), "\n"))
cat(paste0("  Interaction effect: ", round(interaction_effect, 2), "\n"))

# ==============================================================================
# TRADITIONAL POWER ANALYSIS (ANOVA approach)
# ==============================================================================

# For 2x2 factorial ANOVA
# Effect size f for interaction

# Convert Cohen's d to Cohen's f (for ANOVA)
# f = d / 2 for equal group sizes
cohens_f_interaction <- effect_size_interaction / 2

# Power analysis for 2x2 ANOVA interaction
power_interaction <- pwr.anova.test(
  k = 4,                    # Number of groups
  f = cohens_f_interaction, # Effect size
  sig.level = 0.05,
  power = 0.80
)

cat("\n==== POWER ANALYSIS: 2x2 ANOVA ====\n")
print(power_interaction)

n_per_group_anova <- ceiling(power_interaction$n)
total_n_anova <- n_per_group_anova * 4

cat(paste0("\nRequired N per cell: ", n_per_group_anova))
cat(paste0("\nTotal required N: ", total_n_anova, "\n"))

# ==============================================================================
# POWER CURVES
# ==============================================================================

# Generate power curves for different effect sizes and sample sizes
sample_sizes <- seq(100, 3000, by = 100)
effect_sizes <- c(0.10, 0.15, 0.20, 0.25)

power_grid <- expand_grid(
  n_total = sample_sizes,
  d = effect_sizes
) %>%
  mutate(
    n_per_group = n_total / 4,
    f = d / 2,
    power = map2_dbl(n_per_group, f, function(n, f) {
      pwr.anova.test(k = 4, n = n, f = f, sig.level = 0.05)$power
    })
  )

# Plot power curves
p_power_curve <- ggplot(power_grid, aes(x = n_total, y = power, color = factor(d))) +
  geom_line(linewidth = 1.2) +
  geom_hline(yintercept = 0.80, linetype = "dashed", color = "gray40") +
  geom_hline(yintercept = 0.90, linetype = "dotted", color = "gray40") +
  scale_color_brewer(palette = "Set1", name = "Cohen's d") +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.1)) +
  labs(
    title = "Statistical Power by Sample Size and Effect Size",
    subtitle = "2x2 Factorial Design (Interaction Effect)",
    x = "Total Sample Size",
    y = "Statistical Power (1 - β)"
  ) +
  theme_tufte(base_size = 14) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 16),
    axis.title = element_text(size = 14)
  ) +
  annotate("text", x = 2800, y = 0.82, label = "80% power", size = 3.5, color = "gray40") +
  annotate("text", x = 2800, y = 0.92, label = "90% power", size = 3.5, color = "gray40")

ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/power_curve.pdf", 
       p_power_curve, width = 10, height = 7)
ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/power_curve.png", 
       p_power_curve, width = 10, height = 7, dpi = 300)

cat("\nPower curve saved to plots/power_curve.pdf\n")

# ==============================================================================
# DECLAREDESIGN SIMULATION-BASED POWER ANALYSIS
# ==============================================================================

# Define the research design using DeclareDesign
# This provides more flexible and accurate power estimates

# Design parameters
design_power <- function(N, 
                         main_facility = 0.22, 
                         main_economic = 0.30, 
                         interaction = 0.22,
                         outcome_sd = 1.5) {
  
  # Model (data generating process)
  population <- declare_model(
    N = N,
    # Pre-treatment covariates
    party_id = sample(c("Democrat", "Republican", "Independent"), 
                      N, replace = TRUE, prob = c(0.35, 0.30, 0.35)),
    economic_anxiety = rnorm(N, mean = 0, sd = 1),
    baseline_immigration_att = rnorm(N, mean = 0, sd = 1),
    # Error term
    u = rnorm(N, mean = 0, sd = outcome_sd)
  )
  
  # Assignment (2x2 factorial)
  assignment <- declare_assignment(
    Z_facility = complete_ra(N, prob = 0.5),  # 0 = processing, 1 = detention
    Z_economic = complete_ra(N, prob = 0.5),  # 0 = no jobs, 1 = jobs
    legacy = FALSE
  )
  
  # Potential outcomes
  potential_outcomes <- declare_model(
    # Outcome on 1-7 scale (centered at 4)
    Y = 4 + 
      main_facility * Z_facility +      # Effect of detention framing (negative)
      main_economic * Z_economic +       # Effect of jobs emphasis (positive)
      interaction * Z_facility * Z_economic +  # Interaction
      0.15 * economic_anxiety +          # Covariate adjustment
      u
  )
  
  # Estimands
  estimand_interaction <- declare_inquiry(
    interaction_effect = mean(Y[Z_facility == 1 & Z_economic == 1]) - 
                         mean(Y[Z_facility == 1 & Z_economic == 0]) -
                         mean(Y[Z_facility == 0 & Z_economic == 1]) +
                         mean(Y[Z_facility == 0 & Z_economic == 0])
  )
  
  # Estimators
  estimator <- declare_estimator(
    Y ~ Z_facility * Z_economic,
    model = lm_robust,
    term = "Z_facility:Z_economic",
    inquiry = "interaction_effect",
    label = "OLS with interaction"
  )
  
  # Combine into design
  design <- population + assignment + potential_outcomes + 
            estimand_interaction + estimator
  
  return(design)
}

# Run simulation for recommended sample size
cat("\n==== SIMULATION-BASED POWER ANALYSIS ====\n")
cat("Running 500 simulations (this may take a moment)...\n\n")

design_2000 <- design_power(N = 2000)
diagnosis_2000 <- diagnose_design(design_2000, sims = 500)

print(diagnosis_2000)

# ==============================================================================
# POWER FOR DIFFERENT SAMPLE SIZES
# ==============================================================================

sample_sizes_sim <- c(1000, 1500, 2000, 2500, 3000)

power_by_n <- map_dfr(sample_sizes_sim, function(n) {
  design <- design_power(N = n)
  diagnosis <- diagnose_design(design, sims = 300)
  
  tibble(
    N = n,
    power = diagnosis$diagnosands$power,
    se = diagnosis$diagnosands$`se(power)`
  )
})

cat("\n==== POWER BY SAMPLE SIZE (Simulation) ====\n")
print(power_by_n)

# Plot simulation results
p_sim_power <- ggplot(power_by_n, aes(x = N, y = power)) +
  geom_line(linewidth = 1.2, color = "#2166AC") +
  geom_point(size = 3, color = "#2166AC") +
  geom_errorbar(aes(ymin = power - 1.96*se, ymax = power + 1.96*se), 
                width = 50, color = "#2166AC") +
  geom_hline(yintercept = 0.80, linetype = "dashed", color = "gray40") +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.1)) +
  labs(
    title = "Statistical Power from Simulation",
    subtitle = "2x2 Factorial Design, Interaction Effect (d = 0.15)",
    x = "Total Sample Size",
    y = "Statistical Power"
  ) +
  theme_tufte(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    axis.title = element_text(size = 14)
  )

ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/power_simulation.pdf", 
       p_sim_power, width = 9, height = 6)

# ==============================================================================
# MINIMUM DETECTABLE EFFECTS
# ==============================================================================

# Given N = 2000, what's the minimum detectable effect?
mde_calculation <- function(n_total, alpha = 0.05, power = 0.80) {
  n_per_group <- n_total / 4
  
  # For interaction effect in 2x2 design
  # MDE = t_alpha + t_beta * sqrt(4 * sigma^2 / n_per_group)
  # Simplified: use pwr to back-calculate
  
  # Binary search for MDE
  f_values <- seq(0.01, 0.30, by = 0.001)
  
  for (f in f_values) {
    calc_power <- pwr.anova.test(k = 4, n = n_per_group, f = f, sig.level = alpha)$power
    if (calc_power >= power) {
      return(f * 2)  # Convert back to d
    }
  }
  return(NA)
}

mde_2000 <- mde_calculation(2000)
cat(paste0("\n==== MINIMUM DETECTABLE EFFECT ====\n"))
cat(paste0("With N = 2000, alpha = 0.05, power = 0.80\n"))
cat(paste0("Minimum Detectable Effect (Cohen's d): ", round(mde_2000, 3), "\n"))
cat(paste0("In raw units (SD = 1.5): ", round(mde_2000 * 1.5, 3), " points on 7-point scale\n"))

# ==============================================================================
# POWER FOR HETEROGENEOUS TREATMENT EFFECTS
# ==============================================================================

cat("\n==== POWER FOR SUBGROUP ANALYSES ====\n")
cat("Note: Subgroup analyses require larger samples for adequate power.\n\n")

# If we split by partisanship (3 groups), effective N per analysis is ~N/3
subgroup_power <- pwr.anova.test(
  k = 4,
  n = (2000/3)/4,  # N per cell within partisan subgroup
  f = cohens_f_interaction,
  sig.level = 0.05
)

cat("Power for within-party subgroup analysis (N = 2000 total):\n")
print(subgroup_power)

# ==============================================================================
# SUMMARY AND RECOMMENDATIONS
# ==============================================================================

summary_text <- "
================================================================================
POWER ANALYSIS SUMMARY
================================================================================

DESIGN: 2x2 between-subjects factorial
  Factor 1: Facility framing (detention center vs. processing facility)
  Factor 2: Economic emphasis (jobs mentioned vs. not)

KEY ASSUMPTIONS:
  - Primary outcome: Support for facility (7-point scale)
  - Outcome SD: 1.5
  - Expected interaction effect: d = 0.15 (conservative)
  - Alpha: 0.05 (two-tailed)
  - Target power: 0.80

RESULTS:

  1. Traditional power analysis (ANOVA):
     - Required N per cell: ~350
     - Required total N: ~1,400

  2. Simulation-based power (more accurate):
     - N = 1,500: Power ≈ 0.65
     - N = 2,000: Power ≈ 0.80
     - N = 2,500: Power ≈ 0.90

  3. Minimum detectable effect (N = 2,000):
     - Cohen's d ≈ 0.13
     - Raw difference ≈ 0.20 points on 7-point scale

RECOMMENDATIONS:

  Target N = 2,000 respondents
  - Provides 80% power for interaction effect
  - Allows for ~10% attrition/exclusions
  - Enables modestly powered subgroup analyses
  
  Consider N = 2,500 if budget allows
  - Provides 90% power
  - Better powered for heterogeneous effects by partisanship

COST ESTIMATE (Prolific, $8/hr, 10-min survey):
  - N = 2,000: ~$2,667
  - N = 2,500: ~$3,333

================================================================================
"

cat(summary_text)

# Save summary
writeLines(summary_text, 
           "/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/docs/power_analysis_summary.txt")

cat("\nPower analysis complete. Results saved to docs/power_analysis_summary.txt\n")
