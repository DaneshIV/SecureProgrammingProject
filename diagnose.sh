#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}    Payment System Diagnostic Tool       ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check if server is running
check_server() {
  echo -e "${YELLOW}Checking if server is running...${NC}"
  if curl -s http://localhost:3000/ > /dev/null; then
    echo -e "${GREEN}✓ Server is running on port 3000${NC}"
    return 0
  else
    echo -e "${RED}✗ Server is not running on port 3000${NC}"
    return 1
  fi
}

# Check if payment API endpoint is working
check_payment_api() {
  echo -e "${YELLOW}Testing payment API endpoint...${NC}"
  
  RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"cardHolder":"Test User","cardNumber":"4242424242424242","expiry":"12/25","cvv":"123","email":"test@example.com","boxType":"A","amount":25.00,"originalPrice":25.00,"transactionId":"test123","couponCode":""}' \
    http://localhost:3000/api/process-payment)
  
  if [[ $RESPONSE == *"success"* ]]; then
    echo -e "${GREEN}✓ Payment API is working correctly${NC}"
    echo -e "   Response: $RESPONSE"
    return 0
  else
    echo -e "${RED}✗ Payment API error${NC}"
    echo -e "   Response: $RESPONSE"
    return 1
  fi
}

# Check if history API endpoint is working
check_history_api() {
  echo -e "${YELLOW}Testing payment history API endpoint...${NC}"
  
  RESPONSE=$(curl -s "http://localhost:3000/api/payment-history?email=test@example.com")
  
  if [[ $RESPONSE == *"["* ]]; then
    echo -e "${GREEN}✓ Payment history API is working correctly${NC}"
    echo -e "   Found $(echo $RESPONSE | grep -o "id" | wc -l) payment records"
    return 0
  else
    echo -e "${RED}✗ Payment history API error${NC}"
    echo -e "   Response: $RESPONSE"
    return 1
  fi
}

# Check if ngrok is configured and running
check_ngrok() {
  echo -e "${YELLOW}Checking for active ngrok tunnels...${NC}"
  
  NGROK_STATUS=$(curl -s http://localhost:4040/api/tunnels)
  
  if [[ $NGROK_STATUS == *"ngrok"* ]]; then
    NGROK_URL=$(echo $NGROK_STATUS | grep -o 'https://[^"]*\.ngrok-free\.app')
    echo -e "${GREEN}✓ Ngrok is active${NC}"
    echo -e "   Public URL: ${BLUE}$NGROK_URL${NC}"
    
    # Test if the ngrok URL is working
    echo -e "${YELLOW}Testing ngrok connection...${NC}"
    if curl -s $NGROK_URL > /dev/null; then
      echo -e "${GREEN}✓ Ngrok connection is working${NC}"
    else
      echo -e "${RED}✗ Ngrok connection failed${NC}"
    fi
    
    return 0
  else
    echo -e "${YELLOW}! Ngrok is not running or not accessible via localhost:4040${NC}"
    return 1
  fi
}

# Display configuration information
show_config() {
  echo -e "${YELLOW}Current environment configuration:${NC}"
  
  if [ -f ./public/config.js ]; then
    CONFIG=$(cat ./public/config.js)
    echo -e "   Config file exists: ${GREEN}✓${NC}"
    
    if [[ $CONFIG == *"ENVIRONMENT"* ]]; then
      ENV=$(echo $CONFIG | grep -o 'ENVIRONMENT: "[^"]*"' | cut -d'"' -f2)
      API_URL=$(echo $CONFIG | grep -o 'API_URL: "[^"]*"' | cut -d'"' -f2)
      
      echo -e "   Environment: ${BLUE}$ENV${NC}"
      if [ -z "$API_URL" ]; then
        echo -e "   API URL: ${BLUE}[Using relative paths]${NC}"
      else
        echo -e "   API URL: ${BLUE}$API_URL${NC}"
      fi
    else
      echo -e "   ${RED}! Config file format is invalid${NC}"
    fi
  else
    echo -e "   ${RED}✗ Config file is missing${NC}"
  fi
}

# Run all checks
main() {
  show_config
  echo ""
  
  check_server
  SERVER_OK=$?
  echo ""
  
  if [ $SERVER_OK -eq 0 ]; then
    check_payment_api
    echo ""
    check_history_api
    echo ""
  fi
  
  check_ngrok
  echo ""
  
  echo -e "${BLUE}=========================================${NC}"
  echo -e "${BLUE}             Diagnosis Complete          ${NC}"
  echo -e "${BLUE}=========================================${NC}"
}

# Execute
main
