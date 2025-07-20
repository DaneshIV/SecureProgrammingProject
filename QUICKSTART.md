# Quickstart Guide

This guide provides the fastest way to get up and running with the Vulnerable Payment System.

## Setup Options

### Option 1: Run with Local Server (Development)
```bash
# Start the server in local mode
./start-local.sh
```
Then access at: http://localhost:3000

### Option 2: Run with Existing ngrok URL
```bash
# Start with pre-configured ngrok URL
./use-existing-ngrok.sh
```
Then access at: https://83bc16e00594.ngrok-free.app

### Option 3: Run with New ngrok Tunnel
```bash
# Start a fresh ngrok tunnel
./start-ngrok.sh
```
Then access at the URL shown in the terminal.

## Testing the Security Vulnerabilities

1. **SQL Injection Test**
   ```bash
   # Try this query parameter in the browser:
   /api/payment-history?email=test@example.com' OR 1=1 --
   ```

2. **Price Manipulation Test**
   ```bash
   # Add this to the payment page URL:
   ?box=C&price=0.01
   ```

3. **Discount Code Test**
   Enter these codes on the payment page:
   - WELCOME10 (10% off)
   - ADMIN100 (100% off)
   - DEBUG (100% off)

## Troubleshooting

### Common Issues

#### "Server unavailable" in Payment History
If you see "Server unavailable. Showing local transaction data only" when using ngrok:
1. Make sure you're using `./use-existing-ngrok.sh` to start the server
2. Try running `./validate-config.sh ngrok` to fix configuration
3. Check browser console for CORS errors

### General Troubleshooting
If you encounter issues:
1. Run `./diagnose.sh` to check the system status
2. Run `./cleanup.sh` to fix common issues
3. Run `./validate-config.sh [local|ngrok]` to ensure correct configuration
4. Check the README.md for detailed troubleshooting steps

## Documentation Files

- **README.md** - Main documentation
- **SECURITY_REPORT.md** - Analysis of all security vulnerabilities
- **TESTING_GUIDE.md** - Step-by-step guide for testing vulnerabilities
