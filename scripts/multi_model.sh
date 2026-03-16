#!/bin/bash
# Multi-Model Skill Tester

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_test() { echo -e "${BLUE}[TEST]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Available models
MODELS=(
  "minimax-portal/MiniMax-M2.5:MiniMax"
  "anthropic/claude-4-20250514:Opus"
  "xai/grok-2:Grok"
  "openai/gpt-4o:GPT-4o"
  "google/gemini-2.0-flash-exp:Gemini"
)

# Test prompts by category
declare -A TEST_PROMPTS
TEST_PROMPTS[discovery]="Create an opportunity solution tree for improving user activation. The desired outcome is: increase 7-day retention to 40%."
TEST_PROMPTS[strategy]="Create a lean canvas for an AI-powered meeting summarizer for remote teams."
TEST_PROMPTS[execution]="Write a Product Requirements Document for a smart notification system that reduces alert fatigue."
TEST_PROMPTS[research]="Create user personas for a B2B SaaS product targeting enterprise customers."

# Test skill with single model
test_with_model() {
  local model_id="$1"
  local model_name="$2"
  local prompt="$3"
  local output_file="$4"
  
  log_test "Testing with $model_name ($model_id)..."
  
  # This would call the actual model API
  # For now, simulate with a placeholder
  echo "Output from $model_name for prompt: $prompt" > "$output_file"
  
  # In real implementation:
  # curl -s -X POST "$MODEL_API endpoint" \
  #   -H "Authorization: Bearer $API_KEY" \
  #   -d "{\"model\": \"$model_id\", \"prompt\": \"$prompt\"}"
  
  echo "$output_file"
}

# Run multi-model test
run_multi_model_test() {
  local skill_name="$1"
  local category="$2"
  local prompt="${TEST_PROMPTS[$category]}"
  
  [ -z "$prompt" ] && { log_warn "No prompt for category: $category"; return 1; }
  
  local results_dir="/tmp/skill-tests/$skill_name"
  mkdir -p "$results_dir"
  
  log_info "Running multi-model test for: $skill_name (category: $category)"
  echo "Prompt: $prompt"
  echo ""
  
  for model_entry in "${MODELS[@]}"; do
    IFS=':' read -r model_id model_name <<< "$model_entry"
    output_file="$results_dir/${model_name,,}.txt"
    
    test_with_model "$model_id" "$model_name" "$prompt" "$output_file"
    echo ""
  done
  
  log_info "Results saved to: $results_dir"
  echo ""
  echo "=== COMPARISON ==="
  for model_entry in "${MODELS[@]}"; do
    IFS=':' read -r model_id model_name <<< "$model_entry"
    output_file="$results_dir/${model_name,,}.txt"
    echo "- $model_name: $output_file"
  done
}

# Compare outputs
compare_outputs() {
  local skill_name="$1"
  local results_dir="/tmp/skill-tests/$skill_name"
  
  [ ! -d "$results_dir" ] && { log_warn "No results found for $skill_name"; return 1; }
  
  echo "=== COMPARISON: $skill_name ==="
  for f in "$results_dir"/*.txt; do
    echo "--- $(basename $f) ---"
    head -5 "$f"
    echo ""
  done
}

# Main
main() {
  local command="${1:-help}"
  shift || true
  
  case "$command" in
    test)
      local skill="$1"
      local category="${2:-discovery}"
      run_multi_model_test "$skill" "$category"
      ;;
    compare)
      local skill="$1"
      compare_outputs "$skill"
      ;;
    models)
      echo "Available models:"
      for m in "${MODELS[@]}"; do
        IFS=':' read -r id name <<< "$m"
        echo "  - $name: $id"
      done
      ;;
    prompts)
      echo "Test prompts by category:"
      for c in "${!TEST_PROMPTS[@]}"; do
        echo "  $c: ${TEST_PROMPTS[$c]:0:50}..."
      done
      ;;
    help|*)
      cat << 'HELP'
Multi-Model Skill Tester - Usage:
  
  test <skill-name> <category>  - Run test across all models
  compare <skill-name>            - Compare saved outputs
  models                          - List available models
  prompts                         - Show test prompts
  
Examples:
  multi-model-test test opportunity-solution-tree discovery
  multi-model-test compare opportunity-solution-tree
HELP
      ;;
  esac
}

main "$@"
