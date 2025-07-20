// Enhanced global error handler for cross-origin and API connectivity issues
(function() {
  // Track API call attempts to implement progressive fallback strategy
  let apiCallAttempts = {};
  const NGROK_URL = 'https://83bc16e00594.ngrok-free.app';
  
  // Set up global error handler
  window.addEventListener('error', function(event) {
    console.error('Global error caught:', event.error || event.message);
    
    // Check if it's a CORS error or network error
    if (event.message && (
        event.message.includes('access-control-allow-origin') || 
        event.message.includes('CORS') ||
        event.message.includes('cross-origin') ||
        event.message.includes('Unexpected token') ||
        event.message.includes('NetworkError') ||
        event.message.includes('Failed to fetch') ||
        event.message.includes('Network request failed')
      )) {
      console.error('API connectivity error detected');
      
      // Try to auto-fix the configuration
      if (window.APP_CONFIG) {
        console.log('Current APP_CONFIG:', window.APP_CONFIG);
        
        // Determine if we're on Vercel
        const isVercel = window.location.hostname.includes('vercel.app');
        
        // Apply progressive fix strategy
        if (isVercel) {
          // First try using empty API_URL (relative paths through Vercel rewrites)
          if (window.APP_CONFIG.API_URL !== '') {
            window.APP_CONFIG.API_URL = '';
            window.APP_CONFIG.ENVIRONMENT = 'vercel';
          } 
          // If that failed, try using direct ngrok URL
          else if (window.APP_CONFIG.API_URL !== NGROK_URL) {
            window.APP_CONFIG.API_URL = NGROK_URL;
            window.APP_CONFIG.ENVIRONMENT = 'vercel-ngrok';
            
            // Store this in localStorage for persistence
            localStorage.setItem('custom_api_url', NGROK_URL);
          }
          
          console.log('Auto-fixed config for Vercel environment:', window.APP_CONFIG);
          
          // Show a notification
          const notificationId = 'api-fix-notification';
          if (!document.getElementById(notificationId)) {
            const notification = document.createElement('div');
            notification.id = notificationId;
            notification.style.position = 'fixed';
            notification.style.top = '10px';
            notification.style.left = '50%';
            notification.style.transform = 'translateX(-50%)';
            notification.style.backgroundColor = '#f8d7da';
            notification.style.color = '#721c24';
            notification.style.padding = '10px';
            notification.style.borderRadius = '5px';
            notification.style.zIndex = '9999';
            notification.style.boxShadow = '0 2px 10px rgba(0,0,0,0.2)';
            notification.innerHTML = `
              Detected API connectivity issue. Configuration has been updated.<br>
              <div style="margin-top:8px;">
                <a href="javascript:location.reload()" style="color:#721c24;text-decoration:underline;margin-right:15px;">Reload page</a>
                <a href="vercel-test.html" style="color:#721c24;text-decoration:underline;">Run diagnostics</a>
              </div>
            `;
            document.body.appendChild(notification);
            
            // Auto-remove after 10 seconds
            setTimeout(() => {
              if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
              }
            }, 10000);
          }
        }
      }
    }
  });
  
  // Override fetch to implement progressive fallback strategy for API calls
  const originalFetch = window.fetch;
  window.fetch = async function(url, options = {}) {
    // Only intercept API calls
    if (typeof url === 'string' && url.includes('/api/')) {
      const isVercel = window.location.hostname.includes('vercel.app');
      
      // Generate a unique key for this API call
      const apiKey = url.split('?')[0]; // Remove query params
      
      // Initialize attempt tracking if not exists
      if (!apiCallAttempts[apiKey]) {
        apiCallAttempts[apiKey] = {
          count: 0,
          lastAttempt: Date.now()
        };
      }
      
      // Reset if last attempt was more than 5 minutes ago
      if (Date.now() - apiCallAttempts[apiKey].lastAttempt > 5 * 60 * 1000) {
        apiCallAttempts[apiKey].count = 0;
      }
      
      // Update last attempt time
      apiCallAttempts[apiKey].lastAttempt = Date.now();
      
      // Ensure options has the right structure
      options = options || {};
      options.headers = options.headers || {};
      
      // Add appropriate headers
      options.headers['Accept'] = 'application/json';
      options.headers['Origin'] = window.location.origin;
      
      // Vercel environment needs special handling
      if (isVercel) {
        console.log(`API call attempt #${apiCallAttempts[apiKey].count + 1} for ${apiKey}`);
        
        // Progressive fallback strategy based on previous failures
        if (apiCallAttempts[apiKey].count === 0) {
          // First attempt: Try with relative path (through Vercel rewrites)
          console.log('First attempt: Using relative path');
          options.mode = 'same-origin';
          
          try {
            const response = await originalFetch.call(this, url, options);
            if (response.ok) return response;
          } catch (error) {
            console.warn('First attempt failed:', error);
          }
          
          apiCallAttempts[apiKey].count++;
        }
        
        if (apiCallAttempts[apiKey].count === 1) {
          // Second attempt: Try with explicit CORS settings
          console.log('Second attempt: Using CORS mode');
          const relativeUrl = url.startsWith('/') ? url : `/${url}`;
          options.mode = 'cors';
          options.credentials = 'include';
          
          try {
            const response = await originalFetch.call(this, relativeUrl, options);
            if (response.ok) return response;
          } catch (error) {
            console.warn('Second attempt failed:', error);
          }
          
          apiCallAttempts[apiKey].count++;
        }
        
        // Final attempt: Direct ngrok URL
        console.log('Final attempt: Using direct ngrok URL');
        const endpoint = url.includes('/api/') ? url.split('/api/')[1] : url;
        const ngrokUrl = `${NGROK_URL}/api/${endpoint}`;
        
        options.mode = 'cors';
        options.credentials = 'include';
        
        // Log the final attempt
        console.log('Trying direct ngrok URL:', ngrokUrl);
        
        // Update config for future calls
        window.APP_CONFIG.API_URL = NGROK_URL;
        window.APP_CONFIG.ENVIRONMENT = 'vercel-ngrok';
        localStorage.setItem('custom_api_url', NGROK_URL);
        
        return originalFetch.call(this, ngrokUrl, options);
      }
    }
    
    // Default behavior for non-API calls or non-Vercel environments
    return originalFetch.call(this, url, options);
  };
  
  console.log('Enhanced global error handler and API fallback system installed');
})();
