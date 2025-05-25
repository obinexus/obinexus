/**
 * OBINexus Content Discovery System
 * Automated navigation and project indexing for GitHub Pages
 * Waterfall Phase: Implementation & Testing
 */

class OBINexusContentDiscovery {
    constructor() {
        this.divisionsConfig = [
            { name: 'computing', title: 'Computing', icon: '?' },
            { name: 'publishing', title: 'Publishing', icon: '??' },
            { name: 'uche-nnamdi', title: 'UCHE Nnamdi', icon: '??' }
        ];
        this.baseUrl = window.location.origin + window.location.pathname.split('/').slice(0, -1).join('/');
    }

    /**
     * Initialize the content discovery system
     * Phase 1: Validation and structure verification
     */
    async initialize() {
        console.log('[OBINexus] Initializing content discovery system');
        
        try {
            await this.validateStructure();
            await this.generateNavigationIndex();
            await this.loadDynamicContent();
            console.log('[OBINexus] Content discovery initialization complete');
        } catch (error) {
            console.error('[OBINexus] Initialization failed:', error);
            this.fallbackToStaticContent();
        }
    }

    /**
     * Validate the expected directory structure
     * Waterfall validation phase
     */
    async validateStructure() {
        const validationResults = [];
        
        for (const division of this.divisionsConfig) {
            const divisionPath = `docs/${division.name}/`;
            const validation = await this.validateDivisionStructure(divisionPath);
            validationResults.push({ division: division.name, valid: validation });
        }
        
        console.log('[OBINexus] Structure validation results:', validationResults);
        return validationResults;
    }

    /**
     * Validate individual division structure
     */
    async validateDivisionStructure(divisionPath) {
        try {
            // Check if division index exists
            const indexResponse = await fetch(`${this.baseUrl}/${divisionPath}index.html`);
            const hasIndex = indexResponse.ok;
            
            // Check for projects directory
            const projectsResponse = await fetch(`${this.baseUrl}/${divisionPath}projects/`);
            const hasProjects = projectsResponse.ok;
            
            return { hasIndex, hasProjects, path: divisionPath };
        } catch (error) {
            console.warn(`[OBINexus] Validation failed for ${divisionPath}:`, error);
            return { hasIndex: false, hasProjects: false, path: divisionPath };
        }
    }

    /**
     * Generate dynamic navigation index
     * Phase 2: Content aggregation
     */
    async generateNavigationIndex() {
        const navigationData = {
            divisions: [],
            projects: [],
            lastUpdated: new Date().toISOString()
        };

        for (const division of this.divisionsConfig) {
            const divisionData = await this.scanDivision(division);
            navigationData.divisions.push(divisionData);
            navigationData.projects.push(...divisionData.projects);
        }

        // Store navigation data for other scripts
        window.OBINexusNavigation = navigationData;
        
        // Update navigation elements if they exist
        this.updateNavigationElements(navigationData);
        
        return navigationData;
    }

    /**
     * Scan individual division for projects and content
     */
    async scanDivision(division) {
        const divisionData = {
            ...division,
            projects: [],
            status: 'unknown'
        };

        try {
            // Attempt to load division metadata
            const metaResponse = await fetch(`${this.baseUrl}/docs/${division.name}/meta.json`);
            if (metaResponse.ok) {
                const metadata = await metaResponse.json();
                Object.assign(divisionData, metadata);
            }

            // Scan for projects (this would need server-side directory listing or manifest)
            divisionData.projects = await this.discoverProjects(division.name);
            divisionData.status = 'active';
            
        } catch (error) {
            console.warn(`[OBINexus] Failed to scan division ${division.name}:`, error);
            divisionData.status = 'error';
        }

        return divisionData;
    }

    /**
     * Discover projects within a division
     * Note: GitHub Pages doesn't support directory listing, so this uses a manifest approach
     */
    async discoverProjects(divisionName) {
        try {
            // Try to load projects manifest
            const manifestResponse = await fetch(`${this.baseUrl}/docs/${divisionName}/projects/manifest.json`);
            if (manifestResponse.ok) {
                const manifest = await manifestResponse.json();
                return manifest.projects || [];
            }

            // Fallback to hardcoded project lists for each division
            return this.getFallbackProjects(divisionName);
            
        } catch (error) {
            console.warn(`[OBINexus] Project discovery failed for ${divisionName}:`, error);
            return this.getFallbackProjects(divisionName);
        }
    }

    /**
     * Fallback project definitions (static configuration)
     */
    getFallbackProjects(divisionName) {
        const fallbackProjects = {
            'computing': [
                { name: 'riftlang', title: 'RiftLang', status: 'active' },
                { name: 'obix', title: 'OBIX', status: 'active' },
                { name: 'libpolycall', title: 'LibPolyCall', status: 'active' },
                { name: 'nlink', title: 'NLink', status: 'development' },
                { name: 'gosilang', title: 'GosiLang', status: 'development' },
                { name: 'gosi-aura', title: 'GOSI Aura', status: 'planning' }
            ],
            'publishing': [
                { name: 'how-to-rift', title: 'How to RIFT', status: 'active' },
                { name: 'bopumanimals', title: 'Bopumanimals', status: 'active' }
            ],
            'uche-nnamdi': [
                { name: 'cultural-heritage', title: 'Cultural Heritage', status: 'active' },
                { name: 'tech-fusion', title: 'Tech Fusion', status: 'development' }
            ]
        };

        return fallbackProjects[divisionName] || [];
    }

    /**
     * Load dynamic content into page elements
     * Phase 3: Content injection
     */
    async loadDynamicContent() {
        // Update project counts
        this.updateProjectCounts();
        
        // Update status indicators
        this.updateStatusIndicators();
        
        // Generate project cards if container exists
        const projectContainer = document.getElementById('project-container');
        if (projectContainer) {
            this.generateProjectCards(projectContainer);
        }

        // Update breadcrumbs
        this.updateBreadcrumbs();
    }

    /**
     * Update navigation elements with discovered content
     */
    updateNavigationElements(navigationData) {
        // Update project index links
        const projectIndexLinks = document.querySelectorAll('#project-index-link');
        projectIndexLinks.forEach(link => {
            link.href = this.generateProjectIndexUrl(navigationData);
        });

        // Update division-specific elements
        navigationData.divisions.forEach(division => {
            this.updateDivisionElements(division);
        });
    }

    /**
     * Generate project cards for division pages
     */
    generateProjectCards(container) {
        const currentDivision = this.getCurrentDivision();
        if (!currentDivision || !window.OBINexusNavigation) return;

        const divisionData = window.OBINexusNavigation.divisions.find(d => d.name === currentDivision);
        if (!divisionData) return;

        // Clear existing static content
        container.innerHTML = '';

        // Generate cards for each project
        divisionData.projects.forEach(project => {
            const card = this.createProjectCard(project, currentDivision);
            container.appendChild(card);
        });
    }

    /**
     * Create individual project card element
     */
    createProjectCard(project, divisionName) {
        const card = document.createElement('div');
        card.className = 'project-card';
        
        const statusClass = `status-${project.status || 'unknown'}`;
        
        card.innerHTML = `
            <div class="project-status ${statusClass}">${this.formatStatus(project.status)}</div>
            <h3>${project.title || project.name}</h3>
            <p>${project.description || 'Project documentation and resources.'}</p>
            <a href="projects/${project.name}/" class="division-link">View Project </a>
        `;
        
        return card;
    }

    /**
     * Utility functions
     */
    getCurrentDivision() {
        const path = window.location.pathname;
        const match = path.match(/\/docs\/([^\/]+)\//);
        return match ? match[1] : null;
    }

    formatStatus(status) {
        const statusMap = {
            'active': 'Active',
            'development': 'Development',
            'planning': 'Planning',
            'maintenance': 'Maintenance',
            'archived': 'Archived'
        };
        return statusMap[status] || 'Unknown';
    }

    updateProjectCounts() {
        if (!window.OBINexusNavigation) return;
        
        const totalProjects = window.OBINexusNavigation.projects.length;
        const projectCountElements = document.querySelectorAll('.project-count');
        
        projectCountElements.forEach(element => {
            element.textContent = totalProjects;
        });
    }

    updateStatusIndicators() {
        // Update system status based on discovered content
        const statusDot = document.querySelector('.status-dot');
        const statusText = document.querySelector('.status-badge span:last-child');
        
        if (statusDot && statusText && window.OBINexusNavigation) {
            const activeCount = window.OBINexusNavigation.divisions.filter(d => d.status === 'active').length;
            
            if (activeCount === this.divisionsConfig.length) {
                statusText.textContent = 'All Systems Operational';
                statusDot.style.backgroundColor = '#10b981';
            } else if (activeCount > 0) {
                statusText.textContent = 'Partial Systems Active';
                statusDot.style.backgroundColor = '#f59e0b';
            } else {
                statusText.textContent = 'Systems Initializing';
                statusDot.style.backgroundColor = '#6b7280';
            }
        }
    }

    updateBreadcrumbs() {
        // Enhance breadcrumb navigation with dynamic content
        const breadcrumbContainer = document.querySelector('.breadcrumb nav');
        if (!breadcrumbContainer) return;

        // Add division-specific breadcrumb enhancements
        const currentDivision = this.getCurrentDivision();
        if (currentDivision && window.OBINexusNavigation) {
            const divisionData = window.OBINexusNavigation.divisions.find(d => d.name === currentDivision);
            if (divisionData) {
                // Update breadcrumb styling or add project count
                const lastBreadcrumb = breadcrumbContainer.lastElementChild;
                if (lastBreadcrumb && divisionData.projects.length > 0) {
                    lastBreadcrumb.textContent += ` (${divisionData.projects.length} projects)`;
                }
            }
        }
    }

    generateProjectIndexUrl(navigationData) {
        // Generate URL for comprehensive project index
        return '#projects'; // Default fallback
    }

    /**
     * Fallback to static content if dynamic loading fails
     */
    fallbackToStaticContent() {
        console.log('[OBINexus] Falling back to static content');
        
        // Ensure basic functionality still works
        document.querySelectorAll('.division-card').forEach(card => {
            card.style.cursor = 'pointer';
        });
        
        // Update status to indicate fallback mode
        const statusText = document.querySelector('.status-badge span:last-child');
        if (statusText) {
            statusText.textContent = 'Documentation Portal Active (Static Mode)';
        }
    }
}

// Initialize system when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    const contentDiscovery = new OBINexusContentDiscovery();
    contentDiscovery.initialize();
});

// Export for use in other scripts
window.OBINexusContentDiscovery = OBINexusContentDiscovery;
