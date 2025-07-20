const form = document.getElementById('auth-form');
const emailInput = document.getElementById('email');
const passwordInput = document.getElementById('password');
const message = document.getElementById('message');
const toggleLink = document.getElementById('toggle-link');
const formTitle = document.getElementById('form-title');
const toggleText = document.getElementById('toggle-text');
const backendURL = 'https://83bc16e00594.ngrok-free.app'

let isLogin = true;
let csrfToken = '';

// Remove global CSRF token fetch on page load

toggleLink.addEventListener('click', (e) => {
  e.preventDefault();
  isLogin = !isLogin;
  formTitle.textContent = isLogin ? 'Login' : 'Sign Up';
  toggleText.innerHTML = isLogin
    ? `Don't have an account? <a href="#" id="toggle-link">Sign Up</a>`
    : `Already have an account? <a href="#" id="toggle-link">Login</a>`;
  document.getElementById('toggle-link').addEventListener('click', toggleLink.onclick);
  message.textContent = '';
});

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = emailInput.value;
    const password = passwordInput.value;
    if (!isValidEmail(email)) {
      message.textContent = 'Invalid email format';
      message.style.color = 'red';
      return;
    }
    if (password.length < 8) {
      message.textContent = 'Password must be at least 8 characters';
      message.style.color = 'red';
      return;
    }
    const endpoint = isLogin ? '/login' : '/signup';
  
    try {

      // Fetch a fresh CSRF token before the request
      const csrfRes = await fetch('/api/csrf-token', { credentials: 'include' });
      const csrfData = await csrfRes.json();
      const csrfToken = csrfData.csrfToken;

      const res = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'CSRF-Token': csrfToken
        },
        body: JSON.stringify({ email, password }),
        credentials: 'include'
      });
  
      const data = await res.json();
      message.textContent = data.message;
      message.style.color = res.ok ? 'green' : 'red';
  
      if (res.ok) {
        // Redirect to dashboard
        window.location.href = "/dashboard.html";

      }
    } catch (err) {
      message.textContent = 'Error connecting to server';
      message.style.color = 'red';
    }
  });

// Example logout function
async function logout() {
  // Fetch a fresh CSRF token before logout
  const csrfRes = await fetch('/api/csrf-token', { credentials: 'include' });
  const csrfData = await csrfRes.json();
  const csrfToken = csrfData.csrfToken;

  await fetch('/logout', {
    method: 'POST',
    headers: { 'CSRF-Token': csrfToken },
    credentials: 'include'
  });
  window.location.href = '/';
}
  