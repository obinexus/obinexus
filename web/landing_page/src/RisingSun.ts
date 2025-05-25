/**
 * RisingSun.ts
 * WebGL-based hemisphere visualization for OBINexus landing page
 */

import { createShader, createProgram, createBuffer } from '../utils/webgl';

export interface RisingSunOptions {
  containerId: string;  // ID of the container element
  radius?: number;      // Radius of the hemisphere
  detail?: number;      // Level of detail (segments)
  color?: string;       // Main color (will be converted to RGB values)
  speed?: number;       // Rotation speed
}

export class RisingSun {
  private container: HTMLElement;
  private canvas: HTMLCanvasElement;
  private gl: WebGLRenderingContext | null;
  private program: WebGLProgram | null = null;
  
  // Attributes and uniforms
  private positionAttributeLocation: number = -1;
  private colorUniformLocation: WebGLUniformLocation | null = null;
  private matrixUniformLocation: WebGLUniformLocation | null = null;
  
  // Buffers
  private positionBuffer: WebGLBuffer | null = null;
  private indexBuffer: WebGLBuffer | null = null;
  
  // Configuration
  private radius: number;
  private detail: number;
  private color: [number, number, number, number]; // RGBA
  private speed: number;
  
  // Animation state
  private rotation: number = 0;
  private animationFrame: number = 0;
  
  // Geometry data
  private vertices: number[] = [];
  private indices: number[] = [];
  
  constructor(options: RisingSunOptions) {
    // Get container element
    this.container = document.getElementById(options.containerId) || document.body;
    
    // Set configuration with defaults
    this.radius = options.radius || 200;
    this.detail = options.detail || 20;  // Higher detail than original for smoother curves
    this.color = this.parseColor(options.color || '#F71735');
    this.speed = options.speed || 0.01;
    
    // Create canvas element
    this.canvas = document.createElement('canvas');
    this.canvas.width = this.container.clientWidth || 800;
    this.canvas.height = this.container.clientHeight || 600;
    this.canvas.setAttribute('aria-label', 'OBINexus Rising Sun - decorative animation');
    this.canvas.setAttribute('role', 'img');
    this.container.appendChild(this.canvas);
    
    // Get WebGL context
    this.gl = this.canvas.getContext('webgl', { 
      alpha: true,
      antialias: true 
    });
    
    if (!this.gl) {
      console.error('WebGL not supported in this browser');
      return;
    }
    
    // Initialize WebGL
    this.initWebGL();
    
    // Generate geometry
    this.generateGeometry();
    
    // Start animation
    this.startAnimation();
    
    // Handle resize events
    window.addEventListener('resize', this.handleResize.bind(this));
  }
  
  /**
   * Initialize WebGL context, shaders, and programs
   */
  private initWebGL(): void {
    if (!this.gl) return;
    
    // Create shader program
    const vertexShaderSource = `
      attribute vec4 a_position;
      uniform mat4 u_matrix;
      varying float v_height;
      
      void main() {
        // Pass the height to the fragment shader for gradient coloring
        v_height = a_position.y;
        
        // Apply transformation matrix
        gl_Position = u_matrix * a_position;
      }
    `;
    
    const fragmentShaderSource = `
      precision mediump float;
      uniform vec4 u_color;
      varying float v_height;
      
      void main() {
        // Create a gradient effect based on the height
        float normalizedHeight = (v_height + 1.0) / 2.0;
        vec4 gradientColor = mix(u_color * 0.5, u_color, normalizedHeight);
        
        // Apply a slight fade at the edges
        float distanceFromCenter = length(gl_PointCoord - 0.5);
        float alpha = smoothstep(0.5, 0.45, distanceFromCenter);
        
        gl_FragColor = vec4(gradientColor.rgb, gradientColor.a * alpha);
      }
    `;
    
    // Create shaders
    const vertexShader = createShader(this.gl, this.gl.VERTEX_SHADER, vertexShaderSource);
    const fragmentShader = createShader(this.gl, this.gl.FRAGMENT_SHADER, fragmentShaderSource);
    
    if (!vertexShader || !fragmentShader) {
      console.error('Failed to create shaders');
      return;
    }
    
    // Create program
    this.program = createProgram(this.gl, vertexShader, fragmentShader);
    
    if (!this.program) {
      console.error('Failed to create program');
      return;
    }
    
    // Get attribute and uniform locations
    this.positionAttributeLocation = this.gl.getAttribLocation(this.program, 'a_position');
    this.colorUniformLocation = this.gl.getUniformLocation(this.program, 'u_color');
    this.matrixUniformLocation = this.gl.getUniformLocation(this.program, 'u_matrix');
    
    // Create buffers
    this.positionBuffer = this.gl.createBuffer();
    this.indexBuffer = this.gl.createBuffer();
    
    // Set clear color
    this.gl.clearColor(0, 0, 0, 0);
    
    // Enable alpha blending
    this.gl.enable(this.gl.BLEND);
    this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA);
  }
  
  /**
   * Generate hemisphere geometry with the specified detail level
   */
  private generateGeometry(): void {
    this.vertices = [];
    this.indices = [];
    
    // Add center vertex at the bottom of hemisphere
    this.vertices.push(0, 0, 0);
    
    // Generate vertices in a hemisphere pattern
    for (let row = 1; row <= this.detail; row++) {
      const phi = (Math.PI / 2) * (row / this.detail);
      const rowRadius = this.radius * Math.cos(phi);
      const y = this.radius * Math.sin(phi);
      
      for (let col = 0; col < this.detail * 2; col++) {
        const theta = (Math.PI * 2 * col) / (this.detail * 2);
        const x = rowRadius * Math.cos(theta);
        const z = rowRadius * Math.sin(theta);
        
        this.vertices.push(x, y, z);
      }
    }
    
    // Generate indices for triangles
    // Connect to center point for the bottom row
    for (let col = 0; col < this.detail * 2; col++) {
      const nextCol = (col + 1) % (this.detail * 2);
      this.indices.push(
        0,
        col + 1,
        nextCol + 1
      );
    }
    
    // Connect rest of the rows
    for (let row = 0; row < this.detail - 1; row++) {
      for (let col = 0; col < this.detail * 2; col++) {
        const nextCol = (col + 1) % (this.detail * 2);
        
        const currRowStart = 1 + row * this.detail * 2;
        const nextRowStart = 1 + (row + 1) * this.detail * 2;
        
        this.indices.push(
          currRowStart + col,
          nextRowStart + col,
          nextRowStart + nextCol
        );
        
        this.indices.push(
          currRowStart + col,
          nextRowStart + nextCol,
          currRowStart + nextCol
        );
      }
    }
    
    // Upload geometry data to GPU
    this.uploadGeometry();
  }
  
  /**
   * Upload the geometry data to GPU buffers
   */
  private uploadGeometry(): void {
    if (!this.gl || !this.positionBuffer || !this.indexBuffer) return;
    
    // Upload position data
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.positionBuffer);
    this.gl.bufferData(
      this.gl.ARRAY_BUFFER,
      new Float32Array(this.vertices),
      this.gl.STATIC_DRAW
    );
    
    // Upload index data
    this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, this.indexBuffer);
    this.gl.bufferData(
      this.gl.ELEMENT_ARRAY_BUFFER,
      new Uint16Array(this.indices),
      this.gl.STATIC_DRAW
    );
  }
  
  /**
   * Start the animation loop
   */
  private startAnimation(): void {
    this.animate();
  }
  
  /**
   * Animation loop
   */
  private animate(): void {
    this.render();
    this.rotation += this.speed;
    this.animationFrame = requestAnimationFrame(this.animate.bind(this));
  }
  
  /**
   * Render the scene
   */
  private render(): void {
    if (!this.gl || !this.program) return;
    
    // Resize canvas to match container
    if (this.canvas.width !== this.container.clientWidth ||
        this.canvas.height !== this.container.clientHeight) {
      this.handleResize();
    }
    
    // Clear canvas
    this.gl.viewport(0, 0, this.gl.canvas.width, this.gl.canvas.height);
    this.gl.clear(this.gl.COLOR_BUFFER_BIT | this.gl.DEPTH_BUFFER_BIT);
    
    // Use our shader program
    this.gl.useProgram(this.program);
    
    // Set up attributes
    this.gl.enableVertexAttribArray(this.positionAttributeLocation);
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.positionBuffer);
    this.gl.vertexAttribPointer(
      this.positionAttributeLocation,
      3,          // 3 components per vertex (x, y, z)
      this.gl.FLOAT,
      false,
      0,
      0
    );
    
    // Set uniforms
    if (this.colorUniformLocation) {
      this.gl.uniform4fv(this.colorUniformLocation, this.color);
    }
    
    // Create transformation matrix
    // This is a simplified approach - in a real app, use a matrix library
    const aspect = this.gl.canvas.width / this.gl.canvas.height;
    const projectionMatrix = this.perspective(45 * Math.PI / 180, aspect, 0.1, 2000);
    const modelViewMatrix = this.createModelViewMatrix();
    
    // Combine matrices
    const mvpMatrix = this.multiplyMatrices(projectionMatrix, modelViewMatrix);
    
    // Set matrix uniform
    if (this.matrixUniformLocation) {
      this.gl.uniformMatrix4fv(this.matrixUniformLocation, false, mvpMatrix);
    }
    
    // Draw the hemisphere
    this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, this.indexBuffer);
    this.gl.drawElements(
      this.gl.TRIANGLES,
      this.indices.length,
      this.gl.UNSIGNED_SHORT,
      0
    );
  }
  
  /**
   * Create model-view matrix with current rotation
   */
  private createModelViewMatrix(): number[] {
    // Start with identity matrix
    const matrix = [
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    ];
    
    // Apply rotations
    this.rotateY(matrix, this.rotation);
    this.rotateX(matrix, Math.PI / 6); // Tilt slightly
    
    // Apply translation to center the hemisphere
    this.translate(matrix, 0, 0, -this.radius * 2.5);
    
    return matrix;
  }
  
  /**
   * Handle window resize events
   */
  private handleResize(): void {
    if (!this.gl) return;
    
    // Update canvas size
    this.canvas.width = this.container.clientWidth || 800;
    this.canvas.height = this.container.clientHeight || 600;
    
    // Update viewport
    this.gl.viewport(0, 0, this.canvas.width, this.canvas.height);
  }
  
  /**
   * Stop animation and clean up resources
   */
  public dispose(): void {
    // Stop animation
    cancelAnimationFrame(this.animationFrame);
    
    // Remove event listeners
    window.removeEventListener('resize', this.handleResize.bind(this));
    
    // Remove canvas from DOM
    if (this.canvas.parentNode) {
      this.canvas.parentNode.removeChild(this.canvas);
    }
    
    // Clean up WebGL resources
    if (this.gl) {
      this.gl.deleteProgram(this.program);
      this.gl.deleteBuffer(this.positionBuffer);
      this.gl.deleteBuffer(this.indexBuffer);
    }
  }
  
  /**
   * Parse color string to RGBA array
   */
  private parseColor(color: string): [number, number, number, number] {
    const canvas = document.createElement('canvas');
    canvas.width = 1;
    canvas.height = 1;
    const ctx = canvas.getContext('2d');
    
    if (!ctx) {
      return [1, 0, 0, 1]; // Default to red if parsing fails
    }
    
    ctx.fillStyle = color;
    ctx.fillRect(0, 0, 1, 1);
    const data = ctx.getImageData(0, 0, 1, 1).data;
    
    return [
      data[0] / 255,
      data[1] / 255,
      data[2] / 255,
      data[3] / 255
    ];
  }
  
  // Matrix utility functions (simplified)
  // In a real application, use a matrix library like gl-matrix
  
  /**
   * Create perspective projection matrix
   */
  private perspective(fov: number, aspect: number, near: number, far: number): number[] {
    const f = Math.tan(Math.PI * 0.5 - 0.5 * fov);
    const rangeInv = 1.0 / (near - far);
    
    return [
      f / aspect, 0, 0, 0,
      0, f, 0, 0,
      0, 0, (near + far) * rangeInv, -1,
      0, 0, near * far * rangeInv * 2, 0
    ];
  }
  
  /**
   * Multiply two 4x4 matrices
   */
  private multiplyMatrices(a: number[], b: number[]): number[] {
    const result = [];
    
    for (let i = 0; i < 4; i++) {
      for (let j = 0; j < 4; j++) {
        let sum = 0;
        for (let k = 0; k < 4; k++) {
          sum += a[i * 4 + k] * b[k * 4 + j];
        }
        result[i * 4 + j] = sum;
      }
    }
    
    return result;
  }
  
  /**
   * Rotate matrix around X axis
   */
  private rotateX(matrix: number[], angle: number): void {
    const c = Math.cos(angle);
    const s = Math.sin(angle);
    
    const a10 = matrix[4];
    const a11 = matrix[5];
    const a12 = matrix[6];
    const a13 = matrix[7];
    const a20 = matrix[8];
    const a21 = matrix[9];
    const a22 = matrix[10];
    const a23 = matrix[11];
    
    matrix[4] = a10 * c + a20 * s;
    matrix[5] = a11 * c + a21 * s;
    matrix[6] = a12 * c + a22 * s;
    matrix[7] = a13 * c + a23 * s;
    matrix[8] = a20 * c - a10 * s;
    matrix[9] = a21 * c - a11 * s;
    matrix[10] = a22 * c - a12 * s;
    matrix[11] = a23 * c - a13 * s;
  }
  
  /**
   * Rotate matrix around Y axis
   */
  private rotateY(matrix: number[], angle: number): void {
    const c = Math.cos(angle);
    const s = Math.sin(angle);
    
    const a00 = matrix[0];
    const a01 = matrix[1];
    const a02 = matrix[2];
    const a03 = matrix[3];
    const a20 = matrix[8];
    const a21 = matrix[9];
    const a22 = matrix[10];
    const a23 = matrix[11];
    
    matrix[0] = a00 * c - a20 * s;
    matrix[1] = a01 * c - a21 * s;
    matrix[2] = a02 * c - a22 * s;
    matrix[3] = a03 * c - a23 * s;
    matrix[8] = a00 * s + a20 * c;
    matrix[9] = a01 * s + a21 * c;
    matrix[10] = a02 * s + a22 * c;
    matrix[11] = a03 * s + a23 * c;
  }
  
  /**
   * Translate matrix
   */
  private translate(matrix: number[], x: number, y: number, z: number): void {
    matrix[12] += matrix[0] * x + matrix[4] * y + matrix[8] * z;
    matrix[13] += matrix[1] * x + matrix[5] * y + matrix[9] * z;
    matrix[14] += matrix[2] * x + matrix[6] * y + matrix[10] * z;
    matrix[15] += matrix[3] * x + matrix[7] * y + matrix[11] * z;
  }
}
