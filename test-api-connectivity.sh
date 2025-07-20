#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NGROK_URL="https://83bc16e00594.ngrok-free.app"
LOCAL_URL="http://localhost:3000"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}    Advanced API Connectivity Test       ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Function to test an API endpoint
test_endpoint() {
  local url=$1
  local endpoint=$2
  local description=$3
  
  echo -e "${YELLOW}Testing $description${NC}"
  echo -e "URL: ${BLUE}$url$endpoint${NC}"
  
  response=$(curl -s -w "\n%{http_code}" "$url$endpoint")
  status_code=$(echo "$response" | tail -n1)
  response_body=$(echo "$response" | sed '$d')
  
  if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 300 ]; then
    echo -e "${GREEN}✓ Success (HTTP $status_code)${NC}"
    echo -e "Response: $response_body"
    return 0
  else
    echo -e "${RED}✗ Failed (HTTP $status_code)${NC}"
    echo -e "Response: $response_body"
    return 1
  fi
}

# Test local endpoints
echo -e "${BLUE}Testing Local API Endpoints${NC}"
echo -e "=================================${NC}"
test_endpoint "$LOCAL_URL" "/api/cors-test" "Local CORS Test"
echo ""
test_endpoint "$LOCAL_URL" "/api/payment-history?email=test@example.com" "Local Payment History API"
echo ""

# Test ngrok endpoints
echo -e "${BLUE}Testing Ngrok API Endpoints${NC}"
echo -e "=================================${NC}"
test_endpoint "$NGROK_URL" "/api/cors-test" "Ngrok CORS Test"
echo ""
test_endpoint "$NGROK_URL" "/api/payment-history?email=test@example.com" "Ngrok Payment History API"
echo ""

# Check if ngrok tunnel is active
echo -e "${YELLOW}Checking ngrok tunnel status${NC}"
if curl -s "http://localhost:4040/api/tunnels" > /dev/null; then
  echo -e "${GREEN}✓ Ngrok tunnel is active${NC}"
  
  # Get tunnel details
  tunnels=$(curl -s "http://localhost:4040/api/tunnels")
  public_url=$(echo "$tunnels" | grep -o 'public_url":"[^"]*' | sed 's/public_url":"//')
  
  echo -e "Public URL: ${BLUE}$public_url${NC}"
  
  # Check if our expected URL is active
  if [[ "$tunnels" == *"$NGROK_URL"* ]]; then
    echo -e "${GREEN}✓ Expected ngrok URL is active${NC}"
  else
    echo -e "${RED}✗ Expected ngrok URL is NOT active${NC}"
    echo -e "${YELLOW}Active tunnel uses a different URL than expected in config${NC}"
  fi
else
  echo -e "${RED}✗ Ngrok tunnel is not active or ngrok API is not accessible${NC}"
fi

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}             Test Complete               ${NC}"
echo -e "${BLUE}=========================================${NC}"

# Provide recommendations based on tests
echo ""
echo -e "${BLUE}Recommendations:${NC}"
echo -e "1. Try accessing the test page at: ${GREEN}$LOCAL_URL/test-api.html${NC}"
echo -e "2. Use browser developer tools (F12) to check for CORS errors"
echo -e "3. Make sure your ngrok URL is still valid and matches the one in config.js"
echo -e "4. If using a browser extension like CORS Everywhere, make sure it's enabled"
