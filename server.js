const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const app = express();
const PORT = 3000;

// Middleware
app.use(cors({
  origin: '*', // Allow all origins (for demo purposes only)
  
  /*['https://secure-programming-project.vercel.app', 'https://b3d4-2404-160-8170-8d97-9ccd-aaf-9cea-748f.ngrok-free.app'], // both allowed
  credentials: true*/
}));
app.use(express.json());
app.use(express.static('public'));

// Connect to SQLite database (creates file if not exists)
const db = new sqlite3.Database('./users.db', (err) => {
  if (err) return console.error('❌ Database connection failed:', err);
  console.log('✅ Connected to SQLite database');
});

// Create the users table if it doesn't exist
db.run(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL,
    password TEXT NOT NULL
  )
`);

// Insecure login route (vulnerable to SQL injection)
app.post('/login', (req, res) => {
  const { email, password } = req.body;

  // WARNING: This is intentionally insecure
  const query = `SELECT * FROM users WHERE email = '${email}' AND password = '${password}'`;

  console.log(`🔎 Executing SQL: ${query}`); // for debugging

  db.get(query, (err, row) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Server error' });
    }

    if (row) {
      return res.json({ message: 'Login successful' });
    } else {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
  });
});

// Signup route (uses parameterized query – safe)
app.post('/signup', (req, res) => {
  const { email, password } = req.body;

  const stmt = db.prepare('INSERT INTO users (email, password) VALUES (?, ?)');
  stmt.run(email, password, function (err) {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Signup failed' });
    }

    res.json({ message: 'Signup successful', userId: this.lastID });
  });
});

// Start the server
app.listen(PORT, '0.0.0.0',() => {
  console.log(`🚀 Server is running at http://0.0.0.0:${PORT}`);
});

//Add at the end of the server.js 
module.exports = app; // Export the app for testing
