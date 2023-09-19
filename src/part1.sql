create table if not exists P2P
(
	id bigint primary key,
	Checks integer,
	CheckingPeer varchar,
	state varchar,
	created  timestamp with time zone not null
    default (current_timestamp at time zone 'UTC')
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
	created timestamp with time zone not null default current_timestamp,
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
	created timestamp with time zone not null default current_timestamp
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


