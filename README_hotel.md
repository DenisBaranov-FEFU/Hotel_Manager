# Лабораторная работа №1
## Тема: Система управления гостиницей

Проект реализует лабораторную работу по базам данных на PostgreSQL.

В проекте реализованы:
- 5 связанных таблиц предметной области гостиницы;
- хранимые процедуры `INSERT`, `UPDATE`, `DELETE`;
- функции поиска `SELECT`;
- 3 роли доступа: `db_admin`, `db_service`, `db_user`;
- лог-таблицы и триггеры для аудита изменений;
- консольное Python-приложение без ORM.

## Структура БД

### Основные таблицы
1. `hotels` - гостиницы
2. `rooms` - номера
3. `guests` - гости
4. `bookings` - бронирования
5. `services` - дополнительные услуги

### Лог-таблицы
- `hotels_log`
- `rooms_log`
- `guests_log`
- `bookings_log`
- `services_log`

## Роли
- `db_admin / admin123` - полный доступ, включая удаление и просмотр логов.
- `db_service / service123` - поиск, добавление и обновление.
- `db_user / user123` - только поиск.

## Запуск

### 1. Поднять PostgreSQL
```bash
docker-compose up -d
```

### 2. Скопировать SQL в контейнер
```bash
docker cp database_hotel.sql hotel_db_lab:/database_hotel.sql
```

### 3. Выполнить SQL-скрипт
```bash
docker exec -it hotel_db_lab psql -U admin -d hotel_service -f /database_hotel.sql
```

### 4. Установить зависимость для Python
```bash
pip install psycopg2-binary
```

### 5. Запустить приложение
```bash
python app_hotel.py
```