# ==============================================================================
# Jobs for Jails: Conjoint Experiment Analysis
# ==============================================================================
# Purpose: Analyze conjoint data on ICE enforcement preferences
# Author: Charles Crabtree
# ==============================================================================

# Load packages
library(tidyverse)
library(cregg)          # Conjoint analysis
library(cjoint)         # Alternative conjoint package
library(estimatr)
library(ggthemes)
library(ggplot2)

# ==============================================================================
# CONJOINT DESIGN
# ==============================================================================

# Attributes and levels for ICE enforcement conjoint
conjoint_design <- list(
  
  target_type = c(
    "Undocumented workers at a local business",
    "Individuals with prior criminal convictions",
    "Families in a residential neighborhood",
    "Individuals at a courthouse"
  ),
  
  economic_impact = c(
    "Will create 50 local jobs through increased enforcement",
    "Will have no effect on local employment",
    "May result in the loss of 50 local jobs"
  ),
  
  enforcement_method = c(
    "Workplace inspection with advance notice",
    "Unannounced workplace raid",
    "Home visits by ICE agents",
    "Arrests at public locations"
  ),
  
  federal_funding = c(
    "County will receive $5 million in federal funding",
    "County will receive $500,000 in federal funding",
    "No additional federal funding"
  ),
  
  local_cooperation = c(
    "Local police will assist ICE",
    "Local police will not assist but won't interfere",
    "Local police prohibited from assisting ICE"
  )
)

# Print design
cat("==== CONJOINT DESIGN ====\n\n")
for (attr in names(conjoint_design)) {
  cat(paste0(attr, ":\n"))
  for (level in conjoint_design[[attr]]) {
    cat(paste0("  - ", level, "\n"))
  }
  cat("\n")
}

# Total profiles
n_profiles <- prod(sapply(conjoint_design, length))
cat(paste0("Total possible profiles: ", n_profiles, "\n"))

# ==============================================================================
# SIMULATE CONJOINT DATA (for development)
# ==============================================================================

set.seed(123)
n_respondents <- 2000
n_tasks <- 5  # Tasks per respondent
n_profiles_per_task <- 2

# Generate respondent-level data
respondents <- tibble(
  respondent_id = 1:n_respondents,
  party_id = sample(c("Democrat", "Republican", "Independent"),
                    n_respondents, replace = TRUE, prob = c(0.35, 0.30, 0.35)),
  economic_anxiety = rnorm(n_respondents, 0, 1),
  immigration_attitude = rnorm(n_respondents, 0, 1),
  age = round(rnorm(n_respondents, 45, 15)),
  female = rbinom(n_respondents, 1, 0.52)
)

# Generate conjoint tasks
conjoint_data <- expand_grid(
  respondent_id = 1:n_respondents,
  task = 1:n_tasks,
  profile = 1:n_profiles_per_task
) %>%
  mutate(
    # Random attribute assignment
    target_type = sample(conjoint_design$target_type, n(), replace = TRUE),
    economic_impact = sample(conjoint_design$economic_impact, n(), replace = TRUE),
    enforcement_method = sample(conjoint_design$enforcement_method, n(), replace = TRUE),
    federal_funding = sample(conjoint_design$federal_funding, n(), replace = TRUE),
    local_cooperation = sample(conjoint_design$local_cooperation, n(), replace = TRUE)
  ) %>%
  # Join respondent characteristics
  left_join(respondents, by = "respondent_id") %>%
  # Generate choices based on attribute utilities
  group_by(respondent_id, task) %>%
  mutate(
    # Utility function
    utility = 
      # Target type effects
      case_when(
        target_type == "Individuals with prior criminal convictions" ~ 0.8,
        target_type == "Undocumented workers at a local business" ~ 0.2,
        target_type == "Families in a residential neighborhood" ~ -0.5,
        target_type == "Individuals at a courthouse" ~ -0.3
      ) +
      # Economic impact effects
      case_when(
        economic_impact == "Will create 50 local jobs through increased enforcement" ~ 0.5,
        economic_impact == "Will have no effect on local employment" ~ 0,
        economic_impact == "May result in the loss of 50 local jobs" ~ -0.4
      ) +
      # Enforcement method effects
      case_when(
        enforcement_method == "Workplace inspection with advance notice" ~ 0.3,
        enforcement_method == "Unannounced workplace raid" ~ -0.2,
        enforcement_method == "Home visits by ICE agents" ~ -0.4,
        enforcement_method == "Arrests at public locations" ~ -0.5
      ) +
      # Federal funding effects
      case_when(
        federal_funding == "County will receive $5 million in federal funding" ~ 0.4,
        federal_funding == "County will receive $500,000 in federal funding" ~ 0.15,
        federal_funding == "No additional federal funding" ~ 0
      ) +
      # Local cooperation effects
      case_when(
        local_cooperation == "Local police will assist ICE" ~ 0.1,
        local_cooperation == "Local police will not assist but won't interfere" ~ 0,
        local_cooperation == "Local police prohibited from assisting ICE" ~ -0.1
      ) +
      # Party heterogeneity
      0.3 * (party_id == "Republican") +
      -0.2 * (party_id == "Democrat") +
      0.1 * economic_anxiety +
      # Error
      rnorm(n(), 0, 1),
    # Choice probability (softmax within task)
    prob = exp(utility) / sum(exp(utility)),
    chosen = sample(c(0, 1), n(), replace = FALSE, prob = prob)
  ) %>%
  ungroup() %>%
  # Convert to factors for cregg
  mutate(across(c(target_type, economic_impact, enforcement_method, 
                  federal_funding, local_cooperation), as.factor))

# ==============================================================================
# MAIN ANALYSIS: AMCEs (using cregg)
# ==============================================================================

cat("\n==== AVERAGE MARGINAL COMPONENT EFFECTS ====\n")

# Set reference levels
conjoint_data <- conjoint_data %>%
  mutate(
    target_type = relevel(target_type, ref = "Undocumented workers at a local business"),
    economic_impact = relevel(economic_impact, ref = "Will have no effect on local employment"),
    enforcement_method = relevel(enforcement_method, ref = "Workplace inspection with advance notice"),
    federal_funding = relevel(federal_funding, ref = "No additional federal funding"),
    local_cooperation = relevel(local_cooperation, ref = "Local police will not assist but won't interfere")
  )

# Estimate AMCEs with cluster-robust SEs (clustered by respondent)
amce_results <- cj(
  data = conjoint_data,
  formula = chosen ~ target_type + economic_impact + enforcement_method + 
                     federal_funding + local_cooperation,
  id = ~ respondent_id,
  estimate = "amce"
)

print(amce_results)

# Plot AMCEs
p_amce <- plot(amce_results) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  labs(
    title = "Average Marginal Component Effects",
    subtitle = "Effect on probability of supporting enforcement action",
    x = "Change in Pr(Support)",
    y = ""
  ) +
  theme_tufte(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    strip.text = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 11)
  )

ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/conjoint_amce.pdf",
       p_amce, width = 10, height = 10)
ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/conjoint_amce.png",
       p_amce, width = 10, height = 10, dpi = 300)

# ==============================================================================
# MARGINAL MEANS
# ==============================================================================

cat("\n==== MARGINAL MEANS ====\n")

mm_results <- cj(
  data = conjoint_data,
  formula = chosen ~ target_type + economic_impact + enforcement_method + 
                     federal_funding + local_cooperation,
  id = ~ respondent_id,
  estimate = "mm"
)

print(mm_results)

# Plot marginal means
p_mm <- plot(mm_results) +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "gray50") +
  labs(
    title = "Marginal Means",
    subtitle = "Probability of supporting enforcement action",
    x = "Pr(Support)",
    y = ""
  ) +
  theme_tufte(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    strip.text = element_text(face = "bold", size = 12)
  )

ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/conjoint_mm.pdf",
       p_mm, width = 10, height = 10)

# ==============================================================================
# HETEROGENEOUS EFFECTS BY PARTY
# ==============================================================================

cat("\n==== CONDITIONAL AMCEs BY PARTY ====\n")

# AMCEs by party
amce_by_party <- cj(
  data = conjoint_data,
  formula = chosen ~ target_type + economic_impact + enforcement_method + 
                     federal_funding + local_cooperation,
  id = ~ respondent_id,
  estimate = "amce",
  by = ~ party_id
)

# Plot
p_amce_party <- plot(amce_by_party, group = "party_id") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_manual(
    values = c("Democrat" = "#2166AC", "Independent" = "#4DAF4A", "Republican" = "#B2182B"),
    name = "Party"
  ) +
  labs(
    title = "Conditional AMCEs by Party Identification",
    x = "Change in Pr(Support)",
    y = ""
  ) +
  theme_tufte(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    strip.text = element_text(face = "bold", size = 11),
    legend.position = "bottom"
  )

ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/conjoint_amce_party.pdf",
       p_amce_party, width = 12, height = 12)

# ==============================================================================
# INTERACTION EFFECTS
# ==============================================================================

cat("\n==== INTERACTION: ECONOMIC IMPACT × TARGET TYPE ====\n")

# Interaction between economic impact and target type
amce_interaction <- cj(
  data = conjoint_data,
  formula = chosen ~ target_type + economic_impact + enforcement_method + 
                     federal_funding + local_cooperation,
  id = ~ respondent_id,
  estimate = "amce",
  by = ~ economic_impact
)

# Focus on target type effects by economic framing
interaction_plot_data <- amce_interaction %>%
  filter(feature == "target_type")

p_interaction <- ggplot(interaction_plot_data, 
                        aes(x = level, y = estimate, color = economic_impact)) +
  geom_point(position = position_dodge(0.5), size = 3) +
  geom_errorbar(aes(ymin = lower, ymax = upper),
                position = position_dodge(0.5), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_brewer(palette = "Set1", name = "Economic Frame") +
  labs(
    title = "Target Type Effects by Economic Framing",
    x = "Target Type",
    y = "AMCE"
  ) +
  coord_flip() +
  theme_tufte(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "bottom"
  )

ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/conjoint_interaction.pdf",
       p_interaction, width = 10, height = 8)

# ==============================================================================
# DIAGNOSTICS
# ==============================================================================

cat("\n==== CONJOINT DIAGNOSTICS ====\n")

# Check for carryover effects
carryover_test <- cj(
  data = conjoint_data %>% mutate(task_num = as.factor(task)),
  formula = chosen ~ target_type + economic_impact + enforcement_method,
  id = ~ respondent_id,
  estimate = "amce",
  by = ~ task_num
)

cat("Carryover effects (AMCEs by task number):\n")
carryover_test %>%
  filter(feature == "economic_impact") %>%
  select(BY, level, estimate, std.error) %>%
  print()

# Check for profile order effects
conjoint_data <- conjoint_data %>%
  mutate(profile_position = as.factor(profile))

profile_order_test <- cj(
  data = conjoint_data,
  formula = chosen ~ target_type + economic_impact,
  id = ~ respondent_id,
  estimate = "amce",
  by = ~ profile_position
)

cat("\nProfile order effects:\n")
profile_order_test %>%
  filter(feature == "economic_impact") %>%
  print()

# ==============================================================================
# ATTRIBUTE IMPORTANCE
# ==============================================================================

cat("\n==== ATTRIBUTE IMPORTANCE ====\n")

# Calculate range of AMCEs for each attribute
importance <- amce_results %>%
  group_by(feature) %>%
  summarise(
    max_amce = max(estimate),
    min_amce = min(estimate),
    range = max_amce - min_amce,
    .groups = "drop"
  ) %>%
  arrange(desc(range))

print(importance)

# Plot importance
p_importance <- ggplot(importance, aes(x = reorder(feature, range), y = range)) +
  geom_col(fill = "#2166AC", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "Attribute Importance",
    subtitle = "Range of AMCEs within each attribute",
    x = "",
    y = "AMCE Range"
  ) +
  theme_tufte(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16)
  )

ggsave("/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/plots/attribute_importance.pdf",
       p_importance, width = 8, height = 6)

# ==============================================================================
# EXPORT RESULTS
# ==============================================================================

# Save AMCE results
write_csv(amce_results, 
          "/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/output/tables/conjoint_amce.csv")

# Save conjoint data
write_csv(conjoint_data,
          "/Users/f00421k/Documents/GitHub/unm/jobs-for-jails/data/processed/conjoint_data.csv")

cat("\n==== CONJOINT ANALYSIS COMPLETE ====\n")
