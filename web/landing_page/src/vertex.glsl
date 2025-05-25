// vertex.glsl - Vertex shader for OBINexus Rising Sun

attribute vec3 a_position;
attribute vec3 a_normal;
attribute vec2 a_texcoord;

uniform mat4 u_modelViewMatrix;
uniform mat4 u_projectionMatrix;
uniform float u_time;

varying vec3 v_normal;
varying vec2 v_texcoord;
varying float v_height;
varying vec3 v_position;

// Heart-shaped animation for vertices
vec3 heartAnimation(vec3 position, float time) {
    // Calculate the normalized height for the heart effect
    float normalizedHeight = (position.y + 1.0) * 0.5;
    
    // Small pulsing effect
    float pulseAmount = sin(time * 2.0) * 0.05 * normalizedHeight;
    
    // Apply slight heart-shaped distortion
    vec3 adjusted = position;
    
    // Heart curve influence increases as we go up the hemisphere
    float heartInfluence = normalizedHeight * normalizedHeight;
    
    // Apply squeezing from top/sides
    adjusted.x *= 1.0 + pulseAmount + (normalizedHeight * 0.2);
    adjusted.z *= 1.0 + pulseAmount + (normalizedHeight * 0.2);
    
    // Apply heart-shaped dent at top
    if (normalizedHeight > 0.8) {
        float topFactor = (normalizedHeight - 0.8) / 0.2;
        float xFactor = position.x * 3.0;
        adjusted.y -= topFactor * abs(xFactor) * 0.05;
    }
    
    return adjusted;
}

void main() {
    // Apply heart animation to vertex position
    vec3 animatedPosition = heartAnimation(a_position, u_time);
    
    // Transform vertex position
    v_position = (u_modelViewMatrix * vec4(animatedPosition, 1.0)).xyz;
    gl_Position = u_projectionMatrix * u_modelViewMatrix * vec4(animatedPosition, 1.0);
    
    // Pass normal vector to fragment shader
    // We should properly transform the normal using the normal matrix,
    // but for simplicity, we'll just use the model-view matrix
    v_normal = (u_modelViewMatrix * vec4(a_normal, 0.0)).xyz;
    
    // Pass texture coordinates to fragment shader
    v_texcoord = a_texcoord;
    
    // Pass height to fragment shader for color gradient
    v_height = animatedPosition.y;
}

