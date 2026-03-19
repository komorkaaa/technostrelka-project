# technostrelka-project

Кроссплатформенный сервис мониторинга подписок для кейса «Монитор подписок».
Проект включает общий backend, web-клиент, Android-приложение и iOS-приложение.

## Что умеет проект

- Регистрация и авторизация пользователя по JWT.
- Единый backend API для web, Android и iOS.
- Ручное добавление, редактирование и удаление подписок.
- Просмотр списка подписок, ближайших списаний и календаря платежей.
- Аналитика расходов по категориям и сервисам.
- Прогноз затрат на месяц, полгода и год.
- Импорт подписок из почты через IMAP или демо-режим с тестовыми письмами.
- Уведомления о предстоящих списаниях.
- Профиль пользователя: просмотр и редактирование данных, смена пароля.

## Структура репозитория

```text
backend/
  app/
    core/              Конфиг, БД, безопасность, JWT
    models/            SQLAlchemy-модели
    routes/            FastAPI-роуты
    schemas/           Pydantic-схемы
    services/          Бизнес-логика
    email_parser/      IMAP-парсер и эвристики извлечения подписок
    main.py            Точка входа FastAPI
  Dockerfile
  requirements.txt

frontend/
  web/                 WEB-клиент на ванильном JS + Node static server
  android/             Android-приложение
  ios/                 iOS-приложение CtrlS

docker-compose.yml
.env.example
```

## Технологии

### Backend

- Python
- FastAPI
- SQLAlchemy
- PostgreSQL
- JWT
- IMAP

### Web

- HTML
- CSS
- Vanilla JavaScript
- Node.js

### Android

- Java
- Retrofit
- MPAndroidChart
- WorkManager

### iOS

- Swift
- SwiftUI

## Архитектура

Все клиенты используют один backend API.

- Backend поднимает REST API для авторизации, подписок, аналитики, прогноза, уведомлений и импорта из почты.
- Web-клиент проксирует запросы через `/api/*` на backend.
- Android-клиент работает напрямую с backend через Retrofit.
- iOS-клиент работает напрямую с backend через `RealAPIService`.

## Реализованные модули

### Backend

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `PATCH /auth/me`
- `POST /auth/change-password`
- `POST /subscriptions`
- `GET /subscriptions`
- `GET /subscriptions/{id}`
- `PUT /subscriptions/{id}`
- `DELETE /subscriptions/{id}`
- `POST /email/import`
- `GET /analytics`
- `GET /analytics/chart?period=month|half_year|year`
- `GET /forecast`
- `GET /notifications/upcoming?days=3`
- `GET /health`
- `GET /db-check`

### Web

- Страницы логина и регистрации.
- Главная панель с KPI и ближайшими списаниями.
- Экран подписок с созданием, редактированием, удалением и паузой.
- Календарь платежей.
- Аналитика с графиками.
- Настройки профиля и смена пароля.
- Просмотр ближайших уведомлений.

### Android

- Экран авторизации и регистрации.
- Главная страница с прогнозом и ближайшими списаниями.
- Список подписок с фильтрами, редактированием, удалением и паузой.
- Экран аналитики с графиками.
- Календарь платежей.
- Профиль пользователя.
- Импорт подписок из почты.
- Локальные уведомления через WorkManager.

### iOS

- Авторизация и регистрация.
- Главная страница с итогами, прогнозом и ближайшими списаниями.
- Экран подписок с поиском, фильтрацией и CRUD.
- Календарь платежей.
- Аналитика.
- Профиль пользователя.
- Импорт из почты.
- Экран уведомлений.

## Требования

- Docker и Docker Compose, если запускать backend в контейнерах.
- Или локально:
  - Python 3.11+
  - PostgreSQL 16+
- Node.js 18+ для web-клиента.
- Android Studio для Android.
- Xcode для iOS.

## Переменные окружения

Скопируйте `.env.example` в `.env` и заполните значения:

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=technostrelkadb
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
JWT_SECRET_KEY=change-me
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

## Запуск backend

### Вариант 1. Docker

```bash
docker compose up --build
```

После запуска:

- API: `http://127.0.0.1:8000`
- Swagger: `http://127.0.0.1:8000/docs`

### Вариант 2. Локально

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Важно:

- нужен запущенный PostgreSQL;
- backend читает переменные из корневого `.env`.

## Запуск web-клиента

```bash
cd frontend/web
npm install
npm start
```

По умолчанию web-клиент будет доступен на:

- `http://localhost:3000`

По умолчанию запросы проксируются на backend:

- `http://localhost:8000`

При необходимости можно переопределить адрес backend:

```bash
BACKEND_URL=http://127.0.0.1:8000 npm start
```

## Запуск Android-приложения

1. Откройте папку `frontend/android` в Android Studio.
2. Убедитесь, что backend уже запущен.
3. Запустите приложение на эмуляторе или устройстве.

Текущее базовое API для Android:

- `http://10.0.2.2:8000`

Это подходит для Android Emulator. Для физического устройства адрес backend нужно заменить на IP вашей машины в локальной сети.

## Запуск iOS-приложения

1. Откройте `frontend/ios/CtrlS/CtrlS.xcodeproj` в Xcode.
2. Убедитесь, что backend уже запущен.
3. Запустите приложение на симуляторе или устройстве.

Текущее базовое API для iOS:

- `http://127.0.0.1:8000`

Для физического устройства адрес backend также нужно заменить на IP машины, где поднят backend.

## Импорт из почты

Поддерживается два режима:

- `use_sample=true` для безопасной демонстрации на тестовых письмах;
- IMAP-импорт с явным согласием пользователя на использование пароля приложения.

Поддерживаемые IMAP-серверы:

- `imap.gmail.com`
- `imap.mail.ru`
- `imap.yandex.ru`
- `imap.rambler.ru`
- `imap.mail.yahoo.com`
- `imap-mail.outlook.com`
- `outlook.office365.com`

Для публичной демонстрации рекомендуется использовать демо-режим, чтобы не зависеть от внешней почтовой инфраструктуры.
