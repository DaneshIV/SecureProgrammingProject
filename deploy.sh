#!/bin/bash
# Deploy the updated authentication system to Vercel

echo "=== Vercel Deployment Script ==="

# 1. Check if the ngrok tunnel is active
echo "Checking ngrok tunnel connectivity..."
NGROK_URL="https://83bc16e00594.ngrok-free.app"
NGROK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$NGROK_URL/api/cors-test" || echo "failed")

if [[ "$NGROK_STATUS" == "200" ]]; then
  echo "✅ ngrok tunnel is UP and responding (status $NGROK_STATUS)"
else
  echo "⚠️ ngrok tunnel may be down (status $NGROK_STATUS)"
  echo "You may need to update the ngrok URL in these files:"
  echo "- public/config.js"
  echo "- vercel.json" 
  echo "- public/history.html"
  
  read -p "Do you want to continue anyway? (y/n): " CONTINUE
  if [[ "$CONTINUE" != "y" ]]; then
    echo "Deployment aborted."
    exit 1
  fi
fi

# 2. Commit changes
echo "Committing changes to Git..."
git add public/history.html
git commit -m "Fix authentication in payment history page"

# 3. Deploy to Vercel
echo "Deploying to Vercel..."
vercel --prod

echo "=== Deployment Complete ==="
echo "Access your site at https://secureprogrammingproject.vercel.app"
echo ""
echo "IMPORTANT: After deploying, please test the authentication by:"
echo "1. Going to https://secureprogrammingproject.vercel.app/history.html"
echo "2. Clicking one of the demo login buttons"
echo "3. Verifying that payment history loads"
echo ""
echo "If you still have issues:"
echo "- Use the 'Show Debug Info' button on the history page"
echo "- Check the browser console for errors"
echo "- Verify that your ngrok tunnel is active and accessible"
