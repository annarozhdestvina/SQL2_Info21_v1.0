--1) Write a procedure for adding P2P check

CREATE OR replace PROCEDURE addingP2PCheck(PCheckedPeer varchar, PCheckingPeer varchar, task_name varchar, p2p_check_status check_status, time_check time without time zone)
language plpgsql

AS $$
declare 
	check_id integer;
begin 
	if not (select exists (select peers.NickName from peers where peers.NickName = PCheckingPeer))
	then raise 'not found checkingpeer azaza';
	end if;
	
	if not (select exists (select peers.NickName from peers where peers.NickName = PCheckedPeer))
	then raise 'not found checkedpeer aaaaaa';
	end if;
	
	if not (select exists (select tasks.title from tasks where tasks.title = task_name))
	then raise 'not found task_name bebra';
	end if;
	
	
	if (p2p_check_status = 'Start') then
		select max(id)+1 from checks into check_id;
		insert into checks(id, peer, task, date)
		values (check_id, PCheckedPeer, task_name, current_date);
		
	else		
		select (select checks from p2p where p2p.state = 'Start' and p2p.checkingpeer = PCheckingPeer
		except
		select checks from p2p where p2p.state in ('Failure', 'Success') and p2p.checkingpeer = PCheckingPeer) 
		into check_id;
		
	
		if check_id is null then
			raise 'no start status for that checking peer';
		end if;

	end if;
	
	insert into p2p(id, checks, checkingpeer, state, created)
	values ((select max(id)+1 from p2p), check_id, PCheckingPeer, p2p_check_status, time_check);
	
end;
$$;

--  calls for procedures 
call addingP2PCheck( 'Nearache',  'Pararlaf',  'DO4_LinuxMonitoring_v2.0', check_status 'Start', cast('13:15' as time));
call addingP2PCheck( 'Nearache',  'Pararlaf',  'C2_SimpleBashUtils', check_status 'Fuck', cast('13:35' as time));
call addingP2PCheck( 'Nearache',  'Pararlaf',  'C2_SimpleBashUtils', check_status 'Failure', cast('13:35' as time));
call addingP2PCheck( 'Nearache',  'Pararlaf',  'C4_Math', check_status 'Failure', cast('13:35' as time));


call addingP2PCheck( 'Nearache',  'Pararlaf',  'DO4_LinuxMonitoring_v2.0', check_status 'Failure', cast('13:31' as time));


-- 2) A procedure for adding checking by Verter

CREATE OR REPLACE PROCEDURE fill_verter(IN peer_tested VARCHAR, IN task_name VARCHAR(25), IN status_p2p p2p."State"%TYPE,
    IN time_p2p TIME)
AS $$
DECLARE
    p2p_success_exists_id BIGINT = (
        SELECT checks_specific."ID" FROM (
            SELECT * FROM Checks
            WHERE "Peer" = peer_tested AND "Task" = task_name
            ORDER BY "ID" DESC
            LIMIT 1) AS checks_specific
        INNER JOIN P2P
        ON P2P."Check" = checks_specific."ID"
        WHERE P2P."State" = 'Success');
    verter_what_status_exists BIGINT = 0;
BEGIN
    IF p2p_success_exists_id is NULL THEN
        RAISE NOTICE 'This "%" task with "%" peer is not in the "Success" P2P status!', task_name, peer_tested;
    ELSIF status_p2p = 'Start' THEN
        verter_what_status_exists = (SELECT COUNT("Check") FROM Verter WHERE "Check" = p2p_success_exists_id);
        IF verter_what_status_exists = 0 THEN
            INSERT INTO Verter ("Check", "State", "Time")
            VALUES (p2p_success_exists_id, status_p2p, time_p2p);
        ELSE
            RAISE NOTICE 'This "%" task with "%" peer is already in the "Start" Verter status!',task_name, peer_tested;
        END IF;
    ELSE
        verter_what_status_exists = (SELECT COUNT("Check") FROM Verter WHERE "Check" = p2p_success_exists_id);
        IF verter_what_status_exists = 1  THEN
            INSERT INTO Verter ("Check", "State", "Time")
            VALUES (p2p_success_exists_id, status_p2p, time_p2p);
        ELSIF verter_what_status_exists = 0 THEN
            RAISE NOTICE 'This "%" task with "%" peer is not in the "Start" Verter status!', task_name, peer_tested;
        ELSE
            RAISE NOTICE 'This "%" task with "%" peer is already checked by Verter!', task_name, peer_tested;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Task_3 a trigger: after adding a record into p2p table
CREATE OR REPLACE FUNCTION fnc_trg_transferred_point() RETURNS TRIGGER AS
$$
DECLARE
    peer_start VARCHAR = (SELECT "Peer" FROM Checks WHERE Checks."ID" = NEW."Check");
BEGIN
    UPDATE TransferredPoints SET "PointsAmount" = "PointsAmount" + 1 WHERE "CheckingPeer" = NEW."CheckingPeer" AND "CheckedPeer" = peer_start;
    IF NOT FOUND THEN
        INSERT INTO TransferredPoints ("CheckingPeer", "CheckedPeer", "PointsAmount")
        VALUES (NEW."CheckingPeer", peer_start, 1);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_transferred_point
    AFTER INSERT ON P2P
    FOR EACH ROW
    WHEN(NEW."State" = 'Start')
    EXECUTE FUNCTION fnc_trg_transferred_point();

-- Task_4  trigger: before adding a record to the XP
CREATE OR REPLACE FUNCTION fnc_trg_xp() RETURNS TRIGGER AS
$$
DECLARE
    p2p_success_exists_id    BIGINT  = (SELECT P2P."Check"
                                        FROM P2P
                                        WHERE NEW."Check" = P2P."Check"
                                          AND P2P."State" = 'Success');
    xp_amount_max_task       INT     = (SELECT Tasks."MaxXP"
                                        FROM (SELECT * FROM Checks WHERE Checks."ID" = NEW."Check") AS checks_new
                                                 INNER JOIN Tasks
                                                            ON Tasks."Title" = checks_new."Task");
    verter_success_exists_id VARCHAR = (SELECT "State"
                                        FROM Verter
                                        WHERE NEW."Check" = Verter."Check"
                                        ORDER BY "State" DESC
                                        LIMIT 1);
BEGIN
    IF xp_amount_max_task < NEW."XPAmount" THEN
        RAISE NOTICE 'XPAmount more than MaxXP!';
        RETURN NULL;
    ELSIF p2p_success_exists_id is NULL THEN
        RAISE NOTICE 'P2P status is not Success!';
        RETURN NULL;
    ELSIF verter_success_exists_id = 'Failure' OR verter_success_exists_id = 'Start' THEN
        RAISE NOTICE 'Verter status is not Success';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_xp
    BEFORE INSERT ON XP
    FOR EACH ROW
    EXECUTE FUNCTION fnc_trg_xp();


CALL add_p2p('Dynarini', 'Oryadela', 'C2_SimpleBashUtils', 'Success');
CALL add_p2p('Oryadela', 'Dynarini', 'C4_Math', 'Start');

-- TASk_2_3_KЕЙС_1 (Если Р2P не SUCCESS. Вернет RAISE NOTICE)
CALL fill_verter('Dima', 'C3_s21_math', 'Start', '12:00');
-- TASk_2_KЕЙС_1 (Если Verter не начат. Но хотим ввести Success или Failure. Вернет RAISE NOTICE)
CALL fill_verter('Dima', 'C3_s21_math', 'Success', '12:00');
CALL fill_verter('Dima', 'C3_s21_math', 'Failure', '12:00');
-- TASk_2_KЕЙС_2 (Если Verter уже Start. Вернет RAISE NOTICE)
CALL fill_verter('Dima', 'C3_s21_math', 'Start', '12:00');
CALL fill_verter('Dima', 'C3_s21_math', 'Start', '12:00');
-- TASk_2_KЕЙС_2 (Если Verter уже SUCCESS или Failure. Но хотим ввести Success или Failure. Вернет RAISE NOTICE)
CALL fill_verter('Dima', 'C3_s21_math', 'Success', '12:00');
CALL fill_verter('Dima', 'C3_s21_math', 'Success', '12:00');
-- TASk_4_KЕЙС_1 (Если Verter уже SUCCESS или Failure. Но хотим ввести Success или Failure. Вернет RAISE NOTICE)
INSERT INTO XP ("Check", "XPAmount")
VALUES ((SELECT MAX("ID") FROM Checks), 200);