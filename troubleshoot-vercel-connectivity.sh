#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Your ngrok URL
NGROK_URL="https://83bc16e00594.ngrok-free.app"
VERCEL_URL=$(curl -s https://api.vercel.com/v1/projects/secureprogrammingproject/domains | grep -o '"url":"[^"]*' | head -1 | sed 's/"url":"//')

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Vercel-Ngrok Connection Troubleshooter ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test if ngrok is accessible from the internet
echo -e "${BLUE}Testing if ngrok URL is publicly accessible...${NC}"
NGROK_RESPONSE=$(curl -s "$NGROK_URL/api/cors-test")
if [[ $NGROK_RESPONSE == *"success"* ]]; then
  echo -e "${GREEN}✓ ngrok URL is publicly accessible${NC}"
  echo -e "Response: $NGROK_RESPONSE"
else
  echo -e "${RED}✗ ngrok URL is NOT publicly accessible${NC}"
  echo -e "Response: $NGROK_RESPONSE"
  
  # Check for ngrok errors like expired tunnels
  if [[ $NGROK_RESPONSE == *"tunnel"*"not found"* ]]; then
    echo -e "${RED}ERROR: Your ngrok tunnel appears to have expired or changed.${NC}"
    echo -e "Please restart ngrok with: ${YELLOW}ngrok http 3000${NC}"
    
    # Try to get current ngrok URL
    if curl -s localhost:4040/api/tunnels > /dev/null; then
      TUNNELS=$(curl -s localhost:4040/api/tunnels)
      NEW_URL=$(echo $TUNNELS | grep -o '"public_url":"[^"]*' | head -1 | sed 's/"public_url":"//')
      if [[ -n "$NEW_URL" ]]; then
        echo -e "\nCurrent active ngrok URL is: ${GREEN}$NEW_URL${NC}"
        echo -e "You need to update your configuration files with this URL"
      fi
    fi
    
    exit 1
  fi
fi

# Create a temporary HTML file to test Vercel-hosted connectivity
echo -e "\n${BLUE}Creating a temporary test file...${NC}"
cat > /tmp/test-vercel-ngrok.html << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Vercel-Ngrok Connectivity Test</title>
  <script>
    async function testNgrokDirectly() {
      document.getElementById('result1').textContent = 'Testing...';
      try {
        const response = await fetch('$NGROK_URL/api/cors-test', {
          mode: 'cors',
          credentials: 'include'
        });
        const data = await response.json();
        document.getElementById('result1').textContent = 'Success: ' + JSON.stringify(data);
      } catch (error) {
        document.getElementById('result1').textContent = 'Error: ' + error.message;
      }
    }
    
    async function testVercelProxy() {
      document.getElementById('result2').textContent = 'Testing...';
      try {
        const response = await fetch('/api/cors-test');
        const data = await response.json();
        document.getElementById('result2').textContent = 'Success: ' + JSON.stringify(data);
      } catch (error) {
        document.getElementById('result2').textContent = 'Error: ' + error.message;
      }
    }
    
    async function testPaymentHistory() {
      document.getElementById('result3').textContent = 'Testing...';
      try {
        const response = await fetch('/api/payment-history?email=test@example.com');
        const data = await response.json();
        document.getElementById('result3').textContent = 'Success: Found ' + data.length + ' records';
      } catch (error) {
        document.getElementById('result3').textContent = 'Error: ' + error.message;
      }
    }
  </script>
</head>
<body>
  <h1>Vercel-Ngrok Connectivity Test</h1>
  <p>This file should be uploaded to your Vercel deployment to test connectivity</p>
  
  <div>
    <h2>Test 1: Direct Ngrok Connection</h2>
    <button onclick="testNgrokDirectly()">Test ngrok directly</button>
    <p id="result1">Click button to test</p>
  </div>
  
  <div>
    <h2>Test 2: Vercel Proxy</h2>
    <button onclick="testVercelProxy()">Test Vercel proxy</button>
    <p id="result2">Click button to test</p>
  </div>
  
  <div>
    <h2>Test 3: Payment History API</h2>
    <button onclick="testPaymentHistory()">Test Payment History</button>
    <p id="result3">Click button to test</p>
  </div>
</body>
</html>
EOF

echo -e "${GREEN}Test file created at /tmp/test-vercel-ngrok.html${NC}"
echo -e "Please upload this file to your Vercel project and access it to test connectivity"

# Test if vercel.json is properly configured
echo -e "\n${BLUE}Checking vercel.json configuration...${NC}"
if [[ -f "vercel.json" ]]; then
  if grep -q "\"src\": \"/api/(.*)\"" vercel.json && grep -q "$NGROK_URL" vercel.json; then
    echo -e "${GREEN}✓ vercel.json appears to be properly configured${NC}"
  else
    echo -e "${RED}✗ vercel.json may have issues${NC}"
    cat vercel.json
  fi
else
  echo -e "${RED}✗ vercel.json not found${NC}"
fi

# Check if any modifications to vercel.json were committed but not deployed
echo -e "\n${BLUE}Checking if your latest vercel.json changes were deployed...${NC}"
echo -e "${YELLOW}Please visit your Vercel dashboard and ensure your latest changes were deployed.${NC}"
echo -e "Remember that changes to vercel.json will only take effect after a new deployment."

# Provide next steps
echo -e "\n${BLUE}=========================================${NC}"
echo -e "${YELLOW}Recommended Next Steps:${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "1. Upload the test file at /tmp/test-vercel-ngrok.html to your Vercel project"
echo -e "2. Access the file on your Vercel deployment to test connectivity"
echo -e "3. Ensure your ngrok tunnel remains active (current URL: $NGROK_URL)"
echo -e "4. If tests fail, try restarting ngrok with: ${YELLOW}ngrok http 3000${NC}"
echo -e "5. Update vercel.json with the new ngrok URL if needed"
echo -e "6. Redeploy your project to Vercel with: ${YELLOW}vercel --prod${NC}"
echo -e "\n${GREEN}Good luck with your troubleshooting!${NC}"
