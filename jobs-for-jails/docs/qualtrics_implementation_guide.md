# Qualtrics Implementation Guide: Jobs for Jails Experiment

This guide provides step-by-step instructions for implementing the conjoint experiment and Twitter/X simulation in Qualtrics.

## Table of Contents

1. [Survey Structure Overview](#survey-structure-overview)
2. [Setting Up Embedded Data](#setting-up-embedded-data)
3. [Implementing the Vignette Experiment](#implementing-the-vignette-experiment)
4. [Implementing the Conjoint Experiment](#implementing-the-conjoint-experiment)
5. [Implementing the Twitter/X Simulation](#implementing-the-twitterx-simulation)
6. [Data Export and Reshaping](#data-export-and-reshaping)
7. [Troubleshooting](#troubleshooting)

---

## Survey Structure Overview

The survey should follow this block structure:

```
1. Consent Block
2. Demographics & Pre-treatment Measures
3. Vignette Experiment Block (2x2 factorial)
4. Vignette Outcome Measures
5. Conjoint Experiment Block (5 tasks)
6. Twitter/X Simulation Block
7. Post-treatment Measures
8. Debrief Block
```

---

## Setting Up Embedded Data

### Step 1: Access Survey Flow

1. Open your survey in Qualtrics
2. Click **Survey Flow** in the left sidebar

### Step 2: Add Embedded Data Element

1. Click **Add a New Element Here** at the very top (before any blocks)
2. Select **Embedded Data**
3. Add the following fields:

**For Vignette Experiment:**
```
vignette_condition       (leave blank - will be set by randomizer)
facility_frame           (leave blank)
economic_emphasis        (leave blank)
```

**For Conjoint Experiment:**
```
conjoint_task            Set value to: 1

task1_A_target           (leave blank)
task1_A_economic         (leave blank)
task1_A_method           (leave blank)
task1_A_funding          (leave blank)
task1_A_cooperation      (leave blank)
task1_B_target           (leave blank)
task1_B_economic         (leave blank)
task1_B_method           (leave blank)
task1_B_funding          (leave blank)
task1_B_cooperation      (leave blank)
task1_attr_order         (leave blank)

[Repeat for task2 through task5]
```

**For Twitter Simulation:**
```
twitter_treatment        (leave blank - will be set by randomizer)
respondent_county        (leave blank - can be set from ZIP lookup)
twitter_liked            Set value to: 0
twitter_reposted         Set value to: 0
twitter_bookmarked       Set value to: 0
twitter_replied          Set value to: 0
twitter_treatment_shown  (leave blank)
twitter_tweet_text       (leave blank)
```

### Step 3: Set Up Randomization

1. In Survey Flow, add a **Randomizer** element
2. Configure for your design:

**For 2x2 Vignette (4 conditions):**
```
Randomizer: Evenly present elements
├── Branch 1: Set Embedded Data
│   └── vignette_condition = 1
│   └── facility_frame = detention
│   └── economic_emphasis = no_jobs
├── Branch 2: Set Embedded Data
│   └── vignette_condition = 2
│   └── facility_frame = detention
│   └── economic_emphasis = jobs
├── Branch 3: Set Embedded Data
│   └── vignette_condition = 3
│   └── facility_frame = processing
│   └── economic_emphasis = no_jobs
├── Branch 4: Set Embedded Data
│   └── vignette_condition = 4
│   └── facility_frame = processing
│   └── economic_emphasis = jobs
```

**For Twitter Simulation (same 4 conditions or different):**
```
Randomizer: Evenly present elements
├── Branch 1: Set twitter_treatment = detention_no_jobs
├── Branch 2: Set twitter_treatment = detention_jobs
├── Branch 3: Set twitter_treatment = processing_no_jobs
├── Branch 4: Set twitter_treatment = processing_jobs
```

---

## Implementing the Vignette Experiment

### Step 1: Create Vignette Question

1. Create a new **Text/Graphic** question type
2. In the question text, use piped text to display the appropriate vignette:

```html
<div style="background:#f9f9f9; padding:20px; border-radius:8px; margin-bottom:20px;">

${e://Field/facility_frame/ChoiceGroup/SelectedChoicesRecode}

<!-- Or use Display Logic with multiple versions -->

</div>
```

### Step 2: Using Display Logic (Alternative Method)

Create 4 versions of the vignette question and use Display Logic:

1. **Question V1** (Detention + No Jobs):
   - Display Logic: `facility_frame` = `detention` AND `economic_emphasis` = `no_jobs`
   - Question text: Full vignette for this condition

2. **Question V2** (Detention + Jobs):
   - Display Logic: `facility_frame` = `detention` AND `economic_emphasis` = `jobs`
   - Question text: Full vignette for this condition

3. Repeat for V3 and V4

### Step 3: Add Outcome Questions

After the vignette, add your dependent variable questions:

**Primary DV: Support for Facility**
```
Question Type: Matrix - Likert
Scale: 7-point (Strongly oppose to Strongly support)

Items:
- I would support building this facility in my county
- This facility would benefit my community
- I would attend a town hall meeting to support this facility
```

**Secondary DVs:**
- Support for ICE raids in general
- Support for local police cooperation with ICE
- Perceived economic benefits

---

## Implementing the Conjoint Experiment

### Step 1: Create Conjoint Question Block

1. Create a new block called "Conjoint Tasks"
2. Add 5 identical questions (one for each task)

### Step 2: Set Up Each Conjoint Question

For each of the 5 questions:

1. **Question Type:** Multiple Choice (Single Answer)
2. **Choices:** 
   - Option A
   - Option B

3. **Add JavaScript:**
   - Click on the question
   - Click the gear icon → **Add JavaScript**
   - Copy the entire contents of `qualtrics/js/conjoint.js`
   - Paste into the JavaScript editor

### Step 3: Configure Question Settings

For each conjoint question:

1. Go to **Question Behavior** → **JavaScript**
2. Ensure "Run JavaScript when question is displayed" is checked

### Step 4: Important Notes

- The JavaScript automatically increments `conjoint_task` after each question
- Profile attributes are stored in embedded data for analysis
- Attribute order is randomized and recorded

### Step 5: Add Timing (Optional)

To ensure respondents spend adequate time reviewing profiles:

1. Add a **Timing** question before or on the same page
2. Set minimum time (e.g., 10 seconds) before allowing advancement

---

## Implementing the Twitter/X Simulation

### Step 1: Create Twitter Question

1. Create a new **Text/Graphic** question type in a dedicated block
2. You can leave the question text empty (JavaScript will populate it)

### Step 2: Add JavaScript

1. Click on the question
2. Click the gear icon → **Add JavaScript**
3. Copy the entire contents of `qualtrics/js/twitter_simulation.js`
4. Paste into the JavaScript editor

### Step 3: Add Follow-up Questions

After the Twitter simulation, add questions about the respondent's reactions:

**Behavioral Outcomes (already captured via JavaScript):**
- Liked the post (embedded data: `twitter_liked`)
- Reposted (embedded data: `twitter_reposted`)
- Bookmarked (embedded data: `twitter_bookmarked`)

**Attitudinal Follow-ups:**
```
Question: After seeing this post, how do you feel about...
- The proposed facility
- ICE enforcement in general
- Economic benefits of enforcement

Scale: 7-point (Very negative to Very positive)
```

### Step 4: Personalization with County

To display the respondent's actual county in the tweet:

1. Earlier in the survey, collect ZIP code
2. Use Qualtrics' ZIP code → County lookup (via Web Service or lookup table)
3. Store result in `respondent_county` embedded data

Or, ask directly:
```
Question: In which county do you currently reside?
[Open text or dropdown list]
```

Then pipe this value into `respondent_county`.

---

## Data Export and Reshaping

### Exporting from Qualtrics

1. Go to **Data & Analysis** → **Export & Import** → **Export Data**
2. Select **CSV** format
3. Check "Use choice text" for labeling
4. Download

### Reshaping Conjoint Data in R

The conjoint data needs to be reshaped from wide to long format:

```r
library(tidyverse)

# Load raw Qualtrics export
raw_data <- read_csv("qualtrics_export.csv") %>%
  slice(-1:-2)  # Remove Qualtrics header rows

# Reshape conjoint data
conjoint_long <- raw_data %>%
  select(ResponseId, starts_with("task")) %>%
  pivot_longer(
    cols = -ResponseId,
    names_to = c("task", "profile", "attribute"),
    names_pattern = "task(\\d)_([AB])_(.*)",
    values_to = "level"
  ) %>%
  pivot_wider(
    names_from = attribute,
    values_from = level
  ) %>%
  left_join(
    raw_data %>% 
      select(ResponseId, starts_with("Q")) %>%  # Adjust Q# to your choice questions
      pivot_longer(-ResponseId, names_to = "task_q", values_to = "chosen") %>%
      mutate(task = str_extract(task_q, "\\d")),
    by = c("ResponseId", "task")
  )
```

### Reshaping Twitter Data

```r
twitter_data <- raw_data %>%
  select(
    ResponseId,
    treatment = twitter_treatment_shown,
    liked = twitter_liked,
    reposted = twitter_reposted,
    bookmarked = twitter_bookmarked,
    replied = twitter_replied,
    tweet_text = twitter_tweet_text
  ) %>%
  mutate(
    any_engagement = as.numeric(liked == "1" | reposted == "1" | bookmarked == "1"),
    positive_engagement = as.numeric(liked == "1" | reposted == "1")
  )
```

---

## Troubleshooting

### Common Issues

**1. JavaScript not running:**
- Ensure "Look and Feel" settings allow custom JavaScript
- Check browser console for errors (F12 → Console)
- Verify embedded data field names match exactly

**2. Embedded data not saving:**
- Confirm embedded data fields are defined in Survey Flow BEFORE the question block
- Field names are case-sensitive
- Check for typos in `setEmbeddedData()` calls

**3. Conjoint table not displaying:**
- Check that question type is correct
- Ensure JavaScript is added to the correct question
- Preview in an incognito/private browser window

**4. Twitter buttons not working:**
- JavaScript event listeners require the elements to exist
- Check that HTML IDs match (`btn-like`, `btn-repost`, etc.)

### Testing Your Survey

1. **Preview Mode:** Use Qualtrics preview to test
2. **Test Responses:** Generate test data and verify export
3. **Mobile Testing:** Check display on mobile devices
4. **Browser Testing:** Test in Chrome, Firefox, Safari

### Validation Checklist

- [ ] All 4 vignette conditions display correctly
- [ ] Conjoint profiles randomize properly
- [ ] Embedded data captures all profile attributes
- [ ] Task counter increments correctly (1-5)
- [ ] Twitter buttons track interactions
- [ ] Data exports in expected format
- [ ] Timing questions function properly
- [ ] Attention/manipulation checks work

---

## Contact

For questions about this implementation, contact:

Charles Crabtree  
Senior Lecturer, School of Social Sciences  
Monash University  
K-Club Professor, University College, Korea University

---

*Last updated: February 2026*
