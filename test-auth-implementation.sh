#!/bin/bash
# Test authentication in history.html with enhanced API testing

echo "=== Testing Authentication Implementation ==="

# Check if forceDemoLogin function exists (enhanced auth)
if grep -q "forceDemoLogin()" "/Users/daneshmuthukrisnan/Documents/GitHub/SecureProgrammingProject/public/history.html"; then
  echo "✅ Enhanced authentication code is present"
else
  echo "❌ Enhanced authentication code is missing"
fi

# Check if multiple storage methods are used
if grep -q "sessionStorage" "/Users/daneshmuthukrisnan/Documents/GitHub/SecureProgrammingProject/public/history.html"; then
  echo "✅ Using multiple storage methods for auth persistence"
else
  echo "❌ Missing multiple storage methods"
fi

# Check for API status indicator
if grep -q "status-indicator" "/Users/daneshmuthukrisnan/Documents/GitHub/SecureProgrammingProject/public/history.html"; then
  echo "✅ API status indicator is present"
else
  echo "❌ API status indicator is missing"
fi

# Check for debug panel
if grep -q "debug-panel" "/Users/daneshmuthukrisnan/Documents/GitHub/SecureProgrammingProject/public/history.html"; then
  echo "✅ Debug panel is present"
else
  echo "❌ Debug panel is missing"
fi

echo ""
echo "=== Testing Configuration ==="

# Check if the config.js file exists and is readable
CONFIG_FILE="/Users/daneshmuthukrisnan/Documents/GitHub/SecureProgrammingProject/public/config.js"
if [[ -f "$CONFIG_FILE" && -r "$CONFIG_FILE" ]]; then
  echo "✅ config.js file exists and is readable"
  
  # Display current configuration
  echo "Current config.js content:"
  cat "$CONFIG_FILE"
  echo ""
  
  # Check if the script properly handles empty API_URL
  if grep -q "apiEndpoints.push" "/Users/daneshmuthukrisnan/Documents/GitHub/SecureProgrammingProject/public/history.html"; then
    echo "✅ history.html has enhanced API endpoint handling"
  else
    echo "❌ history.html is missing enhanced API endpoint handling"
  fi
else
  echo "❌ config.js file is missing or not readable"
fi

echo ""
echo "=== Testing API Connectivity ==="

# Test the ngrok tunnel
NGROK_URL="https://83bc16e00594.ngrok-free.app"
NGROK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$NGROK_URL/api/cors-test" || echo "failed")

if [[ "$NGROK_STATUS" == "200" ]]; then
  echo "✅ ngrok tunnel is accessible"
  
  # Test payment history endpoint with a sample user
  HISTORY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$NGROK_URL/api/payment-history?email=test@example.com" || echo "failed")
  
  if [[ "$HISTORY_STATUS" == "200" ]]; then
    echo "✅ Payment history API is working"
    
    # Get a sample of the payment history data
    echo "Sample payment history data:"
    curl -s "$NGROK_URL/api/payment-history?email=test@example.com" | head -c 300
    echo "..."
  else
    echo "❌ Payment history API returned status $HISTORY_STATUS"
  fi
else
  echo "⚠️ ngrok tunnel may be down (status $NGROK_STATUS)"
  echo "   You might need to start a new tunnel or update the URL."
  
  # Check if local server is running
  LOCAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000/api/cors-test" || echo "failed")
  
  if [[ "$LOCAL_STATUS" == "200" ]]; then
    echo "✅ Local server is running"
    echo "   Run ./start-ngrok.sh to create a new tunnel"
  else
    echo "❌ Local server is not running"
    echo "   Run ./start-local.sh to start the server"
  fi
fi

echo ""
echo "Run ./deploy.sh to deploy these changes to Vercel"
