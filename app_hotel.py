import psycopg2


def print_rows(rows):
    if not rows:
        print("[i] Ничего не найдено")
        return
    for row in rows:
        print(row)


def execute_fetch(cur, query, params=()):
    cur.execute(query, params)
    return cur.fetchall()


def execute_call(cur, query, params=()):
    cur.execute(query, params)
    print("[+] Операция выполнена")


def hotels_menu(cur, user):
    print("\n[ОТЕЛИ] a. Поиск | b. Добавить | c. Обновить рейтинг | d. Удалить")
    action = input("Действие: ").strip().lower()
    try:
        if action == 'a':
            rows = execute_fetch(cur, "SELECT * FROM select_hotel_by_name(%s);", (input("Название отеля: "),))
            print_rows(rows)
        elif action == 'b':
            execute_call(cur, "CALL insert_hotel(%s, %s, %s);", (
                input("Название: "), input("Город: "), float(input("Рейтинг: "))
            ))
        elif action == 'c':
            execute_call(cur, "CALL update_hotel_rating(%s, %s);", (
                int(input("ID отеля: ")), float(input("Новый рейтинг: "))
            ))
        elif action == 'd':
            execute_call(cur, "CALL delete_hotel(%s);", (int(input("ID отеля: ")),))
    except Exception as exc:
        print(f"[!] Ошибка: {exc}")


def rooms_menu(cur, user):
    print("\n[НОМЕРА] a. Поиск | b. Добавить | c. Обновить статус | d. Удалить")
    action = input("Действие: ").strip().lower()
    try:
        if action == 'a':
            rows = execute_fetch(cur, "SELECT * FROM select_room_by_type(%s);", (input("Тип номера: "),))
            print_rows(rows)
        elif action == 'b':
            execute_call(cur, "CALL insert_room(%s, %s, %s, %s, %s);", (
                int(input("ID отеля: ")),
                input("Номер комнаты: "),
                input("Тип номера: "),
                float(input("Цена за ночь: ")),
                input("Статус (available/occupied/maintenance): ")
            ))
        elif action == 'c':
            execute_call(cur, "CALL update_room_status(%s, %s);", (
                int(input("ID номера: ")), input("Новый статус: ")
            ))
        elif action == 'd':
            execute_call(cur, "CALL delete_room(%s);", (int(input("ID номера: ")),))
    except Exception as exc:
        print(f"[!] Ошибка: {exc}")


def guests_menu(cur, user):
    print("\n[ГОСТИ] a. Поиск | b. Добавить | c. Обновить телефон | d. Удалить")
    action = input("Действие: ").strip().lower()
    try:
        if action == 'a':
            rows = execute_fetch(cur, "SELECT * FROM select_guest_by_name(%s);", (input("ФИО гостя: "),))
            print_rows(rows)
        elif action == 'b':
            execute_call(cur, "CALL insert_guest(%s, %s, %s, %s);", (
                input("ФИО: "),
                input("Телефон: "),
                input("Email: "),
                input("Паспорт: ")
            ))
        elif action == 'c':
            execute_call(cur, "CALL update_guest_phone(%s, %s);", (
                int(input("ID гостя: ")), input("Новый телефон: ")
            ))
        elif action == 'd':
            execute_call(cur, "CALL delete_guest(%s);", (int(input("ID гостя: ")),))
    except Exception as exc:
        print(f"[!] Ошибка: {exc}")


def bookings_menu(cur, user):
    print("\n[БРОНИРОВАНИЯ] a. Поиск | b. Добавить | c. Обновить статус | d. Удалить")
    action = input("Действие: ").strip().lower()
    try:
        if action == 'a':
            rows = execute_fetch(cur, "SELECT * FROM select_booking_by_status(%s);", (input("Статус бронирования: "),))
            print_rows(rows)
        elif action == 'b':
            execute_call(cur, "CALL insert_booking(%s, %s, %s, %s, %s, %s);", (
                int(input("ID гостя: ")),
                int(input("ID номера: ")),
                input("Дата заезда (YYYY-MM-DD): "),
                input("Дата выезда (YYYY-MM-DD): "),
                float(input("Итоговая стоимость: ")),
                input("Статус: ")
            ))
        elif action == 'c':
            execute_call(cur, "CALL update_booking_status(%s, %s);", (
                int(input("ID бронирования: ")), input("Новый статус: ")
            ))
        elif action == 'd':
            execute_call(cur, "CALL delete_booking(%s);", (int(input("ID бронирования: ")),))
    except Exception as exc:
        print(f"[!] Ошибка: {exc}")


def services_menu(cur, user):
    print("\n[УСЛУГИ] a. Поиск | b. Добавить | c. Обновить цену | d. Удалить")
    action = input("Действие: ").strip().lower()
    try:
        if action == 'a':
            rows = execute_fetch(cur, "SELECT * FROM select_service_by_name(%s);", (input("Название услуги: "),))
            print_rows(rows)
        elif action == 'b':
            execute_call(cur, "CALL insert_service(%s, %s, %s, %s);", (
                int(input("ID бронирования: ")),
                input("Название услуги: "),
                float(input("Цена услуги: ")),
                input("Дата услуги (YYYY-MM-DD): ")
            ))
        elif action == 'c':
            execute_call(cur, "CALL update_service_price(%s, %s);", (
                int(input("ID услуги: ")), float(input("Новая цена: "))
            ))
        elif action == 'd':
            execute_call(cur, "CALL delete_service(%s);", (int(input("ID услуги: ")),))
    except Exception as exc:
        print(f"[!] Ошибка: {exc}")


def logs_menu(cur):
    log_queries = {
        '1': ("Логи отелей", "SELECT * FROM select_hotels_log();"),
        '2': ("Логи номеров", "SELECT * FROM select_rooms_log();"),
        '3': ("Логи гостей", "SELECT * FROM select_guests_log();"),
        '4': ("Логи бронирований", "SELECT * FROM select_bookings_log();"),
        '5': ("Логи услуг", "SELECT * FROM select_services_log();"),
    }
    print("\n[ЛОГИ] 1. Отели | 2. Номера | 3. Гости | 4. Бронирования | 5. Услуги")
    choice = input("Выберите таблицу логов: ").strip()
    if choice not in log_queries:
        return
    try:
        title, query = log_queries[choice]
        print(f"\n{title}")
        print_rows(execute_fetch(cur, query))
    except Exception as exc:
        print(f"[!] Ошибка: {exc}")


def main():
    print("=== HOTEL MANAGEMENT SYSTEM: PRO RBAC ===")
    print("Логины: db_admin / db_service / db_user")
    print("Пароли: admin123 / service123 / user123")

    username = input("Username: ").strip()
    password = input("Password: ").strip()

    try:
        conn = psycopg2.connect(
            dbname="hotel_service",
            user=username,
            password=password,
            host="localhost",
            port="5432"
        )
        conn.autocommit = True
        cur = conn.cursor()
        print(f"\n[+] Вход выполнен. Роль: {username}")

        while True:
            print("\n" + "=" * 60)
            print("ГЛАВНОЕ МЕНЮ")
            print("1. Отели")
            print("2. Номера")
            print("3. Гости")
            print("4. Бронирования")
            print("5. Услуги")
            if username == 'db_admin':
                print("L. Просмотр логов")
            print("0. Выход")

            choice = input("\nВыберите раздел: ").strip().upper()
            if choice == '0':
                break
            elif choice == '1':
                hotels_menu(cur, username)
            elif choice == '2':
                rooms_menu(cur, username)
            elif choice == '3':
                guests_menu(cur, username)
            elif choice == '4':
                bookings_menu(cur, username)
            elif choice == '5':
                services_menu(cur, username)
            elif choice == 'L' and username == 'db_admin':
                logs_menu(cur)
    except Exception as exc:
        print(f"\n[!] Ошибка подключения: {exc}")
    finally:
        try:
            cur.close()
            conn.close()
        except Exception:
            pass


if __name__ == '__main__':
    main()
