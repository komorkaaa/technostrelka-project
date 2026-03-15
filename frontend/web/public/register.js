const regForm = document.getElementById("registerForm");
const regStatus = document.getElementById("regStatus");
const toLogin = document.getElementById("toLogin");

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

regForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  regStatus.textContent = "Регистрация...";
  try {
    const email = document.getElementById("regEmail").value.trim();
    const password = document.getElementById("regPassword").value;
    await register(email, password);
    regStatus.textContent = "Готово. Переходим ко входу...";
    setTimeout(() => {
      window.location.href = "/login";
    }, 400);
  } catch (err) {
    regStatus.textContent = err.message;
  }
});

toLogin.addEventListener("click", () => {
  regForm.reset();
  regStatus.textContent = "";
  window.location.href = "/login";
});
