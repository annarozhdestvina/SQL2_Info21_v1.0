-- part1 creation of tables and enum for status

CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');  

CREATE TABLE IF NOT EXISTS Peers
(
    "Nickname" VARCHAR(25) UNIQUE PRIMARY KEY,
    "Birthday" DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS Tasks
(
    "Title" VARCHAR(50) UNIQUE PRIMARY KEY,
    "ParentTask" VARCHAR(50) DEFAULT NULL,
    "MaxXP" NUMERIC NOT NULL,
    CONSTRAINT fk_tasks_parent_task FOREIGN KEY ("ParentTask") REFERENCES Tasks("Title")
);

CREATE TABLE IF NOT EXISTS Checks
(
	"ID" SERIAL PRIMARY KEY,
	"Peer" VARCHAR(25) NOT NULL,
	"Task" VARCHAR(25) NOT NULL,
	"Date" DATE NOT NULL DEFAULT CURRENT_DATE,
 	CONSTRAINT fk_checks_nickname FOREIGN KEY ("Peer") REFERENCES Peers("Nickname"),
 	CONSTRAINT fk_checks_task FOREIGN KEY ("Task") REFERENCES Tasks("Title")
);

CREATE TABLE IF NOT EXISTS P2P
(
	"ID" SERIAL PRIMARY KEY,
	"Check" BIGINT NOT NULL,
	"CheckingPeer" VARCHAR(25) NOT NULL,
	"State" check_status NOT NULL,
	"Time" TIME WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIME,
	CONSTRAINT fk_p2p_check FOREIGN KEY ("Check") REFERENCES Checks("ID"),
	CONSTRAINT fk_p2p_checking_peer FOREIGN KEY ("CheckingPeer") REFERENCES Peers("Nickname")
);

CREATE TABLE IF NOT EXISTS Verter
("ID" SERIAL PRIMARY KEY,
 "Check" BIGINT NOT NULL,
 "State" check_status NOT NULL,
 "Time" TIME WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIME,
 CONSTRAINT fk_verter_check FOREIGN KEY ("Check") REFERENCES Checks("ID")
);

CREATE TABLE IF NOT EXISTS TransferredPoints
(
	"ID" SERIAL PRIMARY KEY,
 	"CheckingPeer" VARCHAR(25) NOT NULL,
 	"CheckedPeer" VARCHAR(25) NOT NULL,
 	"PointsAmount" INT NOT NULL,
 	CONSTRAINT fk_transferred_points_checking_peer FOREIGN KEY ("CheckingPeer") REFERENCES Peers("Nickname"),
 	CONSTRAINT fk_transferred_points_checked_peer FOREIGN KEY ("CheckedPeer") REFERENCES Peers("Nickname")
);

-- Индекс для обеспечения гарантии уникальности записей пар пир1-пир2
-- и уменьшает стоимость JOIN
CREATE UNIQUE INDEX IF NOT EXISTS idx_transferred_points_checkingpeer_checkedpeer_unique ON TransferredPoints USING btree ("CheckingPeer", "CheckedPeer");
-- Ускоряет JOIN по nickname
CREATE INDEX IF NOT EXISTS idx_transferred_points_checkingpeer ON TransferredPoints USING btree ("CheckingPeer");
-- Ускоряет JOIN по nickname
CREATE INDEX IF NOT EXISTS idx_transferred_points_checkedpeer ON TransferredPoints USING btree ("CheckedPeer");

CREATE TABLE IF NOT EXISTS Friends
(
	"ID" SERIAL PRIMARY KEY,
 	"Peer1" VARCHAR(25) NOT NULL,
 	"Peer2" VARCHAR(25) NOT NULL,
 	CONSTRAINT fk_friends_peer1 FOREIGN KEY ("Peer1") REFERENCES Peers("Nickname"),
 	CONSTRAINT fk_friends_peer2 FOREIGN KEY ("Peer2") REFERENCES Peers("Nickname")
);

CREATE TABLE IF NOT EXISTS Recommendations
(
	"ID" SERIAL PRIMARY KEY,
 	"Peer" VARCHAR(25) NOT NULL,
 	"RecommendedPeer" VARCHAR(25) NOT NULL,
 	CONSTRAINT fk_recommendations_peer FOREIGN KEY ("Peer") REFERENCES Peers("Nickname"),
 	CONSTRAINT fk_recommendations_recommended_peer FOREIGN KEY ("RecommendedPeer") REFERENCES Peers("Nickname")
);

CREATE TABLE IF NOT EXISTS XP
(
	"ID" SERIAL PRIMARY KEY,
	"Check" BIGINT NOT NULL,
	"XPAmount" INT NOT NULL,
	CONSTRAINT fk_xp_check FOREIGN KEY ("Check") REFERENCES Checks("ID")
);

-- Индекс для обеспечения гарантии уникальности записей в XP
-- (Для одной проверки Check только одна запись с опытом)
CREATE UNIQUE INDEX IF NOT EXISTS idx_xp_check_unique ON XP USING btree("Check");

CREATE TABLE IF NOT EXISTS TimeTracking
(
	"ID" SERIAL PRIMARY KEY,
 	"Peer" VARCHAR(25) NOT NULL,
 	"Date" DATE NOT NULL DEFAULT CURRENT_DATE,
 	"Time" TIME WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIME,
 	"State" INT NOT NULL,
 	CONSTRAINT fk_time_tracking_state CHECK ("State" IN (1, 2)),
 	CONSTRAINT fk_time_tracking_peer FOREIGN KEY ("Peer") REFERENCES Peers("Nickname")
);

-- create procedure for not duplication of code
CREATE OR REPLACE PROCEDURE import_csv(
        IN table_name text,
        IN csv_file text,
        IN delimiter char DEFAULT ';'
    ) AS $$
DECLARE data_path text := '/Users/annarozdestvina/Documents/School21/SQL2_Info21_v1.0-2/src/data/';
BEGIN EXECUTE format(
    'COPY %s FROM ''%s'' DELIMITER ''%s'' CSV HEADER NULL AS ''null'';',
    table_name,
    data_path || csv_file,
    delimiter
);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE export_csv(
        IN table_name text,
        IN csv_file text,
        IN delimiter char DEFAULT ';'
    ) AS $$
DECLARE data_path text := '/Users/annarozdestvina/Documents/School21/SQL2_Info21_v1.0-2/src/data/';
BEGIN EXECUTE format(
    'COPY %s TO ''%s'' DELIMITER ''%s'' CSV HEADER NULL AS ''null'';',
    table_name,
    data_path || csv_file,
    delimiter
);
END;
$$ LANGUAGE plpgsql;

CALL import_csv('Peers', 'peers.csv', ';');
CALL import_csv('Tasks', 'tasks.csv', ';');
CALL import_csv('Checks', 'checks.csv', ';');
CALL import_csv('P2P', 'p2p.csv', ';');
CALL import_csv('Verter', 'verter.csv', ';');
CALL import_csv('TransferredPoints', 'transfer.csv', ';');
CALL import_csv('Friends', 'friends.csv', ';');
CALL import_csv('Recommendations', 'recommends.csv', ';');
CALL import_csv('XP', 'xp.csv', ';');
CALL import_csv('TimeTracking', 'timetrack.csv', ';');

-- CALL export_csv('Peers', 'peers.csv', ';');
-- CALL export_csv('Tasks', 'tasks.csv', ';');
-- CALL export_csv('Checks', 'checks.csv', ';');
-- CALL export_csv('P2P', 'p2p.csv', ';');
-- CALL export_csv('Verter', 'verter.csv', ';');
-- CALL export_csv('TransferredPoints', 'transfer.csv', ';');
-- CALL export_csv('Friends', 'friends.csv', ';');
-- CALL export_csv('Recommendations', 'recommends.csv', ';');
-- CALL export_csv('XP', 'xp.csv', ';');
-- CALL export_csv('TimeTracking', 'timetrack.csv', ';');

-- CALL pr_export_table('peers', current_s
