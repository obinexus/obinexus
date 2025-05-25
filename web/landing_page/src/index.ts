/**
 * index.ts
 * Main entry point for the OBINexus landing page
 */

import { RisingSun } from './core/components/RisingSun';
import './core/styles/main.scss';

// Wait for DOM to load
document.addEventListener('DOMContentLoaded', () => {
  // Initialize the Rising Sun WebGL component
  const risingSun = new RisingSun({
    containerId: 'rising-sun-container',
    radius: window.innerWidth > 768 ? 300 : 200, // Responsive radius
    detail: window.innerWidth > 768 ? 30 : 20,    // Responsive detail level
    color: '#F71735',                             // OBINexus accent color
    speed: 0.005                                  // Rotation speed
  });

  console.log('OBINexus Rising Sun initialized');

  // Add helper text for screen readers
  const srHelper = document.createElement('div');
  srHelper.className = 'sr-only';
  srHelper.textContent = 'This page contains a decorative WebGL animation of a rising sun, representing the OBINexus heart logo.';
  document.body.appendChild(srHelper);

  // Handle smooth scrolling for navigation links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      e.preventDefault();
      
      const targetId = this.getAttribute('href');
      if (!targetId) return;
      
      const targetElement = document.querySelector(targetId);
      if (!targetElement) return;
      
      window.scrollTo({
        top: targetElement.getBoundingClientRect().top + window.pageYOffset,
        behavior: 'smooth'
      });
    });
  });

  // Set up intersection observer for animation triggering
  const observerOptions = {
    root: null,
    rootMargin: '0px',
    threshold: 0.1
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('animate-in');
      }
    });
  }, observerOptions);

  // Observe elements that should animate on scroll
  document.querySelectorAll('.nav-button, .content-overlay').forEach(el => {
    observer.observe(el);
  });

  // Handle keyboard navigation
  document.addEventListener('keydown', (e) => {
    // If Tab is pressed, make sure interactive elements are visible
    if (e.key === 'Tab') {
      document.body.classList.add('keyboard-navigation');
    }
  });

  // Remove keyboard navigation class when mouse is used
  document.addEventListener('mousedown', () => {
    document.body.classList.remove('keyboard-navigation');
  });

  // Update the current year in the footer
  const currentYearElement = document.getElementById('current-year');
  if (currentYearElement) {
    currentYearElement.textContent = new Date().getFullYear().toString();
  }
});

