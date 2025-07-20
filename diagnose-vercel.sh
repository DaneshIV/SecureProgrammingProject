#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NGROK_URL="https://83bc16e00594.ngrok-free.app"
VERCEL_URL=${1:-""}

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}    Vercel-Ngrok Integration Diagnostic  ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check if ngrok is running
echo -e "${BLUE}Checking ngrok status...${NC}"
if curl -s localhost:4040/api/tunnels > /dev/null; then
  echo -e "${GREEN}✓ ngrok is running${NC}"
  
  # Get the public URL
  TUNNELS=$(curl -s localhost:4040/api/tunnels)
  PUBLIC_URL=$(echo $TUNNELS | grep -o '"public_url":"[^"]*' | head -1 | sed 's/"public_url":"//')
  echo -e "Current public URL: ${YELLOW}$PUBLIC_URL${NC}"
  
  # Check if it matches the expected URL
  if [[ "$PUBLIC_URL" == "$NGROK_URL" ]]; then
    echo -e "${GREEN}✓ ngrok URL matches configuration${NC}"
  else
    echo -e "${RED}✗ ngrok URL doesn't match configuration${NC}"
    echo -e "Expected: ${YELLOW}$NGROK_URL${NC}"
    echo -e "Actual: ${YELLOW}$PUBLIC_URL${NC}"
    
    echo -e "\n${YELLOW}Would you like to update the config.js with the current ngrok URL? (y/n)${NC}"
    read -r UPDATE_CONFIG
    
    if [[ $UPDATE_CONFIG =~ ^[Yy]$ ]]; then
      # Update config.js with the new URL
      sed -i '' "s|API_URL: \".*\"|API_URL: \"$PUBLIC_URL\"|" public/config.js
      echo -e "${GREEN}✓ Updated config.js with current ngrok URL${NC}"
    fi
  fi
else
  echo -e "${RED}✗ ngrok doesn't appear to be running${NC}"
  echo -e "Run ${YELLOW}ngrok http 3000${NC} to start ngrok"
  exit 1
fi

# Test API endpoints on ngrok
echo -e "\n${BLUE}Testing API endpoints on ngrok...${NC}"
echo -e "=================================${NC}"

# Test CORS endpoint
echo -e "Testing ${YELLOW}$NGROK_URL/api/cors-test${NC}"
CORS_RESPONSE=$(curl -s "$NGROK_URL/api/cors-test")
if [[ $CORS_RESPONSE == *"success"* ]]; then
  echo -e "${GREEN}✓ CORS endpoint is working${NC}"
else
  echo -e "${RED}✗ CORS endpoint failed${NC}"
  echo -e "Response: $CORS_RESPONSE"
fi

# Test payment history endpoint
echo -e "\nTesting ${YELLOW}$NGROK_URL/api/payment-history?email=test@example.com${NC}"
PAYMENT_RESPONSE=$(curl -s "$NGROK_URL/api/payment-history?email=test@example.com")
if [[ $PAYMENT_RESPONSE == *"transaction_id"* ]]; then
  echo -e "${GREEN}✓ Payment history endpoint is working${NC}"
  PAYMENT_COUNT=$(echo "$PAYMENT_RESPONSE" | grep -o "id" | wc -l)
  echo -e "Found ${GREEN}$PAYMENT_COUNT${NC} payment records"
else
  echo -e "${RED}✗ Payment history endpoint failed${NC}"
  echo -e "Response: $PAYMENT_RESPONSE"
fi

# Check vercel.json configuration
echo -e "\n${BLUE}Checking vercel.json configuration...${NC}"
if grep -q "\"src\": \"/api/(.*)\"" vercel.json; then
  echo -e "${GREEN}✓ vercel.json has API routing configuration${NC}"
  
  # Check if ngrok URL is in the vercel.json file
  if grep -q "$NGROK_URL" vercel.json; then
    echo -e "${GREEN}✓ vercel.json contains the correct ngrok URL${NC}"
  else
    echo -e "${RED}✗ vercel.json may not have the correct ngrok URL${NC}"
    echo -e "Expected URL: ${YELLOW}$NGROK_URL${NC}"
    
    echo -e "\n${YELLOW}Would you like to update vercel.json with the current ngrok URL? (y/n)${NC}"
    read -r UPDATE_VERCEL
    
    if [[ $UPDATE_VERCEL =~ ^[Yy]$ ]]; then
      # Update vercel.json with the new URL
      sed -i '' "s|\"dest\": \"https://.*\.ngrok-free\.app/api/\$1\"|\"dest\": \"$NGROK_URL/api/\$1\"|" vercel.json
      echo -e "${GREEN}✓ Updated vercel.json with current ngrok URL${NC}"
    fi
  fi
else
  echo -e "${RED}✗ vercel.json may be missing API routing configuration${NC}"
  echo -e "Please check the vercel.json file"
fi

# Provide final instructions
echo -e "\n${BLUE}=========================================${NC}"
echo -e "${GREEN}Diagnostic complete!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "\nRecommendations:"
echo -e "1. Access ${YELLOW}vercel-test.html${NC} on your Vercel deployment to run interactive tests"
echo -e "2. Make sure your ngrok tunnel remains active while testing"
echo -e "3. If you have a custom domain on Vercel, make sure CORS is properly configured"
echo -e "4. Access ${YELLOW}api-tester.html${NC} to run additional API connectivity tests"
echo -e "5. If issues persist, try accessing the API directly via ${YELLOW}curl${NC} to check for errors:"
echo -e "   ${YELLOW}curl $NGROK_URL/api/payment-history?email=test@example.com${NC}"
echo -e "\n${GREEN}Good luck with your secure programming project!${NC}"
