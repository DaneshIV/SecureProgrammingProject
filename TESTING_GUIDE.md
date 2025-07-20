# Practical Guide: Testing the Vulnerable Payment System

This guide provides step-by-step instructions for testing each of the vulnerabilities in our deliberately vulnerable payment system. Use these instructions for educational purposes to understand how these vulnerabilities work.

## Prerequisites

Before starting:
1. The server should be running either:
   - Locally at http://localhost:3000 (run with `./start-local.sh`)
   - Via ngrok at your ngrok URL (run with `./start-ngrok.sh`)
2. Burp Suite should be installed and configured as a proxy for your browser
3. Basic understanding of web application security testing

> **Note:** When using ngrok, replace all instances of `http://localhost:3000` in this guide with your ngrok URL.

### Setting Up Your Testing Environment

#### Local Testing (easiest for initial exploration)
1. Start the server in local mode:
   ```
   ./start-local.sh
   ```
2. Access the application at http://localhost:3000
3. Configure Burp Suite to intercept localhost traffic

#### Remote Testing with ngrok (best for testing from multiple devices or sharing)
1. Start the server with ngrok:
   ```
   ./start-ngrok.sh
   ```
2. Note the ngrok URL displayed in the terminal
3. Configure Burp Suite to intercept traffic to your ngrok domain

#### Verifying Your Setup
Run the diagnostic tool to verify that everything is configured correctly:
```
./diagnose.sh
```

## 1. Price Manipulation Testing

### Using URL Parameters
1. Navigate to http://localhost:3000/shop.html
2. Click on any "Buy Now" button
3. Observe the URL of the payment page (e.g., `payment.html?box=A`)
4. Modify the URL to include a price parameter: `payment.html?box=A&price=0.01`
5. Complete the payment process and verify the order is processed with the manipulated price

### Using Browser DevTools
1. Navigate to the payment page normally
2. Open browser DevTools (F12 or right-click > Inspect)
3. Locate the hidden input field with id="original-price"
4. Change its value to a lower amount (e.g., 0.01)
5. Complete the payment and observe the result

## 2. SQL Injection Testing

### Testing Payment History Endpoint
1. Set up Burp Suite to intercept requests
2. Navigate to http://localhost:3000/history.html (login if necessary)
3. Intercept the request to `/api/payment-history?email=test@example.com`
4. Modify the email parameter to: `' OR 1=1 --`
5. Forward the request and observe that all payment records are returned

### Testing Payment Processing
1. Prepare a payment submission but intercept with Burp Suite
2. Modify the email field in the JSON payload to: `test@example.com'; DROP TABLE payments; --`
3. Forward the request and check if the SQL injection is successful

## 3. Testing Hardcoded Discount Codes

1. Navigate to the payment page
2. In the coupon code field, try these codes one by one:
   - `WELCOME10` (10% discount)
   - `SPECIAL50` (50% discount)
   - `ADMIN100` (100% discount)
   - `DEBUG` (100% discount)
3. Observe how the discount is applied client-side without server verification

## 4. Testing Local Storage Vulnerabilities

1. Complete a payment process
2. Open browser DevTools and navigate to the Application tab
3. Look for the localStorage entries
4. Find entries like `auth` and `lastTransaction`
5. Modify these values (e.g., change the transaction amount)
6. Refresh the page or navigate to history.html to see if your changes persist

## 5. Testing Credit Card Data Exposure

1. Fill out the payment form with test card details
2. Use Burp Suite to intercept the payment request
3. Observe that full card details are sent in plaintext
4. After payment completes, request payment history
5. Note that full card details (except CVV) are returned in the response

## 6. Bypass Authentication Testing

1. Log in with a test account
2. Navigate to history.html to view your payment history
3. Intercept the request to `/api/payment-history`
4. Change the email parameter to another email address
5. Forward the request and observe if you can access another user's payment history

## 7. Cross-Site Request Forgery (CSRF) Testing

1. Create a simple HTML file with this content:
   ```html
   <html>
     <body onload="document.forms[0].submit()">
       <form action="http://localhost:3000/api/process-payment" method="POST" enctype="application/json">
         <input type="hidden" name="cardHolder" value="Hacked User">
         <input type="hidden" name="cardNumber" value="4242424242424242">
         <input type="hidden" name="expiry" value="12/25">
         <input type="hidden" name="cvv" value="123">
         <input type="hidden" name="email" value="victim@example.com">
         <input type="hidden" name="boxType" value="C">
         <input type="hidden" name="amount" value="75.00">
         <input type="hidden" name="originalPrice" value="75.00">
         <input type="hidden" name="transactionId" value="csrf123">
       </form>
     </body>
   </html>
   ```
2. Open this HTML file in your browser while logged in to the vulnerable application
3. Check if the payment is processed without your explicit consent

## 8. Testing Offline Transaction Fallback

1. Fill out the payment form
2. Before submitting, shut down the server (Ctrl+C in the terminal)
3. Submit the payment
4. Observe that the payment is "processed" locally despite server being down
5. Check localStorage for the recorded transaction

## 9. Testing for Missing Input Validation

1. Submit payments with invalid card details:
   - Card number: `1234`
   - Expiry: `99/99`
   - CVV: `9999`
2. Observe if the application accepts these invalid values

## 10. Response Manipulation with Burp Suite

1. Process a payment normally
2. In Burp Suite, go to Proxy > HTTP history
3. Find the response from the `/api/process-payment` endpoint
4. Send it to Repeater
5. Modify the response (e.g., change the item received)
6. Check if the application accepts the modified response

## Security Testing Report Template

After completing these tests, document your findings using this template:

```
# Vulnerability Test Report

## Test Case: [Name of Test]
- Vulnerability Tested: [Description]
- Test Procedure: [Steps taken]
- Expected Secure Behavior: [What should happen in a secure system]
- Actual Result: [What happened]
- Evidence: [Screenshots, request/response data]
- Severity: [High/Medium/Low]
- Recommended Fix: [How to address this issue]
```

## Conclusion

This guide demonstrates various security vulnerabilities in the payment system. Understanding these vulnerabilities and how they can be exploited is the first step in learning how to build secure applications. Remember that these techniques should only be used on systems you have permission to test, and never in production environments or against real websites.
