# Vulnerable Payment System Security Report

## Overview
This document provides an in-depth analysis of the security vulnerabilities deliberately implemented in this payment system. It explains the vulnerabilities, their potential impact, and recommendations for secure coding practices.

## Security Vulnerabilities Analysis

### 1. Client-Side Price Manipulation
**Vulnerability**: The payment page allows price manipulation through URL parameters and client-side JavaScript.

**Code Example**:
```javascript
// Vulnerable: Accepting any price from URL parameter
boxPrice = parseFloat(urlParams.get('price')) || 25.00;
```

**Impact**: Attackers can set arbitrary prices, potentially purchasing items for much less than their actual value.

**Secure Alternative**: Always validate and set prices server-side based on product IDs, never trust client inputs for pricing.

### 2. SQL Injection

**Vulnerability**: The application uses string concatenation to build SQL queries.

**Code Example**:
```javascript
const query = `
  INSERT INTO payments (
    transaction_id, email, card_holder, card_number, expiry, cvv,
    box_type, amount, original_price, coupon_code
  ) VALUES (
    '${transactionId}',
    '${email}',
    '${cardHolder}',
    '${cardNumber}',
    '${expiry}',
    '${cvv}',
    '${boxType}',
    ${amount},
    ${originalPrice},
    '${couponCode}'
  )
`;
```

**Impact**: Attackers can inject malicious SQL code to extract, modify, or delete data from the database.

**Secure Alternative**: Use parameterized queries with prepared statements:
```javascript
const stmt = db.prepare(`
  INSERT INTO payments (
    transaction_id, email, card_holder, card_number, expiry, cvv,
    box_type, amount, original_price, coupon_code
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`);
stmt.run(
  transactionId, email, cardHolder, cardNumber, expiry, cvv,
  boxType, amount, originalPrice, couponCode
);
```

### 3. Insecure Storage of Payment Information

**Vulnerability**: Credit card details are stored in plaintext in the database.

**Code Example**:
```javascript
CREATE TABLE IF NOT EXISTS payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id TEXT,
  email TEXT,
  card_holder TEXT,
  card_number TEXT,       /* Vulnerable: Storing full card numbers */
  expiry TEXT,
  cvv TEXT,               /* Vulnerable: Storing CVV */
  // ...
)
```

**Impact**: If the database is compromised, attackers gain direct access to payment card details.

**Secure Alternative**: 
- Never store sensitive card data like full card numbers and CVVs
- Use a payment processor like Stripe or PayPal
- If card numbers must be stored, encrypt them with strong encryption
- Only store the last 4 digits for reference

### 4. Lack of Authentication and Authorization

**Vulnerability**: Payment history can be accessed by simply providing an email parameter.

**Code Example**:
```javascript
app.get('/api/payment-history', (req, res) => {
  const { email } = req.query;
  
  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }
  
  // Vulnerable: SQL injection possible with email parameter
  const query = `
    SELECT * FROM payments 
    WHERE email = '${email}'
    ORDER BY created_at DESC
  `;
  
  db.all(query, (err, rows) => {
    if (err) {
      console.error('Payment history error:', err);
      return res.status(500).json({ error: 'Failed to retrieve payment history' });
    }
    
    // Vulnerable: Returning all data including sensitive card details
    res.json(rows);
  });
});
```

**Impact**: Any user can access anyone else's payment history by guessing or knowing their email address.

**Secure Alternative**: 
- Implement proper session-based authentication
- Use JWT or other secure token mechanism
- Verify that the authenticated user matches the requested data owner
- Implement proper access controls

### 5. Client-Side Coupon Validation

**Vulnerability**: Coupon codes and their discount values are hardcoded in the client-side JavaScript.

**Code Example**:
```javascript
// Vulnerable: Discount codes hardcoded in client-side JavaScript
const coupons = {
  'WELCOME10': 0.1,    // 10% off
  'SPECIAL50': 0.5,    // 50% off
  'FREESHIP': 0.15,    // 15% off (misleading name)
  'ADMIN100': 1.0,     // 100% off (admin discount)
  'DEBUG': 1.0         // 100% off (debug discount)
};
```

**Impact**: Attackers can easily discover "hidden" discount codes by inspecting the JavaScript code.

**Secure Alternative**: 
- Validate coupon codes server-side
- Store coupon codes in a database with expiration dates and usage limits
- Implement rate limiting for coupon attempts

### 6. Insecure Session Handling

**Vulnerability**: Session information is stored in localStorage without proper verification.

**Code Example**:
```javascript
// Vulnerable: Storing transaction details in localStorage
localStorage.setItem('lastTransaction', JSON.stringify({
  id: paymentData.transactionId,
  amount: paymentData.amount,
  boxType: paymentData.boxType,
  date: new Date().toISOString()
}));
```

**Impact**: Vulnerable to XSS attacks that can steal session data, and localStorage persists even after sessions should be expired.

**Secure Alternative**: 
- Use HttpOnly cookies for session management
- Implement proper session timeouts
- Use secure, signed cookies or tokens

## Burp Suite Testing Guide

### Intercepting and Modifying Requests

1. **Start Burp Suite and Configure Browser**:
   - Open Burp Suite Professional/Community
   - Configure browser to use proxy (127.0.0.1:8080)
   - Install Burp Suite CA certificate in your browser

2. **Intercept Payment Requests**:
   - In Burp Suite, go to the Proxy tab and ensure "Intercept is on"
   - In your browser, navigate to the payment page and fill out the form
   - Submit the form and Burp Suite will intercept the request
   - Modify the JSON payload (e.g., change the amount value from 25.00 to 0.01)
   - Click "Forward" to send the modified request

3. **Testing SQL Injection**:
   - Intercept a request to `/api/payment-history?email=test@example.com`
   - Modify the email parameter to inject SQL: `' OR 1=1 --`
   - Forward the request and observe the response containing all payment records

### Advanced Testing with Burp Suite

1. **Using Repeater for Testing**:
   - Right-click on any intercepted request and select "Send to Repeater"
   - Modify the request parameters to test different scenarios
   - Click "Send" to execute the request and analyze the response

2. **Testing for CSRF Vulnerabilities**:
   - Observe that there are no CSRF tokens in the requests
   - Create a simple HTML form that submits to the payment endpoint
   - Test if the payment is processed without proper origin validation

3. **Using Intruder for Automated Testing**:
   - Send a payment request to Intruder
   - Set payload positions around the coupon code field
   - Use a wordlist of common coupon codes
   - Run the attack to automatically test multiple codes

## Security Improvement Roadmap

### Short-term Fixes
1. Implement server-side validation for all user inputs
2. Use parameterized queries for all database operations
3. Remove sensitive data from responses
4. Implement proper authentication for all API endpoints

### Long-term Improvements
1. Integrate a secure payment processor instead of handling card details directly
2. Implement proper encryption for any sensitive data
3. Add comprehensive logging and monitoring
4. Conduct regular security testing

## Conclusion
This vulnerable payment system demonstrates common security pitfalls in web applications. By understanding these vulnerabilities and their remediation strategies, developers can build more secure payment systems in production environments.

*Note: This document is for educational purposes only. The vulnerabilities described should never be implemented in production systems.*
