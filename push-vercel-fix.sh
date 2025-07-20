#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================================${NC}"
echo -e "${YELLOW}   Preparing and Pushing Vercel Deployment     ${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Validate JSON files
echo -e "${BLUE}Validating JSON files...${NC}"

# Function to validate JSON
validate_json() {
  local file=$1
  if ! jq empty "$file" 2>/dev/null; then
    echo -e "${RED}✗ Invalid JSON in $file${NC}"
    return 1
  else
    echo -e "${GREEN}✓ $file is valid JSON${NC}"
    return 0
  fi
}

# Check vercel.json
if validate_json vercel.json; then
  echo -e "vercel.json looks good!"
else
  echo -e "${RED}Error in vercel.json - please fix before deploying${NC}"
  exit 1
fi

# Check package.json
if validate_json package.json; then
  echo -e "package.json looks good!"
else
  echo -e "${RED}Error in package.json - please fix before deploying${NC}"
  exit 1
fi

# Confirm the ngrok URL in vercel.json
NGROK_URL=$(jq -r '.routes[0].dest' vercel.json | sed 's|/api/\$1||')
echo -e "\n${BLUE}Checking ngrok URL in vercel.json...${NC}"
echo -e "Current URL: ${YELLOW}$NGROK_URL${NC}"

# Test the ngrok URL
echo -e "\n${BLUE}Testing ngrok URL connectivity...${NC}"
RESPONSE=$(curl -s "$NGROK_URL/api/cors-test")
if [[ "$RESPONSE" == *"success"* ]]; then
  echo -e "${GREEN}✓ ngrok URL is accessible${NC}"
else
  echo -e "${RED}✗ Cannot access ngrok URL${NC}"
  echo -e "Response: $RESPONSE"
  
  echo -e "\n${YELLOW}Would you like to update the ngrok URL in vercel.json? (y/n)${NC}"
  read -r UPDATE_URL
  
  if [[ $UPDATE_URL =~ ^[Yy]$ ]]; then
    echo -e "Enter the new ngrok URL (e.g., https://12345.ngrok-free.app):"
    read -r NEW_URL
    
    # Update the URL in vercel.json
    jq --arg url "$NEW_URL/api/\$1" '.routes[0].dest = $url' vercel.json > vercel.json.new
    mv vercel.json.new vercel.json
    echo -e "${GREEN}✓ Updated vercel.json with new URL: $NEW_URL${NC}"
    
    # Test the new URL
    RESPONSE=$(curl -s "$NEW_URL/api/cors-test")
    if [[ "$RESPONSE" == *"success"* ]]; then
      echo -e "${GREEN}✓ New ngrok URL is working${NC}"
    else
      echo -e "${RED}✗ Cannot access new ngrok URL either${NC}"
      echo -e "Please check your ngrok tunnel"
      exit 1
    fi
  fi
fi

# Commit changes
echo -e "\n${BLUE}Committing changes...${NC}"
git add vercel.json package.json
git commit -m "Fix: Removed JSON comments for Vercel compatibility"

# Push to GitHub
echo -e "\n${BLUE}Pushing to GitHub...${NC}"
git push

echo -e "\n${GREEN}Push complete!${NC}"
echo -e "Your changes have been pushed to GitHub, which should trigger a new Vercel deployment."
echo -e "Monitor your Vercel dashboard to see the deployment progress."
echo ""
echo -e "After deployment completes, test your site by accessing:"
echo -e "- ${YELLOW}yourapp.vercel.app/vercel-test.html${NC} to run the connectivity tests"
echo -e "- ${YELLOW}yourapp.vercel.app/history.html${NC} to check if payment history is working"
echo ""
