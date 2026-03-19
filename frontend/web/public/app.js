const API_BASE = window.API_BASE || "";
function clampNotifDays(value) {
  const num = parseInt(value, 10);
  if (!Number.isFinite(num)) return 7;
  if (num < 1) return 1;
  if (num > 30) return 30;
  return num;
}
let notifDays = clampNotifDays(localStorage.getItem("notifDays") || "7");
localStorage.setItem("notifDays", String(notifDays));

const calendarState = {
  date: null,
  subs: [],
  selectedDate: null
};

const analyticsState = {
  period: "month",
  category: ""
};

const subscriptionsState = {
  filter: "all",
  search: ""
};

const homeState = {
  period: "month"
};

function requireAuth() {
  const page = document.body.dataset.page;
  const token = localStorage.getItem("token");
  if (!token && page) {
    window.location.href = "/login";
  }
}

function tokenHeader() {
  const token = localStorage.getItem("token");
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

  const fullUrl = API_BASE ? API_BASE + url.replace(/^\/api/, "") : url;

  let res;
  try {
    res = await fetch(fullUrl, { method, headers, body: payload });
  } catch (err) {
    throw new Error("Не удалось подключиться к серверу. Проверь, что backend запущен.");
  }

  if (!res.ok) {
    const text = await res.text();
    let detail = res.statusText;
    try {
      const data = JSON.parse(text);
      detail = data.detail || detail;
    } catch {}
    if (Array.isArray(detail)) {
      detail = detail.map(d => d.msg || d).join(", ");
    }
    throw new Error(detail);
  }

  return res.status === 204 ? null : res.json();
}

const apiGet = (url) => apiRequest("GET", url);
const apiPost = (url, body) => apiRequest("POST", url, body);
const apiPut = (url, body) => apiRequest("PUT", url, body);
const apiPatch = (url, body) => apiRequest("PATCH", url, body);
const apiDelete = (url) => apiRequest("DELETE", url);

function parseAmountInput(value) {
  if (typeof value !== "string") return Number(value);
  const normalized = value.replace(",", ".").replace(/[^0-9.]/g, "");
  return Number(normalized);
}

function formatMoney(value, currency = "RUB") {
  const num = Number(value);
  if (Number.isNaN(num)) return value;
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency
  }).format(num);
}

function isDateOnlyString(value) {
  return typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function parseDate(value) {
  if (!value) return null;
  if (isDateOnlyString(value)) {
    const [y, m, d] = value.split("-").map(Number);
    return new Date(y, m - 1, d);
  }
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function formatDate(iso) {
  if (!iso) return "";
  const d = parseDate(iso);
  if (!d) return "";
  return d.toLocaleDateString("ru-RU");
}

function daysUntil(dateStr) {
  if (!dateStr) return "";
  const target = parseDate(dateStr);
  if (!target) return "";
  const now = new Date();
  if (isDateOnlyString(dateStr)) now.setHours(0, 0, 0, 0);
  const diff = Math.ceil((target - now) / (1000 * 60 * 60 * 24));
  if (diff <= 0) return "Сегодня";
  return `Через ${diff} дн.`;
}

function formatRelativeDay(diff) {
  if (diff <= 0) return "Сегодня";
  if (diff === 1) return "Завтра";
  return `Через ${diff} дн.`;
}

function pluralizeSubscriptions(count) {
  return `${count} подпис${count % 10 === 1 && count % 100 !== 11 ? "ка" : count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 12 || count % 100 > 14) ? "ки" : "ок"}`;
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
  const target = parseDate(nextDate);
  if (!target) return false;
  const now = new Date();
  if (isDateOnlyString(nextDate)) now.setHours(0, 0, 0, 0);
  const diff = (target - now) / (1000 * 60 * 60 * 24);
  return diff > 180;
}

function svgLineChart(points, width = 520, height = 220, options = {}) {
  if (!points.length) return "";
  const { showPointLabels = true, showBottomLabels = false } = options;
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

  const pointLabels = showPointLabels ? coords.map(c => {
    const placeBelow = c.y < pad + 14;
    const y = placeBelow ? c.y + 14 : c.y - 8;
    return `<text x="${c.x}" y="${y}" text-anchor="middle" font-size="9" fill="#6b7280">${c.label}</text>`;
  }) : [];

  const bottomLabels = showBottomLabels ? coords.map(c => (
    `<text x="${c.x}" y="${height - 10}" text-anchor="middle" font-size="9" fill="#6b7280">${String(c.label).slice(0, 10)}</text>`
  )) : [];

  return `
    <svg viewBox="0 0 ${width} ${height}" width="100%" height="100%">
      ${gridLines.join("")}
      <polyline fill="none" stroke="#8b2cff" stroke-width="3" points="${coords.map(c => `${c.x},${c.y}`).join(" " )}" />
      ${coords.map(c => `<circle cx="${c.x}" cy="${c.y}" r="4" fill="#8b2cff"/>`).join("")}
      ${pointLabels.join("")}
      ${bottomLabels.join("")}
      <text x="${width - pad}" y="${pad - 8}" text-anchor="end" font-size="10" fill="#6b7280">${formatMoney(max)}</text>
      <text x="${width - pad}" y="${height - 6}" text-anchor="end" font-size="10" fill="#6b7280">${formatMoney(min)}</text>
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

function svgDonut(data, width = 240, height = 240, options = {}) {
  const { showLabels = true } = options;
  const total = data.reduce((s, d) => s + d.value, 0) || 1;
  const cx = width / 2;
  const cy = height / 2;
  const r = 90;
  let start = 0;
  const colors = ["#8b2cff", "#2563eb", "#16a34a", "#f97316", "#ef4444", "#0ea5e9"];

  const shouldShowLabels = showLabels && data.length > 1;
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
      ${shouldShowLabels ? `<text x="${lx}" y="${ly}" text-anchor="middle" font-size="10" fill="#6b7280">${d.label}</text>` : ""}
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

function renderCalendarSummary(subs) {
  const totalEl = document.getElementById("calendarSummaryTotal");
  const countEl = document.getElementById("calendarSummaryCount");
  if (!totalEl || !countEl) return;

  const base = calendarState.date || new Date();
  const month = base.getMonth();
  const year = base.getFullYear();

  const items = subs.filter(sub => {
    const date = parseDate(sub.next_billing_date);
    return date && date.getMonth() === month && date.getFullYear() === year;
  });

  const total = items.reduce((sum, sub) => sum + Number(sub.amount || 0), 0);
  totalEl.textContent = formatMoney(total);
  countEl.textContent = `${items.length} платеж${items.length === 1 ? "" : items.length < 5 ? "а" : "ей"}`;
}

async function updateBadge() {
  const badge = document.getElementById("notifBadge");
  if (!badge) return;
  try {
    const data = await apiGet(`/api/notifications/upcoming?days=${notifDays}`);
    badge.querySelector("span").textContent = data.items.length;
  } catch {
    // If backend is unavailable or auth fails, don't break the rest of the UI.
    badge.querySelector("span").textContent = "0";
  }
}

async function openNotificationsModal() {
  const modal = document.getElementById("notificationsModal");
  const backdrop = document.getElementById("notificationsModalBackdrop");
  const list = document.getElementById("notificationsModalList");
  if (!modal || !backdrop || !list) return;

  list.innerHTML = '<div class="empty-inline">Загрузка...</div>';
  modal.classList.add("open");
  backdrop.classList.add("open");

  try {
    const data = await apiGet(`/api/notifications/upcoming?days=${notifDays}`);
    if (!data.items.length) {
      list.innerHTML = '<div class="empty-inline">Нет ближайших уведомлений</div>';
      return;
    }
    list.innerHTML = data.items.map(item => `
      <div class="list-item">
        <div class="left">
          <div class="logo-pill" style="background:#111827;">${item.name[0] || "?"}</div>
          <div>
            <div>${item.name}</div>
            <small>${daysUntil(item.next_billing_date)}</small>
          </div>
        </div>
        <div class="list-item-stack">
          <strong>${formatMoney(item.amount, item.currency)}</strong>
          <small>${formatDate(item.next_billing_date)}</small>
        </div>
      </div>
    `).join("");
  } catch (err) {
    list.innerHTML = `<div class="empty-inline">${err.message}</div>`;
  }
}

function closeNotificationsModal() {
  const modal = document.getElementById("notificationsModal");
  const backdrop = document.getElementById("notificationsModalBackdrop");
  if (modal) modal.classList.remove("open");
  if (backdrop) backdrop.classList.remove("open");
}

function ensureNotificationsModal() {
  if (document.getElementById("notificationsModal")) return;
  document.body.insertAdjacentHTML("beforeend", `
    <div id="notificationsModalBackdrop" class="modal-backdrop"></div>
    <div id="notificationsModal" class="modal">
      <div class="modal-card notifications-modal-card">
        <div class="panel-header">
          <h4>Уведомления</h4>
          <button class="pill" id="closeNotificationsModal">Закрыть</button>
        </div>
        <div class="list" id="notificationsModalList"></div>
      </div>
    </div>
  `);
  document.getElementById("closeNotificationsModal").addEventListener("click", closeNotificationsModal);
  document.getElementById("notificationsModalBackdrop").addEventListener("click", closeNotificationsModal);
}

function initNotifBadge() {
  const badge = document.getElementById("notifBadge");
  if (!badge || badge.dataset.bound) return;
  badge.dataset.bound = "1";
  badge.addEventListener("click", openNotificationsModal);
}

async function loadHome() {
  const [analytics, chart, upcoming, subs] = await Promise.all([
    apiGet("/api/analytics"),
    apiGet(`/api/analytics/chart?period=${homeState.period}`),
    apiGet(`/api/notifications/upcoming?days=${notifDays}`),
    apiGet("/api/subscriptions")
  ]);

  document.getElementById("kpiMonthly").textContent = formatMoney(getSelectedAnalyticsTotal(chart.totals || analytics.totals));
  document.getElementById("kpiActive").textContent = Object.values(analytics.by_service || {}).length;
  document.getElementById("kpiNext").textContent = upcoming.items[0] ? daysUntil(upcoming.items[0].next_billing_date) : "—";
  document.getElementById("homeSubscriptionsCount").textContent = String(subs.length);

  const warningTitle = document.getElementById("homeWarningTitle");
  const warningText = document.getElementById("homeWarningText");
  if (upcoming.items[0]) {
    warningTitle.textContent = "Скоро списание";
    warningText.textContent = `${daysUntil(upcoming.items[0].next_billing_date)} будет списано ${formatMoney(upcoming.items[0].amount, upcoming.items[0].currency)} за ${upcoming.items[0].name}`;
  } else {
    warningTitle.textContent = "Пока спокойно";
    warningText.textContent = "В ближайшие дни нет новых списаний";
  }

  const list = document.getElementById("upcomingList");
  list.innerHTML = "";
  upcoming.items.slice(0, 4).forEach(item => {
    const row = document.createElement("div");
    row.className = "payment-card-mobile";
    row.innerHTML = `
      <div class="payment-card-mobile-left">
        <div class="logo-pill" style="background:#1f2937;">${item.name[0] || "?"}</div>
        <div>
          <div class="payment-card-mobile-title">${item.name}</div>
          <small>${daysUntil(item.next_billing_date)}</small>
        </div>
      </div>
      <div class="payment-card-mobile-right">
        <strong>${formatMoney(item.amount, item.currency)}</strong>
        <small>${formatDate(item.next_billing_date)}</small>
      </div>
    `;
    list.appendChild(row);
  });
  if (!upcoming.items.length) {
    list.innerHTML = '<div class="empty-inline">Нет ближайших платежей</div>';
  }

  const categories = Object.entries(analytics.by_category || {})
    .map(([name, value]) => ({ name, value: Number(value) }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 4);
  const categoriesEl = document.getElementById("homeCategories");
  if (categoriesEl) {
    categoriesEl.innerHTML = categories.map(category => `
      <div class="category-card-mobile">
        <div class="category-card-title">${category.name}</div>
        <div class="category-card-value">${formatMoney(category.value)}</div>
      </div>
    `).join("");
  }

  const heroAdd = document.getElementById("heroAddSubscription");
  if (heroAdd && !heroAdd.dataset.bound) {
    heroAdd.dataset.bound = "1";
    heroAdd.addEventListener("click", () => openModal("add"));
  }

  document.querySelectorAll("[data-home-period]").forEach(btn => {
    btn.classList.toggle("active", btn.dataset.homePeriod === homeState.period);
    if (btn.dataset.bound) return;
    btn.dataset.bound = "1";
    btn.addEventListener("click", async () => {
      homeState.period = btn.dataset.homePeriod;
      document.querySelectorAll("[data-home-period]").forEach(item => {
        item.classList.toggle("active", item.dataset.homePeriod === homeState.period);
      });
      await loadHome();
    });
  });
}

async function loadSubscriptions() {
  const data = await apiGet("/api/subscriptions");
  const container = document.getElementById("subscriptionsList");
  const search = subscriptionsState.search.trim().toLowerCase();
  const filtered = data.filter(sub => {
    const paused = isPaused(sub.next_billing_date);
    if (subscriptionsState.filter === "active" && paused) return false;
    if (subscriptionsState.filter === "paused" && !paused) return false;
    if (!search) return true;
    return [sub.name, sub.category, sub.billing_period]
      .filter(Boolean)
      .some(value => String(value).toLowerCase().includes(search));
  });

  const activeCount = data.filter(sub => !isPaused(sub.next_billing_date)).length;
  const pausedCount = data.length - activeCount;
  const chipAll = document.getElementById("chipAll");
  const chipActive = document.getElementById("chipActive");
  const chipPaused = document.getElementById("chipPaused");
  if (chipAll) chipAll.textContent = `Все (${data.length})`;
  if (chipActive) chipActive.textContent = `Активные (${activeCount})`;
  if (chipPaused) chipPaused.textContent = `На паузе (${pausedCount})`;
  document.querySelectorAll(".chip[data-filter]").forEach(chip => {
    chip.classList.toggle("active", chip.dataset.filter === subscriptionsState.filter);
  });

  container.innerHTML = "";
  filtered.forEach(sub => {
    const paused = isPaused(sub.next_billing_date);
    const card = document.createElement("div");
    card.className = "subscription-card subscription-card-android";
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
  if (!filtered.length) {
    container.innerHTML = '<div class="empty-inline">Ничего не найдено</div>';
  }

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

  const searchInput = document.getElementById("subscriptionsSearch");
  if (searchInput && !searchInput.dataset.bound) {
    searchInput.dataset.bound = "1";
    searchInput.addEventListener("input", async () => {
      subscriptionsState.search = searchInput.value;
      await loadSubscriptions();
    });
  }

  document.querySelectorAll(".chip[data-filter]").forEach(chip => {
    if (chip.dataset.bound) return;
    chip.dataset.bound = "1";
    chip.addEventListener("click", async () => {
      subscriptionsState.filter = chip.dataset.filter;
      await loadSubscriptions();
    });
  });
}

function renderCalendarList(events) {
  const list = document.getElementById("calendarUpcoming");
  const label = document.getElementById("calendarDayLabel");
  if (!list || !label) return;

  list.innerHTML = "";
  const selected = calendarState.selectedDate;
  if (selected) {
    label.textContent = `Подписки на ${selected.toLocaleDateString("ru-RU")}`;
    const items = events.filter(e => e.date.toDateString() === selected.toDateString());
    if (!items.length) {
      const empty = document.createElement("div");
      empty.className = "list-item";
      empty.textContent = "Нет списаний на эту дату";
      list.appendChild(empty);
      return;
    }

    items.forEach(item => {
      const row = document.createElement("div");
      row.className = "list-item";
      row.innerHTML = `
        <div class="left">
          <div class="logo-pill" style="background:#111827;">${item.name[0] || "?"}</div>
          <div>
            <div>${item.name}</div>
            <small>Списание в этот день</small>
          </div>
        </div>
        <strong>${formatMoney(item.amount, item.currency)}</strong>
      `;
      list.appendChild(row);
    });
    return;
  }

  label.textContent = "Ближайшие 7 дней";
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  const end = addDays(start, 7);
  const upcoming = events
    .filter(e => e.date >= start && e.date <= end)
    .sort((a, b) => a.date - b.date);

  if (!upcoming.length) {
    const empty = document.createElement("div");
    empty.className = "list-item";
    empty.textContent = "Нет ближайших списаний";
    list.appendChild(empty);
    return;
  }

  upcoming.forEach(item => {
    const diff = Math.ceil((item.date - start) / (1000 * 60 * 60 * 24));
    const row = document.createElement("div");
    row.className = "list-item";
    row.innerHTML = `
      <div class="left">
        <div class="logo-pill" style="background:#111827;">${item.name[0] || "?"}</div>
        <div>
          <div>${item.name}</div>
          <small>${formatRelativeDay(diff)}</small>
        </div>
      </div>
      <div class="list-item-stack">
        <strong>${formatMoney(item.amount, item.currency)}</strong>
        <small>${item.date.toLocaleDateString("ru-RU", { day: "numeric", month: "short" })}</small>
      </div>
    `;
    list.appendChild(row);
  });
}

function renderCalendar() {
  const monthLabel = document.getElementById("calendarMonth");
  const grid = document.getElementById("calendarGrid");
  if (!monthLabel || !grid) return;

  const base = calendarState.date || new Date();
  const year = base.getFullYear();
  const month = base.getMonth();
  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);

  monthLabel.textContent = firstDay.toLocaleDateString("ru-RU", { month: "long", year: "numeric" });

  const events = [];
  calendarState.subs.forEach(sub => {
    if (!sub.next_billing_date) return;
    let d = parseDate(sub.next_billing_date);
      if (!d) return;
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
    const isSelected = calendarState.selectedDate
      ? calendarState.selectedDate.toDateString() === cellDate.toDateString()
      : false;
    const cell = document.createElement("div");
    cell.className = `calendar-day ${hasEvent ? "has-event" : ""} ${isSelected ? "selected" : ""}`.trim();
    cell.innerHTML = `<div class="num">${day}</div>${hasEvent ? '<div class="dot"></div>' : ""}`;
    cell.addEventListener("click", () => {
      if (calendarState.selectedDate && calendarState.selectedDate.toDateString() === cellDate.toDateString()) {
        calendarState.selectedDate = null;
      } else {
        calendarState.selectedDate = cellDate;
      }
      renderCalendar();
    });
    grid.appendChild(cell);
  }

  renderCalendarList(events);
}

async function loadCalendar() {
  const subs = await apiGet("/api/subscriptions");
  calendarState.subs = subs;
  if (!calendarState.date) {
    const now = new Date();
    calendarState.date = new Date(now.getFullYear(), now.getMonth(), 1);
  }

  const prevBtn = document.getElementById("calendarPrev");
  const nextBtn = document.getElementById("calendarNext");
  if (prevBtn && !prevBtn.dataset.bound) {
    prevBtn.dataset.bound = "1";
    prevBtn.addEventListener("click", () => {
      calendarState.date = new Date(calendarState.date.getFullYear(), calendarState.date.getMonth() - 1, 1);
      renderCalendarSummary(calendarState.subs);
      renderCalendar();
    });
  }
  if (nextBtn && !nextBtn.dataset.bound) {
    nextBtn.dataset.bound = "1";
    nextBtn.addEventListener("click", () => {
      calendarState.date = new Date(calendarState.date.getFullYear(), calendarState.date.getMonth() + 1, 1);
      renderCalendarSummary(calendarState.subs);
      renderCalendar();
    });
  }

  renderCalendarSummary(subs);
  renderCalendar();
}

function getSelectedAnalyticsTotal(totals) {
  if (analyticsState.period === "half_year") return Number(totals.half_year || 0);
  if (analyticsState.period === "year") return Number(totals.year || 0);
  return Number(totals.month || 0);
}

function updateAnalyticsTabs() {
  document.querySelectorAll("[data-period]").forEach(btn => {
    btn.classList.toggle("active", btn.dataset.period === analyticsState.period);
  });
}

function fillAnalyticsCategorySelect(byCategory) {
  const select = document.getElementById("analyticsCategorySelect");
  if (!select) return;
  const categories = Object.keys(byCategory || {}).sort((a, b) => a.localeCompare(b, "ru"));
  const currentValue = analyticsState.category;
  select.innerHTML = '<option value="">Все категории</option>' +
    categories.map(category => `<option value="${category}">${category}</option>`).join("");
  select.value = currentValue;
}

function updateAnalyticsCards(series) {
  const values = (series || []).map(point => Number(point.value));
  const avgEl = document.getElementById("analyticsAvgSpend");
  const trendEl = document.getElementById("analyticsTrend");
  const savingsEl = document.getElementById("analyticsSavings");
  const efficiencyEl = document.getElementById("analyticsEfficiency");
  const minEl = document.getElementById("analyticsMinValue");
  const maxEl = document.getElementById("analyticsMaxValue");

  if (!values.length) {
    [avgEl, trendEl, savingsEl, efficiencyEl, minEl, maxEl].forEach(el => {
      if (el) el.textContent = "—";
    });
    return;
  }

  const sum = values.reduce((acc, value) => acc + value, 0);
  const avg = sum / values.length;
  const min = Math.min(...values);
  const max = Math.max(...values);
  const first = values[0];
  const last = values[values.length - 1];
  const trend = first > 0 ? ((last - first) / first) * 100 : 0;
  const savings = max - min;
  const efficiency = max > 0 ? (avg / max) * 100 : 0;

  avgEl.textContent = formatMoney(avg);
  trendEl.textContent = `${trend >= 0 ? "+" : ""}${trend.toFixed(1)}%`;
  savingsEl.textContent = formatMoney(savings);
  efficiencyEl.textContent = `${Math.round(efficiency)}%`;
  minEl.textContent = formatMoney(min);
  maxEl.textContent = formatMoney(max);
}

function renderAnalyticsRecommendations(byService) {
  const container = document.getElementById("analyticsRecommendations");
  if (!container) return;

  const services = Object.entries(byService || {})
    .map(([name, value]) => ({ name, value: Number(value) }))
    .sort((a, b) => b.value - a.value);

  const recommendations = [];

  if (services[0]) {
    recommendations.push(`Проверь годовой тариф для ${services[0].name}: это самый дорогой сервис в списке.`);
  }
  if (services[1]) {
    recommendations.push(`Сравни семейный или пакетный тариф для ${services[1].name}, если подпиской пользуются несколько человек.`);
  }
  if (services.length > 2) {
    recommendations.push(`Обрати внимание на небольшие подписки: вместе они уже дают ${formatMoney(services.slice(2).reduce((sum, item) => sum + item.value, 0))}.`);
  }

  if (!recommendations.length) {
    recommendations.push("Добавь больше подписок, чтобы увидеть персональные рекомендации по экономии.");
  }

  container.innerHTML = recommendations
    .slice(0, 3)
    .map(text => `<div class="recommendation-item">${text}</div>`)
    .join("");
}

async function loadAnalytics() {
  const [analytics, chart] = await Promise.all([
    apiGet("/api/analytics"),
    apiGet(`/api/analytics/chart?period=${analyticsState.period}${analyticsState.category ? `&category=${encodeURIComponent(analyticsState.category)}` : ""}`)
  ]);

  const byCategory = Object.entries(analytics.by_category || {}).map(([k, v]) => ({ label: k, value: Number(v) }));
  const byService = Object.fromEntries(Object.entries(analytics.by_service || {}).map(([k, v]) => [k, Number(v)]));
  const totalForSelectedPeriod = getSelectedAnalyticsTotal(chart.totals || analytics.totals);

  fillAnalyticsCategorySelect(analytics.by_category);
  updateAnalyticsTabs();
  document.getElementById("categoryChart").innerHTML = svgDonut(byCategory, 220, 220, { showLabels: false });
  document.getElementById("trendChart").innerHTML = svgLineChart(
    chart.series.map(p => ({ label: p.label, value: Number(p.value) })),
    520,
    220,
    { showPointLabels: false, showBottomLabels: true }
  );
  updateAnalyticsCards(chart.series || []);
  renderAnalyticsRecommendations(byService);

  const catLegend = document.getElementById("categoryLegend");
  catLegend.innerHTML = byCategory
    .map(c => `<div>${c.label}: ${formatMoney(c.value)}</div>`)
    .join("");

  const avgEl = document.getElementById("analyticsAvgSpend");
  if (avgEl && (!chart.series || chart.series.length === 0) && totalForSelectedPeriod) {
    avgEl.textContent = formatMoney(totalForSelectedPeriod);
  }

  const periodButtons = document.querySelectorAll("[data-period]");
  periodButtons.forEach(btn => {
    if (btn.dataset.bound) return;
    btn.dataset.bound = "1";
    btn.addEventListener("click", async () => {
      analyticsState.period = btn.dataset.period;
      await loadAnalytics();
    });
  });

  const categorySelect = document.getElementById("analyticsCategorySelect");
  if (categorySelect && !categorySelect.dataset.bound) {
    categorySelect.dataset.bound = "1";
    categorySelect.addEventListener("change", async () => {
      analyticsState.category = categorySelect.value;
      await loadAnalytics();
    });
  }
}

async function loadSettings() {
  const [me, analytics, subs] = await Promise.all([
    apiGet("/api/auth/me"),
    apiGet("/api/analytics"),
    apiGet("/api/subscriptions")
  ]);
  document.getElementById("setEmail").value = me.email || "";
  document.getElementById("setPhone").value = me.phone || "";
  const profileEmailPreview = document.getElementById("profileEmailPreview");
  const profileName = document.getElementById("profileName");
  const profileSubsCount = document.getElementById("profileSubsCount");
  const profileMonthSpend = document.getElementById("profileMonthSpend");
  const profileSavings = document.getElementById("profileSavings");
  if (profileEmailPreview) profileEmailPreview.textContent = me.email || "email не указан";
  if (profileName) profileName.textContent = me.email ? me.email.split("@")[0] : "Пользователь";
  if (profileSubsCount) profileSubsCount.textContent = String(subs.length);
  if (profileMonthSpend) profileMonthSpend.textContent = formatMoney(analytics.totals.month);
  if (profileSavings) profileSavings.textContent = formatMoney(0);

  document.getElementById("saveProfile").addEventListener("click", async () => {
    const email = document.getElementById("setEmail").value.trim();
    const phone = document.getElementById("setPhone").value.trim();
    await apiPatch("/api/auth/me", { email, phone });
    if (profileEmailPreview) profileEmailPreview.textContent = email || "email не указан";
    if (profileName) profileName.textContent = email ? email.split("@")[0] : "Пользователь";
    alert("Профиль сохранён");
  });

  document.getElementById("notifDays").value = String(notifDays);
  document.getElementById("saveNotifications").addEventListener("click", async () => {
    const input = document.getElementById("notifDays");
    const days = clampNotifDays(input.value);
    input.value = String(days);
    notifDays = days;
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

  const settingsModal = document.getElementById("settingsModal");
  const settingsBackdrop = document.getElementById("settingsModalBackdrop");
  const settingsTitle = document.getElementById("settingsModalTitle");
  const settingsPanels = document.querySelectorAll(".settings-modal-panel");
  const titleMap = {
    tabProfile: "Личная информация",
    tabNotifications: "Уведомления",
    tabPayment: "Способы оплаты",
    tabSecurity: "Пароль и безопасность"
  };

  const closeSettingsModal = () => {
    settingsModal.classList.remove("open");
    settingsBackdrop.classList.remove("open");
  };

  const openSettingsModal = (targetId) => {
    settingsPanels.forEach(panel => panel.classList.toggle("active", panel.id === targetId));
    if (settingsTitle) settingsTitle.textContent = titleMap[targetId] || "Настройки";
    settingsModal.classList.add("open");
    settingsBackdrop.classList.add("open");
  };

  window.openSettingsTab = openSettingsModal;

  const closeBtn = document.getElementById("closeSettingsModal");
  if (closeBtn && !closeBtn.dataset.bound) {
    closeBtn.dataset.bound = "1";
    closeBtn.addEventListener("click", closeSettingsModal);
  }
  if (settingsBackdrop && !settingsBackdrop.dataset.bound) {
    settingsBackdrop.dataset.bound = "1";
    settingsBackdrop.addEventListener("click", closeSettingsModal);
  }

  document.querySelectorAll(".profile-row-button[data-target]").forEach(btn => {
    if (btn.dataset.bound) return;
    btn.dataset.bound = "1";
    btn.addEventListener("click", () => {
      openSettingsModal(btn.dataset.target);
    });
  });

  if (window.location.hash === "#notifications") {
    openSettingsModal("tabNotifications");
  }
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
    const name = document.getElementById("subName").value.trim();
    const amountRaw = document.getElementById("subAmount").value.trim();
    const amount = parseAmountInput(amountRaw);

    if (!name) {
      alert("Укажи название подписки");
      return;
    }
    if (!Number.isFinite(amount) || amount <= 0) {
      alert("Сумма должна быть больше 0");
      return;
    }

    const payload = {
      name,
      amount,
      currency: document.getElementById("subCurrency").value.trim() || "RUB",
      billing_period: document.getElementById("subPeriod").value,
      category: document.getElementById("subCategory").value.trim() || null,
      next_billing_date: document.getElementById("subNextDate").value || null
    };

    const modal = document.getElementById("subscriptionModal");
    try {
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
    } catch (err) {
      alert(err.message);
    }
  });
}

document.addEventListener("DOMContentLoaded", async () => {
  requireAuth();
  const page = document.body.dataset.page;

  if (page) {
    // Init modal first so the Add button works even if API calls fail.
    await initModal();
    ensureNotificationsModal();
    initNotifBadge();
    await updateBadge();
  }

  if (page === "home") await loadHome();
  if (page === "subscriptions") await loadSubscriptions();
  if (page === "calendar") await loadCalendar();
  if (page === "analytics") await loadAnalytics();
  if (page === "settings") await loadSettings();
});
