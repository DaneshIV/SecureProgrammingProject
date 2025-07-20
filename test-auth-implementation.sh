#!/bin/bash
# Test authentication in history.html

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
echo "=== Testing API Connectivity ==="

# Test the ngrok tunnel
NGROK_URL="https://83bc16e00594.ngrok-free.app"
NGROK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$NGROK_URL/api/cors-test" || echo "failed")

if [[ "$NGROK_STATUS" == "200" ]]; then
  echo "✅ ngrok tunnel is accessible"
else
  echo "⚠️ ngrok tunnel may be down (status $NGROK_STATUS)"
  echo "   You might need to start a new tunnel or update the URL."
fi

echo ""
echo "Run ./deploy.sh to deploy these changes to Vercel"
