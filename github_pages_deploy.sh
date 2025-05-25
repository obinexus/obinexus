#!/bin/bash
# OBINexus GitHub Pages Quick Deployment
# Execute from repository root

set -euo pipefail

echo "=== OBINexus GitHub Pages Deployment ==="

# Phase 1: Create required root structure
echo "[DEPLOY] Setting up root structure..."

# Copy main index.html to root (from your document index 7)
if [[ ! -f "index.html" ]]; then
    echo "Creating main index.html..."
    cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OBINexus Documentation Portal</title>
    <meta name="description" content="OBINexus modular ecosystem documentation">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            --dark-bg: #0a0f1c;
            --card-bg: rgba(255, 255, 255, 0.05);
            --border-color: rgba(255, 255, 255, 0.1);
            --text-primary: #ffffff;
            --text-secondary: #a0a0a0;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', sans-serif;
            background: var(--dark-bg);
            color: var(--text-primary);
            line-height: 1.6;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            max-width: 800px;
            padding: 3rem 2rem;
            text-align: center;
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 20px;
            backdrop-filter: blur(20px);
        }
        .logo {
            font-size: 3rem;
            font-weight: 700;
            background: var(--primary-gradient);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 1rem;
        }
        .description {
            font-size: 1.2rem;
            color: var(--text-secondary);
            margin-bottom: 2rem;
        }
        .divisions {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-top: 2rem;
        }
        .division-card {
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 1.5rem;
            text-decoration: none;
            color: var(--text-primary);
            transition: transform 0.3s ease;
        }
        .division-card:hover {
            transform: translateY(-5px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">OBINexus</div>
        <p class="description">Connection through technology - modular ecosystem documentation</p>
        
        <div class="divisions">
            <a href="docs/computing/" class="division-card">
                <h3>⚡ Computing</h3>
                <p>Development tools & architectures</p>
            </a>
            <a href="docs/publishing/" class="division-card">
                <h3>📚 Publishing</h3>
                <p>Technical documentation & narratives</p>
            </a>
            <a href="docs/uche-nnamdi/" class="division-card">
                <h3>👗 UCHE Nnamdi</h3>
                <p>Cultural fashion & tech fusion</p>
            </a>
        </div>
        
        <p style="margin-top: 2rem; color: var(--text-secondary); font-size: 0.9rem;">
            &copy; 2025 OBINexus. Documentation portal hosted via GitHub Pages.
        </p>
    </div>
</body>
</html>
EOF
fi

# Phase 2: Create _config.yml
if [[ ! -f "_config.yml" ]]; then
    echo "Creating Jekyll configuration..."
    cat > _config.yml << 'EOF'
title: "OBINexus Documentation Portal"
description: "Connection through technology - modular ecosystem documentation"
url: "https://obinenxus.github.io"
baseurl: "/obinexus"

markdown: kramdown
highlighter: rouge
plugins:
  - jekyll-feed
  - jekyll-sitemap
  - jekyll-seo-tag

exclude:
  - README.md
  - scripts/
  - .github/
  - "*.sh"
EOF
fi

# Phase 3: Create docs directory structure
echo "[DEPLOY] Creating docs structure..."
mkdir -p docs/{computing,publishing,uche-nnamdi}/projects

# Create division index files
for division in computing publishing uche-nnamdi; do
    div_title="$division"
    div_icon="⚡"
    case $division in
        "computing") div_title="Computing"; div_icon="⚡" ;;
        "publishing") div_title="Publishing"; div_icon="📚" ;;
        "uche-nnamdi") div_title="UCHE Nnamdi"; div_icon="👗" ;;
    esac
    
    cat > "docs/${division}/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>OBINexus ${div_title}</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; background: #0a0f1c; color: #fff; padding: 2rem; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { text-align: center; margin-bottom: 3rem; }
        .icon { font-size: 4rem; margin-bottom: 1rem; }
        .title { font-size: 2.5rem; margin-bottom: 1rem; }
        .description { font-size: 1.1rem; color: #a0a0a0; }
        .back-link { 
            display: inline-block; 
            margin-top: 2rem; 
            color: #4facfe; 
            text-decoration: none; 
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="icon">${div_icon}</div>
            <h1 class="title">${div_title} Division</h1>
            <p class="description">Documentation and resources for ${div_title,,} projects</p>
        </div>
        
        <div style="text-align: center;">
            <p>Project documentation will be available here soon.</p>
            <a href="../../" class="back-link">← Back to Main Portal</a>
        </div>
    </div>
</body>
</html>
EOF
done

# Phase 4: Create assets directory
mkdir -p assets/{css,js,images}

echo "
=== DEPLOYMENT READY ===
1. Commit these files to your repository:
   git add .
   git commit -m 'Initial GitHub Pages setup'
   git push origin main

2. Enable GitHub Pages in repository settings:
   - Go to Settings > Pages
   - Source: Deploy from branch
   - Branch: main (root)
   - Save

3. Your site will be live at:
   https://obinenxus.github.io/obinexus

4. Custom domain setup (optional):
   - Add CNAME file with your domain
   - Configure DNS in your domain registrar
"
