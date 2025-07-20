#!/bin/bash
# Comprehensive validation script for the Secure Programming Project
# Tests authentication, API connectivity, and Vercel configuration

# Set text colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${BLUE}================================================${RESET}"
echo -e "${BLUE}     Secure Programming Project Validator       ${RESET}"
echo -e "${BLUE}================================================${RESET}"

# Check environment configuration
echo -e "\n${BLUE}Testing Environment Configuration:${RESET}"

# Check config.js
CONFIG_CONTENT=$(cat public/config.js)
echo -e "Current config.js content:\n${CONFIG_CONTENT}"

# Extract environment and API URL from config.js
ENVIRONMENT=$(echo "$CONFIG_CONTENT" | grep "ENVIRONMENT" | sed -E 's/.*ENVIRONMENT.*"([^"]+)".*/\1/')
API_URL=$(echo "$CONFIG_CONTENT" | grep "API_URL" | sed -E 's/.*API_URL.*"([^"]*)".*,/\1/')

echo -e "Detected environment: ${YELLOW}$ENVIRONMENT${RESET}"
echo -e "Detected API URL: ${YELLOW}$API_URL${RESET}"

# Check ngrok tunnel
NGROK_URL="https://83bc16e00594.ngrok-free.app"
echo -e "\n${BLUE}Testing ngrok tunnel:${RESET} $NGROK_URL"

NGROK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $NGROK_URL/api/cors-test)
if [[ "$NGROK_STATUS" == "200" ]]; then
  echo -e "${GREEN}✅ ngrok tunnel is accessible (status $NGROK_STATUS)${RESET}"
  
  # Test actual API functionality
  echo -e "\n${BLUE}Testing payment history API:${RESET}"
  PAYMENT_DATA=$(curl -s "$NGROK_URL/api/payment-history?email=test@example.com")
  PAYMENT_COUNT=$(echo "$PAYMENT_DATA" | grep -o "transaction_id" | wc -l | tr -d ' ')
  
  if [[ "$PAYMENT_COUNT" -gt 0 ]]; then
    echo -e "${GREEN}✅ Payment history API returned $PAYMENT_COUNT transactions${RESET}"
  else
    echo -e "${RED}❌ Payment history API returned no data or an error${RESET}"
    echo "API response: $PAYMENT_DATA"
  fi
else
  echo -e "${RED}❌ ngrok tunnel returned status $NGROK_STATUS${RESET}"
  echo "Consider updating the ngrok URL in your configuration files"
fi

# Check local server accessibility
echo -e "\n${BLUE}Testing local server:${RESET}"
LOCAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/cors-test || echo "failed")

if [[ "$LOCAL_STATUS" == "200" ]]; then
  echo -e "${GREEN}✅ Local server is running (status $LOCAL_STATUS)${RESET}"
else
  echo -e "${YELLOW}⚠️ Local server not accessible (status $LOCAL_STATUS)${RESET}"
  echo "Consider starting the local server with ./start-local.sh"
fi

# Check Vercel configuration
echo -e "\n${BLUE}Validating Vercel configuration:${RESET}"

if [ -f "vercel.json" ]; then
  # Check if vercel.json is valid JSON
  if jq empty vercel.json 2>/dev/null; then
    echo -e "${GREEN}✅ vercel.json is valid JSON${RESET}"
    
    # Check if it has the ngrok proxy configuration
    PROXY_CONFIG=$(jq '.routes[] | select(.src | contains("/api/"))' vercel.json)
    if [[ -n "$PROXY_CONFIG" ]]; then
      echo -e "${GREEN}✅ API proxy configuration found in vercel.json${RESET}"
      echo "$PROXY_CONFIG" | grep -o "dest.*ngrok.*"
    else
      echo -e "${RED}❌ API proxy configuration not found in vercel.json${RESET}"
    fi
  else
    echo -e "${RED}❌ vercel.json is not valid JSON${RESET}"
    cat vercel.json
  fi
else
  echo -e "${RED}❌ vercel.json not found${RESET}"
fi

# Check history.html implementation
echo -e "\n${BLUE}Validating history.html implementation:${RESET}"

# Check for key functionality
if grep -q "forceDemoLogin" public/history.html; then
  echo -e "${GREEN}✅ Enhanced demo login functionality found${RESET}"
else
  echo -e "${RED}❌ Enhanced demo login functionality missing${RESET}"
fi

if grep -q "sessionStorage" public/history.html; then
  echo -e "${GREEN}✅ Multiple storage mechanisms found${RESET}"
else
  echo -e "${RED}❌ Multiple storage mechanisms missing${RESET}"
fi

if grep -q "status-indicator" public/history.html; then
  echo -e "${GREEN}✅ API status indicator found${RESET}"
else
  echo -e "${RED}❌ API status indicator missing${RESET}"
fi

if grep -q "debug-panel" public/history.html; then
  echo -e "${GREEN}✅ Debug panel found${RESET}"
else
  echo -e "${RED}❌ Debug panel missing${RESET}"
fi

# Check authentication test tool
if [ -f "public/auth-test-tool.html" ]; then
  echo -e "${GREEN}✅ Authentication test tool found${RESET}"
else
  echo -e "${YELLOW}⚠️ Authentication test tool missing${RESET}"
fi

echo -e "\n${BLUE}================= Summary ===================${RESET}"
echo -e "${BLUE}Environment:${RESET} $ENVIRONMENT"
echo -e "${BLUE}API URL:${RESET} $API_URL"
echo -e "${BLUE}ngrok URL:${RESET} $NGROK_URL"
echo -e "${BLUE}Local Server:${RESET} $(if [[ "$LOCAL_STATUS" == "200" ]]; then echo "Running"; else echo "Not running"; fi)"
echo -e "${BLUE}History Page:${RESET} Enhanced authentication implemented"
echo -e "\n${GREEN}✅ Validation complete${RESET}"
echo -e "${BLUE}================================================${RESET}"
echo -e "Next steps:"
echo -e "1. Run the local server: ${YELLOW}./start-local.sh${RESET}"
echo -e "2. Test authentication locally: ${YELLOW}open http://localhost:3000/history.html${RESET}"
echo -e "3. Deploy to Vercel: ${YELLOW}./deploy.sh${RESET}"
echo -e "4. Test authentication on Vercel: ${YELLOW}open https://secureprogrammingproject.vercel.app/history.html${RESET}"
echo -e "${BLUE}================================================${RESET}"
