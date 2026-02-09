# =============================================================================
# Validate Experimental Vignettes
# POLS 681 Guest Lecture - UNM
# Charles Crabtree
# =============================================================================

# Load packages
library(tidyverse)
library(jsonlite)
library(quanteda)
library(quanteda.textstats)
library(httr)
library(tidytext)

# -----------------------------------------------------------------------------
# Setup: API Key for LLM validation
# -----------------------------------------------------------------------------

api_key <- Sys.getenv("OPENAI_API_KEY")
use_llm_validation <- api_key != ""

if (!use_llm_validation) {
  message("OPENAI_API_KEY not set. Skipping LLM validation.")
  message("To enable: Sys.setenv(OPENAI_API_KEY = 'your-key')")
}

# -----------------------------------------------------------------------------
# Load Vignettes
# -----------------------------------------------------------------------------

vignettes_file <- "output/vignettes_economic_frame.json"
if (!file.exists(vignettes_file)) {
  stop("Run generate_vignettes.R first to create vignettes")
}

vignettes <- fromJSON(vignettes_file) |> as_tibble()
cat("Loaded", nrow(vignettes), "vignettes for validation\n\n")

# -----------------------------------------------------------------------------
# 1. Word Count Validation
# -----------------------------------------------------------------------------

cat("=== WORD COUNT VALIDATION ===\n")

vignettes <- vignettes |>
  mutate(actual_words = str_count(text, "\\w+"))

word_stats <- vignettes |>
  summarize(
    n = n(),
    mean_words = mean(actual_words),
    sd_words = sd(actual_words),
    min_words = min(actual_words),
    max_words = max(actual_words),
    range = max_words - min_words
  )

print(word_stats)

# Check if within target range
target_min <- 150
target_max <- 175

vignettes <- vignettes |>
  mutate(words_ok = actual_words >= target_min & actual_words <= target_max)

word_pass <- sum(vignettes$words_ok)
cat("\nWithin target range (", target_min, "-", target_max, "): ", 
    word_pass, "/", nrow(vignettes), "\n", sep = "")

if (word_pass < nrow(vignettes)) {
  cat("⚠️  FAIL: Some vignettes outside word range\n")
  print(vignettes |> filter(!words_ok) |> select(id, policy, actual_words))
} else {
  cat("✅ PASS: All vignettes within word range\n")
}

# -----------------------------------------------------------------------------
# 2. Reading Level Validation
# -----------------------------------------------------------------------------

cat("\n=== READING LEVEL VALIDATION ===\n")

# Create corpus
corp <- corpus(vignettes$text, docnames = paste0("v", vignettes$id))

# Calculate Flesch-Kincaid grade level
readability <- textstat_readability(corp, measure = c("Flesch.Kincaid", "Flesch"))

vignettes <- vignettes |>
  mutate(
    fk_grade = readability$Flesch.Kincaid,
    flesch_ease = readability$Flesch
  )

reading_stats <- vignettes |>
  summarize(
    mean_grade = mean(fk_grade),
    sd_grade = sd(fk_grade),
    min_grade = min(fk_grade),
    max_grade = max(fk_grade)
  )

print(reading_stats)

# Target: 8th grade (allow 6-10 range)
target_grade_min <- 6
target_grade_max <- 10

vignettes <- vignettes |>
  mutate(reading_ok = fk_grade >= target_grade_min & fk_grade <= target_grade_max)

reading_pass <- sum(vignettes$reading_ok)
cat("\nWithin grade range (", target_grade_min, "-", target_grade_max, "): ", 
    reading_pass, "/", nrow(vignettes), "\n", sep = "")

if (reading_pass < nrow(vignettes)) {
  cat("⚠️  FAIL: Some vignettes outside reading level range\n")
  print(vignettes |> filter(!reading_ok) |> select(id, policy, fk_grade))
} else {
  cat("✅ PASS: All vignettes within reading level range\n")
}

# -----------------------------------------------------------------------------
# 3. Sentiment Analysis
# -----------------------------------------------------------------------------

cat("\n=== SENTIMENT VALIDATION ===\n")

# Tokenize and get sentiment
sentiment_scores <- vignettes |>
  select(id, text) |>
  unnest_tokens(word, text) |>
  inner_join(get_sentiments("afinn"), by = "word") |>
  group_by(id) |>
  summarize(
    sentiment_sum = sum(value),
    sentiment_words = n(),
    sentiment_mean = mean(value)
  )

vignettes <- vignettes |>
  left_join(sentiment_scores, by = "id") |>
  mutate(across(starts_with("sentiment"), ~replace_na(., 0)))

sentiment_stats <- vignettes |>
  summarize(
    mean_sentiment = mean(sentiment_sum),
    sd_sentiment = sd(sentiment_sum),
    range_sentiment = max(sentiment_sum) - min(sentiment_sum)
  )

print(sentiment_stats)

# Check for outliers (sentiment should be roughly balanced)
sentiment_threshold <- 2 * sd(vignettes$sentiment_sum, na.rm = TRUE)
vignettes <- vignettes |>
  mutate(sentiment_ok = abs(sentiment_sum - mean(sentiment_sum)) < sentiment_threshold)

sentiment_pass <- sum(vignettes$sentiment_ok)
cat("\nNo sentiment outliers: ", sentiment_pass, "/", nrow(vignettes), "\n", sep = "")

if (sentiment_pass < nrow(vignettes)) {
  cat("⚠️  WARNING: Sentiment outliers detected\n")
  print(vignettes |> filter(!sentiment_ok) |> select(id, policy, sentiment_sum))
} else {
  cat("✅ PASS: No sentiment outliers\n")
}

# -----------------------------------------------------------------------------
# 4. LLM Substantive Validation
# -----------------------------------------------------------------------------

cat("\n=== LLM SUBSTANTIVE VALIDATION ===\n")

if (use_llm_validation) {
  
  # API call function
  call_openai <- function(prompt, model = "gpt-4o-mini", temperature = 0) {
    response <- POST(
      url = "https://api.openai.com/v1/chat/completions",
      add_headers(
        Authorization = paste("Bearer", api_key),
        "Content-Type" = "application/json"
      ),
      body = toJSON(list(
        model = model,
        messages = list(list(role = "user", content = prompt)),
        temperature = temperature
      ), auto_unbox = TRUE)
    )
    
    if (status_code(response) != 200) {
      warning(sprintf("API error %d", status_code(response)))
      return(NULL)
    }
    
    content(response)$choices[[1]]$message$content
  }
  
  # Validation prompt template
  validation_prompt <- '
You are validating a survey vignette for an experiment on climate policy framing.

VIGNETTE:
"""
{text}
"""

INTENDED FRAME: {frame} (economic benefits of green energy)
INTENDED POLICY: {policy}

Rate each dimension 1-7 (1=not at all, 7=extremely):

1. ECONOMIC_EMPHASIS: Does the vignette emphasize economic benefits (jobs, savings, growth)?
2. MORAL_EMPHASIS: Does the vignette emphasize moral/ethical considerations (responsibility, stewardship)?
3. POLICY_MATCH: Does the vignette focus on the intended policy topic ({policy})?
4. NEUTRALITY: Is the tone neutral and journalistic (not advocacy)?
5. PARTISAN_CUES: Does the vignette contain partisan cues or politician names? (1=many, 7=none)

Return ONLY valid JSON (no markdown):
{{"economic_emphasis": N, "moral_emphasis": N, "policy_match": N, "neutrality": N, "partisan_cues": N, "flags": "any concerns"}}
'
  
  cat("Validating", nrow(vignettes), "vignettes with LLM...\n")
  
  # Validate each vignette
  llm_results <- map_dfr(1:nrow(vignettes), function(i) {
    v <- vignettes[i, ]
    
    prompt <- glue::glue(
      validation_prompt,
      text = v$text,
      frame = "economic",
      policy = v$policy
    )
    
    response <- call_openai(prompt)
    
    if (is.null(response)) {
      return(tibble(id = v$id, llm_error = TRUE))
    }
    
    # Parse JSON
    clean_response <- response |>
      str_remove("^```json\\n?") |>
      str_remove("\\n?```$") |>
      str_trim()
    
    result <- tryCatch(
      fromJSON(clean_response),
      error = function(e) list(llm_error = TRUE)
    )
    
    tibble(
      id = v$id,
      economic_emphasis = result$economic_emphasis %||% NA,
      moral_emphasis = result$moral_emphasis %||% NA,
      policy_match = result$policy_match %||% NA,
      neutrality = result$neutrality %||% NA,
      partisan_cues = result$partisan_cues %||% NA,
      llm_flags = result$flags %||% NA
    )
  })
  
  # Merge with vignettes
  vignettes <- vignettes |> left_join(llm_results, by = "id")
  
  # Display results
  cat("\nLLM Ratings (1-7 scale):\n")
  print(vignettes |> 
          select(id, policy, economic_emphasis, moral_emphasis, 
                 policy_match, neutrality, partisan_cues))
  
  # Check for issues
  # Economic frame should have high economic emphasis, low moral emphasis
  vignettes <- vignettes |>
    mutate(
      llm_ok = economic_emphasis >= 5 & moral_emphasis <= 4 & 
               policy_match >= 5 & neutrality >= 5 & partisan_cues >= 5
    )
  
  llm_pass <- sum(vignettes$llm_ok, na.rm = TRUE)
  cat("\nSubstantive validation pass:", llm_pass, "/", nrow(vignettes), "\n")
  
  if (llm_pass < nrow(vignettes)) {
    cat("⚠️  WARNING: Some vignettes may have substantive issues\n")
    print(vignettes |> filter(!llm_ok | is.na(llm_ok)) |> 
            select(id, policy, economic_emphasis, moral_emphasis, llm_flags))
  } else {
    cat("✅ PASS: All vignettes pass substantive validation\n")
  }
  
  # Flag any concerns
  if (any(!is.na(vignettes$llm_flags) & vignettes$llm_flags != "none")) {
    cat("\nLLM flagged concerns:\n")
    print(vignettes |> filter(!is.na(llm_flags) & llm_flags != "none") |>
            select(id, policy, llm_flags))
  }
  
} else {
  cat("Skipped (no API key). Set OPENAI_API_KEY to enable.\n")
  vignettes$llm_ok <- NA
  llm_pass <- NA
}

# -----------------------------------------------------------------------------
# 5. Summary Report
# -----------------------------------------------------------------------------

cat("\n=== VALIDATION SUMMARY ===\n")

# Build check summary based on available validations
if (use_llm_validation) {
  all_checks <- vignettes |>
    summarize(
      words_pass = sum(words_ok),
      reading_pass = sum(reading_ok),
      sentiment_pass = sum(sentiment_ok),
      llm_pass = sum(llm_ok, na.rm = TRUE),
      all_pass = sum(words_ok & reading_ok & sentiment_ok & llm_ok, na.rm = TRUE),
      total = n()
    )
} else {
  all_checks <- vignettes |>
    summarize(
      words_pass = sum(words_ok),
      reading_pass = sum(reading_ok),
      sentiment_pass = sum(sentiment_ok),
      all_pass = sum(words_ok & reading_ok & sentiment_ok),
      total = n()
    )
}

print(all_checks)

if (all_checks$all_pass == all_checks$total) {
  cat("\n✅✅✅ ALL VALIDATION CHECKS PASSED ✅✅✅\n")
  cat("Ready for pilot testing with manipulation checks\n")
} else {
  cat("\n⚠️  SOME CHECKS FAILED - Review and iterate\n")
  cat("Problem vignettes:\n")
  if (use_llm_validation) {
    print(vignettes |> filter(!(words_ok & reading_ok & sentiment_ok & llm_ok)) |> 
            select(id, policy, actual_words, fk_grade, sentiment_sum, llm_ok))
  } else {
    print(vignettes |> filter(!(words_ok & reading_ok & sentiment_ok)) |> 
            select(id, policy, actual_words, fk_grade, sentiment_sum))
  }
}

# -----------------------------------------------------------------------------
# 6. Save Validation Report
# -----------------------------------------------------------------------------

# Save full results
write_csv(vignettes, "output/vignettes_validated.csv")

# Create summary report
report <- list(
  timestamp = Sys.time(),
  n_vignettes = nrow(vignettes),
  word_count = list(
    target = paste(target_min, "-", target_max),
    mean = word_stats$mean_words,
    sd = word_stats$sd_words,
    pass = word_pass
  ),
  reading_level = list(
    target_grade = paste(target_grade_min, "-", target_grade_max),
    mean_grade = reading_stats$mean_grade,
    sd_grade = reading_stats$sd_grade,
    pass = reading_pass
  ),
  sentiment = list(
    mean = sentiment_stats$mean_sentiment,
    sd = sentiment_stats$sd_sentiment,
    pass = sentiment_pass
  ),
  llm_validation = list(
    enabled = use_llm_validation,
    pass = if (use_llm_validation) llm_pass else NA
  ),
  all_pass = all_checks$all_pass == all_checks$total
)

write_json(report, "output/validation_report.json", pretty = TRUE)
cat("\nValidation report saved to: output/validation_report.json\n")

# -----------------------------------------------------------------------------
# 7. Per-Vignette Details
# -----------------------------------------------------------------------------

cat("\n=== PER-VIGNETTE DETAILS ===\n")
if (use_llm_validation) {
  print(vignettes |> 
          select(id, policy, actual_words, fk_grade, sentiment_sum,
                 economic_emphasis, moral_emphasis, policy_match,
                 words_ok, reading_ok, sentiment_ok, llm_ok))
} else {
  print(vignettes |> 
          select(id, policy, actual_words, fk_grade, sentiment_sum, 
                 words_ok, reading_ok, sentiment_ok))
}
