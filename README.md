# technostrelka-project (RU)

Сервис мониторинга подписок: backend API для управления подписками, импорта из почты,
аналитики, прогнозов и уведомлений о предстоящих списаниях. Веб и мобильные клиенты используют один API.

---

# 1) Общая информация

Проект мониторинга подписок для пользователей и команд. Система агрегирует данные о подписках,
строит аналитику и прогнозы, помогает избегать неожиданных списаний.

---

# 2) Структура проекта

```
backend/
  app/
    main.py                # вход в FastAPI
    core/                  # конфиг, БД, безопасность (JWT)
    models/                # модели SQLAlchemy
    schemas/               # схемы Pydantic
    routes/                # роутеры API
    services/              # бизнес-логика
    email_parser/          # IMAP-парсер
  Dockerfile
  requirements.txt
frontend/
  (TBD)
```

---

# 3) Стек

**Backend**
- Python + FastAPI
- SQLAlchemy + PostgreSQL
- JWT аутентификация
- IMAP парсер почты

**Frontend (планируется)**
- Web: React/Vue
- Mobile: iOS/Android

---

# 4) Backend

## 4.1 Окружение
Создайте `.env` в корне репозитория:
```
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=technostrelkadb
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
JWT_SECRET_KEY=change-me
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

## 4.2 Запуск через Docker (рекомендуется)
```
docker compose up --build
```

Backend: http://127.0.0.1:8000  
Docs: http://127.0.0.1:8000/docs

## 4.3 Локальный запуск (venv)
```
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## 4.4 API

### Аутентификация
- POST `/auth/register`
- POST `/auth/login`
- GET `/auth/me`
- PATCH `/auth/me`
- POST `/auth/change-password`

### Подписки (JWT обязателен)
- POST `/subscriptions`
- GET `/subscriptions`
- GET `/subscriptions/{id}`
- PUT `/subscriptions/{id}`
- DELETE `/subscriptions/{id}`

### Импорт из почты (JWT обязателен)
- POST `/email/import`

### Аналитика (JWT обязателен)
- GET `/analytics`
- GET `/analytics/chart?period=month|half_year|year`

### Прогноз (JWT обязателен)
- GET `/forecast`

### Уведомления (JWT обязателен)
- GET `/notifications/upcoming?days=3`

---

# 5) Frontend (TBD)

# 5) Frontend (iOS)

## 5.1 Папка
```
frontend/ios/CtrlS
```

## 5.2 Запуск iOS
1. Откройте `frontend/ios/CtrlS/CtrlS.xcodeproj` в Xcode.
2. Запустите Backend (Docker или локально).
3. Запустите приложение на симуляторе.

## 5.3 Функциональность iOS
- Авторизация и регистрация (JWT).
- Главная: итог за месяц, прогноз, ближайшие платежи, категории, последние подписки.
- Подписки: список, поиск, фильтры, сортировка, детали, создание/редактирование/удаление.
- Календарь: навигация по месяцам, платежи по дням, “Сегодня”.
- Аналитика: период, категории, график, метрики.
- Профиль: просмотр, редактирование email/phone, смена пароля.
- Импорт подписок из почты (IMAP + демо-режим).
- Уведомления: ближайшие списания.

---

# 6) Демо-поток (backend)

1. Зарегистрироваться и получить JWT.
2. Создать или импортировать подписки.
3. Посмотреть аналитику, прогноз и ближайшие уведомления.
3. View analytics, forecast, and upcoming notifications.
