const regForm = document.getElementById("registerForm");
const loginForm = document.getElementById("loginForm");
const regStatus = document.getElementById("regStatus");
const loginStatus = document.getElementById("loginStatus");
const logoutBtn = document.getElementById("logoutBtn");

async function register(email, password) {
  const res = await fetch("/api/auth/register", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password })
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.detail || "Registration failed");
  return data;
}

async function login(email, password) {
  const body = new URLSearchParams();
  body.set("username", email);
  body.set("password", password);

  const res = await fetch("/api/auth/login", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.detail || "Login failed");
  return data;
}

regForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  regStatus.textContent = "Регистрация...";
  try {
    const email = document.getElementById("regEmail").value.trim();
    const password = document.getElementById("regPassword").value;
    await register(email, password);
    regStatus.textContent = "Готово. Теперь войдите.";
  } catch (err) {
    regStatus.textContent = err.message;
  }
});

loginForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  loginStatus.textContent = "Вход...";
  try {
    const email = document.getElementById("loginEmail").value.trim();
    const password = document.getElementById("loginPassword").value;
    const data = await login(email, password);
    localStorage.setItem("token", data.access_token);
    loginStatus.textContent = "Успешно. Токен сохранён.";
  } catch (err) {
    loginStatus.textContent = err.message;
  }
});

logoutBtn.addEventListener("click", () => {
  localStorage.removeItem("token");
  loginStatus.textContent = "Токен удалён.";
});
