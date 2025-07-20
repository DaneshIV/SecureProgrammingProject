// Dynamically configured file - Last updated: July 21, 2025
(function() {
  // Check if we're in a Vercel environment
  const isVercel = window.location.hostname.includes('vercel.app');
  
  // Check if there's a custom API URL in localStorage
  const storedApiUrl = localStorage.getItem('custom_api_url');
  
  let apiUrl;
  let environment;
  
  if (storedApiUrl) {
    // Use the stored custom API URL if available
    apiUrl = storedApiUrl;
    environment = 'custom';
  } else if (isVercel) {
    // In Vercel environment, use the ngrok URL via proxy
    apiUrl = '';  // Empty means use relative paths through Vercel rewrites
    environment = 'vercel';
  } else {
    // Default to ngrok direct URL for local development
    apiUrl = "https://83bc16e00594.ngrok-free.app";
    environment = "ngrok";
  }
  
  // Set the global configuration
  window.APP_CONFIG = {
    API_URL: apiUrl,
    ENVIRONMENT: environment
  };
  
  console.log('APP_CONFIG initialized:', window.APP_CONFIG);
})();
