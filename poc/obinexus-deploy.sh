#!/bin/bash
# obinexus-deploy.sh - Systematic deployment automation for OBINexus dual-stack architecture
# Waterfall Phase: Implementation & Integration Testing

set -euo pipefail

# Configuration constants - Dynamic path resolution for cross-platform compatibility
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BASE_DIR="${SCRIPT_DIR}"
readonly SOURCE_DB="${BASE_DIR}/db"
readonly GITHUB_PAGES_DIR="${BASE_DIR}/github_pages"
readonly IONOS_STAGING="${BASE_DIR}/ionos_staging"
readonly LOG_DIR="${BASE_DIR}/scripts/logs"
readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
readonly LOG_FILE="${LOG_DIR}/deployment_${TIMESTAMP}.log"

# Division configuration array
readonly DIVISIONS=("computing" "publishing" "uchennamdi")

# Logging functions
log_info() {
    echo "[INFO $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" >&2
}

log_success() {
    echo "[SUCCESS $(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Pre-deployment validation
validate_source_structure() {
    log_info "Phase 1: Source structure validation"
    
    local validation_errors=0
    
    # Validate base directories
    for division in "${DIVISIONS[@]}"; do
        local division_path="${SOURCE_DB}/${division}"
        
        if [[ ! -d "$division_path" ]]; then
            log_error "Missing division directory: $division_path"
            ((validation_errors++))
            continue
        fi
        
        # Validate required subdirectories
        local required_subdirs=("projects" "shared")
        for subdir in "${required_subdirs[@]}"; do
            if [[ ! -d "${division_path}/${subdir}" ]]; then
                log_error "Missing required subdirectory: ${division_path}/${subdir}"
                ((validation_errors++))
            fi
        done
        
        # Validate project metadata
        local project_count=0
        while IFS= read -r -d '' project_dir; do
            if [[ ! -f "${project_dir}/meta.json" ]]; then
                log_error "Missing meta.json in: $project_dir"
                ((validation_errors++))
            else
                # Validate JSON structure
                if ! jq empty "${project_dir}/meta.json" 2>/dev/null; then
                    log_error "Invalid JSON in: ${project_dir}/meta.json"
                    ((validation_errors++))
                else
                    ((project_count++))
                fi
            fi
        done < <(find "${division_path}/projects" -maxdepth 1 -type d -print0 2>/dev/null)
        
        log_info "Division $division: $project_count projects validated"
    done
    
    if [[ $validation_errors -gt 0 ]]; then
        log_error "Structure validation failed with $validation_errors errors"
        return 1
    fi
    
    log_success "Source structure validation completed successfully"
    return 0
}

# Generate project indexes
generate_project_indexes() {
    log_info "Phase 2: Generating project indexes"
    
    for division in "${DIVISIONS[@]}"; do
        local division_path="${SOURCE_DB}/${division}"
        local projects_path="${division_path}/projects"
        
        if [[ ! -d "$projects_path" ]]; then
            continue
        fi
        
        # Generate division-level index
        cat > "${division_path}/index.md" << EOF
---
layout: division
title: $(echo "$division" | sed 's/.*/\u&/' | sed 's/uchennamdi/UCHE Nnamdi/')
division: $division
generated: $(date -Iseconds)
---

# $(echo "$division" | sed 's/.*/\u&/' | sed 's/uchennamdi/UCHE Nnamdi/') Division

## Active Projects

EOF
        
        # Add project listings with metadata
        local project_count=0
        while IFS= read -r -d '' project_dir; do
            local project_name=$(basename "$project_dir")
            
            if [[ -f "${project_dir}/meta.json" ]]; then
                local display_name=$(jq -r '.name // "Unknown"' "${project_dir}/meta.json")
                local description=$(jq -r '.description // "No description available"' "${project_dir}/meta.json")
                local status=$(jq -r '.status // "unknown"' "${project_dir}/meta.json")
                
                cat >> "${division_path}/index.md" << EOF
### [$display_name](projects/$project_name/)
**Status:** $status  
$description

EOF
                ((project_count++))
            fi
        done < <(find "$projects_path" -maxdepth 1 -type d -not -path "$projects_path" -print0 2>/dev/null)
        
        log_info "Generated index for $division ($project_count projects)"
    done
    
    log_success "Project indexes generated successfully"
}

# GitHub Pages deployment
deploy_github_pages() {
    log_info "Phase 3: GitHub Pages deployment preparation"
    
    # Clean and recreate target structure
    rm -rf "${GITHUB_PAGES_DIR}/docs"
    mkdir -p "${GITHUB_PAGES_DIR}/docs"
    mkdir -p "${GITHUB_PAGES_DIR}/_data"
    mkdir -p "${GITHUB_PAGES_DIR}/assets/css"
    mkdir -p "${GITHUB_PAGES_DIR}/assets/js"
    mkdir -p "${GITHUB_PAGES_DIR}/assets/images"
    
    # Copy division content with rsync for efficiency
    for division in "${DIVISIONS[@]}"; do
        local target_name="$division"
        if [[ "$division" == "uchennamdi" ]]; then
            target_name="uche-nnamdi"
        fi
        
        log_info "Syncing $division -> $target_name"
        
        rsync -av \
            --exclude='*.tmp' \
            --exclude='.DS_Store' \
            --exclude='*.log' \
            --exclude='.git*' \
            "${SOURCE_DB}/${division}/" \
            "${GITHUB_PAGES_DIR}/docs/${target_name}/"
    done
    
    # Generate navigation metadata
    generate_navigation_data
    
    # Copy and update main index.html if it exists
    if [[ -f "${BASE_DIR}/templates/github-pages-index.html" ]]; then
        cp "${BASE_DIR}/templates/github-pages-index.html" "${GITHUB_PAGES_DIR}/index.html"
    fi
    
    # Update Jekyll configuration
    cat > "${GITHUB_PAGES_DIR}/_config.yml" << EOF
title: OBINexus Documentation Portal
description: Connection through technology - modular ecosystem documentation
baseurl: /obinenxu
url: https://obinenxus.github.io
markdown: kramdown
highlighter: rouge
theme: minima
plugins:
  - jekyll-feed
  - jekyll-sitemap
  - jekyll-seo-tag
collections:
  computing:
    output: true
    permalink: /:collection/:name/
  publishing:
    output: true
    permalink: /:collection/:name/
  uche-nnamdi:
    output: true
    permalink: /:collection/:name/
EOF
    
    log_success "GitHub Pages structure prepared"
}

# Navigation data generation
generate_navigation_data() {
    log_info "Generating navigation metadata"
    
    cat > "${GITHUB_PAGES_DIR}/_data/navigation.yml" << EOF
main:
  - title: "Overview"
    url: /
  - title: "Computing"
    url: /docs/computing/
  - title: "Publishing"  
    url: /docs/publishing/
  - title: "UCHE Nnamdi"
    url: /docs/uche-nnamdi/
  - title: "Main Site"
    url: https://obinexus.org

divisions:
EOF
    
    for division in "${DIVISIONS[@]}"; do
        local target_name="$division"
        if [[ "$division" == "uchennamdi" ]]; then
            target_name="uche-nnamdi"
        fi
        
        echo "  $target_name:" >> "${GITHUB_PAGES_DIR}/_data/navigation.yml"
        
        local projects_path="${SOURCE_DB}/${division}/projects"
        if [[ -d "$projects_path" ]]; then
            while IFS= read -r -d '' project_dir; do
                local project_name=$(basename "$project_dir")
                
                if [[ -f "${project_dir}/meta.json" ]]; then
                    local display_name=$(jq -r '.name // "Unknown"' "${project_dir}/meta.json")
                    echo "    - title: \"$display_name\"" >> "${GITHUB_PAGES_DIR}/_data/navigation.yml"
                    echo "      url: /docs/$target_name/projects/$project_name/" >> "${GITHUB_PAGES_DIR}/_data/navigation.yml"
                fi
            done < <(find "$projects_path" -maxdepth 1 -type d -not -path "$projects_path" -print0 2>/dev/null)
        fi
    done
}

# IONOS staging preparation
prepare_ionos_staging() {
    log_info "Phase 4: IONOS staging preparation"
    
    mkdir -p "$IONOS_STAGING"
    
    # Copy maintenance page
    if [[ -f "${BASE_DIR}/templates/maintenance.html" ]]; then
        cp "${BASE_DIR}/templates/maintenance.html" "${IONOS_STAGING}/index.html"
    else
        log_error "Maintenance template not found"
        return 1
    fi
    
    # Generate .htaccess for redirects
    cat > "${IONOS_STAGING}/.htaccess" << EOF
# OBINexus IONOS FTP - Redirect Architecture
# Generated: $(date -Iseconds)

# Documentation portal redirect
RedirectMatch 301 ^/docs(.*)$ https://obinenxus.github.io/obinenxu\$1

# Division-specific redirects
RedirectMatch 301 ^/computing(.*)$ https://obinenxus.github.io/obinenxu/docs/computing\$1
RedirectMatch 301 ^/publishing(.*)$ https://obinenxus.github.io/obinenxu/docs/publishing\$1
RedirectMatch 301 ^/fashion(.*)$ https://obinenxus.github.io/obinenxu/docs/uche-nnamdi\$1

# SEO and security headers
<IfModule mod_headers.c>
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</IfModule>

# Cache control
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/html "access plus 1 hour"
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
</IfModule>
EOF
    
    # Generate robots.txt
    cat > "${IONOS_STAGING}/robots.txt" << EOF
User-agent: *
Allow: /
Sitemap: https://obinexus.org/sitemap.xml

# Redirect crawlers to documentation portal
# Main documentation: https://obinenxus.github.io/obinenxu
EOF
    
    log_success "IONOS staging prepared"
}

# Post-deployment validation
validate_deployment() {
    log_info "Phase 5: Deployment validation"
    
    local validation_errors=0
    
    # Validate GitHub Pages structure
    local required_gh_files=(
        "index.html"
        "_config.yml"
        "docs/computing/index.md"
        "docs/publishing/index.md"
        "docs/uche-nnamdi/index.md"
        "_data/navigation.yml"
    )
    
    for file in "${required_gh_files[@]}"; do
        if [[ ! -f "${GITHUB_PAGES_DIR}/$file" ]]; then
            log_error "Missing GitHub Pages file: $file"
            ((validation_errors++))
        fi
    done
    
    # Validate IONOS staging
    local required_ionos_files=(
        "index.html"
        ".htaccess"
        "robots.txt"
    )
    
    for file in "${required_ionos_files[@]}"; do
        if [[ ! -f "${IONOS_STAGING}/$file" ]]; then
            log_error "Missing IONOS file: $file"
            ((validation_errors++))
        fi
    done
    
    # Count total projects deployed
    local total_projects=0
    for division in "${DIVISIONS[@]}"; do
        local target_name="$division"
        if [[ "$division" == "uchennamdi" ]]; then
            target_name="uche-nnamdi"
        fi
        
        local division_projects=0
        if [[ -d "${GITHUB_PAGES_DIR}/docs/${target_name}/projects" ]]; then
            division_projects=$(find "${GITHUB_PAGES_DIR}/docs/${target_name}/projects" -maxdepth 1 -type d | wc -l)
            ((division_projects--)) # Subtract the projects directory itself
            ((total_projects += division_projects))
        fi
        
        log_info "Division $division: $division_projects projects deployed"
    done
    
    if [[ $validation_errors -gt 0 ]]; then
        log_error "Deployment validation failed with $validation_errors errors"
        return 1
    fi
    
    log_success "Deployment validation completed - $total_projects total projects deployed"
    return 0
}

# Main deployment orchestration
main() {
    # Ensure log directory exists BEFORE any logging calls
    mkdir -p "$LOG_DIR"
    
    log_info "Starting OBINexus dual-stack deployment - Timestamp: $TIMESTAMP"
    
    # Execute waterfall phases
    if ! validate_source_structure; then
        log_error "Deployment aborted due to validation failures"
        exit 1
    fi
    
    generate_project_indexes
    deploy_github_pages
    prepare_ionos_staging
    
    if ! validate_deployment; then
        log_error "Deployment validation failed"
        exit 1
    fi
    
    log_success "OBINexus deployment completed successfully"
    log_info "GitHub Pages ready: ${GITHUB_PAGES_DIR}"
    log_info "IONOS staging ready: ${IONOS_STAGING}"
    log_info "Log file: $LOG_FILE"
    
    # Generate deployment summary
    cat << EOF

=== DEPLOYMENT SUMMARY ===
Timestamp: $TIMESTAMP
GitHub Pages Target: $GITHUB_PAGES_DIR
IONOS Staging: $IONOS_STAGING
Log File: $LOG_FILE

Next Steps:
1. Review GitHub Pages content in: $GITHUB_PAGES_DIR
2. Test locally with: jekyll serve --source $GITHUB_PAGES_DIR
3. Deploy IONOS content from: $IONOS_STAGING
4. Validate live deployment URLs

EOF
}

# Execute main function
main "$@"
