#!/bin/bash
# OBINexus GitHub Pages Pre-Deployment Validation
# Waterfall Phase: System Testing & Validation

set -euo pipefail

readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly DOCS_DIR="${REPO_ROOT}/docs"
readonly ASSETS_DIR="${REPO_ROOT}/assets"
readonly DIVISIONS=("computing" "publishing" "uche-nnamdi")

# Validation functions
validate_structure() {
    echo "[VALIDATE] Checking repository structure..."
    
    local validation_errors=0
    
    # Check root files
    local required_root_files=("index.html" "_config.yml")
    for file in "${required_root_files[@]}"; do
        if [[ ! -f "${REPO_ROOT}/${file}" ]]; then
            echo "[ERROR] Missing required file: ${file}"
            ((validation_errors++))
        fi
    done
    
    # Check docs directory structure
    if [[ ! -d "$DOCS_DIR" ]]; then
        echo "[ERROR] Missing docs directory"
        ((validation_errors++))
        return 1
    fi
    
    # Validate division directories
    for division in "${DIVISIONS[@]}"; do
        local division_path="${DOCS_DIR}/${division}"
        
        if [[ ! -d "$division_path" ]]; then
            echo "[ERROR] Missing division directory: ${division}"
            ((validation_errors++))
            continue
        fi
        
        # Check required division files
        local required_division_files=("index.html")
        for file in "${required_division_files[@]}"; do
            if [[ ! -f "${division_path}/${file}" ]]; then
                echo "[ERROR] Missing ${file} in division: ${division}"
                ((validation_errors++))
            fi
        done
        
        # Check projects directory
        if [[ ! -d "${division_path}/projects" ]]; then
            echo "[WARNING] Missing projects directory in division: ${division}"
        fi
    done
    
    # Check assets directory
    if [[ ! -d "$ASSETS_DIR" ]]; then
        echo "[ERROR] Missing assets directory"
        ((validation_errors++))
    else
        local required_asset_dirs=("css" "js" "images")
        for asset_dir in "${required_asset_dirs[@]}"; do
            if [[ ! -d "${ASSETS_DIR}/${asset_dir}" ]]; then
                echo "[WARNING] Missing assets subdirectory: ${asset_dir}"
            fi
        done
    fi
    
    if [[ $validation_errors -gt 0 ]]; then
        echo "[VALIDATE] Structure validation failed with $validation_errors errors"
        return 1
    fi
    
    echo "[VALIDATE] Structure validation passed"
    return 0
}

validate_html() {
    echo "[VALIDATE] Checking HTML file validity..."
    
    local html_files=()
    while IFS= read -r -d '' file; do
        html_files+=("$file")
    done < <(find "$REPO_ROOT" -name "*.html" -print0)
    
    local html_errors=0
    
    for html_file in "${html_files[@]}"; do
        # Basic HTML validation - check for required elements
        if ! grep -q "<html" "$html_file"; then
            echo "[ERROR] Missing <html> tag in: $html_file"
            ((html_errors++))
        fi
        
        if ! grep -q "<head>" "$html_file"; then
            echo "[ERROR] Missing <head> tag in: $html_file"
            ((html_errors++))
        fi
        
        if ! grep -q "<title>" "$html_file"; then
            echo "[ERROR] Missing <title> tag in: $html_file"
            ((html_errors++))
        fi
        
        # Check for common issues
        if grep -q "localhost" "$html_file"; then
            echo "[WARNING] Found localhost reference in: $html_file"
        fi
        
        if grep -q "127.0.0.1" "$html_file"; then
            echo "[WARNING] Found local IP reference in: $html_file"
        fi
    done
    
    if [[ $html_errors -gt 0 ]]; then
        echo "[VALIDATE] HTML validation failed with $html_errors errors"
        return 1
    fi
    
    echo "[VALIDATE] HTML validation passed (${#html_files[@]} files checked)"
    return 0
}

validate_links() {
    echo "[VALIDATE] Checking internal link integrity..."
    
    local link_errors=0
    
    # Check for relative links that might be broken
    while IFS= read -r -d '' html_file; do
        # Extract relative links
        local relative_links=()
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                relative_links+=("$line")
            fi
        done < <(grep -oE 'href="[^"]*"' "$html_file" | grep -E 'href="[^http][^"]*"' | sed 's/href="//g' | sed 's/"//g')
        
        # Validate each relative link
        for link in "${relative_links[@]}"; do
            # Skip anchors and special links
            if [[ "$link" =~ ^# ]] || [[ "$link" =~ ^mailto: ]] || [[ "$link" =~ ^tel: ]]; then
                continue
            fi
            
            # Resolve relative path
            local html_dir="$(dirname "$html_file")"
            local target_path="$(realpath -m "${html_dir}/${link}" 2>/dev/null)"
            
            if [[ ! -e "$target_path" ]] && [[ ! -e "${target_path}/index.html" ]]; then
                echo "[ERROR] Broken link in $html_file: $link -> $target_path"
                ((link_errors++))
            fi
        done
    done < <(find "$REPO_ROOT" -name "*.html" -print0)
    
    if [[ $link_errors -gt 0 ]]; then
        echo "[VALIDATE] Link validation failed with $link_errors errors"
        return 1
    fi
    
    echo "[VALIDATE] Link validation passed"
    return 0
}

validate_jekyll_config() {
    echo "[VALIDATE] Checking Jekyll configuration..."
    
    local config_file="${REPO_ROOT}/_config.yml"
    
    if [[ ! -f "$config_file" ]]; then
        echo "[ERROR] Missing _config.yml file"
        return 1
    fi
    
    # Check for required configuration keys
    local required_keys=("title" "description" "url" "baseurl")
    local config_errors=0
    
    for key in "${required_keys[@]}"; do
        if ! grep -q "^${key}:" "$config_file"; then
            echo "[ERROR] Missing required configuration key: $key"
            ((config_errors++))
        fi
    done
    
    # Validate YAML syntax
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null; then
            echo "[ERROR] Invalid YAML syntax in _config.yml"
            ((config_errors++))
        fi
    fi
    
    if [[ $config_errors -gt 0 ]]; then
        echo "[VALIDATE] Jekyll configuration validation failed"
        return 1
    fi
    
    echo "[VALIDATE] Jekyll configuration validation passed"
    return 0
}

generate_manifest_files() {
    echo "[GENERATE] Creating project manifest files..."
    
    for division in "${DIVISIONS[@]}"; do
        local projects_dir="${DOCS_DIR}/${division}/projects"
        local manifest_file="${projects_dir}/manifest.json"
        
        if [[ ! -d "$projects_dir" ]]; then
            mkdir -p "$projects_dir"
        fi
        
        # Generate manifest based on existing directories
        local projects=()
        if [[ -d "$projects_dir" ]]; then
            while IFS= read -r -d '' project_dir; do
                local project_name="$(basename "$project_dir")"
                local project_title="$project_name"
                
                # Check for meta.json file
                if [[ -f "${project_dir}/meta.json" ]]; then
                    project_title="$(jq -r '.title // .name // "'"$project_name"'"' "${project_dir}/meta.json" 2>/dev/null || echo "$project_name")"
                fi
                
                projects+=("{\"name\":\"$project_name\",\"title\":\"$project_title\"}")
            done < <(find "$projects_dir" -maxdepth 1 -type d -not -path "$projects_dir" -print0 2>/dev/null)
        fi
        
        # Write manifest file
        cat > "$manifest_file" << EOF
{
    "division": "$division",
    "generated": "$(date -Iseconds)",
    "projects": [
        $(IFS=','; echo "${projects[*]}")
    ]
}
EOF
        
        echo "[GENERATE] Created manifest for $division (${#projects[@]} projects)"
    done
}

validate_github_pages_compatibility() {
    echo "[VALIDATE] Checking GitHub Pages compatibility..."
    
    local compatibility_errors=0
    
    # Check for unsupported plugins
    local config_file="${REPO_ROOT}/_config.yml"
    local unsupported_plugins=("jekyll-admin" "jekyll-coffeescript" "jekyll-sass-converter")
    
    for plugin in "${unsupported_plugins[@]}"; do
        if grep -q "$plugin" "$config_file" 2>/dev/null; then
            echo "[WARNING] Potentially unsupported plugin: $plugin"
        fi
    done
    
    # Check file naming conventions
    while IFS= read -r -d '' file; do
        local filename="$(basename "$file")"
        
        # Check for problematic characters
        if [[ "$filename" =~ [[:space:]] ]]; then
            echo "[WARNING] File with spaces in name: $file"
        fi
        
        if [[ "$filename" =~ [A-Z] ]] && [[ "$filename" != "README.md" ]] && [[ "$filename" != "LICENSE" ]]; then
            echo "[WARNING] File with uppercase characters: $file"
        fi
    done < <(find "$REPO_ROOT" -type f -print0)
    
    echo "[VALIDATE] GitHub Pages compatibility check completed"
    return 0
}

# Main validation execution
main() {
    echo "=== OBINexus GitHub Pages Deployment Validation ==="
    echo "Repository: $REPO_ROOT"
    echo "Timestamp: $(date -Iseconds)"
    echo ""
    
    local validation_failed=0
    
    # Execute validation phases
    validate_structure || validation_failed=1
    validate_html || validation_failed=1
    validate_jekyll_config || validation_failed=1
    validate_links || validation_failed=1
    validate_github_pages_compatibility
    
    # Generate supporting files
    generate_manifest_files
    
    echo ""
    if [[ $validation_failed -eq 0 ]]; then
        echo "=== VALIDATION PASSED ==="
        echo "Repository is ready for GitHub Pages deployment"
        echo ""
        echo "Next steps:"
        echo "1. Commit all changes to repository"
        echo "2. Push to main branch"
        echo "3. Enable GitHub Pages in repository settings"
        echo "4. Verify deployment at: https://obinenxus.github.io/obinenxu"
    else
        echo "=== VALIDATION FAILED ==="
        echo "Repository requires fixes before deployment"
        echo "Review error messages above and resolve issues"
        exit 1
    fi
}

# Execute main function
main "$@"
