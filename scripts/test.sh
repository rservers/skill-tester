#!/bin/bash
# Skill Tester - Main Workflow Script

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Load credentials
load_creds() {
  source ~/.openclaw/credentials/jira-confluence.json 2>/dev/null || {
    log_warn "No Jira credentials found"
  }
}

# Clone/fetch repo
clone_repo() {
  local repo="$1"
  local target_dir="/tmp/skill-review-$(echo $repo | tr '/' '-')"
  
  if [ -d "$target_dir" ]; then
    log_info "Updating existing repo..."
    cd "$target_dir" && git pull
  else
    log_info "Cloning $repo..."
    git clone --depth 1 "https://github.com/$repo.git" "$target_dir"
  fi
  echo "$target_dir"
}

# Validate single skill
validate_skill() {
  local skill_path="$1"
  local skill_name=$(basename "$skill_path")
  local result="PASS"
  
  echo "=== $skill_name ==="
  
  # Check SKILL.md exists
  if [ ! -f "$skill_path/SKILL.md" ]; then
    echo "  ❌ Missing SKILL.md"
    result="FAIL"
    return 1
  fi
  echo "  ✓ SKILL.md exists"
  
  # Check YAML frontmatter
  if head -3 "$skill_path/SKILL.md" | grep -q "^---"; then
    echo "  ✓ YAML frontmatter"
  else
    echo "  ❌ No YAML frontmatter"
    result="FAIL"
  fi
  
  # Check name
  if grep -q "^name:" "$skill_path/SKILL.md"; then
    echo "  ✓ Has name"
  else
    echo "  ❌ Missing name"
    result="FAIL"
  fi
  
  # Check description
  if grep -q "^description:" "$skill_path/SKILL.md"; then
    echo "  ✓ Has description"
  else
    echo "  ❌ Missing description"
    result="FAIL"
  fi
  
  # Check for dangerous patterns
  if grep -iqE "rm -rf /|chmod 777|sudo.*without.*password" "$skill_path/SKILL.md" 2>/dev/null; then
    echo "  ⚠️  Contains risky patterns"
  fi
  
  # Count lines
  lines=$(wc -l < "$skill_path/SKILL.md")
  echo "  📄 Lines: $lines"
  
  echo "  Result: $result"
  [ "$result" = "PASS" ]
}

# Full validation
validate_all() {
  local repo_dir="$1"
  local total=0
  local passed=0
  local failed=0
  
  for plugin in "$repo_dir"/pm-*/; do
    [ -d "$plugin" ] || continue
    plugin_name=$(basename "$plugin")
    echo ""
    echo "=== PLUGIN: $plugin_name ==="
    
    if [ -d "$plugin/skills" ]; then
      for skill in "$plugin/skills"/*/; do
        [ -d "$skill" ] || continue
        total=$((total + 1))
        if validate_skill "$skill"; then
          passed=$((passed + 1))
        else
          failed=$((failed + 1))
        fi
      done
    fi
  done
  
  echo ""
  echo "========================================"
  echo "VALIDATION SUMMARY"
  echo "========================================"
  echo "Total: $total"
  echo "Passed: $passed"
  echo "Failed: $failed"
  echo "========================================"
}

# Create Jira ticket
create_jira_ticket() {
  local skill_name="$1"
  local repo="$2"
  local result="$3"
  local description="$4"
  
  load_creds
  
  if [ -z "$ATLASSIAN_EMAIL" ] || [ -z "$ATLASSIAN_API_TOKEN" ]; then
    log_error "Jira credentials not available"
    return 1
  fi
  
  log_info "Creating Jira ticket for $skill_name..."
  
  curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN" \
    -X POST "https://$JIRA_INSTANCE/rest/api/3/issue" \
    -H "Content-Type: application/json" \
    -d "{
      \"fields\": {
        \"project\": {\"key\": \"RC\"},
        \"summary\": \"Skill Vetting: $skill_name\",
        \"description\": {\"type\": \"doc\", \"version\": 1, \"content\": [
          {\"type\": \"paragraph\", \"content\": [{\"type\": \"text\", \"text\": \"Source: $repo\"}]},
          {\"type\": \"paragraph\", \"content\": [{\"type\": \"text\", \"text\": \"Validation: $result\"}]},
          {\"type\": \"paragraph\", \"content\": [{\"type\": \"text\", \"text\": \"$description\"}]}
        ]},
        \"issuetype\": {\"name\": \"Task\"},
        \"priority\": {\"name\": \"Medium\"}
      }
    }"
}

# Main command
main() {
  local command="${1:-help}"
  shift || true
  
  case "$command" in
    vet)
      local repo="$1"
      [ -z "$repo" ] && { echo "Usage: $0 vet <owner/repo>"; exit 1; }
      log_info "Starting vet workflow for $repo..."
      local repo_dir=$(clone_repo "$repo")
      validate_all "$repo_dir"
      ;;
    validate)
      local path="$1"
      [ -z "$path" ] && { echo "Usage: $0 validate <skill-path>"; exit 1; }
      validate_skill "$path"
      ;;
    ticket)
      load_creds
      create_jira_ticket "$1" "$2" "$3" "$4"
      ;;
    help|*)
      cat << 'HELP'
Skill Tester - Usage:
  
  vet <owner/repo>     - Full vetting workflow
  validate <path>      - Validate single skill
  ticket <name> <repo> <result> <desc> - Create Jira ticket
  
Examples:
  skill-tester vet phuryn/pm-skills
  skill-tester validate /path/to/skill
HELP
      ;;
  esac
}

main "$@"
