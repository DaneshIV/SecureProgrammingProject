# API Connectivity Troubleshooting Guide

This guide will help you resolve common connectivity issues between the client and server, particularly when using ngrok.

## Quick Fixes

### "Server unavailable" in Payment History

1. **Make sure the server is running with the right configuration**:
   ```bash
   ./use-existing-ngrok.sh
   ```

2. **Reset the configuration**:
   ```bash
   ./validate-config.sh ngrok
   ```

3. **Try the test page**:
   Open [http://localhost:3000/test-api.html](http://localhost:3000/test-api.html) to run connectivity tests

## Comprehensive Troubleshooting

### Step 1: Verify Server Status

1. Run the diagnostics tool:
   ```bash
   ./diagnose.sh
   ```

2. Check API connectivity directly:
   ```bash
   ./test-api-connectivity.sh
   ```

3. Ensure the server is running and accessible at http://localhost:3000

### Step 2: Verify Configuration

1. Check config.js content:
   ```bash
   cat public/config.js
   ```

2. For ngrok mode, it should contain:
   ```javascript
   window.APP_CONFIG = {
     API_URL: "https://83bc16e00594.ngrok-free.app",
     ENVIRONMENT: "ngrok"
   };
   ```

3. Reset configuration if needed:
   ```bash
   ./validate-config.sh ngrok
   ```

### Step 3: Check CORS Configuration

1. Verify CORS settings:
   ```bash
   curl -s "http://localhost:3000/api/cors-test" | json_pp
   ```

2. Test from browser: Open http://localhost:3000/test-api.html and try CORS tests

3. Check browser console for CORS errors (F12 > Console)

### Step 4: Check Ngrok Status

1. Verify ngrok is running:
   ```bash
   curl -s "http://localhost:4040/api/tunnels" | json_pp
   ```

2. Ensure the URL in config.js matches the active ngrok URL

### Step 5: Browser Troubleshooting

1. Clear browser cache and cookies for localhost and ngrok domains
2. Try a different browser
3. Install a CORS browser extension (for testing only)
4. Check Network tab in browser dev tools for failed requests

## Common Issues and Solutions

### Invalid Ngrok URL
- **Symptom**: API requests fail with CORS errors or network errors
- **Solution**: Restart ngrok and update config.js with the new URL
  ```bash
  ./use-existing-ngrok.sh
  ```

### CORS Errors
- **Symptom**: Console shows "Access to fetch at X from origin Y has been blocked by CORS policy"
- **Solution**: 
  1. Verify origins in server.js match the domains you're using
  2. Try using a CORS browser extension (temporarily)
  3. Ensure API_URL in config.js exactly matches the ngrok URL (https prefix, no trailing slash)

### Mixed Content Errors
- **Symptom**: Console shows "Mixed Content: The page was loaded over HTTPS, but requested an insecure resource"
- **Solution**: Ensure all API URLs use HTTPS when accessing via ngrok

### LocalStorage Issues
- **Symptom**: "No user logged in" error
- **Solution**: 
  ```javascript
  localStorage.setItem('auth', JSON.stringify({email: 'test@example.com'}));
  ```

## Test Tools

- **API Test Page**: http://localhost:3000/test-api.html
- **Diagnostic Script**: ./diagnose.sh
- **API Connectivity Test**: ./test-api-connectivity.sh
- **Config Validation**: ./validate-config.sh

## Last Resort Solutions

If all else fails:

1. **Complete Environment Reset**:
   ```bash
   # Kill all node processes
   killall node
   # Delete any temporary files
   rm ngrok.log
   # Reset configuration
   ./validate-config.sh ngrok
   # Start fresh
   ./use-existing-ngrok.sh
   ```

2. **Use Local Mode**: If ngrok consistently causes issues, use local mode for development:
   ```bash
   ./start-local.sh
   ```
