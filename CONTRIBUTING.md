# Git Workflow Guide

## Структура веток

В репозитории используются следующие ветки:

main
— стабильная версия проекта

develop
— основная рабочая ветка

feature/*
— ветки для разработки новых задач

hotfix/*
— срочные исправления

---

# Общий рабочий процесс

1. Всегда начинайте работу с обновления develop.

```
git checkout develop
git pull origin develop
```

2. Создайте новую ветку для задачи.

```
git checkout -b feature/<short-name>
```

пример:

```
feature/auth-api
feature/user-profile-ui
feature/chat-service
```

3. Работайте только в своей ветке.

---

# Коммиты

Коммиты должны быть небольшими и осмысленными.

Используем Conventional Commits:

```
feat: add login endpoint
fix: correct token validation
refactor: split auth service
docs: update README
chore: update project structure
```

Рекомендации:

* один логический шаг = один коммит
* избегайте коммитов типа "update", "fix stuff"

---

# Синхронизация с develop

Если develop обновился, необходимо подтянуть изменения.

```
git checkout develop
git pull origin develop
```

После этого обновить свою ветку.

```
git checkout feature/<branch>
git merge develop
```

Если возникают конфликты:

1. исправить конфликтные файлы
2. удалить конфликтные маркеры
3. сделать commit

```
git add .
git commit
```

---

# Публикация ветки

После первых коммитов ветку нужно отправить в GitHub.

```
git push origin feature/<branch>
```

---

# Создание Pull Request

После завершения задачи создаётся PR:

```
feature/<branch> → develop
```

PR должен содержать:

* описание изменений
* список затронутых компонентов
* при необходимости инструкции для тестирования

---

# Code Review

Все PR проходят review.

Процесс:

1. автор создаёт PR
2. ревьюер оставляет комментарии
3. автор исправляет замечания
4. автор делает новый commit
5. изменения автоматически добавляются в PR

---

# Merge Pull Request

После одобрения PR:

Merge → develop

Тип merge:

```
Squash and merge
```

Это объединяет все коммиты ветки в один аккуратный коммит.

---

# После Merge

После успешного merge:

1. удалить ветку

```
git branch -d feature/<branch>
```

2. удалить удалённую ветку

```
git push origin --delete feature/<branch>
```

3. обновить локальный develop

```
git checkout develop
git pull
```

---

# Работа с конфликтами

Git помечает конфликтные места так:

```
<<<<<<< HEAD
ваш код
=======
код из develop
>>>>>>> branch
```

Нужно:

1. выбрать правильный вариант
2. удалить маркеры
3. сохранить файл
4. сделать commit

---

# Основные правила

Нельзя:

* пушить напрямую в main
* пушить напрямую в develop
* делать одну ветку для нескольких задач

Нужно:

* одна задача = одна ветка
* делать маленькие PR
* регулярно синхронизироваться с develop
* писать понятные commit messages

---

# Рекомендуемый размер PR

Оптимальный PR:

100–300 строк изменений

Большие PR сложнее ревьюить и они чаще содержат ошибки.


