function tokenHeader() {
  const token = localStorage.getItem("token");
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function apiGet(url) {
  const res = await fetch(url, { headers: tokenHeader() });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.detail || res.statusText);
  }
  return res.json();
}

function formatMoney(value, currency = "RUB") {
  const num = Number(value);
  if (Number.isNaN(num)) return value;
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency
  }).format(num);
}

function formatDate(iso) {
  if (!iso) return "";
  const d = new Date(iso);
  return d.toLocaleDateString("ru-RU");
}

function daysUntil(dateStr) {
  if (!dateStr) return "";
  const target = new Date(dateStr);
  const now = new Date();
  const diff = Math.ceil((target - now) / (1000 * 60 * 60 * 24));
  if (diff < 0) return `-${Math.abs(diff)} дн.`;
  if (diff === 0) return "Сегодня";
  return `Через ${diff} дн.`;
}

async function loadIndex() {
  const [analytics, upcoming] = await Promise.all([
    apiGet("/api/analytics"),
    apiGet("/api/notifications/upcoming?days=10")
  ]);

  document.getElementById("kpiMonthly").textContent = formatMoney(analytics.totals.month);
  document.getElementById("kpiActive").textContent = Object.values(analytics.by_service || {}).length;
  const next = upcoming.items && upcoming.items[0];
  document.getElementById("kpiNext").textContent = next ? daysUntil(next.next_billing_date) : "—";
  document.getElementById("kpiSavings").textContent = formatMoney(0);

  const list = document.getElementById("upcomingList");
  list.innerHTML = "";
  (upcoming.items || []).forEach(item => {
    const row = document.createElement("div");
    row.className = "list-item";
    row.innerHTML = `
      <div class="left">
        <div class="logo-pill" style="background:#111827;">${item.name[0] || "?"}</div>
        <div>
          <div>${item.name}</div>
          <small>${daysUntil(item.next_billing_date)}</small>
        </div>
      </div>
      <strong>${formatMoney(item.amount, item.currency)}</strong>
    `;
    list.appendChild(row);
  });
}

async function loadSubscriptions() {
  const data = await apiGet("/api/subscriptions");
  const container = document.getElementById("subscriptionsList");
  container.innerHTML = "";
  data.forEach(sub => {
    const card = document.createElement("div");
    card.className = "subscription-card";
    card.innerHTML = `
      <div class="meta">
        <div class="logo-pill" style="background:#1f2937;">${sub.name[0] || "?"}</div>
        <div>
          <h4>${sub.name} <span class="tag">Активна</span></h4>
          <small>${sub.category || "Без категории"}</small>
        </div>
      </div>
      <div class="details">
        <span>Стоимость: <strong>${formatMoney(sub.amount, sub.currency)}</strong></span>
        <span>Период: <strong>${sub.billing_period}</strong></span>
        <span>Следующий платёж: <strong>${formatDate(sub.next_billing_date)}</strong></span>
      </div>
      <div class="pills"><span class="pill">${sub.category || "Без категории"}</span></div>
    `;
    container.appendChild(card);
  });
}

async function loadCalendar() {
  const [forecast, upcoming] = await Promise.all([
    apiGet("/api/forecast"),
    apiGet("/api/notifications/upcoming?days=7")
  ]);

  document.getElementById("calMonthly").textContent = formatMoney(forecast.month);
  document.getElementById("calCount").textContent = upcoming.items.length;
  document.getElementById("calNext").textContent = upcoming.items[0]
    ? daysUntil(upcoming.items[0].next_billing_date)
    : "—";

  const list = document.getElementById("calendarUpcoming");
  list.innerHTML = "";
  upcoming.items.forEach(item => {
    const row = document.createElement("div");
    row.className = "list-item";
    row.innerHTML = `
      <div class="left">
        <div class="logo-pill" style="background:#111827;">${item.name[0] || "?"}</div>
        <div>
          <div>${item.name}</div>
          <small>${formatDate(item.next_billing_date)}</small>
        </div>
      </div>
      <strong>${formatMoney(item.amount, item.currency)}</strong>
    `;
    list.appendChild(row);
  });
}

async function loadAnalytics() {
  const analytics = await apiGet("/api/analytics");
  document.getElementById("anMonthly").textContent = formatMoney(analytics.totals.month);
  document.getElementById("anHalfYear").textContent = formatMoney(analytics.totals.half_year);
  document.getElementById("anYear").textContent = formatMoney(analytics.totals.year);
}

async function loadSettings() {
  const me = await apiGet("/api/auth/me");
  document.getElementById("setEmail").value = me.email || "";
  document.getElementById("setPhone").value = me.phone || "";
}

(async function init() {
  const page = document.body.dataset.page;
  try {
    if (page === "index") await loadIndex();
    if (page === "subscriptions") await loadSubscriptions();
    if (page === "calendar") await loadCalendar();
    if (page === "analytics") await loadAnalytics();
    if (page === "settings") await loadSettings();
  } catch (e) {
    console.error(e);
    alert("Ошибка API: " + e.message + ". Проверь, что ты вошел и backend запущен.");
  }
})();
