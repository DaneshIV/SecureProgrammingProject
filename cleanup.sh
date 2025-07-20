#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}        Server.js Clean-up Tool           ${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Check server.js for common issues
SERVER_FILE="./server.js"
if [ -f "$SERVER_FILE" ]; then
  echo -e "${YELLOW}Checking server.js for issues...${NC}"
  
  # Check for accidentally inserted script names
  if grep -q "\.\/.*\.sh" "$SERVER_FILE"; then
    echo -e "${RED}✗ Found script names accidentally inserted in server.js${NC}"
    echo -e "${YELLOW}Cleaning up...${NC}"
    
    # Create a temporary file
    TMP_FILE=$(mktemp)
    
    # Filter out lines containing script names and write to temporary file
    sed '/\/\..*\.sh/d' "$SERVER_FILE" > "$TMP_FILE"
    
    # Replace server.js with cleaned content
    mv "$TMP_FILE" "$SERVER_FILE"
    echo -e "${GREEN}✓ Cleaned server.js${NC}"
  else
    echo -e "${GREEN}✓ No script name issues found${NC}"
  fi
  
  # Check for CORS configuration
  if grep -q "app.use(cors(corsOptions));" "$SERVER_FILE"; then
    echo -e "${GREEN}✓ CORS configuration found${NC}"
  else
    echo -e "${RED}✗ CORS configuration not found or incomplete${NC}"
  fi

else
  echo -e "${RED}✗ server.js file not found${NC}"
fi

echo ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}              Check Complete              ${NC}"
echo -e "${BLUE}==========================================${NC}"
