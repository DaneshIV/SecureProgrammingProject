#!/bin/bash
# Deploy the authentication fix to Vercel

echo "=== Deploying Authentication Fix to Vercel ==="

# 1. Make test-auth.sh executable
chmod +x test-auth.sh

# 2. Run the authentication test to validate changes locally
./test-auth.sh

# 3. Commit changes
git add public/history.html
git commit -m "Fix authentication in payment history page"

# 4. Deploy to Vercel
echo "Deploying to Vercel..."
vercel --prod

echo "=== Deployment Complete ==="
echo "Access your site at https://secureprogrammingproject.vercel.app"
echo "Check the payment history page to verify authentication is working correctly."
