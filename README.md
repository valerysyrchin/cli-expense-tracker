# CLI Expense Tracker MVP

[Русское описание ниже](#описание-проекта-на-русском)

A personal finance CLI (Command Line Interface) application designed to track expenses, manage custom categories, and handle multi-currency transactions with automated exchange rate updates. 

### Tech Stack
* **Database:** PostgreSQL
* **Query Language:** SQL
* **Scripting & Automation:** Bash (advanced CLI menu logic, API integration, and database communication)
* **API Integration:** Integration with an external currency exchange rates API via `curl` and `jq`

### Key Achievements & Skills Learned:
* Designed and deployed a relational database schema in PostgreSQL for financial tracking (expenses, currencies, and categories).
* Implemented automatic exchange rate updates by fetching live JSON data from an external API, parsing it with `jq`, and updating the database.
* Built an interactive Bash terminal menu architectural framework with placeholder routing for future modular features.
* Handled multi-currency calculations, linking dynamic exchange rates to automate conversions back to the base currency.
* Used advanced `psql` scripting flags to cleanly pass variables and format automated data updates.

### Project Structure
* `schema.sql` - database schema script containing table structures, constraints, and initial currency/category data.
* `finance.sh` - main interactive Bash script. It features a complete core menu system architecture (Insert, Edit, Analyze, Exit), with the **Expense Insertion** engine fully operational for the MVP stage.
* `update_rates.sh` - automation script that connects to the currency API and updates exchange rates in the database.

### Project Roadmap & Current Status
The application’s core navigation tree is fully structured. Features are being rolled out modularly:
* [x] **1) INSERT_MENU** - Fully functional. Allows multi-currency expense logging and real-time category selection.
* [ ] **2) EDIT_MENU** - Planned. Will handle expense modification and entry deletion.
* [ ] **3) ANALYZE_MENU** - Planned. Will generate monthly breakdowns, charts, and budget reports directly in the terminal.

---

## Описание проекта на русском

Консольное приложение (CLI) для учета личных финансов. Проект позволяет фиксировать расходы, управлять категориями затрат и проводить мультивалютные операции с автоматическим обновлением курсов валют через API.

### Технологический стек
* **СУБД:** PostgreSQL
* **Язык запросов:** SQL
* **Скрипты/Автоматизация:** Bash (интерактивное меню, интеграция с API, связь с БД)
* **Интеграция сторонних сервисов:** Запросы к внешнему API курсов валют с помощью `curl` и парсинг JSON через `jq`

### Чему я научился в этом проекте:
* Проектировать и разворачивать реляционную схему данных PostgreSQL для финансового учета (расходы, валюты, категории).
* Реализовывать автоматическое обновление курсов валют: скрипт забирает актуальный JSON из внешнего API, парсит его через `jq` и обновляет данные в СУБД.
* Разрабатывать архитектурную структуру интерактивных меню на Bash с маршрутизацией для будущих модулей.
* Работать с мультивалютностью и динамической конвертацией затрат на основе актуальных коэффициентов в базе данных.
* Использовать специфические флаги утилиты `psql` для безопасной передачи переменных из Bash внутрь SQL-запросов.

### Структура проекта
* `schema.sql` - готовый SQL-скрипт со всей структурой базы данных, связями и начальным списком валют и категорий.
* `finance.sh` - главный интерактивный Bash-скрипт. Включает в себя готовую архитектуру главного меню (Добавление, Корректировка, Анализ, Выход). На этапе MVP полностью реализован и готов к работе первый модуль **Добавление расходов**.
* `update_rates.sh` - скрипт автоматизации, отвечающий за обращение к API и обновление курсов валют в базе.

### План развития проекта (Roadmap)
Навигационное дерево приложения полностью спроектировано. Функционал добавляется модульно:
* [x] **1) INSERT_MENU (Добавление)** - Полностью готово. Позволяет вносить траты в разных валютах с автоматической привязкой к категориям.
* [ ] **2) EDIT_MENU (Корректировка)** - В планах. Изменение и удаление уже существующих записей о расходах.
* [ ] **3) ANALYZE_MENU (Анализ)** - В планах. Вывод аналитики за месяц, группировка по категориям и отображение графиков прямо в консоли.
