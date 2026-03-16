const token = localStorage.getItem("token");
const notifDays = parseInt(localStorage.getItem("notifDays") || "7", 10);

function requireAuth() {
  const page = document.body.dataset.page;
  if (!token && page) {
    window.location.href = "/login";
  }
}

function tokenHeader() {
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function apiRequest(method, url, body) {
  const headers = { ...tokenHeader() };
  let payload;
  if (body !== undefined) {
    if (body instanceof URLSearchParams) {
      headers["Content-Type"] = "application/x-www-form-urlencoded";
      payload = body;
    } else {
      headers["Content-Type"] = "application/json";
      payload = JSON.stringify(body);
    }
  }
  const res = await fetch(url, { method, headers, body: payload });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.detail || res.statusText);
  }
  return res.status === 204 ? null : res.json();
}

const apiGet = (url) => apiRequest("GET", url);
const apiPost = (url, body) => apiRequest("POST", url, body);
const apiPut = (url, body) => apiRequest("PUT", url, body);
const apiPatch = (url, body) => apiRequest("PATCH", url, body);
const apiDelete = (url) => apiRequest("DELETE", url);

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

function addDays(date, days) {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}

function addMonths(date, months) {
  const d = new Date(date);
  d.setMonth(d.getMonth() + months);
  return d;
}

function addYears(date, years) {
  const d = new Date(date);
  d.setFullYear(d.getFullYear() + years);
  return d;
}

function nextDateFromNow(period) {
  const now = new Date();
  if (period === "weekly") return addDays(now, 7);
  if (period === "yearly") return addYears(now, 1);
  return addMonths(now, 1);
}

function isPaused(nextDate) {
  if (!nextDate) return false;
  const diff = (new Date(nextDate) - new Date()) / (1000 * 60 * 60 * 24);
  return diff > 180;
}

function svgLineChart(points, width = 520, height = 220) {
  if (!points.length) return "";
  const max = Math.max(...points.map(p => p.value)) || 1;
  const min = Math.min(...points.map(p => p.value)) || 0;
  const pad = 28;
  const w = width - pad * 2;
  const h = height - pad * 2;

  const coords = points.map((p, i) => {
    const x = pad + (w * i) / Math.max(points.length - 1, 1);
    const y = pad + h - ((p.value - min) / (max - min || 1)) * h;
    return { x, y, label: p.label, value: p.value };
  });

  const gridLines = Array.from({ length: 5 }).map((_, i) => {
    const y = pad + (h * i) / 4;
    return `<line x1="${pad}" y1="${y}" x2="${pad + w}" y2="${y}" stroke="#e5e7eb" stroke-dasharray="4 4"/>`;
  });

  return `
    <svg viewBox="0 0 ${width} ${height}" width="100%" height="100%">
      ${gridLines.join("")}
      <polyline fill="none" stroke="#8b2cff" stroke-width="3" points="${coords.map(c => `${c.x},${c.y}`).join(" ")}" />
      ${coords.map(c => `<circle cx="${c.x}" cy="${c.y}" r="4" fill="#8b2cff"/>`).join("")}
      ${coords.map(c => `<text x="${c.x}" y="${c.y - 8}" text-anchor="middle" font-size="10" fill="#6b7280">${c.label}</text>`).join("")}
      <text x="${pad}" y="${pad - 8}" font-size="10" fill="#6b7280">${formatMoney(max)}</text>
      <text x="${pad}" y="${height - 6}" font-size="10" fill="#6b7280">${formatMoney(min)}</text>
    </svg>
  `;
}

function svgBars(data, width = 520, height = 220) {
  if (!data.length) return "";
  const max = Math.max(...data.map(d => d.value)) || 1;
  const pad = 28;
  const w = width - pad * 2;
  const h = height - pad * 2;
  const barW = w / data.length - 8;

  const gridLines = Array.from({ length: 5 }).map((_, i) => {
    const y = pad + (h * i) / 4;
    return `<line x1="${pad}" y1="${y}" x2="${pad + w}" y2="${y}" stroke="#e5e7eb" stroke-dasharray="4 4"/>`;
  });

  return `
    <svg viewBox="0 0 ${width} ${height}" width="100%" height="100%">
      ${gridLines.join("")}
      ${data.map((d, i) => {
        const x = pad + i * (barW + 8);
        const barH = (d.value / max) * h;
        const y = pad + (h - barH);
        return `
          <rect x="${x}" y="${y}" width="${barW}" height="${barH}" fill="#7c3aed" rx="6"></rect>
          <text x="${x + barW / 2}" y="${y - 6}" text-anchor="middle" font-size="10" fill="#6b7280">${d.label}</text>
        `;
      }).join("")}
      <text x="${pad}" y="${pad - 8}" font-size="10" fill="#6b7280">${formatMoney(max)}</text>
    </svg>
  `;
}

function svgDonut(data, width = 240, height = 240) {
  const total = data.reduce((s, d) => s + d.value, 0) || 1;
  const cx = width / 2;
  const cy = height / 2;
  const r = 90;
  let start = 0;
  const colors = ["#8b2cff", "#2563eb", "#16a34a", "#f97316", "#ef4444", "#0ea5e9"];

  const arcs = data.map((d, i) => {
    const angle = (d.value / total) * Math.PI * 2;
    const end = start + angle;
    const x1 = cx + r * Math.cos(start);
    const y1 = cy + r * Math.sin(start);
    const x2 = cx + r * Math.cos(end);
    const y2 = cy + r * Math.sin(end);
    const large = angle > Math.PI ? 1 : 0;
    const path = `M ${cx} ${cy} L ${x1} ${y1} A ${r} ${r} 0 ${large} 1 ${x2} ${y2} Z`;
    const mid = start + angle / 2;
    const lx = cx + (r + 14) * Math.cos(mid);
    const ly = cy + (r + 14) * Math.sin(mid);
    start = end;

    return `
      <path d="${path}" fill="${colors[i % colors.length]}"></path>
      <text x="${lx}" y="${ly}" text-anchor="middle" font-size="10" fill="#6b7280">${d.label}</text>
    `;
  });

  return `
    <svg viewBox="0 0 ${width} ${height}" width="100%" height="100%">
      ${arcs.join("")}
      <circle cx="${cx}" cy="${cy}" r="50" fill="#fff"></circle>
      <text x="${cx}" y="${cy}" text-anchor="middle" dominant-baseline="middle" font-size="12" fill="#6b7280">Категории</text>
    </svg>
  `;
}

async function updateBadge() {
  const badge = document.getElementById("notifBadge");
  if (!badge) return;
  const data = await apiGet(`/api/notifications/upcoming?days=${notifDays}`);
  badge.querySelector("span").textContent = data.items.length;
}

async function loadHome() {
  const [analytics, chart, upcoming] = await Promise.all([
    apiGet("/api/analytics"),
    apiGet("/api/analytics/chart?period=month"),
    apiGet(`/api/notifications/upcoming?days=${notifDays}`)
  ]);

  document.getElementById("kpiMonthly").textContent = formatMoney(analytics.totals.month);
  document.getElementById("kpiActive").textContent = Object.values(analytics.by_service || {}).length;
  document.getElementById("kpiNext").textContent = upcoming.items[0] ? daysUntil(upcoming.items[0].next_billing_date) : "—";
  document.getElementById("kpiSavings").textContent = formatMoney(0);

  const list = document.getElementById("upcomingList");
  list.innerHTML = "";
  upcoming.items.forEach(item => {
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

  const chartContainer = document.getElementById("homeChart");
  chartContainer.innerHTML = svgLineChart(chart.series.map(p => ({ label: p.label, value: Number(p.value) })));
}

async function loadSubscriptions() {
  const data = await apiGet("/api/subscriptions");
  const container = document.getElementById("subscriptionsList");
  container.innerHTML = "";
  data.forEach(sub => {
    const paused = isPaused(sub.next_billing_date);
    const card = document.createElement("div");
    card.className = "subscription-card";
    card.innerHTML = `
      <div class="meta">
        <div class="logo-pill" style="background:#1f2937;">${sub.name[0] || "?"}</div>
        <div>
          <h4>${sub.name} <span class="tag ${paused ? "paused" : ""}">${paused ? "На паузе" : "Активна"}</span></h4>
          <small>${sub.category || "Без категории"}</small>
        </div>
      </div>
      <div class="details">
        <span>Стоимость: <strong>${formatMoney(sub.amount, sub.currency)}</strong></span>
        <span>Период: <strong>${sub.billing_period}</strong></span>
        <span>Следующий платёж: <strong>${formatDate(sub.next_billing_date)}</strong></span>
      </div>
      <div class="pills">
        <span class="pill" data-action="edit" data-id="${sub.id}">Изменить</span>
        <span class="pill warning" data-action="pause" data-id="${sub.id}" data-period="${sub.billing_period}" data-next="${sub.next_billing_date || ""}">
          ${paused ? "Возобновить" : "Пауза"}
        </span>
        <span class="pill danger" data-action="deactivate" data-id="${sub.id}">Деактивировать</span>
      </div>
    `;
    container.appendChild(card);
  });

  container.onclick = async (e) => {
    const btn = e.target.closest("[data-action]");
    if (!btn) return;
    const id = btn.dataset.id;
    const action = btn.dataset.action;

    if (action === "edit") {
      openModal("edit", data.find(s => String(s.id) === id));
      return;
    }

    if (action === "pause") {
      const next = btn.dataset.next;
      const period = btn.dataset.period || "monthly";
      const paused = isPaused(next);
      const newDate = paused ? nextDateFromNow(period) : addYears(new Date(), 5);
      await apiPut(`/api/subscriptions/${id}`, { next_billing_date: newDate.toISOString().slice(0, 10) });
      await loadSubscriptions();
      return;
    }

    if (action === "deactivate") {
      await apiDelete(`/api/subscriptions/${id}`);
      await loadSubscriptions();
    }
  };
}

async function loadCalendar() {
  const subs = await apiGet("/api/subscriptions");
  const monthLabel = document.getElementById("calendarMonth");
  const grid = document.getElementById("calendarGrid");
  const list = document.getElementById("calendarUpcoming");

  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth();
  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);

  monthLabel.textContent = firstDay.toLocaleDateString("ru-RU", { month: "long", year: "numeric" });

  const events = [];
  subs.forEach(sub => {
    if (!sub.next_billing_date) return;
    let d = new Date(sub.next_billing_date);
    while (d < firstDay) {
      if (sub.billing_period === "monthly") d = addMonths(d, 1);
      else if (sub.billing_period === "yearly") d = addYears(d, 1);
      else if (sub.billing_period === "weekly") d = addDays(d, 7);
      else break;
    }
    while (d <= lastDay) {
      events.push({ date: new Date(d), name: sub.name, amount: sub.amount, currency: sub.currency });
      if (sub.billing_period === "monthly") d = addMonths(d, 1);
      else if (sub.billing_period === "yearly") d = addYears(d, 1);
      else if (sub.billing_period === "weekly") d = addDays(d, 7);
      else break;
    }
  });

  const firstWeekday = (firstDay.getDay() + 6) % 7;
  grid.innerHTML = "";

  for (let i = 0; i < firstWeekday; i++) {
    const cell = document.createElement("div");
    cell.className = "calendar-day";
    cell.innerHTML = "&nbsp;";
    grid.appendChild(cell);
  }

  for (let day = 1; day <= lastDay.getDate(); day++) {
    const cellDate = new Date(year, month, day);
    const hasEvent = events.some(e => e.date.toDateString() === cellDate.toDateString());
    const cell = document.createElement("div");
    cell.className = `calendar-day ${hasEvent ? "has-event" : ""}`;
    cell.innerHTML = `<div class="num">${day}</div>${hasEvent ? '<div class="dot"></div>' : ""}`;
    grid.appendChild(cell);
  }

  list.innerHTML = "";
  const upcoming = events
    .filter(e => e.date >= new Date())
    .sort((a, b) => a.date - b.date)
    .slice(0, 7);

  upcoming.forEach(item => {
    const row = document.createElement("div");
    row.className = "list-item";
    row.innerHTML = `
      <div class="left">
        <div class="logo-pill" style="background:#111827;">${item.name[0] || "?"}</div>
        <div>
          <div>${item.name}</div>
          <small>${item.date.toLocaleDateString("ru-RU")}</small>
        </div>
      </div>
      <strong>${formatMoney(item.amount, item.currency)}</strong>
    `;
    list.appendChild(row);
  });
}

async function loadAnalytics() {
  const [analytics, chart] = await Promise.all([
    apiGet("/api/analytics"),
    apiGet("/api/analytics/chart?period=month")
  ]);

  document.getElementById("anMonthly").textContent = formatMoney(analytics.totals.month);
  document.getElementById("anHalfYear").textContent = formatMoney(analytics.totals.half_year);
  document.getElementById("anYear").textContent = formatMoney(analytics.totals.year);

  const byCategory = Object.entries(analytics.by_category || {}).map(([k, v]) => ({ label: k, value: Number(v) }));
  const byService = Object.entries(analytics.by_service || {}).map(([k, v]) => ({ label: k, value: Number(v) }));

  document.getElementById("categoryChart").innerHTML = svgDonut(byCategory);
  document.getElementById("serviceChart").innerHTML = svgBars(byService);
  document.getElementById("trendChart").innerHTML = svgLineChart(chart.series.map(p => ({ label: p.label, value: Number(p.value) })));

  const catLegend = document.getElementById("categoryLegend");
  catLegend.innerHTML = byCategory.map(c => `<div>${c.label}: ${formatMoney(c.value)}</div>`).join("");

  const servLegend = document.getElementById("serviceLegend");
  servLegend.innerHTML = byService.map(c => `<div>${c.label}: ${formatMoney(c.value)}</div>`).join("");
}

async function loadSettings() {
  const me = await apiGet("/api/auth/me");
  document.getElementById("setEmail").value = me.email || "";
  document.getElementById("setPhone").value = me.phone || "";

  document.getElementById("saveProfile").addEventListener("click", async () => {
    const email = document.getElementById("setEmail").value.trim();
    const phone = document.getElementById("setPhone").value.trim();
    await apiPatch("/api/auth/me", { email, phone });
    alert("Профиль сохранён");
  });

  document.getElementById("notifDays").value = String(notifDays);
  document.getElementById("saveNotifications").addEventListener("click", async () => {
    const days = parseInt(document.getElementById("notifDays").value, 10);
    localStorage.setItem("notifDays", String(days));
    await renderNotificationsList(days);
    await updateBadge();
  });

  await renderNotificationsList(notifDays);

  document.getElementById("changePassword").addEventListener("click", async () => {
    const current = document.getElementById("currentPassword").value;
    const next = document.getElementById("newPassword").value;
    await apiPost("/api/auth/change-password", { current_password: current, new_password: next });
    alert("Пароль изменён");
  });

  document.getElementById("logoutBtn").addEventListener("click", () => {
    localStorage.removeItem("token");
    window.location.href = "/login";
  });

  const tabs = document.querySelectorAll(".tab");
  const panels = document.querySelectorAll(".tab-panel");
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active"));
      panels.forEach(p => p.classList.remove("active"));
      tab.classList.add("active");
      document.getElementById(tab.dataset.target).classList.add("active");
    });
  });
}

async function renderNotificationsList(days) {
  const list = document.getElementById("notifList");
  if (!list) return;
  const data = await apiGet(`/api/notifications/upcoming?days=${days}`);
  list.innerHTML = "";
  data.items.forEach(item => {
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

function openModal(mode, sub) {
  const modal = document.getElementById("subscriptionModal");
  const backdrop = document.getElementById("modalBackdrop");
  modal.dataset.mode = mode;
  modal.dataset.id = sub ? sub.id : "";

  document.getElementById("subName").value = sub?.name || "";
  document.getElementById("subAmount").value = sub?.amount || "";
  document.getElementById("subCurrency").value = sub?.currency || "RUB";
  document.getElementById("subPeriod").value = sub?.billing_period || "monthly";
  document.getElementById("subCategory").value = sub?.category || "";
  document.getElementById("subNextDate").value = sub?.next_billing_date || "";

  modal.classList.add("open");
  backdrop.classList.add("open");
}

function closeModal() {
  document.getElementById("subscriptionModal").classList.remove("open");
  document.getElementById("modalBackdrop").classList.remove("open");
}

async function initModal() {
  const addBtn = document.getElementById("openAddSubscription");
  if (addBtn) addBtn.addEventListener("click", () => openModal("add"));

  document.getElementById("closeModal").addEventListener("click", closeModal);
  document.getElementById("modalBackdrop").addEventListener("click", closeModal);

  document.getElementById("saveSubscription").addEventListener("click", async () => {
    const payload = {
      name: document.getElementById("subName").value.trim(),
      amount: Number(document.getElementById("subAmount").value),
      currency: document.getElementById("subCurrency").value.trim() || "RUB",
      billing_period: document.getElementById("subPeriod").value,
      category: document.getElementById("subCategory").value.trim() || null,
      next_billing_date: document.getElementById("subNextDate").value || null
    };

    const modal = document.getElementById("subscriptionModal");
    if (modal.dataset.mode === "edit") {
      await apiPut(`/api/subscriptions/${modal.dataset.id}`, payload);
    } else {
      await apiPost("/api/subscriptions", payload);
    }
    closeModal();

    const page = document.body.dataset.page;
    if (page === "subscriptions") await loadSubscriptions();
    if (page === "calendar") await loadCalendar();
    if (page === "home") await loadHome();
  });
}

document.addEventListener("DOMContentLoaded", async () => {
  requireAuth();
  const page = document.body.dataset.page;

  if (page) {
    await updateBadge();
    await initModal();
  }

  if (page === "home") await loadHome();
  if (page === "subscriptions") await loadSubscriptions();
  if (page === "calendar") await loadCalendar();
  if (page === "analytics") await loadAnalytics();
  if (page === "settings") await loadSettings();
});
