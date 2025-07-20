#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NGROK_URL="https://83bc16e00594.ngrok-free.app"

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}      Configuration Validation Tool       ${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Check config.js
echo -e "${YELLOW}Checking config.js...${NC}"
if [ -f "./public/config.js" ]; then
  # Get current environment and API URL
  CONFIG=$(cat ./public/config.js)
  
  # Extract environment and API URL using grep and sed
  ENV=$(echo "$CONFIG" | grep -o 'ENVIRONMENT: "[^"]*"' | sed 's/ENVIRONMENT: "\([^"]*\)"/\1/')
  API_URL=$(echo "$CONFIG" | grep -o 'API_URL: "[^"]*"' | sed 's/API_URL: "\([^"]*\)"/\1/')
  
  echo -e "Current environment: ${BLUE}$ENV${NC}"
  echo -e "Current API URL: ${BLUE}$API_URL${NC}"
  
  # Validate consistency with mode
  if [ "$1" == "ngrok" ]; then
    if [ "$ENV" == "ngrok" ] && [ "$API_URL" == "$NGROK_URL" ]; then
      echo -e "${GREEN}✓ Configuration is correct for ngrok mode${NC}"
    else
      echo -e "${RED}✗ Configuration is not correct for ngrok mode${NC}"
      echo -e "${YELLOW}Fixing configuration...${NC}"
      
      # Update config.js
      cat > ./public/config.js << EOF
// Auto-generated config file - Do not edit manually
window.APP_CONFIG = {
  API_URL: "$NGROK_URL",
  ENVIRONMENT: "ngrok"
};
EOF
      echo -e "${GREEN}✓ Configuration updated for ngrok mode${NC}"
    fi
  elif [ "$1" == "local" ]; then
    if [ "$ENV" == "local" ] && [ -z "$API_URL" ]; then
      echo -e "${GREEN}✓ Configuration is correct for local mode${NC}"
    else
      echo -e "${RED}✗ Configuration is not correct for local mode${NC}"
      echo -e "${YELLOW}Fixing configuration...${NC}"
      
      # Update config.js
      cat > ./public/config.js << EOF
// Auto-generated config file - Do not edit manually
window.APP_CONFIG = {
  API_URL: "",
  ENVIRONMENT: "local"
};
EOF
      echo -e "${GREEN}✓ Configuration updated for local mode${NC}"
    fi
  else
    echo -e "${YELLOW}No mode specified. Use: $0 [local|ngrok]${NC}"
  fi
else
  echo -e "${RED}✗ config.js file not found${NC}"
fi

echo ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}            Validation Complete           ${NC}"
echo -e "${BLUE}==========================================${NC}"
