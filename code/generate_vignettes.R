# =============================================================================
# Generate Experimental Vignettes with OpenAI API
# POLS 681 Guest Lecture - UNM
# Charles Crabtree
# =============================================================================

# Load packages
library(tidyverse)
library(httr)
library(jsonlite)
library(glue)

# -----------------------------------------------------------------------------
# Setup: API Key
# -----------------------------------------------------------------------------

# Get API key from environment variable
# Set via: Sys.setenv(OPENAI_API_KEY = "your-key-here") or in .Renviron
api_key <- Sys.getenv("OPENAI_API_KEY")

if (api_key == "") {
  stop("OPENAI_API_KEY not set. Run: Sys.setenv(OPENAI_API_KEY = 'your-key')")
}

# -----------------------------------------------------------------------------
# Function: Call OpenAI API (matches statistical-horizons pattern)
# -----------------------------------------------------------------------------

call_openai <- function(prompt, 
                        model = "gpt-4o-mini",
                        temperature = 0.7,
                        max_tokens = 2000) {
  
  response <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    add_headers(
      Authorization = paste("Bearer", api_key),
      "Content-Type" = "application/json"
    ),
    body = toJSON(list(
      model = model,
      messages = list(
        list(role = "user", content = prompt)
      ),
      temperature = temperature,
      max_tokens = max_tokens
    ), auto_unbox = TRUE)
  )
  
  if (status_code(response) != 200) {
    stop(sprintf("API error %d: %s", 
                 status_code(response), 
                 content(response)$error$message))
  }
  
  result <- content(response)
  return(result$choices[[1]]$message$content)
}

# -----------------------------------------------------------------------------
# Load Prompt Template
# -----------------------------------------------------------------------------

# Read the 5-part prompt from file
prompt_file <- "prompts/economic_frame.txt"
if (file.exists(prompt_file)) {
  base_prompt <- read_file(prompt_file)
} else {
  # Inline fallback
  base_prompt <- "
ROLE: You are an expert experimental social scientist specializing in 
survey materials for political science research.

TASK: Generate 3 news vignettes about climate policy emphasizing 
economic benefits of green energy.

CONTEXT: Survey experiment testing economic vs. moral framing effects 
on climate policy support among US adults.

CONSTRAINTS:
- Length: 150-175 words each (strict)
- Reading level: 8th grade Flesch-Kincaid
- Tone: Neutral, journalistic (no advocacy language)
- No politician names or partisan cues
- Vary policies: solar, wind, EVs

FORMAT: Return ONLY a JSON array (no markdown, no explanation):
[{\"id\": 1, \"text\": \"...\", \"words\": N, \"policy\": \"solar\"},
 {\"id\": 2, \"text\": \"...\", \"words\": N, \"policy\": \"wind\"},
 {\"id\": 3, \"text\": \"...\", \"words\": N, \"policy\": \"EVs\"}]
"
}

cat("Using prompt:\n", substr(base_prompt, 1, 500), "...\n\n")

# -----------------------------------------------------------------------------
# Generate Vignettes
# -----------------------------------------------------------------------------

cat("Generating vignettes...\n")
raw_response <- call_openai(base_prompt, temperature = 0.7)

# Parse JSON response
# Handle potential markdown code blocks
clean_response <- raw_response |>
  str_remove("^```json\\n?") |>
  str_remove("\\n?```$") |>
  str_trim()

vignettes <- tryCatch(
 fromJSON(clean_response),
  error = function(e) {
    cat("JSON parse error. Raw response:\n", raw_response, "\n")
    stop("Failed to parse JSON response")
  }
)

# Convert to tibble
vignettes_df <- as_tibble(vignettes)
cat("Generated", nrow(vignettes_df), "vignettes\n\n")

# -----------------------------------------------------------------------------
# Quick Validation Check
# -----------------------------------------------------------------------------

# Actual word counts
vignettes_df <- vignettes_df |>
  mutate(
    actual_words = str_count(text, "\\w+"),
    word_diff = actual_words - words,
    in_range = actual_words >= 150 & actual_words <= 175
  )

# Summary
cat("Word count summary:\n")
print(vignettes_df |> select(id, policy, words, actual_words, in_range))

# Flag issues
issues <- vignettes_df |> filter(!in_range)
if (nrow(issues) > 0) {
  cat("\n⚠️  WARNING:", nrow(issues), "vignettes outside word range!\n")
} else {
  cat("\n✅ All vignettes within target word range (150-175)\n")
}

# -----------------------------------------------------------------------------
# Save Output
# -----------------------------------------------------------------------------

# Save as CSV
output_file <- "output/vignettes_economic_frame.csv"
write_csv(vignettes_df, output_file)
cat("\nSaved to:", output_file, "\n")

# Save as JSON (for validation script)
write_json(vignettes_df, "output/vignettes_economic_frame.json", pretty = TRUE)

# -----------------------------------------------------------------------------
# Preview
# -----------------------------------------------------------------------------

cat("\n--- Preview of first vignette ---\n")
cat(vignettes_df$text[1], "\n")

# -----------------------------------------------------------------------------
# Next Steps
# -----------------------------------------------------------------------------

cat("\n
=== NEXT STEPS ===
1. Run validation: source('code/validate_vignettes.R')
2. If issues found, iterate on prompt and regenerate
3. Generate moral frame vignettes (modify prompt)
4. Run full validation across both conditions
")
