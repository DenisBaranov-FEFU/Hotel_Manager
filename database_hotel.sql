-- =====================================================
-- Лабораторная работа №1
-- Тема: Система управления гостиницей
-- СУБД: PostgreSQL
-- Все операции приложения выполняются через функции и процедуры
-- =====================================================

-- 1. Очистка старых объектов
DROP TRIGGER IF EXISTS trg_hotels_audit ON hotels;
DROP TRIGGER IF EXISTS trg_rooms_audit ON rooms;
DROP TRIGGER IF EXISTS trg_guests_audit ON guests;
DROP TRIGGER IF EXISTS trg_bookings_audit ON bookings;
DROP TRIGGER IF EXISTS trg_services_audit ON services;

DROP FUNCTION IF EXISTS fn_log_hotels() CASCADE;
DROP FUNCTION IF EXISTS fn_log_rooms() CASCADE;
DROP FUNCTION IF EXISTS fn_log_guests() CASCADE;
DROP FUNCTION IF EXISTS fn_log_bookings() CASCADE;
DROP FUNCTION IF EXISTS fn_log_services() CASCADE;

DROP TABLE IF EXISTS services_log, bookings_log, guests_log, rooms_log, hotels_log CASCADE;
DROP TABLE IF EXISTS services, bookings, guests, rooms, hotels CASCADE;

DROP ROLE IF EXISTS db_admin;
DROP ROLE IF EXISTS db_service;
DROP ROLE IF EXISTS db_user;

-- 2. Основные таблицы
CREATE TABLE hotels (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    city TEXT NOT NULL,
    rating NUMERIC(2,1) CHECK (rating BETWEEN 1 AND 5)
);

CREATE TABLE rooms (
    id SERIAL PRIMARY KEY,
    hotel_id INTEGER NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    room_number TEXT NOT NULL,
    room_type TEXT NOT NULL,
    price_per_night NUMERIC(10,2) NOT NULL CHECK (price_per_night > 0),
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'occupied', 'maintenance')),
    UNIQUE (hotel_id, room_number)
);

CREATE TABLE guests (
    id SERIAL PRIMARY KEY,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT UNIQUE,
    passport_number TEXT UNIQUE NOT NULL
);

CREATE TABLE bookings (
    id SERIAL PRIMARY KEY,
    guest_id INTEGER NOT NULL REFERENCES guests(id) ON DELETE CASCADE,
    room_id INTEGER NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    total_price NUMERIC(10,2) NOT NULL CHECK (total_price >= 0),
    booking_status TEXT NOT NULL DEFAULT 'confirmed' CHECK (booking_status IN ('confirmed', 'checked_in', 'checked_out', 'cancelled')),
    CHECK (check_out_date > check_in_date)
);

CREATE TABLE services (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    service_name TEXT NOT NULL,
    service_price NUMERIC(10,2) NOT NULL CHECK (service_price >= 0),
    service_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- 3. Лог-таблицы
CREATE TABLE hotels_log (
    log_id SERIAL PRIMARY KEY,
    id INTEGER,
    name TEXT,
    city TEXT,
    rating NUMERIC(2,1),
    user_name TEXT,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action TEXT
);

CREATE TABLE rooms_log (
    log_id SERIAL PRIMARY KEY,
    id INTEGER,
    hotel_id INTEGER,
    room_number TEXT,
    room_type TEXT,
    price_per_night NUMERIC(10,2),
    status TEXT,
    user_name TEXT,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action TEXT
);

CREATE TABLE guests_log (
    log_id SERIAL PRIMARY KEY,
    id INTEGER,
    full_name TEXT,
    phone TEXT,
    email TEXT,
    passport_number TEXT,
    user_name TEXT,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action TEXT
);

CREATE TABLE bookings_log (
    log_id SERIAL PRIMARY KEY,
    id INTEGER,
    guest_id INTEGER,
    room_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    total_price NUMERIC(10,2),
    booking_status TEXT,
    user_name TEXT,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action TEXT
);

CREATE TABLE services_log (
    log_id SERIAL PRIMARY KEY,
    id INTEGER,
    booking_id INTEGER,
    service_name TEXT,
    service_price NUMERIC(10,2),
    service_date DATE,
    user_name TEXT,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action TEXT
);

-- 4. Функции логирования
CREATE OR REPLACE FUNCTION fn_log_hotels()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO hotels_log(id, name, city, rating, user_name, action)
        VALUES (OLD.id, OLD.name, OLD.city, OLD.rating, current_user, 'DELETE');
        RETURN OLD;
    ELSE
        INSERT INTO hotels_log(id, name, city, rating, user_name, action)
        VALUES (NEW.id, NEW.name, NEW.city, NEW.rating, current_user, TG_OP);
        RETURN NEW;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_log_rooms()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO rooms_log(id, hotel_id, room_number, room_type, price_per_night, status, user_name, action)
        VALUES (OLD.id, OLD.hotel_id, OLD.room_number, OLD.room_type, OLD.price_per_night, OLD.status, current_user, 'DELETE');
        RETURN OLD;
    ELSE
        INSERT INTO rooms_log(id, hotel_id, room_number, room_type, price_per_night, status, user_name, action)
        VALUES (NEW.id, NEW.hotel_id, NEW.room_number, NEW.room_type, NEW.price_per_night, NEW.status, current_user, TG_OP);
        RETURN NEW;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_log_guests()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO guests_log(id, full_name, phone, email, passport_number, user_name, action)
        VALUES (OLD.id, OLD.full_name, OLD.phone, OLD.email, OLD.passport_number, current_user, 'DELETE');
        RETURN OLD;
    ELSE
        INSERT INTO guests_log(id, full_name, phone, email, passport_number, user_name, action)
        VALUES (NEW.id, NEW.full_name, NEW.phone, NEW.email, NEW.passport_number, current_user, TG_OP);
        RETURN NEW;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_log_bookings()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO bookings_log(id, guest_id, room_id, check_in_date, check_out_date, total_price, booking_status, user_name, action)
        VALUES (OLD.id, OLD.guest_id, OLD.room_id, OLD.check_in_date, OLD.check_out_date, OLD.total_price, OLD.booking_status, current_user, 'DELETE');
        RETURN OLD;
    ELSE
        INSERT INTO bookings_log(id, guest_id, room_id, check_in_date, check_out_date, total_price, booking_status, user_name, action)
        VALUES (NEW.id, NEW.guest_id, NEW.room_id, NEW.check_in_date, NEW.check_out_date, NEW.total_price, NEW.booking_status, current_user, TG_OP);
        RETURN NEW;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_log_services()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO services_log(id, booking_id, service_name, service_price, service_date, user_name, action)
        VALUES (OLD.id, OLD.booking_id, OLD.service_name, OLD.service_price, OLD.service_date, current_user, 'DELETE');
        RETURN OLD;
    ELSE
        INSERT INTO services_log(id, booking_id, service_name, service_price, service_date, user_name, action)
        VALUES (NEW.id, NEW.booking_id, NEW.service_name, NEW.service_price, NEW.service_date, current_user, TG_OP);
        RETURN NEW;
    END IF;
END;
$$;

-- 5. Триггеры
CREATE TRIGGER trg_hotels_audit
AFTER INSERT OR UPDATE OR DELETE ON hotels
FOR EACH ROW EXECUTE FUNCTION fn_log_hotels();

CREATE TRIGGER trg_rooms_audit
AFTER INSERT OR UPDATE OR DELETE ON rooms
FOR EACH ROW EXECUTE FUNCTION fn_log_rooms();

CREATE TRIGGER trg_guests_audit
AFTER INSERT OR UPDATE OR DELETE ON guests
FOR EACH ROW EXECUTE FUNCTION fn_log_guests();

CREATE TRIGGER trg_bookings_audit
AFTER INSERT OR UPDATE OR DELETE ON bookings
FOR EACH ROW EXECUTE FUNCTION fn_log_bookings();

CREATE TRIGGER trg_services_audit
AFTER INSERT OR UPDATE OR DELETE ON services
FOR EACH ROW EXECUTE FUNCTION fn_log_services();

-- 6. Хранимые процедуры и функции
-- HOTELS
CREATE OR REPLACE PROCEDURE insert_hotel(p_name TEXT, p_city TEXT, p_rating NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO hotels(name, city, rating) VALUES (p_name, p_city, p_rating);
END;
$$;

CREATE OR REPLACE PROCEDURE update_hotel_rating(p_id INTEGER, p_rating NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE hotels SET rating = p_rating WHERE id = p_id;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_hotel(p_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM hotels WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION select_hotel_by_name(p_name TEXT)
RETURNS TABLE(id INTEGER, name TEXT, city TEXT, rating NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT h.id, h.name, h.city, h.rating FROM hotels h
    WHERE h.name ILIKE '%' || p_name || '%'
    ORDER BY h.id;
END;
$$;

-- ROOMS
CREATE OR REPLACE PROCEDURE insert_room(p_hotel_id INTEGER, p_room_number TEXT, p_room_type TEXT, p_price NUMERIC, p_status TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO rooms(hotel_id, room_number, room_type, price_per_night, status)
    VALUES (p_hotel_id, p_room_number, p_room_type, p_price, p_status);
END;
$$;

CREATE OR REPLACE PROCEDURE update_room_status(p_id INTEGER, p_status TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE rooms SET status = p_status WHERE id = p_id;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_room(p_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM rooms WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION select_room_by_type(p_room_type TEXT)
RETURNS TABLE(id INTEGER, hotel_id INTEGER, room_number TEXT, room_type TEXT, price_per_night NUMERIC, status TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT r.id, r.hotel_id, r.room_number, r.room_type, r.price_per_night, r.status FROM rooms r
    WHERE r.room_type ILIKE '%' || p_room_type || '%'
    ORDER BY r.id;
END;
$$;

-- GUESTS
CREATE OR REPLACE PROCEDURE insert_guest(p_full_name TEXT, p_phone TEXT, p_email TEXT, p_passport_number TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO guests(full_name, phone, email, passport_number)
    VALUES (p_full_name, p_phone, p_email, p_passport_number);
END;
$$;

CREATE OR REPLACE PROCEDURE update_guest_phone(p_id INTEGER, p_phone TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE guests SET phone = p_phone WHERE id = p_id;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_guest(p_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM guests WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION select_guest_by_name(p_name TEXT)
RETURNS TABLE(id INTEGER, full_name TEXT, phone TEXT, email TEXT, passport_number TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT g.id, g.full_name, g.phone, g.email, g.passport_number FROM guests g
    WHERE g.full_name ILIKE '%' || p_name || '%'
    ORDER BY g.id;
END;
$$;

-- BOOKINGS
CREATE OR REPLACE PROCEDURE insert_booking(
    p_guest_id INTEGER,
    p_room_id INTEGER,
    p_check_in DATE,
    p_check_out DATE,
    p_total_price NUMERIC,
    p_status TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO bookings(guest_id, room_id, check_in_date, check_out_date, total_price, booking_status)
    VALUES (p_guest_id, p_room_id, p_check_in, p_check_out, p_total_price, p_status);
END;
$$;

CREATE OR REPLACE PROCEDURE update_booking_status(p_id INTEGER, p_status TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE bookings SET booking_status = p_status WHERE id = p_id;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_booking(p_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM bookings WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION select_booking_by_status(p_status TEXT)
RETURNS TABLE(id INTEGER, guest_id INTEGER, room_id INTEGER, check_in_date DATE, check_out_date DATE, total_price NUMERIC, booking_status TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT b.id, b.guest_id, b.room_id, b.check_in_date, b.check_out_date, b.total_price, b.booking_status FROM bookings b
    WHERE b.booking_status ILIKE '%' || p_status || '%'
    ORDER BY b.id;
END;
$$;

-- SERVICES
CREATE OR REPLACE PROCEDURE insert_service(p_booking_id INTEGER, p_service_name TEXT, p_service_price NUMERIC, p_service_date DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO services(booking_id, service_name, service_price, service_date)
    VALUES (p_booking_id, p_service_name, p_service_price, p_service_date);
END;
$$;

CREATE OR REPLACE PROCEDURE update_service_price(p_id INTEGER, p_service_price NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE services SET service_price = p_service_price WHERE id = p_id;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_service(p_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM services WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION select_service_by_name(p_name TEXT)
RETURNS TABLE(id INTEGER, booking_id INTEGER, service_name TEXT, service_price NUMERIC, service_date DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT s.id, s.booking_id, s.service_name, s.service_price, s.service_date FROM services s
    WHERE s.service_name ILIKE '%' || p_name || '%'
    ORDER BY s.id;
END;
$$;

-- LOG FUNCTIONS FOR APP (чтобы не делать прямой SELECT из приложения)
CREATE OR REPLACE FUNCTION select_hotels_log()
RETURNS TABLE(log_id INTEGER, id INTEGER, name TEXT, city TEXT, rating NUMERIC, user_name TEXT, update_time TIMESTAMP, action TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT l.log_id, l.id, l.name, l.city, l.rating, l.user_name, l.update_time, l.action
    FROM hotels_log l ORDER BY l.update_time DESC LIMIT 10;
END;
$$;

CREATE OR REPLACE FUNCTION select_rooms_log()
RETURNS TABLE(log_id INTEGER, id INTEGER, hotel_id INTEGER, room_number TEXT, room_type TEXT, price_per_night NUMERIC, status TEXT, user_name TEXT, update_time TIMESTAMP, action TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT l.log_id, l.id, l.hotel_id, l.room_number, l.room_type, l.price_per_night, l.status, l.user_name, l.update_time, l.action
    FROM rooms_log l ORDER BY l.update_time DESC LIMIT 10;
END;
$$;

CREATE OR REPLACE FUNCTION select_guests_log()
RETURNS TABLE(log_id INTEGER, id INTEGER, full_name TEXT, phone TEXT, email TEXT, passport_number TEXT, user_name TEXT, update_time TIMESTAMP, action TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT l.log_id, l.id, l.full_name, l.phone, l.email, l.passport_number, l.user_name, l.update_time, l.action
    FROM guests_log l ORDER BY l.update_time DESC LIMIT 10;
END;
$$;

CREATE OR REPLACE FUNCTION select_bookings_log()
RETURNS TABLE(log_id INTEGER, id INTEGER, guest_id INTEGER, room_id INTEGER, check_in_date DATE, check_out_date DATE, total_price NUMERIC, booking_status TEXT, user_name TEXT, update_time TIMESTAMP, action TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT l.log_id, l.id, l.guest_id, l.room_id, l.check_in_date, l.check_out_date, l.total_price, l.booking_status, l.user_name, l.update_time, l.action
    FROM bookings_log l ORDER BY l.update_time DESC LIMIT 10;
END;
$$;

CREATE OR REPLACE FUNCTION select_services_log()
RETURNS TABLE(log_id INTEGER, id INTEGER, booking_id INTEGER, service_name TEXT, service_price NUMERIC, service_date DATE, user_name TEXT, update_time TIMESTAMP, action TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT l.log_id, l.id, l.booking_id, l.service_name, l.service_price, l.service_date, l.user_name, l.update_time, l.action
    FROM services_log l ORDER BY l.update_time DESC LIMIT 10;
END;
$$;

-- 7. Наполнение данными через процедуры (50+ записей)
DO $$
BEGIN
    -- 5 отелей
    CALL insert_hotel('Aurora Hotel', 'Владивосток', 4.6);
    CALL insert_hotel('Sea Breeze Inn', 'Находка', 4.3);
    CALL insert_hotel('Mountain View Hotel', 'Хабаровск', 4.7);
    CALL insert_hotel('City Center Suites', 'Уссурийск', 4.2);
    CALL insert_hotel('Golden Bay Resort', 'Владивосток', 4.8);

    -- 15 номеров
    CALL insert_room(1, '101', 'Standard', 3500, 'available');
    CALL insert_room(1, '102', 'Deluxe', 4800, 'occupied');
    CALL insert_room(1, '103', 'Suite', 7200, 'maintenance');
    CALL insert_room(2, '201', 'Standard', 3200, 'available');
    CALL insert_room(2, '202', 'Deluxe', 4500, 'occupied');
    CALL insert_room(2, '203', 'Suite', 6800, 'available');
    CALL insert_room(3, '301', 'Standard', 3700, 'occupied');
    CALL insert_room(3, '302', 'Deluxe', 5100, 'available');
    CALL insert_room(3, '303', 'Suite', 7600, 'available');
    CALL insert_room(4, '401', 'Standard', 3000, 'available');
    CALL insert_room(4, '402', 'Deluxe', 4300, 'maintenance');
    CALL insert_room(4, '403', 'Suite', 6500, 'occupied');
    CALL insert_room(5, '501', 'Standard', 3900, 'available');
    CALL insert_room(5, '502', 'Deluxe', 5600, 'occupied');
    CALL insert_room(5, '503', 'Suite', 8100, 'available');

    -- 10 гостей
    CALL insert_guest('Иванов Иван Иванович', '+79990000001', 'ivanov@mail.ru', '4500-100001');
    CALL insert_guest('Петров Петр Сергеевич', '+79990000002', 'petrov@mail.ru', '4500-100002');
    CALL insert_guest('Сидорова Анна Олеговна', '+79990000003', 'sidorova@mail.ru', '4500-100003');
    CALL insert_guest('Кузнецов Дмитрий Андреевич', '+79990000004', 'kuznetsov@mail.ru', '4500-100004');
    CALL insert_guest('Смирнова Мария Игоревна', '+79990000005', 'smirnova@mail.ru', '4500-100005');
    CALL insert_guest('Попов Алексей Романович', '+79990000006', 'popov@mail.ru', '4500-100006');
    CALL insert_guest('Васильева Елена Павловна', '+79990000007', 'vasileva@mail.ru', '4500-100007');
    CALL insert_guest('Морозов Кирилл Викторович', '+79990000008', 'morozov@mail.ru', '4500-100008');
    CALL insert_guest('Новикова Дарья Ильинична', '+79990000009', 'novikova@mail.ru', '4500-100009');
    CALL insert_guest('Федоров Никита Артемович', '+79990000010', 'fedorov@mail.ru', '4500-100010');

    -- 12 бронирований
    CALL insert_booking(1, 2, '2026-04-01', '2026-04-05', 19200, 'confirmed');
    CALL insert_booking(2, 5, '2026-04-02', '2026-04-06', 18000, 'checked_in');
    CALL insert_booking(3, 7, '2026-04-03', '2026-04-08', 18500, 'confirmed');
    CALL insert_booking(4, 12, '2026-04-04', '2026-04-07', 19500, 'checked_out');
    CALL insert_booking(5, 14, '2026-04-05', '2026-04-09', 22400, 'cancelled');
    CALL insert_booking(6, 1, '2026-04-06', '2026-04-08', 7000, 'confirmed');
    CALL insert_booking(7, 4, '2026-04-07', '2026-04-10', 9600, 'checked_in');
    CALL insert_booking(8, 8, '2026-04-08', '2026-04-12', 20400, 'confirmed');
    CALL insert_booking(9, 10, '2026-04-09', '2026-04-11', 6000, 'checked_out');
    CALL insert_booking(10, 15, '2026-04-10', '2026-04-13', 24300, 'confirmed');
    CALL insert_booking(1, 6, '2026-04-11', '2026-04-14', 20400, 'confirmed');
    CALL insert_booking(2, 9, '2026-04-12', '2026-04-15', 22800, 'cancelled');

    -- 10 услуг
    CALL insert_service(1, 'Завтрак', 900, '2026-04-02');
    CALL insert_service(1, 'Трансфер', 1500, '2026-04-03');
    CALL insert_service(2, 'Прачечная', 700, '2026-04-03');
    CALL insert_service(3, 'Спа', 2500, '2026-04-04');
    CALL insert_service(4, 'Парковка', 500, '2026-04-05');
    CALL insert_service(5, 'Завтрак', 900, '2026-04-06');
    CALL insert_service(6, 'Мини-бар', 1200, '2026-04-06');
    CALL insert_service(7, 'Прачечная', 700, '2026-04-08');
    CALL insert_service(8, 'Спа', 2500, '2026-04-09');
    CALL insert_service(10, 'Трансфер', 1500, '2026-04-11');
END
$$;

-- 8. Учетные записи и права
CREATE ROLE db_admin LOGIN PASSWORD 'admin123';
CREATE ROLE db_service LOGIN PASSWORD 'service123';
CREATE ROLE db_user LOGIN PASSWORD 'user123';

GRANT USAGE ON SCHEMA public TO db_admin, db_service, db_user;

-- Администратор: полный доступ ко всем таблицам и процедурам
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO db_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO db_admin;

-- Права для db_service
GRANT SELECT, INSERT, UPDATE ON hotels, rooms, guests, bookings, services TO db_service;

GRANT USAGE, SELECT ON SEQUENCE hotels_id_seq TO db_service;
GRANT USAGE, SELECT ON SEQUENCE rooms_id_seq TO db_service;
GRANT USAGE, SELECT ON SEQUENCE guests_id_seq TO db_service;
GRANT USAGE, SELECT ON SEQUENCE bookings_id_seq TO db_service;
GRANT USAGE, SELECT ON SEQUENCE services_id_seq TO db_service;

-- лог-таблицы
GRANT INSERT ON hotels_log, rooms_log, guests_log, bookings_log, services_log TO db_service;

-- sequence лог-таблиц
GRANT USAGE, SELECT ON SEQUENCE hotels_log_log_id_seq TO db_service;
GRANT USAGE, SELECT ON SEQUENCE rooms_log_log_id_seq TO db_service;
GRANT USAGE, SELECT ON SEQUENCE guests_log_log_id_seq TO db_service;
GRANT USAGE, SELECT ON SEQUENCE bookings_log_log_id_seq TO db_service;
GRANT USAGE, SELECT ON SEQUENCE services_log_log_id_seq TO db_service;

-- ПРАВА ДЛЯ db_user (только чтение через функции поиска)
GRANT SELECT ON hotels, rooms, bookings, services TO db_user;

GRANT EXECUTE ON FUNCTION
select_hotel_by_name(TEXT),
select_room_by_type(TEXT),
select_booking_by_status(TEXT),
select_service_by_name(TEXT)
TO db_user;

-- Сервисная учетная запись: SELECT, INSERT, UPDATE через процедуры/функции
GRANT EXECUTE ON PROCEDURE
    insert_hotel(TEXT, TEXT, NUMERIC),
    update_hotel_rating(INTEGER, NUMERIC),
    insert_room(INTEGER, TEXT, TEXT, NUMERIC, TEXT),
    update_room_status(INTEGER, TEXT),
    insert_guest(TEXT, TEXT, TEXT, TEXT),
    update_guest_phone(INTEGER, TEXT),
    insert_booking(INTEGER, INTEGER, DATE, DATE, NUMERIC, TEXT),
    update_booking_status(INTEGER, TEXT),
    insert_service(INTEGER, TEXT, NUMERIC, DATE),
    update_service_price(INTEGER, NUMERIC)
TO db_service;

GRANT EXECUTE ON FUNCTION
    select_hotel_by_name(TEXT),
    select_room_by_type(TEXT),
    select_guest_by_name(TEXT),
    select_booking_by_status(TEXT),
    select_service_by_name(TEXT)
TO db_service;

-- Пользователь: только SELECT-функции
GRANT EXECUTE ON FUNCTION
    select_hotel_by_name(TEXT),
    select_room_by_type(TEXT),
    select_booking_by_status(TEXT),
    select_service_by_name(TEXT)
TO db_user;

-- Администратору дополнительно разрешаем удаление и просмотр логов
GRANT EXECUTE ON PROCEDURE
    delete_hotel(INTEGER),
    delete_room(INTEGER),
    delete_guest(INTEGER),
    delete_booking(INTEGER),
    delete_service(INTEGER)
TO db_admin;

GRANT EXECUTE ON FUNCTION
    select_hotels_log(),
    select_rooms_log(),
    select_guests_log(),
    select_bookings_log(),
    select_services_log()
TO db_admin;
