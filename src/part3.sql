--------------------------------------------------------------------------------
-- Task 1
--------------------------------------------------------------------------------
-- Написать функцию, возвращающую таблицу TransferredPoints в более
-- человекочитаемом виде
--
-- При реализации учитваем, что при JOIN у нас может быть ситуация, что пара
-- p1-p2 у нас может быть в таблице, а p2-p1 может отсутстовать. Чтобы сохранить
-- такие записи нужно второе условие в WHERE (OR t2.id IS NULL)

CREATE OR REPLACE FUNCTION fnc_part3_task1()
RETURNS TABLE ("Peer1" VARCHAR, "Peer2" VARCHAR, "PointsAmount" INT)
LANGUAGE plpgsql
AS $$
BEGIN RETURN QUERY
    SELECT t1."CheckingPeer" AS Peer1,
           t1."CheckedPeer" AS Peer2,
           COALESCE(t1."PointsAmount", 0)  - COALESCE(t2."PointsAmount", 0)
    FROM TransferredPoints AS t1 FULL JOIN TransferredPoints AS t2
        ON t1."CheckedPeer" = t2."CheckingPeer" AND t1."CheckingPeer" = t2."CheckedPeer"
    WHERE t1."ID" < t2."ID" OR t2."ID" IS NULL;
END;
$$;

--------------------------------------------------------------------------------
-- Проверяем работу функции
--------------------------------------------------------------------------------

SELECT * FROM fnc_part3_task1();


CREATE OR REPLACE FUNCTION fnc_part3_task2()
    RETURNS TABLE
        (
            "Peer" VARCHAR,
            "Task" VARCHAR,
            "XP"   INTEGER
        )
AS
$$
BEGIN
    RETURN QUERY SELECT Checks."Peer", Checks."Task", XP."XPAmount"
         FROM P2P
              INNER JOIN Checks ON P2P."Check" = Checks."ID"
              INNER JOIN XP ON XP."Check" = Checks."ID"
              INNER JOIN Verter ON Verter."Check" = Checks."ID"
         WHERE P2P."State" = 'Success'
              AND Verter."State" = 'Success';
END;
$$ LANGUAGE plpgsql;


SELECT * FROM fnc_part3_task2();


--------------------------------------------------------------------------------
-- Task 3
--------------------------------------------------------------------------------
-- Написать функцию, определяющую пиров, которые не выходили из кампуса
-- в течение всего дня
--

CREATE OR REPLACE FUNCTION fnc_part3_task3(p_current_date DATE)
    RETURNS TABLE
            (
                "Peer" VARCHAR
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT TimeTracking."Peer"
        FROM TimeTracking
        WHERE TimeTracking."Date" = p_current_date
          AND "State" = 1
        GROUP BY TimeTracking."Peer"
        HAVING COUNT("State") = 1;
END;
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------
-- Проверяем работу функции
--------------------------------------------------------------------------------

SELECT * FROM fnc_part3_task3('2022-12-01');

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Task 4
--------------------------------------------------------------------------------
-- Посчитать изменение в количестве пир поинтов каждого пира по таблице
-- TransferredPoints
--

CREATE OR REPLACE FUNCTION fnc_part3_task4()
RETURNS TABLE ("Peer" VARCHAR, "PointsChange" NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN RETURN QUERY
    WITH positive AS (
            SELECT TransferredPoints."CheckingPeer" AS Peer,
               sum(TransferredPoints."PointsAmount") AS total_points
            FROM TransferredPoints
            GROUP BY TransferredPoints."CheckingPeer"),
        negative AS (
            SELECT TransferredPoints."CheckedPeer" AS Peer,
              -sum(TransferredPoints."PointsAmount") AS total_points
            FROM TransferredPoints
            GROUP BY TransferredPoints."CheckedPeer"),
        total AS (
            SELECT positive.Peer, positive.total_points
            FROM positive
            UNION
            SELECT negative.Peer, negative.total_points
            FROM negative)
    SELECT total.Peer, sum(total.total_points) FROM total
    group by total.Peer;
END;
$$;

--------------------------------------------------------------------------------
-- Проверяем работу функции
--------------------------------------------------------------------------------

SELECT * FROM fnc_part3_task4();

--------------------------------------------------------------------------------
-- Task 5
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fnc_part3_task5()
RETURNS TABLE ("Peer" VARCHAR, "summa" NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN RETURN QUERY
    with tmp as (
    SELECT "Peer1", sum("PointsAmount") as sm FROM fnc_part3_task1()
    group by "Peer1"
    union
    SELECT "Peer2", -sum("PointsAmount") FROM fnc_part3_task1()
    group by "Peer2")

    select "Peer1", sum(sm) FROM tmp
    group by "Peer1";
END;
$$;

SELECT * FROM fnc_part3_task5();


--------------------------------------------------------------------------------
-- Task 6
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fnc_part3_task6()
RETURNS TABLE ("Date" date, "Task" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN RETURN QUERY
WITH t1 AS (SELECT checks."Date", checks."Task", count(*) AS checks_amount
            FROM checks
            GROUP BY checks."Task", checks."Date"
            ORDER BY checks."Date", checks_amount),
     maximum AS (SELECT t1."Date", max(checks_amount) AS max_checks
                 FROM t1
                 GROUP BY t1."Date")

SELECT maximum."Date", t1."Task"
FROM maximum
         JOIN t1 ON t1."Date" = maximum."Date" AND t1.checks_amount = maximum.max_checks;
END;
$$;

SELECT * FROM fnc_part3_task6();

--------------------------------------------------------------------------------
-- Task 7
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fnc_part3_task7(task VARCHAR)
    RETURNS TABLE
            (
                "Peer" VARCHAR,
                "Date" date
            )
    LANGUAGE plpgsql
AS

$$

DECLARE
    last_task VARCHAR;
BEGIN

    SELECT "Title"
    INTO last_task
    FROM tasks
    WHERE "Title" ~ (task || '[0-9]')
    ORDER BY "Title" DESC
    LIMIT 1;

    RETURN QUERY
        SELECT peers."Nickname", c."Date"
        FROM peers
                 JOIN checks c ON peers."Nickname" = c."Peer"
                 JOIN p2p p on c."ID" = p."Check"
                 LEFT JOIN verter v
                           ON c."ID" = v."Check"
        WHERE p."State" = 'Success'
          AND (v."State" = 'Success' OR v."State" IS NULL)
          AND c."Task" = last_task;


END;
$$;


SELECT * FROM fnc_part3_task7('DO');

--------------------------------------------------------------------------------
-- Task 8
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fnc_part3_task8()
RETURNS TABLE(Peer VARCHAR, RecommendedPeer VARCHAR) AS $$
BEGIN
	RETURN QUERY
		WITH recom_friends AS (
			SELECT Recommendations."Peer",
				Recommendations."RecommendedPeer",
				COUNT(Recommendations."RecommendedPeer") AS recoms
			FROM Recommendations
			GROUP BY Recommendations."Peer", Recommendations."RecommendedPeer"),
		counts_recom AS (
			SELECT recom_friends."RecommendedPeer",
				COUNT(recom_friends."RecommendedPeer") AS all_recoms,
				Friends."Peer1" AS Peer
			FROM recom_friends
			LEFT JOIN Friends ON recom_friends."Peer" = Friends."Peer2"
			WHERE Friends."Peer1" != recom_friends."RecommendedPeer"
			GROUP BY recom_friends."RecommendedPeer", recom_friends."Peer", Friends."Peer1"),
		result_out AS (
			SELECT counts_recom.Peer,
				counts_recom."RecommendedPeer",
				all_recoms,
				ROW_NUMBER() OVER (PARTITION BY counts_recom.Peer ORDER BY COUNT(*) DESC) AS num
			FROM counts_recom
			WHERE all_recoms = (SELECT MAX(all_recoms) FROM counts_recom)
				AND counts_recom.Peer != counts_recom."RecommendedPeer"
			GROUP BY counts_recom.Peer, counts_recom."RecommendedPeer", all_recoms
			ORDER BY 1)
	SELECT result_out.Peer, result_out."RecommendedPeer"
	FROM result_out
	WHERE num = 1;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fnc_part3_task8();

--------------------------------------------------------------------------------
-- Task 9
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fnc_part3_task9("block1" VARCHAR, "block2" VARCHAR)
    RETURNS TABLE (StartedBlock1 INT, StartedBlock2 INT, StartedBothBlocks INT, DidntStartAnyBlocks INT)
AS
$$
DECLARE
    "all_peers" BIGINT;
BEGIN
    all_peers := (SELECT count("Nickname") FROM Peers);
    RETURN QUERY
	WITH block1_users AS        (SELECT DISTINCT "Peer"
								FROM Checks
								WHERE checks."Task" ~ ('^' || $1 ||'[0-9]+_{1}')
								),

		 block2_users AS        (SELECT DISTINCT "Peer"
								FROM Checks
								WHERE checks."Task" ~ ('^' || $2 ||'[0-9]+_{1}')
								),

		 both_blocks_users AS   (SELECT "Peer"
								FROM block1_users
								INTERSECT
								SELECT "Peer"
								FROM block2_users
								),

		 neither_block_users AS (SELECT "Nickname" AS Peer
								FROM Peers
								EXCEPT
								(SELECT "Peer"
								FROM block1_users
								UNION DISTINCT
								SELECT "Peer"
								FROM block2_users)
								)
    SELECT ((SELECT count("Peer") FROM block1_users)::numeric/all_peers*100)::int,
           ((SELECT count("Peer") FROM block2_users)::numeric/all_peers*100)::int,
           ((SELECT count("Peer") FROM both_blocks_users)::numeric/all_peers*100)::int,
           ((SELECT count(Peer) FROM neither_block_users)::numeric/all_peers*100)::int;
END
$$ LANGUAGE plpgsql;

SELECT * FROM fnc_part3_task9('DO', 'C');

--------------------------------------------------------------------------------
-- Task 10
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fnc_part3_task10()
    RETURNS TABLE
            (
                SuccessfulChecks   INT,
                UnsuccessfulChecks INT
            )
AS
$$
BEGIN
    RETURN QUERY
        WITH counts AS (SELECT COUNT(Checks."Peer")
                               FILTER (WHERE P2P."State" = 'Success') AS success,
                               COUNT(Checks."Peer")
                               FILTER (WHERE P2P."State" = 'Failure') AS fail
                        FROM Checks
                                 LEFT JOIN Peers ON Checks."Peer" = Peers."Nickname"
                                 JOIN P2P ON Checks."ID" = P2P."Check"
                        WHERE (EXTRACT(MONTH FROM Checks."Date") = EXTRACT(MONTH FROM Peers."Birthday"))
                          AND (EXTRACT(DAY FROM Checks."Date") = EXTRACT(DAY FROM Peers."Birthday")))

        SELECT (success::NUMERIC / NULLIF(success + fail, 0)::NUMERIC * 100)::INT AS SuccessfulChecks,
               (fail::NUMERIC / NULLIF(success + fail, 0)::NUMERIC * 100)::INT    AS UnsuccessfulChecks
        FROM counts;
END
$$ LANGUAGE plpgsql;


SELECT * FROM fnc_part3_task10();

--------------------------------------------------------------------------------
-- Task 11
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fnc_part3_task11(task1 VARCHAR, task2 VARCHAR, task3 VARCHAR)
    RETURNS SETOF VARCHAR
AS
$$
BEGIN
    RETURN QUERY
        WITH success AS (SELECT "Peer", count("Peer")
                         FROM (SELECT "Peer", "Task"
                               FROM ((SELECT *
                                      FROM checks
                                               JOIN XP ON checks."ID" = XP."Check"
                                      WHERE "Task" = task1)
                                     UNION
                                     (SELECT *
                                      FROM checks
                                               JOIN XP ON checks."ID" = XP."Check"
                                      WHERE "Task" = task2)) t1
                               GROUP BY "Peer", "Task") t2
                         GROUP BY "Peer"
                         HAVING count("Peer") = 2)

            (SELECT "Peer"
             FROM success)
        EXCEPT
        (SELECT success."Peer"
         FROM success
                  JOIN checks ON checks."Peer" = success."Peer"
                  JOIN XP ON checks."ID" = XP."Check"
         WHERE "Task" = task3);
END;
$$ LANGUAGE plpgsql;


SELECT * FROM fnc_part3_task11('C1_SimpleBashUtils', 'C5_s21_matrix', 'DO4_LinuxMonitoring_v2.0');

--------------------------------------------------------------------------------
-- Task 12
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fnc_part3_task12()
    RETURNS TABLE
            (
                "Task"      VARCHAR,
                "PrevCount" INT
            )
AS
$$
BEGIN
    RETURN QUERY
        WITH RECURSIVE parent AS
           (SELECT (SELECT "Title"
                    FROM tasks
                    WHERE "ParentTask" IS NULL) AS Task,
                    0 AS PrevCount
            UNION ALL
            SELECT tasks."Title",
                   PrevCount + 1
            FROM parent
                     JOIN tasks ON tasks."ParentTask" = parent.Task)

        SELECT *
        FROM parent;
END;
$$
    LANGUAGE plpgsql;

SELECT * FROM fnc_part3_task12();

--------------------------------------------------------------------------------
-- Task 13
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fnc_part3_task13(n int)
RETURNS SETOF DATE AS
$$
DECLARE
	l RECORD;
	l2 RECORD;
    i INT := 0;
BEGIN
	FOR l IN SELECT "Date" FROM checks GROUP BY "Date" ORDER BY "Date"
	LOOP
		FOR l2 IN SELECT *
				FROM (SELECT "Peer", p2p."State", xp."XPAmount", tasks."MaxXP", p2p."Time", "Date"
					  FROM checks
					  JOIN p2p ON checks."ID" = p2p."Check"
					  LEFT JOIN verter ON checks."ID" = verter."Check"
					  JOIN tasks ON checks."Task" = tasks."Title"
					  JOIN xp ON checks."ID" = xp."Check"
					  WHERE p2p."State" != 'Start'
						AND xp."XPAmount" >= tasks."MaxXP" * 0.8
						AND (verter."State" = 'Success' OR verter."State" IS NULL)
					  ORDER BY 6, 5) AS tmp
				WHERE l."Date" = tmp."Date"
		LOOP
			IF l2."State" = 'Success'
				THEN i := i + 1;
                    IF i = n THEN RETURN NEXT l2."Date";
                        EXIT;
                    END IF;
                ELSE i := 0;
                END IF;
		END LOOP;
        i := 0;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM fnc_part3_task13(2);

--------------------------------------------------------------------------------
-- Task 14
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fnc_part3_task14()
RETURNS TABLE ("Peer" VARCHAR, "XP" INTEGER)
LANGUAGE plpgsql
AS
$$
BEGIN
RETURN QUERY
    SELECT DISTINCT f."Peer", cast(sum(f."XP") as INTEGER) FROM fnc_part3_task2() f
    GROUP BY f."Peer"
    ORDER BY 2 DESC
    LIMIT 1;
END;
$$;

SELECT * FROM fnc_part3_task14();

--------------------------------------------------------------------------------
-- Task 15
--------------------------------------------------------------------------------

DROP TABLE IF EXISTS t_13_tst_t;
CREATE TABLE IF NOT EXISTS t_13_tst_t (
	Peers VARCHAR
);

CREATE OR REPLACE PROCEDURE p_part3_task15(f_time TIME, n INT)
AS $$
BEGIN
	INSERT INTO t_13_tst_t
		SELECT tt."Peer" FROM TimeTracking tt
		WHERE tt."Time" < f_time
		GROUP BY tt."Peer"
		HAVING COUNT(*) >= n;
END;
$$ LANGUAGE plpgsql;

CALL p_part3_task15(TIME '16:00', 2);

SELECT * FROM t_13_tst_t;


--------------------------------------------------------------------------------
-- Task 16
--------------------------------------------------------------------------------

DROP TABLE IF EXISTS t_14_tst_t;
CREATE TABLE IF NOT EXISTS t_14_tst_t (
	Peers VARCHAR
);

CREATE OR REPLACE PROCEDURE get_time_tracking_leaves(N int, M int)
AS $$
BEGIN
    WITH days AS (
    SELECT "Date" FROM TimeTracking
    WHERE "Date" >= CURRENT_DATE - N
    GROUP BY "Date"
    ),
    num_of_peers AS (
    SELECT TimeTracking."Peer", count(*) FROM days
        JOIN TimeTracking ON days."Date" = TimeTracking."Date"
    GROUP BY TimeTracking."Peer"
    )
    INSERT INTO t_14_tst_t
    SELECT num_of_peers."Peer" FROM num_of_peers
    WHERE num_of_peers.count > M;
END;
$$ LANGUAGE plpgsql;

CALL get_time_tracking_leaves(1000, 2);
SELECT * FROM t_14_tst_t;

--------------------------------------------------------------------------------
-- Task 17
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS TempTableTask17 (
	Month        VARCHAR,
	EarlyEntries INT
);

CREATE OR REPLACE PROCEDURE calculate_early_entry_percentage()
AS
$$
BEGIN
	WITH m_entry AS (SELECT date_trunc('month', TimeTracking."Date") AS month_e,
					 COUNT(*)  AS total_entries,
					 COUNT(*) FILTER (WHERE EXTRACT(hour FROM TimeTracking."Time") < 12) AS early_entries
					 FROM TimeTracking
					 JOIN Peers ON TimeTracking."Peer" = Peers."Nickname" AND EXTRACT(month FROM Peers."Birthday") = EXTRACT(month FROM TimeTracking."Date")
					 WHERE TimeTracking."State" = 1
					 GROUP BY date_trunc('month', TimeTracking."Date")
					)
	INSERT INTO TempTableTask17
	SELECT to_char(m_entry.month_e, 'Month'), round(100.0 * m_entry.early_entries / m_entry.total_entries, 2)
	FROM m_entry;
END;
$$ LANGUAGE plpgsql;

CALL calculate_early_entry_percentage();
SELECT * FROM TempTableTask17;
