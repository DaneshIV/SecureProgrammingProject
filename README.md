# Secure Programming Project - Vulnerable Payment System

This project demonstrates a deliberately vulnerable payment system for educational purposes, inspired by OWASP Juice Shop. It contains various security vulnerabilities to help students learn about common web application security issues.

> **New to this project?** Check out the [QUICKSTART.md](QUICKSTART.md) file for a quick way to get up and running!

## Setup Instructions

### Local Development

1. Clone this repository
2. Install dependencies:
   ```
   npm install
   ```
3. Run the server locally:
   ```
   npm start
   ```
   or
   ```
   ./start-local.sh
   ```
4. Access the application at `http://localhost:3000`

### Hosting with ngrok

#### Option 1: Use an existing ngrok URL
If you already have a working ngrok URL:

1. Use the existing ngrok script:
   ```
   npm run existing-ngrok
   ```
   or
   ```
   ./use-existing-ngrok.sh
   ```
2. The server will start using the pre-configured ngrok URL (https://83bc16e00594.ngrok-free.app)

#### Option 2: Create a new ngrok tunnel
To create a fresh ngrok tunnel:

1. Install ngrok (https://ngrok.com/download)
2. Make sure ngrok is authenticated with your account:
   ```
   ngrok authtoken YOUR_NGROK_AUTHTOKEN
   ```
3. Run the application with ngrok:
   ```
   npm run ngrok
   ```
   or
   ```
   ./start-ngrok.sh
   ```
4. The terminal will display your public ngrok URL
5. Share this URL to access your application from anywhere

### Manual Environment Configuration

If you need to manually set the environment:

1. For local development:
   ```
   ./set-environment.sh local
   ```

2. For ngrok deployment:
   ```
   ./set-environment.sh ngrok "https://your-ngrok-url.ngrok-free.app"
   ```

## Security Vulnerabilities Implemented

### Client-Side Vulnerabilities
1. **Price Manipulation**: Users can modify prices through URL parameters or by manipulating DOM elements
2. **Client-Side Validation**: Minimal validation for payment details (card numbers, CVV)
3. **Hardcoded Discount Codes**: Discount codes including 'ADMIN100' and 'DEBUG' for 100% discounts
4. **Insecure Data Storage**: Sensitive data stored in localStorage
5. **Offline Transaction Fallback**: System accepts payments even when server is unreachable

### Server-Side Vulnerabilities
1. **SQL Injection**: Non-parameterized queries in payment processing and history endpoints
2. **Lack of Authentication**: Payment history accessible with only an email parameter
3. **Sensitive Data Exposure**: Full credit card numbers and CVVs stored in plaintext
4. **Insecure Direct Object References (IDOR)**: No validation of transaction ownership
5. **Cross-Site Request Forgery (CSRF)**: No CSRF tokens implemented

## Testing with Burp Suite

### Setting up Burp Suite for Testing
1. Configure your browser to use Burp Suite as a proxy (typically `127.0.0.1:8080`)
2. Start Burp Suite and ensure the proxy is running
3. Visit the application and navigate through the payment flow

### Test Cases for Burp Suite

#### 1. Price Manipulation
- Intercept the payment request with Burp Suite
- Modify the `amount` field to a lower value (e.g., from `25.00` to `0.01`)
- Forward the request and observe the payment being processed with the modified amount

#### 2. SQL Injection in Payment History
- Visit `http://localhost:3000/history.html`
- Intercept the request to `/api/payment-history?email=test@example.com`
- Modify the email parameter to `' OR 1=1 --`
- Forward the request to view all payment records

#### 3. Session Handling Vulnerabilities
- Use the Burp Suite Repeater to replay payment requests with different transaction IDs
- Extract a transaction ID from localStorage using the browser's dev tools
- Use this ID to access transaction details without proper authentication

#### 4. Credit Card Data Exposure
- Capture a payment request in Burp Suite
- Observe that full credit card numbers and CVVs are transmitted in plaintext
- Verify that this data is stored unencrypted in the database

## Troubleshooting

### Using the Diagnostic and Cleanup Tools

The project includes several utility tools to help identify and fix issues:

#### Diagnostic Tool
```
./diagnose.sh
```

This will check:
- If the server is running
- If the payment API endpoints are accessible
- If ngrok is configured properly
- Current environment configuration

#### Cleanup Tool
```
./cleanup.sh
```

This tool:
- Checks for common issues in server.js
- Fixes formatting problems
- Ensures CORS is properly configured

### Local Connection Issues
If you encounter 404 errors or connectivity issues when running locally:
1. Make sure the server is running on port 3000
2. Check for any console errors in the browser developer tools
3. Verify that the API endpoints (/api/process-payment and /api/payment-history) are accessible
4. Run `./set-environment.sh local` to ensure the configuration is correct

### Port Already in Use Issues
If you get an error that port 3000 is already in use:
1. Our startup scripts will automatically attempt to kill processes using port 3000
2. If this fails, you can manually find and kill the processes:
   ```
   lsof -i :3000
   kill -9 [PID]
   ```
3. Then restart the server with either `./start-local.sh` or `./use-existing-ngrok.sh`

### ngrok Connection Issues
If you're having trouble with ngrok:
1. Ensure your ngrok authtoken is configured (`ngrok authtoken YOUR_TOKEN`)
2. Check that the server is running before starting ngrok
3. Make sure CORS is working correctly (check browser console for CORS errors)
4. If one ngrok session expires, you'll get a new URL when you restart - update the config with:
   ```
   ./set-environment.sh ngrok "https://your-new-ngrok-url.ngrok-free.app"
   ```

## Disclaimer

This project contains intentional security vulnerabilities for educational purposes. DO NOT use any part of this code in production environments.