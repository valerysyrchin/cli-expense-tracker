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
* `schema.sql` - Database schema script containing table structures, constraints, and initial currency/category data.
* `finance.sh` - Main interactive Bash script. It features a complete core menu system architecture (insert, edit, delete, analyze, exit).
* `update_rates.sh` - Automation script that connects to the currency API and updates exchange rates in the database.
* `sample.env` - Template file for environment variables, which contains configuration parameters (such as database credentials) required to run the application. Copy this file to `.env` and fill in your actual data before starting.


### Technical Highlights
Instead of processing string padding and column alignment inside complex Bash loops, the application delegates formatting to the database layer and native system utilities:
* **SQL Data Merging:** The SQL query uses the `||` operator to combine multiple columns into a single string separated by semicolons (`;`).
* **Stream Processing:** The raw data is read into a Bash array using `readarray`, automatically stripping carriage returns (`\r`).
* **Built-in Table Formatting:** The entire dataset is piped into the native CLI utility `column -t -s ';'`, generating a perfectly aligned, lightweight table in the terminal regardless of data length.

### Project Roadmap & Current Status
The application’s core navigation tree is fully structured. Features are being rolled out modularly:
* [x] **1) INSERT_MENU** - Fully functional. Allows multi-currency expense logging and real-time category selection.
* [x] **2) EDIT_MENU** - Fully functional. Implements multi-criteria search (`FIND_EXPENSE_MENU`) and dynamic transaction updates (`UPDATE_EXPENSE_MENU`).
* [ ] **3) DELETE_MENU** - Planned. Will handle safe transaction removal with confirmation prompts.
* [ ] **4) ANALYZE_MENU** - Planned. Will generate monthly breakdowns, charts, and budget reports directly in the terminal.

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
* `schema.sql` - Готовый SQL-скрипт со всей структурой базы данных, связями и начальным списком валют и категорий.
* `finance.sh` - Главный интерактивный Bash-скрипт. Включает в себя готовую архитектуру главного меню (добавление, корректировка, удаление, анализ, выход).
* `update_rates.sh` - Скрипт автоматизации, отвечающий за обращение к API и обновление курсов валют в базе.
* `sample.env` - Шаблон файла переменных окружения, содержащий конфигурационные параметры (например, данные для подключения к базе данных), необходимые для работы приложения. Перед запуском скопируйте этот файл под именем `.env` и укажите свои реальные данные.


### Особенности реализации
Вместо сложного выравнивания строк и подсчета пробелов внутри циклов Bash, приложение перекладывает задачу форматирования на уровень базы данных и встроенные системные утилиты:
* **Объединение полей в SQL:** SQL-запрос использует оператор `||` для объединения нескольких колонок в одну строку с разделителем «точка с запятой» (`;`).
* **Потоковая обработка:** Сырые данные считываются в массив Bash с помощью `readarray` с автоматическим удалением Windows-символов переноса строки (`\r`).
* **Автоматическое форматирование:** Весь массив данных направляется в системную утилиту `column -t -s ';'`, которая мгновенно строит идеально выровненную таблицу в терминале, независимо от длины текста в ячейках.

### План развития проекта (Roadmap)
Навигационное дерево приложения полностью спроектировано. Функционал добавляется модульно:
* [x] **1) INSERT_MENU (Модуль добавления расходов)** - Полностью готов. Позволяет вносить траты в разных валютах с автоматической привязкой к категориям.
* [x] **2) EDIT_MENU (Модуль редактирования расходов)** - Полностью готов. Реализован поиск по нескольким критериям (`FIND_EXPENSE_MENU`) и динамическое обновление данных в БД (`UPDATE_EXPENSE_MENU`).
* [ ] **3) DELETE_MENU (Модуль удаления расходов)** - В планах. Безопасное удаление транзакций с подтверждением пользователя.
* [ ] **4) ANALYZE_MENU (Модуль анализа расходов)** - В планах. Вывод аналитики за месяц, группировка по категориям и отображение графиков прямо в консоли.
