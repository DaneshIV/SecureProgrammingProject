#!/bin/zsh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==============================================${NC}"
echo -e "${YELLOW}  Final Fix for Vercel Deployment Issues     ${NC}"
echo -e "${BLUE}==============================================${NC}"
echo ""

# First, check the current ngrok tunnel
echo -e "${BLUE}Checking ngrok tunnel status...${NC}"
NGROK_RESPONSE=$(curl -s "https://83bc16e00594.ngrok-free.app/api/cors-test")

if [[ $NGROK_RESPONSE == *"success"* ]]; then
  echo -e "${GREEN}✓ Ngrok tunnel is active and responding correctly${NC}"
  CURRENT_NGROK="https://83bc16e00594.ngrok-free.app"
else
  echo -e "${RED}✗ Ngrok tunnel is not responding${NC}"
  
  # Try to get current ngrok URL
  if curl -s localhost:4040/api/tunnels > /dev/null; then
    TUNNELS=$(curl -s localhost:4040/api/tunnels)
    CURRENT_NGROK=$(echo $TUNNELS | grep -o '"public_url":"[^"]*' | head -1 | sed 's/"public_url":"//')
    
    echo -e "${YELLOW}Found active ngrok tunnel: ${CURRENT_NGROK}${NC}"
    
    # Test the new URL
    NEW_RESPONSE=$(curl -s "${CURRENT_NGROK}/api/cors-test")
    if [[ $NEW_RESPONSE == *"success"* ]]; then
      echo -e "${GREEN}✓ New ngrok URL is working correctly${NC}"
    else
      echo -e "${RED}✗ New ngrok URL is not working. Please check your ngrok setup.${NC}"
      echo -e "Start a new ngrok tunnel with: ${YELLOW}ngrok http 3000${NC}"
      exit 1
    fi
  else
    echo -e "${RED}✗ No active ngrok tunnel found${NC}"
    echo -e "Start ngrok with: ${YELLOW}ngrok http 3000${NC}"
    exit 1
  fi
fi

# Create a simplified vercel.json without the headers section
echo -e "\n${BLUE}Creating simplified vercel.json...${NC}"

cat > vercel.json << EOF
{
  "version": 2,
  "builds": [
    {
      "src": "server.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "${CURRENT_NGROK}/api/\$1"
    },
    {
      "src": "/(.*)",
      "dest": "server.js"
    }
  ]
}
EOF

echo -e "${GREEN}✓ Created simplified vercel.json${NC}"

# Update config.js to always use the direct ngrok URL in Vercel environment
echo -e "\n${BLUE}Updating config.js for Vercel environment...${NC}"

cat > public/config.js << EOF
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
    // In Vercel environment, always use the direct ngrok URL
    apiUrl = "${CURRENT_NGROK}";
    environment = 'vercel-ngrok';
  } else {
    // Default to ngrok direct URL for local development
    apiUrl = "${CURRENT_NGROK}";
    environment = "ngrok";
  }
  
  // Set the global configuration
  window.APP_CONFIG = {
    API_URL: apiUrl,
    ENVIRONMENT: environment
  };
  
  console.log('APP_CONFIG initialized:', window.APP_CONFIG);
})();
EOF

echo -e "${GREEN}✓ Updated config.js to use the direct ngrok URL${NC}"

# Update error-handler.js to immediately use the ngrok URL
echo -e "\n${BLUE}Updating error-handler.js...${NC}"

sed -i '' "s|const NGROK_URL = 'https://83bc16e00594.ngrok-free.app';|const NGROK_URL = '${CURRENT_NGROK}';|" public/error-handler.js

echo -e "${GREEN}✓ Updated error-handler.js with the correct ngrok URL${NC}"

# Commit the changes
echo -e "\n${BLUE}Committing changes...${NC}"
git add vercel.json public/config.js public/error-handler.js
git commit -m "Fix: Simplify vercel.json and update config for direct ngrok usage"

# Deploy to Vercel with max verbosity
echo -e "\n${BLUE}Deploying to Vercel...${NC}"
vercel --prod --yes

# Create the test HTML file
echo -e "\n${BLUE}Creating quick test file...${NC}"

cat > public/quick-test.html << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Quick Connectivity Test</title>
  <script src="config.js"></script>
  <script src="error-handler.js"></script>
  <style>
    body { font-family: Arial, sans-serif; padding: 20px; }
    .result { margin: 10px 0; padding: 10px; border: 1px solid #ddd; }
    .success { background-color: #dff0d8; color: #3c763d; }
    .error { background-color: #f2dede; color: #a94442; }
  </style>
</head>
<body>
  <h1>Quick API Connectivity Test</h1>
  <div>
    <p>Current configuration:</p>
    <pre id="config-info">Loading...</pre>
    <button onclick="testConnectivity()">Test Connectivity</button>
  </div>
  <div id="result" class="result">Click the button to test connectivity</div>
  <script>
    // Display the current configuration
    document.getElementById('config-info').textContent = 
      JSON.stringify(window.APP_CONFIG, null, 2);
    
    async function testConnectivity() {
      const resultDiv = document.getElementById('result');
      resultDiv.textContent = 'Testing connectivity...';
      resultDiv.className = 'result';
      
      try {
        // Test CORS endpoint
        const corsUrl = \`\${window.APP_CONFIG.API_URL}/api/cors-test\`;
        console.log('Testing URL:', corsUrl);
        
        const response = await fetch(corsUrl);
        
        if (response.ok) {
          const data = await response.json();
          resultDiv.textContent = 'Success! API is responding correctly: ' + JSON.stringify(data);
          resultDiv.className = 'result success';
          
          // Now try the payment history endpoint
          testPaymentHistory();
        } else {
          resultDiv.textContent = \`Error: \${response.status} \${response.statusText}\`;
          resultDiv.className = 'result error';
        }
      } catch (error) {
        resultDiv.textContent = \`Connection error: \${error.message}\`;
        resultDiv.className = 'result error';
        console.error(error);
      }
    }
    
    async function testPaymentHistory() {
      try {
        const historyUrl = \`\${window.APP_CONFIG.API_URL}/api/payment-history?email=test@example.com\`;
        const response = await fetch(historyUrl);
        
        if (response.ok) {
          const data = await response.json();
          const resultDiv = document.createElement('div');
          resultDiv.className = 'result success';
          resultDiv.textContent = \`Payment history API working! Found \${data.length} records.\`;
          document.body.appendChild(resultDiv);
        } else {
          const resultDiv = document.createElement('div');
          resultDiv.className = 'result error';
          resultDiv.textContent = \`Payment history API error: \${response.status} \${response.statusText}\`;
          document.body.appendChild(resultDiv);
        }
      } catch (error) {
        const resultDiv = document.createElement('div');
        resultDiv.className = 'result error';
        resultDiv.textContent = \`Payment history API connection error: \${error.message}\`;
        document.body.appendChild(resultDiv);
      }
    }
  </script>
</body>
</html>
EOF

echo -e "${GREEN}✓ Created quick-test.html for easy testing${NC}"
echo -e "\n${BLUE}==============================================${NC}"
echo -e "${YELLOW}                Next Steps                   ${NC}"
echo -e "${BLUE}==============================================${NC}"
echo -e "1. Access your Vercel deployment at:"
echo -e "   ${GREEN}https://secure-programming-project-n07coejcy-daneshivs-projects.vercel.app${NC}"
echo -e "2. Test connectivity with the quick test page:"
echo -e "   ${GREEN}https://secure-programming-project-n07coejcy-daneshivs-projects.vercel.app/quick-test.html${NC}"
echo -e "3. Check if payment history is working:"
echo -e "   ${GREEN}https://secure-programming-project-n07coejcy-daneshivs-projects.vercel.app/history.html${NC}"
echo -e "4. Make sure your ngrok tunnel stays active at: ${GREEN}${CURRENT_NGROK}${NC}"
echo -e "\nRemember: If your ngrok tunnel changes, you'll need to update and redeploy."
