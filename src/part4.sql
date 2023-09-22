-- CREATE DATABASE part4_db;
--
-- CREATE SCHEMA public;

CREATE TABLE test_table1 (
    id SERIAL PRIMARY KEY,
    title VARCHAR(25) NOT NULL
);

CREATE TABLE test_table2 (
    id SERIAL PRIMARY KEY,
    title VARCHAR(25) NOT NULL
);

CREATE TABLE no_test_table (
    id SERIAL PRIMARY KEY,
    title VARCHAR(25) NOT NULL
);

CREATE TABLE table_not_for_test (
    id SERIAL PRIMARY KEY,
    title VARCHAR(25) NOT NULL
);

CREATE TABLE Dynarini_only (
    id SERIAL PRIMARY KEY,
    title VARCHAR(25) NOT NULL
);

CREATE TABLE Dynarini_only2 (
    id SERIAL PRIMARY KEY,
    title VARCHAR(25) NOT NULL
);

--------------------------------------------------------------------------------
-- Создание функций БД part4
--------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS fnc_test_table1;

CREATE OR REPLACE FUNCTION fnc_test_table1() RETURNS SETOF test_table1 AS
    $$ SELECT * FROM test_table1; $$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION fnc_no_test_table_all() RETURNS SETOF no_test_table AS
    $$ SELECT * FROM no_test_table; $$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION fnc_no_test_table(ptitle VARCHAR DEFAULT 'female') RETURNS SETOF no_test_table AS
$$ SELECT
        *
    FROM
        no_test_table
    WHERE
        title = ptitle; $$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION fnc_no_test_table(ptitle TEXT, pid INTEGER) RETURNS SETOF no_test_table AS
$$ SELECT
        *
    FROM
        no_test_table
    WHERE
        title = ptitle
        ANd id = pid; $$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION fnc_Dynarini(Dynarini TEXT DEFAULT 'Dynarini') RETURNS VARCHAR AS
$$ SELECT Dynarini; $$
LANGUAGE SQL;

--------------------------------------------------------------------------------
-- Создание триггеров БД part4
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fnc_Dynarini_only_handle() RETURNS TRIGGER AS $$
    BEGIN
        IF (TG_OP = 'INSERT') THEN
            NEW.title = 'Dynarini';
            RETURN NEW;
        ELSIF (TG_OP = 'UPDATE') THEN
            NEW.title = 'Dynarini';
            RETURN NEW;
        ELSIF (TG_OP = 'DELETE') THEN
            RETURN OLD;
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fnc_Dynarini_only_handle2() RETURNS TRIGGER AS $$
    BEGIN
        NEW.title = NEW.title || 'Dynarini';
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fnc_test_table2() RETURNS TRIGGER AS $$
    BEGIN
        RAISE NOTICE 'TEST1!!!!!!!';
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_Dynarini_only
BEFORE INSERT OR UPDATE OR DELETE ON Dynarini_only
    FOR EACH ROW EXECUTE FUNCTION fnc_Dynarini_only_handle();

CREATE OR REPLACE TRIGGER trg_Dynarini_only
BEFORE INSERT OR UPDATE ON Dynarini_only2
    FOR EACH ROW EXECUTE FUNCTION fnc_Dynarini_only_handle();

CREATE OR REPLACE TRIGGER trg_Dynarini_only2
BEFORE INSERT ON Dynarini_only2
    FOR EACH ROW EXECUTE FUNCTION fnc_Dynarini_only_handle2();

CREATE OR REPLACE TRIGGER trg_test_table1
BEFORE INSERT ON test_table1
    FOR EACH ROW EXECUTE FUNCTION fnc_test_table2();

--------------------------------------------------------------------------------
-- Задания
--------------------------------------------------------------------------------
-- Task1
--------------------------------------------------------------------------------
-- Создать хранимую процедуру, которая, не уничтожая базу данных, уничтожает
-- все те таблицы текущей базы данных, имена которых начинаются с фразы
-- 'TableName'.
--
-- Мы не хотим удалять служебные таблицы.
-- Поэтому параметр схемы укажем в процедуре с дефолтным значением "public."
-- Альтернативно можно было делать выборку:
-- table_schema NOT LIKE 'pg_%' AND table_schema NOT LIKE 'information_schema' 
CREATE
OR REPLACE PROCEDURE pr_part4_task1(
    IN table_name_pattern TEXT,
    IN table_schema_pattern TEXT DEFAULT 'public'
) AS $$
DECLARE
    rec record;
BEGIN
    FOR rec IN
    SELECT
        table_schema,
        table_name
    FROM
        information_schema.tables
    WHERE
        table_schema LIKE table_schema_pattern || '%'
        AND table_type = 'BASE TABLE'
        AND table_name LIKE table_name_pattern || '%'
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(rec.table_schema) || '.' || quote_ident(rec.table_name) || ' CASCADE';
        RAISE NOTICE 'Table deleted: %', quote_ident(rec.table_schema) || '.' || quote_ident(rec.table_name);
    END LOOP;

END;
$$ LANGUAGE plpgsql;

-- Проверяем работу процедуры
BEGIN;
CALL pr_part4_task1('test');
END;


-------------------------ex02-------------------------

CREATE
OR REPLACE PROCEDURE pr_part4_task2(
    INOUT rows_count INTEGER,
    IN table_schema_pattern TEXT DEFAULT 'public'
) AS $$
BEGIN
    DROP TABLE IF EXISTS tmp_part4_task2;
    CREATE TEMP TABLE tmp_part4_task2 AS
        SELECT
            MAX(routines.routine_name) AS function_name,
            -- Т.к. при агрегации порядок соединения не гарантируется, а мы бы 
            -- хотели тот же порядок, что при объявлении функции, то используем
            -- агрегацию с сортировкой
            string_agg(
                parameters.parameter_name,
                ', '
                ORDER BY
                    parameters.ordinal_position
            ) AS function_parameters
        FROM
            information_schema.routines
            LEFT JOIN information_schema.parameters ON routines.specific_name = parameters.specific_name
        WHERE
            routines.specific_schema = table_schema_pattern
            AND routine_type = 'FUNCTION'
            AND parameter_name IS NOT NULL
        GROUP BY
            parameters.specific_name -- Группировку делаем не по routine_name
            -- чтобы отобразить все перегрузки с одним именем
        ORDER BY
            function_name;

    SELECT COUNT(*) FROM tmp_part4_task2 INTO rows_count;
END;

$$ LANGUAGE plpgsql;


-------------------------ex03------------------------- 
CREATE OR REPLACE PROCEDURE destroy_all_dml_triggers(OUT destroyed_trigger_count INTEGER)
AS $$
DECLARE
    trigger_rec RECORD;
    trigger_row RECORD;
BEGIN
    destroyed_trigger_count := 0;
    FOR trigger_rec IN (
        SELECT event_object_table, trigger_name
        FROM information_schema.triggers
        WHERE trigger_schema = 'public'
    )
    LOOP
        trigger_row := trigger_rec;
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_row.trigger_name || ' ON ' || trigger_row.event_object_table;
        destroyed_trigger_count := destroyed_trigger_count + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- DO $$
-- DECLARE
-- 	total_triggers INTEGER;
-- BEGIN
-- 	CALL destroy_all_dml_triggers(total_triggers);
-- 	RAISE NOTICE 'Total triggers destroyed: %', total_triggers;
-- END;
-- $$;


CREATE OR REPLACE PROCEDURE search_objects_by_description(IN search_string TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    object_name TEXT;
    object_description TEXT;
BEGIN
    FOR object_name, object_description IN (
        SELECT proname, obj_description(oid, 'pg_proc')
        FROM pg_proc
        WHERE proname ILIKE '%' || search_string || '%'
    )
    LOOP
        RAISE NOTICE 'Object Name: %, Description: %', object_name, object_description;
    END LOOP;
END;
$$;

--CALL search_objects_by_description('add');