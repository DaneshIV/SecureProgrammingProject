const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
const saltRounds = 10;
const session = require('express-session');
const csrf = require('csurf');
const { v4: uuidv4 } = require('uuid');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = 3000;

// CORS configuration
const corsOptions = {
  origin: [
    'http://localhost:3000',   
    'https://secure-programming-project.vercel.app',
    'https://83bc16e00594.ngrok-free.app'
  ],
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'CSRF-Token'],
  credentials: true
};

app.use(cors(corsOptions));

app.options('*', cors(corsOptions)); // enable preflight for all routes

// Body parser and static files
app.use(express.json());
app.use(express.static('public'));

// Session middleware
app.use(session({
  secret: 'Secure-Programming',
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: false, // set to true in production with HTTPS
    sameSite: 'strict',
    maxAge: 1000 * 60 * 60 // 1 hour
  }
}));

// CSRF protection middleware (after session)
const csrfProtection = csrf();
app.use(csrfProtection);

// Provide CSRF token to frontend
app.get('/api/csrf-token', (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// Simple request logger
app.use((req, res, next) => {
  console.log(`📥 ${req.method} request to ${req.url}`);
  next();
});

// Connect to SQLite database (creates file if not exists)
const db = new sqlite3.Database('./users.db', err => {
  if (err) {
    console.error('❌ Database connection failed:', err);
    process.exit(1);
  }
  console.log('✅ Connected to SQLite database');
});

// Users table
db.run(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL,
    password TEXT NOT NULL
  )
`);

const validateEmail = email =>
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

const validatePassword = password =>
  typeof password === 'string' &&
  password.length >= 8 &&
  /[A-Z]/.test(password) &&
  /[0-9]/.test(password) &&
  /[^A-Za-z0-9]/.test(password); // special char

// Rate limiter for login endpoint
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // limit each IP to 5 login requests per windowMs
  message: { message: 'Too many login attempts, please try again later.' }
});

// Insecure login (vulnerable to SQL injection)
app.post('/login', loginLimiter, (req, res) => {
  const { email, password } = req.body;
  if (!validateEmail(email) || !validatePassword(password)) {
    return res.status(400).json({ message: 'Invalid input' });
  }
  const query = 'SELECT * FROM users WHERE email = ?';
  db.get(query, [email], (err, row) => {
    if (err) return res.status(500).json({ message: 'Server error' });
    if (!row) return res.status(401).json({ message: 'Invalid credentials' });

    bcrypt.compare(password, row.password, (err, match) => {
      if (err || !match) return res.status(401).json({ message: 'Invalid credentials' });
      // Regenerate session ID to prevent session fixation
      req.session.regenerate(() => {
        req.session.user = { email };
        res.json({ message: 'Login successful' });
      });
    });
  });
});

// Logout endpoint
app.post('/logout', (req, res) => {
  req.session.destroy(err => {
    if (err) return res.status(500).json({ message: 'Logout failed' });
    res.clearCookie('connect.sid');
    res.json({ message: 'Logged out' });
  });
});

// Middleware to require authentication
function requireAuth(req, res, next) {
  if (!req.session.user) {
    return res.status(401).json({ message: 'Unauthorized' });
  }
  next();
}

// Insecure signup (vulnerable to SQL injection)
app.post('/signup', (req, res) => {
  const { email, password } = req.body;
  if (!validateEmail(email) || !validatePassword(password)) {
    return res.status(400).json({ message: 'Invalid input' });
  }
  bcrypt.hash(password, saltRounds, (err, hashedPassword) => {
    if (err) {
      return res.status(500).json({ message: 'Error hashing password' });
    }
    const stmt = db.prepare('INSERT INTO users (email, password) VALUES (?, ?)');
    stmt.run(email, hashedPassword, function(err) {
      if (err) return res.status(500).json({ message: 'Signup failed' });
      res.json({ message: 'Signup successful', userId: this.lastID });
    });
  });
});

// Blind box database (optional)
db.run(`
  CREATE TABLE IF NOT EXISTS purchases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL,
    boxType TEXT NOT NULL,
    item TEXT NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  )
`);

// Vulnerable blind box API (no input validation, no auth)

app.post('/api/purchase', requireAuth, (req, res) => {
  const { email, boxType } = req.body;

  // Use session user email for security
  const userEmail = req.session.user.email;

  // Insecure: Blind box logic fully exposed
  const blindBoxItems = {
    A: ['Sticker', 'Keychain', 'Pen'],
    B: ['Notebook', 'T-Shirt', 'Mug'],
    C: ['Power Bank', 'Bluetooth Speaker', 'Wireless Earbuds']
  };

  const items = blindBoxItems[boxType];
  if (!items) return res.status(400).json({ error: 'Invalid box type' });

  const randomItem = items[Math.floor(Math.random() * items.length)];


  // Secure: Parameterized query
  const stmt = db.prepare('INSERT INTO purchases (email, boxType, item) VALUES (?, ?, ?)');
  stmt.run(userEmail, boxType, randomItem, (err) => {

    if (err) {
      console.error('Insert failed:', err);
      return res.status(500).json({ error: 'Purchase failed' });
    }
    res.json({ item: randomItem });
  });
});

// Create payments table with intentionally vulnerable design
db.run(`
  CREATE TABLE IF NOT EXISTS payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    transaction_id TEXT,
    email TEXT,
    card_holder TEXT,
    card_number TEXT,       /* Vulnerable: Storing full card numbers */
    expiry TEXT,
    cvv TEXT,               /* Vulnerable: Storing CVV */
    box_type TEXT,
    amount REAL,
    original_price REAL,
    coupon_code TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  )
`);

function validateCardHolder(name) {
  return typeof name === 'string' && name.trim().length > 0;
}
function validateCardNumber(number) {
  return typeof number === 'string' && /^\d{13,19}$/.test(number);
}
function validateExpiry(expiry) {
  return typeof expiry === 'string' && /^(0[1-9]|1[0-2])\/(\d{2}|\d{4})$/.test(expiry);
}
function validateCVV(cvv) {
  return typeof cvv === 'string' && /^\d{3,4}$/.test(cvv);
}
function validateBoxType(boxType) {
  return ['A', 'B', 'C'].includes(boxType);
}
function validateCouponCode(code) {
  return typeof code === 'string' || code === undefined;
}

// Vulnerable payment processing endpoint
app.post('/api/process-payment', requireAuth, (req, res) => {
  const {
    cardHolder,
    cardNumber,
    expiry,
    cvv,
    email,
    boxType,
    couponCode,
    timestamp
  } = req.body;

  // Validate payment fields
  if (!validateCardHolder(cardHolder) ||
      !validateCardNumber(cardNumber) ||
      !validateExpiry(expiry) ||
      !validateCVV(cvv) ||
      !validateBoxType(boxType) ||
      !validateCouponCode(couponCode)) {
    return res.status(400).json({ error: 'Invalid payment input' });
  }
  
  // 1. Calculate price on the server
  const boxPrices = { A: 10, B: 20, C: 30 };
  let originalPrice = boxPrices[boxType] || boxPrices.A;
  let amount = originalPrice;

  // 2. Validate/apply coupon on the server
  if (couponCode === 'DISCOUNT10') {
    amount = amount * 0.9; // 10% off
  }

  // 3. Generate transactionId on the server
  const transactionId = uuidv4();

  console.log(`💳 Processing payment of $${amount} for ${email}`);

  // Only store last 4 digits of card number, do not store cvv
  const cardLastFour = cardNumber.slice(-4);

  const stmt = db.prepare(`
    INSERT INTO payments (
      transaction_id, email, card_holder, card_number, expiry,
      box_type, amount, original_price, coupon_code
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  stmt.run(
    transactionId, email, cardHolder, cardLastFour, expiry,
    boxType, amount, originalPrice, couponCode,
    function(err) {
      if (err) {
        console.error('💥 Payment error:', err);
        return res.status(500).json({ error: 'Payment processing failed' });
      }
      
      // Process the blind box item
      const blindBoxItems = {
        A: ['Sticker', 'Keychain', 'Pen'],
        B: ['Notebook', 'T-Shirt', 'Mug'],
        C: ['Power Bank', 'Bluetooth Speaker', 'Wireless Earbuds']
      };
      
      const items = blindBoxItems[boxType] || blindBoxItems.A;
      const randomItem = items[Math.floor(Math.random() * items.length)];
      
      // Secure: Parameterized query for purchases
      const purchaseStmt = db.prepare('INSERT INTO purchases (email, boxType, item) VALUES (?, ?, ?)');
      purchaseStmt.run(email, boxType, randomItem, (err) => {
        if (err) {
          console.error('Purchase record error:', err);
          // Continue despite the error - vulnerable behavior
        }
        
        // Success response with minimal card info
        res.json({
          success: true,
          message: 'Payment processed successfully',
          transactionId: transactionId,
          paymentId: this.lastID,
          item: randomItem,
          cardLastFour: cardLastFour,
          amount: amount,
          originalPrice: originalPrice,
          timestamp: new Date().toISOString()
        });
      });
    }
  );
});

// Vulnerable payment history endpoint (no proper authentication)
app.get('/api/payment-history', requireAuth, (req, res) => {
  const userEmail = req.session.user.email;

  // Secure: Parameterized query
  const query = `
    SELECT * FROM payments 
    WHERE email = ?
    ORDER BY created_at DESC
  `;

  db.all(query, [userEmail], (err, rows) => {
    if (err) {
      console.error('Payment history error:', err);
      return res.status(500).json({ error: 'Failed to retrieve payment history' });
    }
    
    // Vulnerable: Returning all data including sensitive card details
    res.json(rows);
  });
});

// Server start
app.listen(PORT, () => {
  console.log(`🚨 Vulnerable server running at http://localhost:${PORT}`);
});

module.exports = app; // for testing
