const form = document.getElementById('auth-form');
const emailInput = document.getElementById('email');
const passwordInput = document.getElementById('password');
const message = document.getElementById('message');
const toggleLink = document.getElementById('toggle-link');
const formTitle = document.getElementById('form-title');
const toggleText = document.getElementById('toggle-text');
const backendURL = 'https://7e85-161-139-102-162.ngrok-free.app'

let isLogin = true;

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

form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = emailInput.value;
    const password = passwordInput.value;
    const endpoint = isLogin ? '/login' : '/signup';
  
    try {
      const res = await fetch(`${backendURL}${endpoint}`, {  // Use the ngrok URL here
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });
  
      const data = await res.json();
      message.textContent = data.message;
      message.style.color = res.ok ? 'green' : 'red';
  
      if (res.ok) {
        // Simulate session (not secure – for demo only)
        localStorage.setItem("auth", JSON.stringify({ email }));
  
        // Redirect to dashboard
        window.location.href = "public/dashboard.html";
      }
    } catch (err) {
      message.textContent = 'Error connecting to server';
      message.style.color = 'red';
    }
  });
  