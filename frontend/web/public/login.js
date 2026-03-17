const loginForm = document.getElementById("loginForm");
const loginStatus = document.getElementById("loginStatus");
const toRegister = document.getElementById("toRegister");

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

loginForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  loginStatus.textContent = "Вход...";
  try {
    const email = document.getElementById("loginEmail").value.trim();
    const password = document.getElementById("loginPassword").value;
    const data = await login(email, password);
    localStorage.setItem("token", data.access_token);
    loginStatus.textContent = "Успешно. Переходим на главную...";
    setTimeout(() => {
      window.location.href = "/home";
    }, 400);
  } catch (err) {
    loginStatus.textContent = err.message;
  }
});

toRegister.addEventListener("click", () => {
  loginForm.reset();
  loginStatus.textContent = "";
  window.location.href = "/register";
});
