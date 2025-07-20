#!/bin/bash
# Test authentication flow for the payment history page

echo "=== Authentication Flow Test ==="
echo "1. Testing API connectivity to ngrok tunnel..."

# Test direct API connectivity
NGROK_URL="https://83bc16e00594.ngrok-free.app"
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$NGROK_URL/api/cors-test")

if [[ "$API_STATUS" == "200" ]]; then
  echo "✅ ngrok tunnel is UP and responding (status $API_STATUS)"
else
  echo "❌ ngrok tunnel returned status $API_STATUS"
fi

# Test the Vercel API proxy
VERCEL_URL="${VERCEL_URL:-https://secureprogrammingproject.vercel.app}"
echo "2. Testing Vercel API proxy at $VERCEL_URL..."

VERCEL_API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$VERCEL_URL/api/cors-test")

if [[ "$VERCEL_API_STATUS" == "200" ]]; then
  echo "✅ Vercel API proxy is working (status $VERCEL_API_STATUS)"
else
  echo "❌ Vercel API proxy returned status $VERCEL_API_STATUS"
fi

# Test authentication flow with a sample user
echo "3. Testing authentication flow with sample user..."
curl -s "$NGROK_URL/api/payment-history?email=test@example.com" | jq 'length'

# Validate the history.html file has been updated
echo "4. Validating history.html file has been updated..."
if grep -q "forceDemoLogin()" "/Users/daneshmuthukrisnan/Documents/GitHub/SecureProgrammingProject/public/history.html"; then
  echo "✅ history.html contains the enhanced authentication code"
else
  echo "❌ history.html has not been updated correctly"
fi

echo "=== Test Complete ==="
echo "You can now deploy to Vercel to test the changes:"
echo "vercel --prod"
