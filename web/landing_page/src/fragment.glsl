// fragment.glsl - Fragment shader for OBINexus Rising Sun

precision mediump float;

// Input from vertex shader
varying vec3 v_normal;
varying vec2 v_texcoord;
varying float v_height;
varying vec3 v_position;

// Uniform variables
uniform vec4 u_baseColor;
uniform float u_time;
uniform float u_opacity;
uniform vec3 u_lightPosition;

// Lighting calculations
vec3 calculateLighting(vec3 normal, vec3 position, vec3 lightPos, vec3 baseColor) {
    // Normalize vectors
    vec3 N = normalize(normal);
    vec3 L = normalize(lightPos - position);
    
    // Ambient light component
    float ambientStrength = 0.3;
    vec3 ambient = ambientStrength * baseColor;
    
    // Diffuse light component
    float diff = max(dot(N, L), 0.0);
    vec3 diffuse = diff * baseColor;
    
    // Specular light component
    float specularStrength = 0.5;
    vec3 viewDir = normalize(-position); // Assuming view direction is from origin
    vec3 reflectDir = reflect(-L, N);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
    vec3 specular = specularStrength * spec * vec3(1.0, 1.0, 1.0);
    
    // Combine all lighting components
    return ambient + diffuse + specular;
}

// OBINexus color theme
vec3 getThemeColor(float height, float time) {
    // Primary color: #F71735 (red)
    vec3 primaryColor = vec3(0.968, 0.09, 0.208);
    
    // Secondary color: #2c5282 (blue)
    vec3 secondaryColor = vec3(0.173, 0.322, 0.51);
    
    // Accent color: subtle golden glow
    vec3 accentColor = vec3(1.0, 0.8, 0.2);
    
    // Normalize height to 0-1 range
    float normalizedHeight = (height + 1.0) * 0.5;
    
    // Create a gradient based on height
    vec3 baseColor = mix(secondaryColor, primaryColor, normalizedHeight);
    
    // Add pulsing accent effect
    float pulse = (sin(time * 2.0) + 1.0) * 0.5; // 0 to 1 pulsing
    float accentInfluence = pulse * 0.2 * normalizedHeight * normalizedHeight;
    
    // Mix in accent color
    return mix(baseColor, accentColor, accentInfluence);
}

// Heart-shaped glow effect
float heartGlow(vec2 texCoord, float time) {
    // Center the coordinates
    vec2 centered = texCoord * 2.0 - 1.0;
    
    // Scale coordinates
    centered *= 1.2;
    
    // Apply heart curve math (simplified heart equation)
    float x = centered.x;
    float y = centered.y;
    
    // Heart equation
    float heart = pow(x*x + y*y - 1.0, 3.0) - x*x*y*y*y;
    
    // Animating pulse
    float pulse = (sin(time * 1.5) + 1.0) * 0.5; // 0 to 1 pulsing
    
    // Create glow with animated radius
    float radius = 0.15 + 0.05 * pulse;
    float glowStrength = smoothstep(radius, radius * 0.5, heart);
    
    return glowStrength * 0.5; // Reduce intensity
}

void main() {
    // Get base color from theme
    vec3 baseColor = getThemeColor(v_height, u_time);
    
    // Calculate lighting
    vec3 litColor = calculateLighting(v_normal, v_position, u_lightPosition, baseColor);
    
    // Add heart glow effect
    float glow = heartGlow(v_texcoord, u_time);
    vec3 glowColor = mix(litColor, vec3(1.0, 0.3, 0.3), glow);
    
    // Apply rim lighting for edge glow
    vec3 viewDirection = normalize(-v_position);
    float rimFactor = 1.0 - max(dot(viewDirection, normalize(v_normal)), 0.0);
    rimFactor = pow(rimFactor, 3.0);
    
    // Mix rim lighting with base color
    vec3 finalColor = mix(glowColor, vec3(1.0, 0.5, 0.5), rimFactor * 0.5);
    
    // Apply final opacity
    float finalOpacity = u_opacity;
    
    // Fade edges for smoother rendering
    float edgeFade = smoothstep(0.9, 1.0, 1.0 - rimFactor);
    finalOpacity *= edgeFade;
    
    // Output final color with opacity
    gl_FragColor = vec4(finalColor, finalOpacity);
}

