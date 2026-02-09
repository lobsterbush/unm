# Warp Agent Commands for Live Demo

These are ready-to-use prompts for the Warp terminal agent during the live demo.

---

## Demo 1: Generate Economic Frame Vignettes

**Warp prompt:**
```
Read the prompt in prompts/economic_frame.txt, then use that prompt to call 
the OpenAI API (gpt-4o-mini, temperature 0.7) to generate vignettes. Save 
the JSON output to output/vignettes_economic.json
```

**Alternative (using the R script):**
```
Run the R script code/generate_vignettes.R and show me the output
```

---

## Demo 2: Validate the Generated Vignettes

**Warp prompt:**
```
Run the validation script code/validate_vignettes.R on the vignettes we 
just generated. Show me which checks pass and fail.
```

---

## Demo 3: Generate Moral Frame Vignettes

**Warp prompt:**
```
Now generate the moral frame vignettes using prompts/moral_frame.txt. 
Same process - call OpenAI API and save to output/vignettes_moral.json
```

---

## Demo 4: Compare Conditions

**Warp prompt:**
```
Compare the word counts, reading levels, and sentiment between the economic 
and moral frame vignettes. Create a summary table showing whether the 
conditions are balanced on these dimensions.
```

---

## Demo 5: LLM-Based Validation

**Warp prompt:**
```
For each vignette in output/vignettes_economic.json, use the OpenAI API to 
rate it on these dimensions (1-7 scale):
1. Economic emphasis
2. Moral emphasis  
3. Emotional intensity
4. Political lean (1=liberal, 7=conservative)

Save results to output/llm_validation.json
```

---

## Demo 6: Fix a Problem Vignette

**Warp prompt:**
```
Vignette 2 is too long (185 words). Regenerate just that vignette using 
the same prompt but constrained to exactly 160 words. Keep the policy 
focus on wind energy.
```

---

## Backup: If API Fails

If the OpenAI API is unavailable during the demo, use this fallback:

```
Show me the code in generate_vignettes.R and walk through what each 
section does. Then show example output from the pre-generated file 
output/example_vignettes.json
```

---

## Quick Reference: API Call Pattern

For direct API calls in Warp:

```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [{"role": "user", "content": "YOUR PROMPT HERE"}],
    "temperature": 0.7
  }'
```

---

## Setup Check

Before demo, verify:
```
echo $OPENAI_API_KEY  # Should show key (or masked)
ls prompts/           # Should show economic_frame.txt, moral_frame.txt
ls code/              # Should show generate_vignettes.R, validate_vignettes.R
```
