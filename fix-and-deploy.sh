#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${YELLOW}    Fix JSON Files and Deploy to Vercel    ${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Function to validate JSON
validate_json() {
  local file=$1
  if which jq > /dev/null; then
    if ! jq empty "$file" 2>/dev/null; then
      echo -e "${RED}✗ Invalid JSON in $file${NC}"
      return 1
    else
      echo -e "${GREEN}✓ $file is valid JSON${NC}"
      return 0
    fi
  else
    echo -e "${YELLOW}⚠️ jq not installed, skipping validation${NC}"
    return 0
  fi
}

# Fix vercel.json
echo -e "${BLUE}Fixing vercel.json...${NC}"
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
      "dest": "https://83bc16e00594.ngrok-free.app/api/\$1"
    },
    {
      "src": "/(.*)",
      "dest": "server.js"
    }
  ],
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Access-Control-Allow-Credentials", "value": "true" },
        { "key": "Access-Control-Allow-Origin", "value": "*" },
        { "key": "Access-Control-Allow-Methods", "value": "GET,OPTIONS,PATCH,DELETE,POST,PUT" },
        { "key": "Access-Control-Allow-Headers", "value": "X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Origin, Authorization" }
      ]
    }
  ]
}
EOF

# Fix package.json
echo -e "${BLUE}Fixing package.json...${NC}"
cat > package.json << EOF
{
  "name": "secureprogrammingproject",
  "version": "1.0.0",
  "description": "A vulnerable payment system for educational purposes",
  "main": "server.js",
  "scripts": {
    "test": "echo \\"Error: no test specified\\" && exit 1",
    "start": "node server.js",
    "local": "./start-local.sh",
    "ngrok": "./start-ngrok.sh",
    "existing-ngrok": "./use-existing-ngrok.sh",
    "deploy": "vercel --prod",
    "diagnose": "./diagnose.sh",
    "cleanup": "./cleanup.sh",
    "help": "cat QUICKSTART.md"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "cors": "^2.8.5",
    "express": "^4.18.3",
    "sqlite3": "^5.1.6"
  },
  "engines": {
    "node": ">=14"
  }
}
EOF

# Validate JSON files
echo -e "\n${BLUE}Validating JSON files...${NC}"
validate_json vercel.json && validate_json package.json

if [ $? -ne 0 ]; then
  echo -e "${RED}JSON validation failed. Please fix the errors before deploying.${NC}"
  exit 1
fi

# Make sure config.js is not interfering
echo -e "\n${BLUE}Checking config.js...${NC}"
grep -q "// filepath:" public/config.js

if [ $? -eq 0 ]; then
  echo -e "${YELLOW}⚠️ Found comments in config.js, fixing...${NC}"
  
  # Save a backup
  cp public/config.js public/config.js.bak
  
  # Remove the first line if it's a comment
  sed '1s/^\/\/.*$//' public/config.js > public/config.js.tmp
  mv public/config.js.tmp public/config.js
  
  echo -e "${GREEN}✓ Fixed config.js${NC}"
fi

# Commit changes
echo -e "\n${BLUE}Committing changes...${NC}"
git add vercel.json package.json public/config.js
git commit -m "Fix: JSON files for Vercel deployment"

# Deploy to Vercel
echo -e "\n${BLUE}Deploying to Vercel...${NC}"
echo -e "${YELLOW}This might take a minute...${NC}"

# Run vercel with auto-confirm
echo "y" | vercel --prod

if [ $? -eq 0 ]; then
  echo -e "\n${GREEN}✓ Deployment initiated successfully!${NC}"
  echo -e "Check your Vercel dashboard for deployment status."
else
  echo -e "\n${RED}✗ Deployment failed.${NC}"
  echo -e "Try running 'vercel --prod' manually to see detailed error messages."
fi

echo -e "\n${BLUE}==========================================${NC}"
echo -e "${YELLOW}             Next Steps                  ${NC}"
echo -e "${BLUE}==========================================${NC}"
echo -e "1. Verify your deployment on the Vercel dashboard"
echo -e "2. Test your site with vercel-test.html"
echo -e "3. Make sure your ngrok tunnel is still active"
echo -e "4. If issues persist, check ngrok logs and Vercel build logs"
echo -e "\nGood luck!"
