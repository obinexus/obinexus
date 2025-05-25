#!/bin/bash
# OBINexus GitHub Pages Maintenance & Validation
# Post-deployment maintenance script - Waterfall Phase: Maintenance

set -euo pipefail

readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
readonly LOG_FILE="deployment_maintenance_${TIMESTAMP}.log"

# Logging functions
log_info() {
    echo "[INFO $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo "[SUCCESS $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo "[WARNING $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

echo "=== OBINexus GitHub Pages Maintenance ==="
log_info "Starting maintenance validation - Timestamp: $TIMESTAMP"

# Phase 1: Structure Validation (Non-destructive)
echo "[VALIDATE] Verifying deployment structure..."

# Validate essential files exist
essential_files=("index.html" "_config.yml")
for file in "${essential_files[@]}"; do
    if [[ -f "$file" ]]; then
        log_success "Confirmed: $file exists"
    else
        log_warning "Missing: $file - deployment may be incomplete"
    fi
done

# Validate directory structure
required_dirs=("docs/computing" "docs/publishing" "docs/uche-nnamdi" "assets")
for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        log_success "Confirmed: $dir/ directory structure"
    else
        log_warning "Missing: $dir/ - creating directory structure"
        mkdir -p "$dir/projects" 2>/dev/null || true
    fi
done

# Phase 2: Jekyll Configuration Validation
echo "[VALIDATE] Jekyll configuration analysis..."

if [[ -f "_config.yml" ]]; then
    # Validate critical configuration keys
    config_keys=("title" "baseurl" "url")
    for key in "${config_keys[@]}"; do
        if grep -q "^${key}:" "_config.yml"; then
            log_success "Jekyll config: $key configured"
        else
            log_warning "Jekyll config: Missing $key configuration"
        fi
    done
else
    log_warning "Jekyll configuration missing - GitHub Pages build may fail"
fi

# Phase 3: Asset Directory Maintenance
echo "[MAINTAIN] Asset directory structure..."

asset_dirs=("assets/css" "assets/js" "assets/images")
for asset_dir in "${asset_dirs[@]}"; do
    if [[ ! -d "$asset_dir" ]]; then
        mkdir -p "$asset_dir"
        log_info "Created asset directory: $asset_dir"
    fi
done

# Phase 4: Git Repository Status Analysis
echo "[ANALYZE] Git repository status..."

if git rev-parse --git-dir > /dev/null 2>&1; then
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        log_info "Uncommitted changes detected:"
        git status --short | while read -r line; do
            log_info "  $line"
        done
        
        echo ""
        echo "=== COMMIT RECOMMENDATION ==="
        echo "Execute the following commands to deploy changes:"
        echo "  git add ."
        echo "  git commit -m 'chore: GitHub Pages maintenance update - $(date +%Y%m%d)'"
        echo "  git push origin main"
        echo ""
    else
        log_success "Repository is clean - no uncommitted changes"
    fi
    
    # Check current branch
    current_branch=$(git branch --show-current)
    if [[ "$current_branch" == "main" ]]; then
        log_success "Currently on main branch - deployment ready"
    else
        log_warning "Currently on $current_branch - switch to main for deployment"
    fi
else
    log_warning "Not in a git repository - manual deployment required"
fi

# Phase 5: GitHub Pages URL Verification
echo "[VERIFY] GitHub Pages deployment URLs..."

expected_url="https://obinenxus.github.io/obinexus"
log_info "Expected site URL: $expected_url"
log_info "Division URLs:"
log_info "  Computing: $expected_url/docs/computing/"
log_info "  Publishing: $expected_url/docs/publishing/"
log_info "  UCHE Nnamdi: $expected_url/docs/uche-nnamdi/"

# Phase 6: Maintenance Summary
echo ""
echo "=== MAINTENANCE SUMMARY ==="
echo "Timestamp: $TIMESTAMP"
echo "Log file: $LOG_FILE"

if [[ -f "index.html" && -f "_config.yml" && -d "docs" ]]; then
    echo "Status: ✓ Deployment structure validated"
    echo "Action: Ready for content updates and expansion"
else
    echo "Status: ⚠ Incomplete deployment structure"
    echo "Action: Review warnings above and complete missing components"
fi

echo ""
echo "=== NEXT DEVELOPMENT PHASE ==="
echo "1. Verify site accessibility at: $expected_url"
echo "2. Add project-specific documentation to docs/[division]/projects/"
echo "3. Implement automated content discovery system"
echo "4. Configure custom domain (optional): docs.obinexus.org"
echo ""

log_success "Maintenance validation completed successfully"

