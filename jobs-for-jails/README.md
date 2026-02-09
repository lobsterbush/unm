# Jobs for Jails: Economic Self-Interest and Public Support for Immigration Enforcement

## Research Question

Does framing immigration enforcement facilities in terms of local economic benefits (job creation) increase public support for ICE raids and detention, particularly among those who might otherwise oppose such policies?

## Author

Charles Crabtree  
Senior Lecturer, School of Social Sciences, Monash University  
K-Club Professor, University College, Korea University

## Abstract

What factors shape public support for immigration enforcement in local communities? While existing research emphasizes ideology and racial attitudes, we argue that economic self-interest—specifically, the prospect of local job creation—can increase support for enforcement activities that citizens might otherwise oppose. We test this argument using a multi-method approach with a nationally representative sample of Americans. First, we conduct a 2×2 factorial vignette experiment that randomly varies (a) whether a proposed federal facility is framed as a "detention center" or "processing facility" and (b) whether economic benefits (jobs, local spending) are emphasized. Second, we deploy a conjoint experiment examining preferences over specific enforcement actions, varying target type, enforcement method, economic impact, and federal funding. Third, we embed treatments in a simulated Twitter/X environment to measure behavioral engagement. We complement these experiments with an observational analysis of public opinion in counties that have experienced ICE raids, examining whether support varies with local economic conditions. Our findings have implications for understanding how framing and self-interest interact to shape immigration policy attitudes.

## Project Structure

```
jobs-for-jails/
├── README.md                     # This file
├── data/
│   ├── raw/                      # Raw data from Qualtrics, TRAC, BLS
│   └── processed/                # Cleaned analysis-ready datasets
├── docs/
│   ├── pilot_protocol.txt        # Pilot study protocol
│   ├── power_analysis_summary.txt # Power analysis results
│   └── qualtrics_implementation_guide.md  # Qualtrics setup instructions
├── output/
│   ├── figures/                  # Publication-ready figures
│   └── tables/                   # LaTeX tables for paper
├── plots/                        # Exploratory and diagnostic plots
├── qualtrics/
│   ├── js/
│   │   ├── conjoint.js           # Conjoint experiment JavaScript
│   │   └── twitter_simulation.js # Twitter/X simulation JavaScript
│   ├── css/                      # Custom CSS for Qualtrics
│   └── treatment_texts.csv       # Vignette texts for Qualtrics
├── scripts/
│   ├── 01_treatment_development.R  # Treatment design and validation
│   ├── 02_power_analysis.R         # Power calculations
│   ├── 03_vignette_analysis.R      # Main vignette experiment analysis
│   └── 04_conjoint_analysis.R      # Conjoint experiment analysis
└── text/                         # Paper drafts and notes
```

## Experimental Design

### Study 1: Vignette Experiment (2×2 Factorial)

**Factors:**
1. Facility framing: "ICE detention center" vs. "federal immigration processing facility"
2. Economic emphasis: Jobs/economic benefits mentioned vs. not mentioned

**Sample:** N = 2,000 U.S. adults (nationally representative)

**Primary outcomes:**
- Support for the proposed facility (7-point scale)
- Support for ICE operations in respondent's area

### Study 2: Conjoint Experiment

**Attributes:**
- Target type (4 levels): Workers, criminals, families, courthouse
- Economic impact (3 levels): Create jobs, no effect, lose jobs
- Enforcement method (4 levels): Inspection, raid, home visits, public arrests
- Federal funding (3 levels): $5M, $500K, none
- Local cooperation (3 levels): Police assist, neutral, prohibited

**Tasks:** 5 forced-choice tasks per respondent

### Study 3: Twitter/X Simulation

Respondents view a realistic tweet about ICE enforcement with randomly varied framing and can:
- Like the post
- Repost/retweet
- Bookmark
- Reply

Behavioral engagement is tracked as outcome.

## Running the Analysis

### Prerequisites

```r
# Install required R packages
install.packages(c(
  "tidyverse", "estimatr", "cregg", "cjoint", 
  "DeclareDesign", "pwr", "ggthemes", "modelsummary",
  "marginaleffects", "randomizr", "fabricatr"
))
```

### Analysis Pipeline

1. **Treatment Development:** Run `scripts/01_treatment_development.R`
2. **Power Analysis:** Run `scripts/02_power_analysis.R`
3. **After data collection:**
   - Vignette analysis: `scripts/03_vignette_analysis.R`
   - Conjoint analysis: `scripts/04_conjoint_analysis.R`

## Qualtrics Implementation

See `docs/qualtrics_implementation_guide.md` for detailed instructions on:
- Setting up embedded data fields
- Implementing randomization
- Adding JavaScript for conjoint and Twitter simulation
- Exporting and reshaping data

## Timeline

- [ ] Finalize design and pre-register
- [ ] Pilot test (N = 100)
- [ ] Main data collection (N = 2,000)
- [ ] Analysis and paper draft
- [ ] Submission to [target journal]

## Data Availability

We will make all data and code used to generate our results available at a figshare repository at the time of publication.

## Ethics

We received ethics approval from [fill in] (protocol number: [fill in]).

## Contact

For questions, contact: charles.crabtree@monash.edu

## License

This project is licensed under the MIT License.
