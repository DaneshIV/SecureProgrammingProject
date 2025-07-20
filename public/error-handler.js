// Global error handler for cross-origin issues
(function() {
  // Set up global error handler
  window.addEventListener('error', function(event) {
    console.error('Global error caught:', event.error);
    
    // Check if it's a CORS error
    if (event.message && (
        event.message.includes('access-control-allow-origin') || 
        event.message.includes('CORS') ||
        event.message.includes('cross-origin') ||
        event.message.includes('Unexpected token')
      )) {
      console.error('CORS error detected');
      
      // Try to auto-fix the configuration
      if (window.APP_CONFIG) {
        console.log('Current APP_CONFIG:', window.APP_CONFIG);
        
        // Determine if we're on Vercel
        const isVercel = window.location.hostname.includes('vercel.app');
        if (isVercel && (!window.APP_CONFIG.API_URL || !window.APP_CONFIG.API_URL.includes('ngrok'))) {
          window.APP_CONFIG.API_URL = 'https://83bc16e00594.ngrok-free.app';
          window.APP_CONFIG.ENVIRONMENT = 'vercel-ngrok';
          console.log('Auto-fixed config for Vercel environment:', window.APP_CONFIG);
          
          // Show a notification
          const notification = document.createElement('div');
          notification.style.position = 'fixed';
          notification.style.top = '10px';
          notification.style.left = '50%';
          notification.style.transform = 'translateX(-50%)';
          notification.style.backgroundColor = '#f8d7da';
          notification.style.color = '#721c24';
          notification.style.padding = '10px';
          notification.style.borderRadius = '5px';
          notification.style.zIndex = '9999';
          notification.innerHTML = 'Detected CORS issue. Configuration auto-fixed. <a href="javascript:location.reload()">Reload page</a>';
          document.body.appendChild(notification);
        }
      }
    }
  });
  
  // Override fetch to add CORS headers
  const originalFetch = window.fetch;
  window.fetch = function(url, options = {}) {
    // If it's an API call and we're on Vercel
    if (typeof url === 'string' && 
        (url.includes('/api/') || url.includes('ngrok')) && 
        window.location.hostname.includes('vercel.app')) {
      
      // Ensure options has the right structure
      options = options || {};
      options.headers = options.headers || {};
      
      // Add CORS headers
      options.mode = 'cors';
      options.credentials = 'include';
      options.headers['Accept'] = 'application/json';
      options.headers['Origin'] = window.location.origin;
      
      // Log the fetch for debugging
      console.log('Enhanced fetch call:', url, options);
    }
    
    return originalFetch.call(this, url, options);
  };
  
  console.log('Global error handler and fetch interceptor installed');
})();
