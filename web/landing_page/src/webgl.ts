/**
 * webgl.ts
 * Utility functions for WebGL operations
 */

/**
 * Creates and compiles a shader from source
 */
export function createShader(
  gl: WebGLRenderingContext,
  type: number,
  source: string
): WebGLShader | null {
  // Create shader
  const shader = gl.createShader(type);
  if (!shader) {
    console.error('Failed to create shader');
    return null;
  }
  
  // Set the shader source code and compile
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  
  // Check if compilation was successful
  const success = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
  if (!success) {
    console.error('Could not compile shader:', gl.getShaderInfoLog(shader));
    gl.deleteShader(shader);
    return null;
  }
  
  return shader;
}

/**
 * Creates and links a program from two shaders
 */
export function createProgram(
  gl: WebGLRenderingContext,
  vertexShader: WebGLShader,
  fragmentShader: WebGLShader
): WebGLProgram | null {
  // Create program
  const program = gl.createProgram();
  if (!program) {
    console.error('Failed to create program');
    return null;
  }
  
  // Attach shaders
  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  
  // Link program
  gl.linkProgram(program);
  
  // Check if linking was successful
  const success = gl.getProgramParameter(program, gl.LINK_STATUS);
  if (!success) {
    console.error('Could not link program:', gl.getProgramInfoLog(program));
    gl.deleteProgram(program);
    return null;
  }
  
  return program;
}

/**
 * Creates a buffer and initializes it with data
 */
export function createBuffer(
  gl: WebGLRenderingContext,
  target: number,
  data: ArrayBuffer | null,
  usage: number
): WebGLBuffer | null {
  // Create buffer
  const buffer = gl.createBuffer();
  if (!buffer) {
    console.error('Failed to create buffer');
    return null;
  }
  
  // Bind and initialize buffer
  gl.bindBuffer(target, buffer);
  if (data) {
    gl.bufferData(target, data, usage);
  }
  
  return buffer;
}

/**
 * Creates a texture and initializes it with an image
 */
export function createTexture(
  gl: WebGLRenderingContext,
  image: HTMLImageElement
): WebGLTexture | null {
  // Create texture
  const texture = gl.createTexture();
  if (!texture) {
    console.error('Failed to create texture');
    return null;
  }
  
  // Bind texture
  gl.bindTexture(gl.TEXTURE_2D, texture);
  
  // Set parameters
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  
  // Upload image data
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
  
  return texture;
}

/**
 * Creates a texture and initializes it with data
 */
export function createDataTexture(
  gl: WebGLRenderingContext,
  width: number,
  height: number,
  data: Uint8Array
): WebGLTexture | null {
  // Create texture
  const texture = gl.createTexture();
  if (!texture) {
    console.error('Failed to create texture');
    return null;
  }
  
  // Bind texture
  gl.bindTexture(gl.TEXTURE_2D, texture);
  
  // Set parameters
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  
  // Upload data
  gl.texImage2D(
    gl.TEXTURE_2D,
    0,
    gl.RGBA,
    width,
    height,
    0,
    gl.RGBA,
    gl.UNSIGNED_BYTE,
    data
  );
  
  return texture;
}

/**
 * Resizes canvas to match its CSS size
 */
export function resizeCanvasToDisplaySize(canvas: HTMLCanvasElement): boolean {
  const width = canvas.clientWidth;
  const height = canvas.clientHeight;
  
  // Check if the canvas is not the same size
  if (canvas.width !== width || canvas.height !== height) {
    // Update canvas size
    canvas.width = width;
    canvas.height = height;
    return true;
  }
  
  return false;
}

/**
 * Loads an image from a URL and returns a Promise
 */
export function loadImage(url: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = (err) => reject(err);
    image.crossOrigin = 'anonymous'; // Enable loading from other domains
    image.src = url;
  });
}

/**
 * Creates WebGL context with default settings
 */
export function createGLContext(
  canvas: HTMLCanvasElement
): WebGLRenderingContext | null {
  // Try to get WebGL context
  let gl: WebGLRenderingContext | null = null;
  
  try {
    gl = canvas.getContext('webgl', {
      alpha: true,
      antialias: true,
      depth: true,
      premultipliedAlpha: false
    });
  } catch (e) {
    console.error('WebGL context creation failed:', e);
    return null;
  }
  
  if (!gl) {
    console.error('WebGL not supported in this browser');
    return null;
  }
  
  return gl;
}
