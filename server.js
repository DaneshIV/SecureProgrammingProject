const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();

const app = express();
const PORT = 3000;

// CORS configuration
const corsOptions = {
  origin: [
    'https://secure-programming-project.vercel.app',
    'https://83bc16e00594.ngrok-free.app'
  ],
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type'],
  credentials: true
};

app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // enable preflight for all routes

// Body parser and static files
app.use(express.json());
app.use(express.static('public'));

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

// Insecure login (vulnerable to SQL injection)
app.post('/login', (req, res) => {
  const { email, password } = req.body;
  const query = `SELECT * FROM users WHERE email = '${email}' AND password = '${password}'`;

  console.log(`🔎 Executing SQL: ${query}`);

  db.get(query, (err, row) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Server error' });
    }
    if (row) {
      res.json({ message: 'Login successful' });
    } else {
      res.status(401).json({ message: 'Invalid credentials' });
    }
  });
});

// Signup route (parameterized query — safe)
app.post('/signup', (req, res) => {
  const { email, password } = req.body;
  const stmt = db.prepare('INSERT INTO users (email, password) VALUES (?, ?)');
  stmt.run(email, password, function(err) {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Signup failed' });
    }
    res.json({ message: 'Signup successful', userId: this.lastID });
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
app.post('/api/purchase', (req, res) => {
  const { email, boxType } = req.body;

  // Insecure: Blind box logic fully exposed
  const blindBoxItems = {
    A: ['Sticker', 'Keychain', 'Pen'],
    B: ['Notebook', 'T-Shirt', 'Mug'],
    C: ['Power Bank', 'Bluetooth Speaker', 'Wireless Earbuds']
  };

  const items = blindBoxItems[boxType];
  if (!items) return res.status(400).json({ error: 'Invalid box type' });

  const randomItem = items[Math.floor(Math.random() * items.length)];

  // Insecure: No parameterized query
  const insertQuery = `INSERT INTO purchases (email, boxType, item) VALUES ('${email}', '${boxType}', '${randomItem}')`;
  console.log(`💥 Inserting into DB: ${insertQuery}`);
  db.run(insertQuery, (err) => {
    if (err) {
      console.error('Insert failed:', err);
      return res.status(500).json({ error: 'Purchase failed' });
    }
    res.json({ item: randomItem });
  });
});

// Server start
app.listen(PORT, () => {
  console.log(`🚨 Vulnerable server running at http://localhost:${PORT}`);
});

module.exports = app; // for testing
