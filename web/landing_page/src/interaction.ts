/**
 * interaction.ts
 * Utility functions for handling user interactions
 */

export interface TouchDragHandler {
  onStart: (x: number, y: number) => void;
  onMove: (x: number, y: number, dx: number, dy: number) => void;
  onEnd: () => void;
}

/**
 * Sets up mouse and touch drag interactions for an element
 */
export function setupDragInteraction(
  element: HTMLElement,
  handler: TouchDragHandler
): () => void {
  let isDragging = false;
  let lastX = 0;
  let lastY = 0;
  
  // Mouse events
  const onMouseDown = (e: MouseEvent) => {
    isDragging = true;
    lastX = e.clientX;
    lastY = e.clientY;
    handler.onStart(lastX, lastY);
    
    // Prevent text selection during drag
    e.preventDefault();
  };
  
  const onMouseMove = (e: MouseEvent) => {
    if (!isDragging) return;
    
    const x = e.clientX;
    const y = e.clientY;
    const dx = x - lastX;
    const dy = y - lastY;
    
    handler.onMove(x, y, dx, dy);
    
    lastX = x;
    lastY = y;
  };
  
  const onMouseUp = () => {
    if (isDragging) {
      isDragging = false;
      handler.onEnd();
    }
  };
  
  // Touch events
  const onTouchStart = (e: TouchEvent) => {
    if (e.touches.length !== 1) return;
    
    isDragging = true;
    lastX = e.touches[0].clientX;
    lastY = e.touches[0].clientY;
    handler.onStart(lastX, lastY);
    
    // Prevent scrolling during drag
    e.preventDefault();
  };
  
  const onTouchMove = (e: TouchEvent) => {
    if (!isDragging || e.touches.length !== 1) return;
    
    const x = e.touches[0].clientX;
    const y = e.touches[0].clientY;
    const dx = x - lastX;
    const dy = y - lastY;
    
    handler.onMove(x, y, dx, dy);
    
    lastX = x;
    lastY = y;
  };
  
  const onTouchEnd = () => {
    if (isDragging) {
      isDragging = false;
      handler.onEnd();
    }
  };
  
  // Add event listeners
  element.addEventListener('mousedown', onMouseDown);
  window.addEventListener('mousemove', onMouseMove);
  window.addEventListener('mouseup', onMouseUp);
  
  element.addEventListener('touchstart', onTouchStart, { passive: false });
  element.addEventListener('touchmove', onTouchMove, { passive: false });
  element.addEventListener('touchend', onTouchEnd);
  
  // Return cleanup function
  return () => {
    element.removeEventListener('mousedown', onMouseDown);
    window.removeEventListener('mousemove', onMouseMove);
    window.removeEventListener('mouseup', onMouseUp);
    
    element.removeEventListener('touchstart', onTouchStart);
    element.removeEventListener('touchmove', onTouchMove);
    element.removeEventListener('touchend', onTouchEnd);
  };
}

/**
 * Creates a debounced version of a function
 * @param func Function to debounce
 * @param wait Delay in milliseconds
 */
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: number | null = null;
  
  return function(...args: Parameters<T>): void {
    const later = () => {
      timeout = null;
      func(...args);
    };
    
    if (timeout !== null) {
      clearTimeout(timeout);
    }
    
    timeout = window.setTimeout(later, wait);
  };
}

/**
 * Creates a throttled version of a function
 * @param func Function to throttle
 * @param limit Limit in milliseconds
 */
export function throttle<T extends (...args: any[]) => any>(
  func: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle = false;
  let lastArgs: Parameters<T> | null = null;
  
  return function(...args: Parameters<T>): void {
    lastArgs = args;
    
    if (!inThrottle) {
      func(...lastArgs);
      inThrottle = true;
      
      setTimeout(() => {
        inThrottle = false;
        if (lastArgs !== null) {
          func(...lastArgs);
        }
      }, limit);
    }
  };
}

/**
 * Sets up keyboard controls for interactive elements
 */
export function setupKeyboardControls(
  element: HTMLElement,
  actions: Record<string, () => void>
): () => void {
  // Make element focusable if it isn't already
  if (element.tabIndex < 0) {
    element.tabIndex = 0;
  }
  
  // Add ARIA attributes for accessibility
  element.setAttribute('role', 'application');
  element.setAttribute('aria-label', 'Interactive Control');
  
  const onKeyDown = (e: KeyboardEvent) => {
    const action = actions[e.key];
    if (action) {
      action();
      e.preventDefault();
    }
  };
  
  element.addEventListener('keydown', onKeyDown);
  
  // Return cleanup function
  return () => {
    element.removeEventListener('keydown', onKeyDown);
  };
}

/**
 * Sets up a simple overlay for displaying help information
 */
export function createHelpOverlay(parent: HTMLElement, text: string): () => void {
  const overlay = document.createElement('div');
  overlay.style.position = 'absolute';
  overlay.style.top = '20px';
  overlay.style.left = '50%';
  overlay.style.transform = 'translateX(-50%)';
  overlay.style.backgroundColor = 'rgba(0,0,0,0.8)';
  overlay.style.color = 'white';
  overlay.style.padding = '10px 20px';
  overlay.style.borderRadius = '5px';
  overlay.style.zIndex = '1000';
  overlay.style.display = 'none';
  overlay.textContent = text;
  
  parent.appendChild(overlay);
  
  let visible = false;
  
  const toggleOverlay = () => {
    visible = !visible;
    overlay.style.display = visible ? 'block' : 'none';
  };
  
  // Show help overlay when ? key is pressed
  const onKeyDown = (e: KeyboardEvent) => {
    if (e.key === '?') {
      toggleOverlay();
    } else if (e.key === 'Escape' && visible) {
      toggleOverlay();
    }
  };
  
  window.addEventListener('keydown', onKeyDown);
  
  // Return cleanup function
  return () => {
    window.removeEventListener('keydown', onKeyDown);
    if (overlay.parentNode) {
      overlay.parentNode.removeChild(overlay);
    }
  };
}
