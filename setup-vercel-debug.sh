#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================================${NC}"
echo -e "${YELLOW}Vercel + Ngrok Integration Setup (Debug Version)${NC}"
echo -e "${BLUE}=================================================${NC}"

# NGROK URL - use provided URL or default
NGROK_URL=${1:-"https://83bc16e00594.ngrok-free.app"}

# Validate ngrok URL
if [[ ! $NGROK_URL =~ ^https?://.*\.ngrok-free\.app$ ]]; then
  echo -e "${RED}ERROR: Invalid ngrok URL format. Should be like https://xxxxx.ngrok-free.app${NC}"
  exit 1
fi

echo -e "${YELLOW}Using ngrok URL:${NC} $NGROK_URL"

# Check if ngrok is running
echo -e "\n${BLUE}Checking ngrok status...${NC}"
if ! curl -s localhost:4040/api/tunnels > /dev/null; then
  echo -e "${RED}ERROR: ngrok doesn't appear to be running. Start it with 'ngrok http 3000'${NC}"
  echo -e "${YELLOW}Attempting to check for running ngrok processes...${NC}"
  
  if ps aux | grep -v grep | grep -q "ngrok http"; then
    echo -e "${GREEN}Found running ngrok process.${NC}"
    
    # Try to get the public URL from the process info
    PROCESS_INFO=$(ps aux | grep -v grep | grep "ngrok http")
    echo -e "${BLUE}Process info:${NC} $PROCESS_INFO"
  else
    echo -e "${RED}No running ngrok processes found.${NC}"
    echo -e "${YELLOW}Would you like to start ngrok now? (y/n)${NC}"
    read -r START_NGROK
    
    if [[ $START_NGROK =~ ^[Yy]$ ]]; then
      echo -e "${BLUE}Starting ngrok...${NC}"
      nohup ngrok http 3000 > ngrok.log 2>&1 &
      echo -e "${GREEN}Waiting for ngrok to start...${NC}"
      sleep 5
      
      # Check if ngrok started successfully
      if ! curl -s localhost:4040/api/tunnels > /dev/null; then
        echo -e "${RED}Failed to start ngrok. Check ngrok.log for details.${NC}"
        exit 1
      else
        NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*' | sed 's/"public_url":"//')
        echo -e "${GREEN}ngrok started successfully with URL: $NGROK_URL${NC}"
      fi
    else
      echo -e "${YELLOW}Continuing setup without starting ngrok...${NC}"
    fi
  fi
else
  echo -e "${GREEN}ngrok is running.${NC}"
  DETECTED_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*' | sed 's/"public_url":"//')
  
  if [[ $DETECTED_URL != "" ]]; then
    echo -e "${BLUE}Detected ngrok URL: $DETECTED_URL${NC}"
    
    # If the detected URL is different from the provided one, ask which to use
    if [[ $DETECTED_URL != $NGROK_URL ]]; then
      echo -e "${YELLOW}The detected ngrok URL is different from the one you provided.${NC}"
      echo -e "${YELLOW}Which one would you like to use?${NC}"
      echo -e "1) Detected URL: $DETECTED_URL"
      echo -e "2) Provided URL: $NGROK_URL"
      read -r URL_CHOICE
      
      if [[ $URL_CHOICE == "1" ]]; then
        NGROK_URL=$DETECTED_URL
        echo -e "${GREEN}Using detected URL: $NGROK_URL${NC}"
      else
        echo -e "${GREEN}Using provided URL: $NGROK_URL${NC}"
      fi
    fi
  fi
fi

# Create robust config.js
echo -e "\n${BLUE}Updating config.js for Vercel + ngrok...${NC}"

CONFIG_PATH="./public/config.js"
cat > $CONFIG_PATH << EOF
// Auto-generated config file - Do not edit manually
window.APP_CONFIG = {
  API_URL: "$NGROK_URL",
  ENVIRONMENT: "vercel-ngrok"
};

// Safety check to ensure configuration is available
(function() {
  console.log("Config loaded:", window.APP_CONFIG);
  
  // Check if we're on Vercel
  if (window.location.hostname.includes('vercel.app')) {
    console.log('Vercel environment detected, ensuring ngrok URL is set');
    
    // If API_URL is not set but we're on Vercel, use a fallback
    if (!window.APP_CONFIG.API_URL) {
      window.APP_CONFIG.API_URL = "$NGROK_URL";
      console.log('Using fallback ngrok URL:', window.APP_CONFIG.API_URL);
    }
  }
})();
EOF

echo -e "${GREEN}✅ config.js updated successfully${NC}"

# Check server.js CORS configuration
echo -e "\n${BLUE}Checking CORS configuration in server.js...${NC}"
if grep -q "'origin': '\*'" ./server.js; then
  echo -e "${GREEN}✅ CORS is properly configured to allow all origins${NC}"
else
  echo -e "${YELLOW}⚠️ CORS might not be properly configured for Vercel integration${NC}"
  echo -e "${YELLOW}Would you like to update the CORS configuration? (y/n)${NC}"
  read -r UPDATE_CORS
  
  if [[ $UPDATE_CORS =~ ^[Yy]$ ]]; then
    # Save the original file
    cp ./server.js ./server.js.backup
    
    # Update CORS configuration using sed
    sed -i '' 's/const corsOptions = {[^}]*origin: function(origin, callback)[^}]*}/const corsOptions = {\n  origin: "*",/g' ./server.js
    
    echo -e "${GREEN}✅ CORS configuration updated${NC}"
  fi
fi

# Create a test file to verify connectivity
echo -e "\n${BLUE}Creating connectivity test file...${NC}"

TEST_PATH="./public/vercel-test.html"
cat > $TEST_PATH << EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Vercel-Ngrok Connectivity Test</title>
  <script src="config.js"></script>
  <script src="error-handler.js"></script>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 20px;
      line-height: 1.6;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
      border: 1px solid #ddd;
      border-radius: 5px;
    }
    .result {
      margin-top: 15px;
      padding: 10px;
      background-color: #f5f5f5;
      border-radius: 5px;
      white-space: pre-wrap;
    }
    .success {
      background-color: #d4edda;
      border: 1px solid #c3e6cb;
    }
    .error {
      background-color: #f8d7da;
      border: 1px solid #f5c6cb;
    }
    button {
      padding: 8px 16px;
      background-color: #007bff;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
    }
    button:hover {
      background-color: #0069d9;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Vercel-Ngrok Connectivity Test</h1>
    
    <p>This page tests the connectivity between your Vercel frontend and ngrok backend.</p>
    
    <div>
      <h3>Current Configuration:</h3>
      <div id="config-info"></div>
    </div>
    
    <div>
      <h3>CORS Test:</h3>
      <button id="test-cors">Run CORS Test</button>
      <div id="cors-result" class="result">Click the button to test</div>
    </div>
    
    <div>
      <h3>API Test:</h3>
      <button id="test-api">Test API Endpoint</button>
      <div id="api-result" class="result">Click the button to test</div>
    </div>
    
    <div>
      <h3>Browser Information:</h3>
      <button id="show-browser-info">Show Browser Info</button>
      <div id="browser-info" class="result">Click the button to show</div>
    </div>
    
    <div style="margin-top: 20px;">
      <a href="index.html">Back to Home</a> |
      <a href="history.html">View Payment History</a> |
      <a href="payment.html">Make a Payment</a>
    </div>
  </div>
  
  <script>
    document.addEventListener('DOMContentLoaded', function() {
      // Display configuration
      const configInfo = document.getElementById('config-info');
      configInfo.innerHTML = \`
        <strong>API URL:</strong> \${window.APP_CONFIG?.API_URL || 'Not set'}<br>
        <strong>Environment:</strong> \${window.APP_CONFIG?.ENVIRONMENT || 'Not set'}<br>
        <strong>Current URL:</strong> \${window.location.href}<br>
        <strong>Origin:</strong> \${window.location.origin}
      \`;
      
      // Test CORS button
      document.getElementById('test-cors').addEventListener('click', async function() {
        const corsResult = document.getElementById('cors-result');
        corsResult.textContent = 'Testing CORS...';
        corsResult.className = 'result';
        
        try {
          const apiUrl = window.APP_CONFIG?.API_URL || '';
          const response = await fetch(\`\${apiUrl}/api/cors-test\`, {
            mode: 'cors',
            headers: {
              'Accept': 'application/json',
              'Origin': window.location.origin
            }
          });
          
          corsResult.textContent = \`Status: \${response.status}\nHeaders received: \${response.headers.get('content-type')}\n\n\`;
          
          if (response.ok) {
            const data = await response.json();
            corsResult.textContent += JSON.stringify(data, null, 2);
            corsResult.className = 'result success';
          } else {
            corsResult.textContent += \`Error: \${response.statusText}\`;
            corsResult.className = 'result error';
          }
        } catch (error) {
          corsResult.textContent = \`Error: \${error.message}\`;
          corsResult.className = 'result error';
        }
      });
      
      // Test API button
      document.getElementById('test-api').addEventListener('click', async function() {
        const apiResult = document.getElementById('api-result');
        apiResult.textContent = 'Testing API...';
        apiResult.className = 'result';
        
        try {
          const apiUrl = window.APP_CONFIG?.API_URL || '';
          const response = await fetch(\`\${apiUrl}/api/payment-history?email=test@example.com\`, {
            mode: 'cors',
            headers: {
              'Accept': 'application/json',
              'Origin': window.location.origin
            }
          });
          
          apiResult.textContent = \`Status: \${response.status}\nHeaders received: \${response.headers.get('content-type')}\n\n\`;
          
          if (response.ok) {
            const text = await response.text();
            try {
              const data = JSON.parse(text);
              apiResult.textContent += \`Found \${data.length} payment records\`;
              apiResult.className = 'result success';
            } catch (e) {
              apiResult.textContent += \`Error parsing JSON: \${e.message}\n\nResponse text: \${text.substring(0, 200)}...\`;
              apiResult.className = 'result error';
            }
          } else {
            apiResult.textContent += \`Error: \${response.statusText}\`;
            apiResult.className = 'result error';
          }
        } catch (error) {
          apiResult.textContent = \`Error: \${error.message}\`;
          apiResult.className = 'result error';
        }
      });
      
      // Browser info button
      document.getElementById('show-browser-info').addEventListener('click', function() {
        const browserInfo = document.getElementById('browser-info');
        const info = {
          userAgent: navigator.userAgent,
          language: navigator.language,
          cookiesEnabled: navigator.cookieEnabled,
          localStorage: !!window.localStorage,
          sessionStorage: !!window.sessionStorage,
          online: navigator.onLine,
          screenSize: {
            width: window.screen.width,
            height: window.screen.height
          },
          documentDomain: document.domain,
          cookieLength: document.cookie.length
        };
        
        browserInfo.textContent = JSON.stringify(info, null, 2);
      });
    });
  </script>
</body>
</html>
EOF

echo -e "${GREEN}✅ Created vercel-test.html${NC}"

# Verify the server is running
echo -e "\n${BLUE}Checking if server is running...${NC}"
if curl -s localhost:3000 > /dev/null; then
  echo -e "${GREEN}✅ Server is running${NC}"
else
  echo -e "${YELLOW}⚠️ Server doesn't appear to be running${NC}"
  echo -e "${YELLOW}Would you like to start the server? (y/n)${NC}"
  read -r START_SERVER
  
  if [[ $START_SERVER =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Starting server...${NC}"
    node server.js > server.log 2>&1 &
    echo $! > server.pid
    echo -e "${GREEN}✅ Server started with PID $(cat server.pid)${NC}"
  fi
fi

echo -e "\n${BLUE}=================================================${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${BLUE}=================================================${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Push these changes to your GitHub repository"
echo -e "2. Vercel will automatically deploy the updated frontend"
echo -e "3. Test the connectivity using ${BLUE}vercel-test.html${NC}"
echo -e "4. Visit your site at ${BLUE}https://secure-programming-project.vercel.app/vercel-test.html${NC}"
echo -e "\n${YELLOW}If you still have issues:${NC}"
echo -e "- Check that ngrok is running and using URL: ${BLUE}$NGROK_URL${NC}"
echo -e "- Verify CORS is properly configured in server.js"
echo -e "- Check that your ngrok session hasn't expired"
echo -e "${BLUE}=================================================${NC}"
