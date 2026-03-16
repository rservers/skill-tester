# Skill Tester

A comprehensive skill testing and vetting workflow for OpenClaw agents.

## Overview

This skill provides a complete workflow for testing and vetting skills across multiple LLM models. Each model independently evaluates skills and produces its own detailed vetting report.

## Features

- **Multi-Model Testing**: Spawn subagents with different model providers
- **Independent Vetting**: Each model produces its own assessment
- **Validation Checks**: YAML structure, required fields, safety scans
- **Quality Assessment**: Strengths, weaknesses, recommendations
- **Per-Model Reports**: Detailed reports from each model's perspective

## Supported Models

```json
{
  "minimax-portal": "MiniMax-M2.5",
  "openai-codex": "gpt-5.3-codex"
}
```

## Workflow

### 1. Discovery
Clone/fetch skill repository and list available skills.

### 2. Validation (Per Model)
For each skill:
1. Spawn subagent with specific model
2. Run vetting process
3. Generate independent report

### 3. Vetting Criteria

| Area | Description |
|------|-------------|
| **Structure** | Valid YAML, required fields present |
| **Completeness** | All sections included, well-documented |
| **Quality** | Clear instructions, actionable steps |
| **Safety** | No dangerous commands or patterns |
| **Usability** | Clear examples, proper formatting |

### 4. Report Generation
Each model produces its own detailed report with:
- Validation checklist results
- Quality assessment (strengths/weaknesses)
- Recommendations
- Final verdict (APPROVED / NEEDS REVISION / REJECTED)

## Usage

### Commands

```bash
# Test a skill with all models
vet skill <skill-name>

# Test all skills in a category
vet category <category-name>

# Show specific model's report
show report <skill-name> <model-name>

# Full workflow - discover, validate, test, report
vet <github-repo>
```

### Examples

1. **"Vet opportunity-solution-tree with all models"**
   - Spawns subagents for MiniMax and GPT-5.3
   - Each model independently evaluates the skill
   - Generates per-model reports

2. **"Test brainstorm-ideas with MiniMax only"**
   - Single model vetting
   - Detailed quality assessment

3. **"Show me GPT-5.3's report for lean-canvas""**
   - Display specific model's findings

## Report Format

```markdown
# Skill Vetting Report
**Model:** [Model Name]
**Skill:** [Skill Name]
**Date:** [Date]

---

## Validation

| Check | Status |
|-------|---------|
| YAML Frontmatter | ✅/❌ |
| Name Field | ✅/❌ |
| Description | ✅/❌ |
| Tool References | ✅/❌ |
| Dangerous Patterns | ✅/❌ |

---

## Quality Assessment

### Strengths
- [Model's assessment]

### Weaknesses
- [Model's assessment]

### Recommendations
- [Model's suggestions]

---

## Verdict
**Vetting Status:** APPROVED / NEEDS REVISION / REJECTED
```

## Integration

### Subagent Spawning

```typescript
// For each model:
const subagent = await spawnSubagent({
  label: `vet-${skill}-${model}`,
  model: providers[providerName],
  task: vettingPrompt,
  runtime: "subagent",
  timeoutSeconds: 60
});
```

### Model Configuration

Add models to `openclaw.json`:

```json
{
  "models": {
    "providers": {
      "minimax-portal": {
        "baseUrl": "https://api.minimax.io/anthropic",
        "apiKey": "minimax-oauth"
      },
      "openai-codex": {
        "baseUrl": "https://openrouter.ai",
        "apiKey": "openrouter-oauth"
      }
    }
  }
}
```

## File Structure

```
skill-tester/
├── SKILL.md          # Skill definition
├── README.md         # This file
└── scripts/
    ├── test.sh       # Validation script
    └── multi_model.sh # Multi-model runner
```

## Contributing

1. Fork the repo
2. Add your skill
3. Test with multiple models
4. Submit for review

## License

MIT
