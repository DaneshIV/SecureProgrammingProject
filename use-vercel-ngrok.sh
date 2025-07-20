#!/bin/bash

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================${NC}"
echo -e "${YELLOW}Setting up environment for Vercel + Ngrok${NC}"
echo -e "${BLUE}=======================================${NC}"

# Check if ngrok URL is provided
NGROK_URL=${1:-"https://83bc16e00594.ngrok-free.app"}

if [[ ! $NGROK_URL =~ ^https?://[a-zA-Z0-9].*\.ngrok-free\.app$ ]]; then
    echo -e "${RED}Error: Invalid ngrok URL. Please provide a valid URL in the format 'https://XXXX.ngrok-free.app'${NC}"
    exit 1
fi

# Update the configuration for Vercel + Ngrok
cat > ./public/config.js << EOF
// Auto-generated config file - Do not edit manually
window.APP_CONFIG = {
  API_URL: "${NGROK_URL}",
  ENVIRONMENT: "vercel-ngrok"
};
EOF

echo -e "${GREEN}✅ Configuration updated for Vercel + Ngrok integration${NC}"
echo -e "${BLUE}API URL set to:${NC} ${NGROK_URL}"

echo -e "${YELLOW}⚠️  IMPORTANT: ${NC}"
echo -e "1. Ensure the ngrok instance is running at ${NGROK_URL}"
echo -e "2. Push these changes to your GitHub repository"
echo -e "3. Wait for Vercel to deploy the updated frontend"

# Validate CORS configuration in server.js
if grep -q "secure-programming-project.vercel.app" ./server.js; then
    echo -e "${GREEN}✅ CORS configuration for Vercel is present${NC}"
else
    echo -e "${RED}⚠️ CORS configuration for Vercel might be missing!${NC}"
    echo -e "${YELLOW}Please check the 'corsOptions' in server.js${NC}"
fi

echo -e "${BLUE}=======================================${NC}"
echo -e "${GREEN}Setup complete! Your project is now configured for Vercel frontend with Ngrok backend.${NC}"
echo -e "${BLUE}=======================================${NC}"
