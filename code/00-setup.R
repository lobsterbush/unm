# ============================================================================
# 00-setup.R: UNM Guest Lecture Setup Script
# ============================================================================
# Purpose: Install packages and configure API access for the demo
# Lecture: Experimental Design, Treatment Creation & AI Tools (POLS 681)
# Author: Charles Crabtree (Monash University, Korea University)
# Date: February 2026
# ============================================================================

# Get API key from environment variable
# Set via: Sys.setenv(OPENAI_API_KEY = "your-key-here") or in .Renviron
OPENAI_API_KEY <- Sys.getenv("OPENAI_API_KEY")

if (OPENAI_API_KEY == "") {
  stop("OPENAI_API_KEY not set. Run: Sys.setenv(OPENAI_API_KEY = 'your-key')")
}

# Install required packages (uncomment if needed)
# packages <- c("tidyverse", "httr", "jsonlite", "quanteda", "quanteda.textstats", "tidytext", "glue")
# install.packages(packages)

# Load required libraries
library(tidyverse)
library(httr)
library(jsonlite)
library(glue)

# ============================================================================
# Helper Functions
# ============================================================================

# Basic API call function
call_api <- function(prompt, model = "gpt-4o-mini", temperature = 0.7) {
  response <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    add_headers(
      Authorization = paste("Bearer", OPENAI_API_KEY),
      "Content-Type" = "application/json"
    ),
    body = toJSON(list(
      model = model,
      messages = list(list(role = "user", content = prompt)),
      temperature = temperature
    ), auto_unbox = TRUE)
  )
  
  if(status_code(response) != 200) {
    stop(sprintf("API error %d: %s", 
                 status_code(response), 
                 content(response)$error$message))
  }
  
  result <- content(response)
  return(result$choices[[1]]$message$content)
}

# Cost-tracking API call
api_cost_total <- 0

call_api_with_cost <- function(prompt, model = "gpt-4o-mini", temperature = 0.7) {
  response <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    add_headers(
      Authorization = paste("Bearer", OPENAI_API_KEY),
      "Content-Type" = "application/json"
    ),
    body = toJSON(list(
      model = model,
      messages = list(list(role = "user", content = prompt)),
      temperature = temperature
    ), auto_unbox = TRUE)
  )
  
  if(status_code(response) != 200) {
    stop(sprintf("API error %d: %s", 
                 status_code(response), 
                 content(response)$error$message))
  }
  
  result <- content(response)
  
  # Calculate cost (GPT-4o-mini pricing)
  usage <- result$usage
  cost <- (usage$prompt_tokens * 0.15 / 1000000) + 
          (usage$completion_tokens * 0.60 / 1000000)
  
  api_cost_total <<- api_cost_total + cost
  
  message(sprintf("Cost: $%.6f | Total: $%.4f | Tokens: %d", 
                  cost, api_cost_total, usage$total_tokens))
  
  return(result$choices[[1]]$message$content)
}

# ============================================================================
# Test API connection
# ============================================================================

cat("Testing API connection...\n")
test_result <- tryCatch({
  call_api("Say 'API connection successful!'")
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
  return(NULL)
})

if(!is.null(test_result)) {
  cat("\n✅ Setup complete!\n")
  cat("Response:", test_result, "\n")
} else {
  cat("\n❌ Setup failed. Check your API key.\n")
}

# ============================================================================
# Lecture information
# ============================================================================

cat("\n=== POLS 681 Guest Lecture: Experimental Design & AI Tools ===\n")
cat("Instructor: Charles Crabtree\n")
cat("Affiliation: Monash University & Korea University\n")
cat("Date: February 2026\n")
cat("\nAPI key loaded. Ready for demo!\n")
