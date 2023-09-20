CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');

create table if not exists P2P
(
	id bigint primary key,
	Checks integer,
	CheckingPeer varchar,
	state check_status,
	created time  
);

create table if not exists TransferredPoints
(
	id bigint primary key,
	CheckingPeer varchar,
	CheckedPeer varchar,
	PointsAmount integer
);

create table if not exists Friends
(
	id bigint primary key,
	Peer1 varchar,
	Peer2 varchar
);

create table if not exists Recommendations
(
	id bigint primary key,
	Peer varchar,
	RecommendatedPeer varchar
);

create table if not exists TimeTracking
(
	id bigint primary key,
	Peer varchar,
	Date date not null,
	created time,
	State integer
);

create table if not exists Checks
(
	id bigint primary key,
	Peer varchar,
	Task varchar,
	Date date not null
);

create table if not exists Peers
(
	NickName varchar primary key,
	Birthday date not null
);

create table if not exists Verter
(
	id bigint primary key,
	Checks bigint,
	State varchar,
	created time
);

create table if not exists XP
(
	id bigint primary key,
	Checks bigint,
	XPAmount bigint
);

create table if not exists Tasks
(
	Title varchar primary key,
	ParentTask varchar,
	MaxXP bigint
);


COPY tasks
FROM '/Users/annarozdestvina/Documents/School21/SQL2_Info21_v1.0-1/src/data/tasks.csv'
DELIMITER ';'
CSV Header;

SELECT * FROM public.tasks


COPY checks
FROM '/Users/annarozdestvina/Documents/School21/SQL2_Info21_v1.0-1/src/data/checks.csv'
DELIMITER ';'
CSV Header;

COPY friends
FROM '/Users/annarozdestvina/Documents/School21/SQL2_Info21_v1.0-1/src/data/friends.csv'
DELIMITER ';'
CSV Header;

COPY p2p
FROM '/Users/annarozdestvina/Documents/School21/SQL2_Info21_v1.0-1/src/data/p2p.csv'
DELIMITER ';'
CSV Header;

COPY peers
FROM '/Users/annarozdestvina/Documents/School21/SQL2_Info21_v1.0-1/src/data/peers.csv'
DELIMITER ';'
CSV Header;

COPY recommendations
FROM '/Users/annarozdestvina/Documents/School21/SQL2_Info21_v1.0-1/src/data/recommends.csv'
DELIMITER ';'
CSV Header;

COPY TimeTracking
FROM '/Users/annarozdestvina/Documents/School21/SQL2_Info21_v1.0-1/src/data/timetrack.csv'
DELIMITER ';'
CSV Header;

COPY transferredpoints
FROM '/Users/annarozdestvina/Documents/School21/SQL2_Info21_v1.0-1/src/data/transfer.csv'
DELIMITER ';'
CSV Header;

COPY verter
FROM '/Users/annarozdestvina/Documents/School21/SQL2_Info21_v1.0-1/src/data/verter.csv'
DELIMITER ';'
CSV Header;

COPY xp
FROM '/Users/annarozdestvina/Documents/School21/SQL2_Info21_v1.0-1/src/data/xp.csv'
DELIMITER ';'
CSV Header;